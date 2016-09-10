import Foundation
import RxSwift
import RxCocoa

/// Typealias for compatibility with UIButton's rx_action property.
public typealias CocoaAction = Action<Void, Void>

/// Possible errors from invoking execute()
public enum ActionError: Error {
    case notEnabled
    case underlyingError(Error)
}

/// TODO: Add some documentation.
public final class Action<Input, Element> {
    public typealias WorkFactory = (Input) -> Observable<Element>

    public let _enabledIf: Observable<Bool>
    public let workFactory: WorkFactory

    /// Inputs that triggers execution of action.
    /// This subject also includes inputs as aguments of execute().
    /// All inputs are always appear in this subject even if the action is not enabled.
    /// Thus, inputs count equals elements count + errors count.
    public let inputs = PublishSubject<Input>()
    fileprivate let _completed = PublishSubject<Void>()

    /// Errors aggrevated from invocations of execute(). 
    /// Delivered on whatever scheduler they were sent from.
    public var errors: Observable<ActionError> {
        return self._errors.asObservable()
    }
    fileprivate let _errors = PublishSubject<ActionError>()

    /// Whether or not we're currently executing. 
    /// Delivered on whatever scheduler they were sent from.
    public var elements: Observable<Element> {
        return self._elements.asObservable()
    }
    fileprivate let _elements = PublishSubject<Element>()

    /// Whether or not we're currently executing. 
    /// Always observed on MainScheduler.
    public var executing: Observable<Bool> {
        return self._executing.asObservable().observeOn(MainScheduler.instance)
    }
    fileprivate let _executing = Variable(false)
    
    /// Observables returned by the workFactory.
    /// Useful for sending results back from work being completed
    /// e.g. response from a network call.
    public var executionObservables: Observable<Observable<Element>> {
        return self._executionObservables.asObservable().observeOn(MainScheduler.instance)
    }
    fileprivate let _executionObservables = PublishSubject<Observable<Element>>()
    
    /// Whether or not we're enabled. Note that this is a *computed* sequence
    /// property based on enabledIf initializer and if we're currently executing.
    /// Always observed on MainScheduler.
    public var enabled: Observable<Bool> {
        return _enabled.asObservable().observeOn(MainScheduler.instance)
    }
    public fileprivate(set) var _enabled = BehaviorSubject(value: true)

    fileprivate let executingQueue = DispatchQueue(label: "com.ashfurrow.Action.executingQueue", attributes: [])
    fileprivate let disposeBag = DisposeBag()

    public init(enabledIf: Observable<Bool> = Observable.just(true), workFactory: @escaping WorkFactory) {
        self._enabledIf = enabledIf
        
        self.workFactory = workFactory

        Observable.combineLatest(self._enabledIf, self.executing) { (enabled, executing) -> Bool in
            return enabled && !executing
        }.bindTo(_enabled).addDisposableTo(disposeBag)

        self.inputs.subscribe(onNext: { [weak self] (input) in
            self?._execute(input)
        }).addDisposableTo(disposeBag)
    }
}


// MARK: Execution!
public extension Action {

    @discardableResult
    public func execute(_ input: Input) -> Observable<Element> {
        let buffer = ReplaySubject<Element>.createUnbounded()
        let error = errors
            .flatMap { error -> Observable<Element> in
                if case .underlyingError(let error) = error {
                    throw error
                } else {
                    return Observable.empty()
                }
            }
        
        Observable
            .of(elements, error)
            .merge()
            .takeUntil(_completed)
            .bindTo(buffer)
            .addDisposableTo(disposeBag)
        
        inputs.onNext(input)
        
        return buffer.asObservable()
    }

    @discardableResult
    fileprivate func _execute(_ input: Input) -> Observable<Element> {

        // Buffer from the work to a replay subject.
        let buffer = ReplaySubject<Element>.createUnbounded()

        // See if we're already executing.
        var startedExecuting = false
        self.doLocked {
            if self._enabled.valueOrFalse {
                self._executing.value = true
                startedExecuting = true
            }
        }

        // Make sure we started executing and we're accidentally disabled.
        guard startedExecuting else {
            let error = ActionError.notEnabled
            self._errors.onNext(error)
            buffer.onError(error)

            return buffer
        }

        let work = self.workFactory(input)
        defer {
            // Subscribe to the work.
            work.multicast(buffer).connect().addDisposableTo(disposeBag)
        }

		self._executionObservables.onNext(buffer)

        buffer.subscribe(onNext: {[weak self] element in
                    self?._elements.onNext(element)
                },
                onError: {[weak self] error in
                    self?._errors.onNext(ActionError.underlyingError(error))
                },
                onCompleted: {[weak self] in
                    self?._completed.onNext()
                },
                onDisposed: {[weak self] in
                    self?.doLocked { self?._executing.value = false }
                })
            .addDisposableTo(disposeBag)


        return buffer.asObservable()
    }
}

private extension Action {
    func doLocked(_ closure: () -> Void) {
        executingQueue.sync(execute: closure)
    }
}

internal extension BehaviorSubject where Element: ExpressibleByBooleanLiteral {
    var valueOrFalse: Element {
        guard let value = try? value() else { return false }

        return value
    }
}
