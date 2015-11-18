import Foundation
import RxSwift

// Possible errors from invoking execute()
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
        return self._executing.asObservable().observeOn(MainScheduler.sharedInstance)
    }
    private let _executing = Variable(false)

    /// Whether or not we're enabled. Note that this is a *computed* sequence
    /// property based on enabledIf initializer and if we're currently executing.
    /// Always observed on MainScheduler.
    public var enabled: Observable<Bool> {
        return _enabled.asObservable().observeOn(MainScheduler.sharedInstance)
    }
    public private(set) var _enabled = BehaviorSubject(value: true)

    private let executingQueue = dispatch_queue_create("com.ashfurrow.Action.executingQueue", DISPATCH_QUEUE_SERIAL)
    private let disposeBag = DisposeBag()

    public init(enabledIf: Observable<Bool>, workFactory: WorkFactory) {
        self._enabledIf = enabledIf
        self.workFactory = workFactory

        combineLatest(self._enabledIf, self.executing) { (enabled, executing) -> Bool in
            return enabled && !executing
        }.bindTo(_enabled).addDisposableTo(disposeBag)
    }
}

public extension Action {

    public convenience init(workFactory: WorkFactory) {
        self.init(enabledIf: just(true), workFactory: workFactory)
    }

    public func execute(input: Input) -> Observable<Element> {
        return create { (observer) -> Disposable in
            var startedExecuting = false

            self.doLocked {
                if self._enabled.valueOrFalse {
                    self._executing.value = true
                    startedExecuting = true
                }
            }

            guard startedExecuting else {
                observer.onError(ActionError.NotEnabled)
                return NopDisposable.instance
            }

            let work = self.workFactory(input)

            // Buffer from the work to a replay subject.
            let buffer = ReplaySubject<Element>.create(bufferSize: Int.max)
            buffer.doOn { (event) in

                // Pipe values to _elements and errors to _errors.
                // Completion of the work signals we're no longer executing.
                switch event {
                case .Next(let element):
                    self._elements.onNext(element)
                case .Error(let error):
                    self._errors.onNext(ActionError.UnderlyingError(error))
                    fallthrough
                case .Completed:
                    self.doLocked {
                        self._executing.value = false
                    }
                }
            }.subscribe(observer)

            // Subscribe to the work
            work.multicast(buffer).connect()

            return NopDisposable.instance
        }
    }
}

private extension Action {
    private func doLocked(closure: () -> Void) {
        dispatch_sync(executingQueue, closure)
    }
}

private extension BehaviorSubject where Element: BooleanLiteralConvertible {
    var valueOrFalse: Element {
        guard let value = try? value() else { return false }

        return value
    }
}
