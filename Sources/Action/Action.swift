import Foundation
import RxSwift
import RxCocoa

/// Typealias for compatibility with UIButton's rx.action property.
public typealias CocoaAction = Action<Void, Void>

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
    /// Always observed on MainScheduler.
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

        let executionStart = executionObservables
        let executionEnd = executionObservables
            .flatMap { observable -> Observable<Void> in
                return observable
                    .flatMap { _ in Observable<Void>.empty() }
                    .concat(Observable.just())
                    .catchErrorJustReturn()
            }

        executing = Observable
            .of(executionStart.map { _ in true }, executionEnd.map { _ in false })
            .merge()
            .shareReplay(1)
            .startWith(false)

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
