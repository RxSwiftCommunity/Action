import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class ButtonTests: QuickSpec {
    override func spec() {

        it("is nil by default") {
            let subject = UIButton(type: .system)
            expect(subject.rx.action).to( beNil() )
        }

        it("respects setter") {
            var subject = UIButton(type: .system)

            let action = emptyAction()

            subject.rx.action = action

            expect(subject.rx.action) === action
        }

        it("disables the button while executing") {
            var subject = UIButton(type: .system)

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

        it("disables the button if the Action is disabled") {
            var subject = UIButton(type: .system)

            subject.rx.action = emptyAction(.just(false))
            
            expect(subject.isEnabled).toEventually(beFalse())
        }

        it("doesn't execute a disabled action when tapped") {
            var subject = UIButton(type: .system)

            var executed = false
            subject.rx.action = CocoaAction(enabledIf: .just(false), workFactory: { _ in
                executed = true
                return .empty()
            })

            subject.sendActions(for: .touchUpInside)

            expect(executed) == false
        }

        it("executes the action when tapped") {
            var subject = UIButton(type: .system)

            var executed = false
            let action = CocoaAction(workFactory: { _ in
                executed = true
                return .empty()
            })
            subject.rx.action = action

            // Normally I'd use subject.sendActionsForControlEvents(.TouchUpInside) but it's not working
            for case let target as NSObject in subject.allTargets {
                for action in subject.actions(forTarget: target, forControlEvent: .touchUpInside) ?? [] {
                    target.perform(Selector(action), with: subject)
                }
            }

            expect(executed) == true
        }

        it("disposes of old action subscriptions when re-set") {
            var subject = UIButton(type: .system)

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
                    .addDisposableTo(disposeBag)
            }

            subject.rx.action = nil

            expect(disposed) == true
        }
        
        it("cancels the observable if the button is deallocated") {
            
            var disposed = false
            
            autoreleasepool {
                var subject = UIButton(type: .system)
                let action = CocoaAction {
                    return Observable.create {_ in
                        Disposables.create {
                            disposed = true
                        }
                    }
                }
                
                subject.rx.action = action
                subject.rx.action?.execute()
            }
            
            expect(disposed).toEventually(beTrue())
        }
    }
}

func emptyAction(_ enabledIf: Observable<Bool> = .just(true)) -> CocoaAction {
    return CocoaAction(enabledIf: enabledIf, workFactory: { _ in
        return .empty()
    })
}
