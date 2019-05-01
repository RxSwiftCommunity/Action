import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class RefreshControlTests: QuickSpec {
    override func spec() {

        it("is nil by default") {
            let subject = UIRefreshControl()
            expect(subject.rx.action).to( beNil() )
        }

        it("respects setter") {
            var subject = UIRefreshControl()

            let action = emptyAction()

            subject.rx.action = action

            expect(subject.rx.action) === action
        }

        it("disables the refresh control while executing") {
            var subject = UIRefreshControl()

            var observer: AnyObserver<Void>!
            let action = CocoaAction(workFactory: { _ in
                return Observable.create { (obsv) -> Disposable in
                    observer = obsv
                    return Disposables.create()
                }
            })

            subject.rx.action = action

            action.execute()
            expect(subject.isEnabled).toEventually( beFalse() )

            observer.onCompleted()
            expect(subject.isEnabled).toEventually( beTrue() )
        }

        it("disables the refresh control if the Action is disabled") {
            var subject = UIRefreshControl()

            subject.rx.action = emptyAction(.just(false))
            expect(subject.allTargets.count) == 1

            expect(subject.isEnabled) == false
        }

        it("doesn't execute a disabled action when refreshed") {
            var subject = UIRefreshControl()

            var executed = false
            subject.rx.action = CocoaAction(enabledIf: .just(false), workFactory: { _ in
                executed = true
                return .empty()
            })

            subject.sendActions(for: .valueChanged)

            expect(executed) == false
        }

        it("executes the action when refreshed") {
            var subject = UIRefreshControl()

            var executed = false
            let action = CocoaAction(workFactory: { _ in
                executed = true
                return .empty()
            })
            subject.rx.action = action

            // Setting the action has an asynchronous effect of adding a target.
            expect(subject.allTargets.count) == 1

            subject.test_executeRefresh()

            expect(executed).toEventually( beTrue() )
        }

        it("disposes of old action subscriptions when re-set") {
            var subject = UIRefreshControl()

            var disposed = false
            autoreleasepool {
                let disposeBag = DisposeBag()

                let action = emptyAction()
                subject.rx.action = action

                action
                    .elements
                    .subscribe(onNext: nil, onError: nil, onCompleted: nil, onDisposed: {
                        disposed = true
                    })
                    .disposed(by: disposeBag)
            }

            subject.rx.action = nil

            expect(disposed) == true
        }

        it("disposes of old action subscriptions when re-set") {
            var subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)

            var disposed = false
            autoreleasepool {
                let disposeBag = DisposeBag()

                let action = emptyAction()
                subject.rx.action = action

                action
                    .elements
                    .subscribe(onNext: nil, onError: nil, onCompleted: nil, onDisposed: {
                        disposed = true
                    })
                    .disposed(by: disposeBag)
            }

            subject.rx.action = nil

            expect(disposed) == true
        }
    }
}
