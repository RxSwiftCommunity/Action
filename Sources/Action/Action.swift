import Foundation
import RxSwift
import RxCocoa

/// Typealias for compatibility with UIButton's rx.action property.
public typealias CocoaAction = Action<Void, Void>


public final class ControlAction: NSObject {
    /// The selector for message senders.
    
    public typealias Sender = Any
        
    /// Whether the action is enabled.
    ///
    /// This property will only change on the main thread.
    public let enabled: Observable<Bool>
    
    /// Whether the action is executing.
    ///
    /// This property will only change on the main thread.
    public let executing: Observable<Bool>
    
    private let _execute: (Sender) -> Void
    
    /// Initialize a CocoaAction that invokes the given Action by mapping the
    /// sender to the input type of the Action.
    ///
    /// - parameters:
    ///   - action: The Action.
    ///   - inputTransform: A closure that maps Sender to the input type of the
    ///                     Action.
    public init<Input, Output>(_ action: Action<Input, Output>, _ inputTransform: @escaping (Sender) -> Input) {
        _execute = { sender in
            let observer = action.execute(inputTransform(sender))
            _ = observer.subscribe()
        }
        
        
        self.enabled = action.enabled
        self.executing = action.executing
        super.init()
    }
    
    /// Initialize a CocoaAction that invokes the given Action.
    ///
    /// - parameters:
    ///   - action: The Action.
    public convenience init<Output>(_ action: Action<(), Output>) {
        self.init(action, { _ in })
    }
    
    /// Initialize a CocoaAction that invokes the given Action with the given
    /// constant.
    ///
    /// - parameters:
    ///   - action: The Action.
    ///   - input: The constant value as the input to the action.
    public convenience init<Input, Output>(_ action: Action<Input, Output>, input: Input) {
        self.init(action, { _ in input })
    }
    
    /// Attempt to execute the underlying action with the given input, subject
    /// to the behavior described by the initializer that was used.
    ///
    /// - parameters:
    ///   - sender: The sender which initiates the attempt.
    @IBAction public func execute(_ sender: Any) {
        _execute(sender )
    }
}


/// Possible errors from invoking execute()
public enum ActionError: Error {
    case notEnabled
    case underlyingError(Error)
}

/**
Represents a value that accepts a workFactory which takes some Observable<Input> as its input
and produces an Observable<Element> as its output.

When this excuted via execute() or inputs subject, it passes its parameter to this closure and subscribes to the work.
*/
public final class Action<Input, Element> {
    public typealias WorkFactory = (Input) -> Observable<Element>

    public let _enabledIf: Observable<Bool>
    public let workFactory: WorkFactory

    /// Inputs that triggers execution of action.
    /// This subject also includes inputs as aguments of execute().
    /// All inputs are always appear in this subject even if the action is not enabled.
    /// Thus, inputs count equals elements count + errors count.
    public let inputs = PublishSubject<Input>()

    /// Errors aggrevated from invocations of execute().
    /// Delivered on whatever scheduler they were sent from.
    public let errors: Observable<ActionError>

    /// Whether or not we're currently executing.
    /// Delivered on whatever scheduler they were sent from.
    public let elements: Observable<Element>

    /// Whether or not we're currently executing. 
    public let executing: Observable<Bool>

    /// Observables returned by the workFactory.
    /// Useful for sending results back from work being completed
    /// e.g. response from a network call.
    public let executionObservables: Observable<Observable<Element>>

    /// Whether or not we're enabled. Note that this is a *computed* sequence
    /// property based on enabledIf initializer and if we're currently executing.
    /// Always observed on MainScheduler.
    public let enabled: Observable<Bool>

    private let disposeBag = DisposeBag()

    public init(
        enabledIf: Observable<Bool> = Observable.just(true),
        workFactory: @escaping WorkFactory) {
        
        self._enabledIf = enabledIf
        self.workFactory = workFactory

        let enabledSubject = BehaviorSubject<Bool>(value: false)
        enabled = enabledSubject.asObservable()
        
        executionObservables = inputs
            .withLatestFrom(enabled) { $0 }
            .flatMap { input, enabled -> Observable<Observable<Element>> in
                if enabled {
                    return Observable.of(workFactory(input).shareReplay(1))
                } else {
                    return Observable.empty()
                }
            }
            .share()

        elements = executionObservables
            .flatMap { $0.catchError { _ in Observable.empty() } }

        let notEnabledError = inputs
            .withLatestFrom(enabled)
            .flatMap { $0 ? Observable.empty() : Observable.of(ActionError.notEnabled) }

        let underlyingError = executionObservables
            .flatMap { elements in
                return elements
                    .flatMap { _ in Observable<ActionError>.never() }
                    .catchError { error in
                        if let actionError = error as? ActionError {
                            return Observable.of(actionError)
                        } else {
                            return Observable.of(.underlyingError(error))
                        }
                    }
            }
        
        errors = Observable
            .of(notEnabledError, underlyingError)
            .merge()

        executing = executionObservables.flatMap {
                execution -> Observable<Bool> in
                let execution = execution
                    .flatMap { _ in Observable<Bool>.empty() }
                    .catchError { _ in Observable.empty()}

                return Observable.concat([Observable.just(true),
                                          execution,
                                          Observable.just(false)])
            }
            .startWith(false)
            .shareReplay(1)

        Observable
            .combineLatest(executing, enabledIf) { !$0 && $1 }
            .bindTo(enabledSubject)
            .addDisposableTo(disposeBag)
    }

    @discardableResult
    public func execute(_ value: Input) -> Observable<Element> {
        defer {
            inputs.onNext(value)
        }

        let execution = executionObservables
            .take(1)
            .flatMap { $0 }
            .catchError { throw ActionError.underlyingError($0) }

        let notEnabledError = inputs
            .takeUntil(executionObservables)
            .withLatestFrom(enabled)
            .flatMap { $0 ? Observable<Element>.empty() : Observable.error(ActionError.notEnabled) }

        let subject = ReplaySubject<Element>.createUnbounded()
        Observable
            .of(execution, notEnabledError)
            .merge()
            .subscribe(subject)
            .addDisposableTo(disposeBag)

        return subject.asObservable()
    }
}
