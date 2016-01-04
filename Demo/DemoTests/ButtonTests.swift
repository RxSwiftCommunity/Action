import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class ButtonTests: QuickSpec {
    override func spec() {

        it("is nil by default") {
            let subject = UIButton(type: .System)
            expect(subject.rx_action).to( beNil() )
        }

        it("respects setter") {
            let subject = UIButton(type: .System)

            let action = emptyAction()

            subject.rx_action = action

            expect(subject.rx_action) === action
        }

        it("disables the button while executing") {
            let subject = UIButton(type: .System)

            var observer: AnyObserver<Void>!
            let action = CocoaAction(workFactory: { _ in
                return Observable.create { (obsv) -> Disposable in
                    observer = obsv
                    return NopDisposable.instance
                }
            })

            subject.rx_action = action

            action.execute()
            expect(subject.enabled).toEventually( beFalse() )

            observer.onCompleted()
            expect(subject.enabled).toEventually( beTrue() )
        }

        it("disables the button if the Action is disabled") {
            let subject = UIButton(type: .System)

            subject.rx_action = emptyAction(.just(false))
            
            expect(subject.enabled) == false
        }

        it("doesn't execute a disabled action when tapped") {
            let subject = UIButton(type: .System)

            var executed = false
            subject.rx_action = CocoaAction(enabledIf: .just(false), workFactory: { _ in
                executed = true
                return .empty()
            })

            subject.sendActionsForControlEvents(.TouchUpInside)

            expect(executed) == false
        }

        it("executes the action when tapped") {
            let subject = UIButton(type: .System)

            var executed = false
            let action = CocoaAction(workFactory: { _ in
                executed = true
                return .empty()
            })
            subject.rx_action = action

            // Normally I'd use subject.sendActionsForControlEvents(.TouchUpInside) but it's not working
            for target in subject.allTargets() {
                for action in subject.actionsForTarget(target, forControlEvent: .TouchUpInside) ?? [] {
                    target.performSelector(Selector(action), withObject: subject)
                }
            }

            expect(executed) == true
        }

        it("disposes of old action subscriptions when re-set") {
            let subject = UIButton(type: .System)

            var disposed = false
            autoreleasepool {
                let disposeBag = DisposeBag()

                let action = emptyAction()
                subject.rx_action = action

                action
                    .elements
                    .subscribe(onNext: nil, onError: nil, onCompleted: nil, onDisposed: {
                        disposed = true
                    })
                    .addDisposableTo(disposeBag)
            }

            subject.rx_action = nil

            expect(disposed) == true
        }
    }
}

func emptyAction(enabledIf: Observable<Bool> = .just(true)) -> CocoaAction {
    return CocoaAction(enabledIf: enabledIf, workFactory: { _ in
        return .empty()
    })
}
