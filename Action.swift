import Foundation
import RxSwift
import RxCocoa

/// Typealias for compatibility with UIButton's rx_action property.
public typealias CocoaAction = Action<Void, Void>

/// Possible errors from invoking execute()
public enum ActionError: ErrorType {
    case NotEnabled
    case UnderlyingError(ErrorType)
}

/// TODO: Add some documentation.
public final class Action<Input, Element> {
    public typealias WorkFactory = Input -> Observable<Element>

    public let _enabledIf: Observable<Bool>
    public let workFactory: WorkFactory

    /// Inputs that triggers execution of action.
    /// This subject also includes inputs as aguments of execute().
    /// All inputs are always appear in this subject even if the action is not enabled.
    /// Thus, inputs count equals elements count + errors count.
    public let inputs = PublishSubject<Input>()
    private let _completed = PublishSubject<Void>()

    /// Errors aggrevated from invocations of execute(). 
    /// Delivered on whatever scheduler they were sent from.
    public var errors: Observable<ActionError> {
        return self._errors.asObservable()
    }
    private let _errors = PublishSubject<ActionError>()

    /// Whether or not we're currently executing. 
    /// Delivered on whatever scheduler they were sent from.
    public var elements: Observable<Element> {
        return self._elements.asObservable()
    }
    private let _elements = PublishSubject<Element>()

    /// Whether or not we're currently executing. 
    /// Always observed on MainScheduler.
    public var executing: Observable<Bool> {
        return self._executing.asObservable().observeOn(MainScheduler.instance)
    }
    private let _executing = Variable(false)
    
    /// Observables returned by the workFactory.
    /// Useful for sending results back from work being completed
    /// e.g. response from a network call.
    public var executionObservables: Observable<Observable<Element>> {
        return self._executionObservables.asObservable().observeOn(MainScheduler.instance)
    }
    private let _executionObservables = PublishSubject<Observable<Element>>()
    
    /// Whether or not we're enabled. Note that this is a *computed* sequence
    /// property based on enabledIf initializer and if we're currently executing.
    /// Always observed on MainScheduler.
    public var enabled: Observable<Bool> {
        return _enabled.asObservable().observeOn(MainScheduler.instance)
    }
    public private(set) var _enabled = BehaviorSubject(value: true)

    private let executingQueue = dispatch_queue_create("com.ashfurrow.Action.executingQueue", DISPATCH_QUEUE_SERIAL)
    private let disposeBag = DisposeBag()

    public init<B: BooleanType>(enabledIf: Observable<B>, workFactory: WorkFactory) {
        self._enabledIf = enabledIf.map { booleanType in
            return booleanType.boolValue
        }
        self.workFactory = workFactory

        Observable.combineLatest(self._enabledIf, self.executing) { (enabled, executing) -> Bool in
            return enabled && !executing
        }.bindTo(_enabled).addDisposableTo(disposeBag)

        self.inputs
            .subscribeNext { [weak self] input in
                self?._execute(input)
            }
            .addDisposableTo(disposeBag)
    }
}

// MARK: Convenience initializers.
public extension Action {

    /// Always enabled.
    public convenience init(workFactory: WorkFactory) {
        self.init(enabledIf: .just(true), workFactory: workFactory)
    }
}

// MARK: Execution!
public extension Action {

    public func execute(input: Input) -> Observable<Element> {
        let buffer = ReplaySubject<Element>.createUnbounded()
        let error = errors
            .flatMap { error -> Observable<Element> in
                if case .UnderlyingError(let error) = error {
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

    private func _execute(input: Input) -> Observable<Element> {

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
            let error = ActionError.NotEnabled
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
                    self?._errors.onNext(ActionError.UnderlyingError(error))
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
    private func doLocked(closure: () -> Void) {
        dispatch_sync(executingQueue, closure)
    }
}

internal extension BehaviorSubject where Element: BooleanLiteralConvertible {
    var valueOrFalse: Element {
        guard let value = try? value() else { return false }

        return value
    }
}
