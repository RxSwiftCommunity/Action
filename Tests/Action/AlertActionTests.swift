import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class AlertActionTests: QuickSpec {
    override func spec() {
        it("is nil by default") {
            let subject = UIAlertAction.Action("Hi", style: .default)
            expect(subject.rx_action).to( beNil() )
        }

        it("respects setter") {
            let subject = UIAlertAction.Action("Hi", style: .default)

            let action = emptyAction()

            subject.rx_action = action

            expect(subject.rx_action) === action
        }

        it("disables the alert action while executing") {
            let subject = UIAlertAction.Action("Hi", style: .default)

            var observer: AnyObserver<Void>!
            let action = CocoaAction(workFactory: { _ in
                return Observable.create { (obsv) -> Disposable in
                    observer = obsv
                    return Disposables.create()
                }
            })

            subject.rx_action = action

            action.execute()
            expect(subject.isEnabled).toEventually( beFalse() )

            observer.onCompleted()
            expect(subject.isEnabled).toEventually( beTrue() )
        }

        it("disables the alert action if the Action is disabled") {
            let subject = UIAlertAction.Action("Hi", style: .default)
            let disposeBag = DisposeBag()

            subject.rx_action = emptyAction(.just(false))
            waitUntil { done in
                subject.rx.observe(Bool.self, "enabled")
                    .take(1)
                    .subscribe(onNext: { _ in
                        done()
                    })
                    .addDisposableTo(disposeBag)
            }

            expect(subject.isEnabled) == false
        }
        
        it("disposes of old action subscriptions when re-set") {
            let subject = UIAlertAction.Action("Hi", style: .default)
            
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
