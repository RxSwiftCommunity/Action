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

        buffer.subscribe(onNext: {[weak self] element in
                    self?._elements.onNext(element)
                },
                onError: {[weak self] error in
                    self?._errors.onNext(ActionError.UnderlyingError(error))
                },
                onCompleted: nil,
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
