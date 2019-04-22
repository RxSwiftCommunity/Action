import Foundation
import RxSwift

public extension Action {
    /// Filters out `notEnabled` errors and returns
    /// only underlying error from `ActionError`
    var underlyingError: Observable<Error> {
        return errors.flatMap { actionError -> Observable<Error> in
            guard case .underlyingError(let error) = actionError else {
                return Observable.empty()
            }
            return Observable.just(error)
        }
    }
}

public extension Action where Input == Void {
    /// use to trigger an action.
    @discardableResult
    func execute() -> Observable<Element> {
        return execute(())
    }
}

extension CompletableAction {
    /// Emits everytime work factory completes.
    public var completions: Observable<Void> {
        return executionObservables
            .flatMap { execution in
                execution.flatMap {_ in Observable.empty() }
                    .concat(Observable.just(()))
        }
    }
}
