import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class AlertActionTests: QuickSpec {
    override func spec() {
        it("is nil by default") {
            let subject = UIAlertAction.Action("Hi", style: .Default)
            expect(subject.rx_action).to( beNil() )
        }

        it("respects setter") {
            let subject = UIAlertAction.Action("Hi", style: .Default)

            let action = emptyAction()

            subject.rx_action = action

            expect(subject.rx_action) === action
        }

        it("disables the alert action while executing") {
            let subject = UIAlertAction.Action("Hi", style: .Default)

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

        it("disables the alert action if the Action is disabled") {
            let subject = UIAlertAction.Action("Hi", style: .Default)
            let disposeBag = DisposeBag()

            subject.rx_action = emptyAction(.just(false))
            waitUntil { done in
                subject.rx_observe(Bool.self, "enabled")
                    .take(1)
                    .subscribeNext { _ in
                        done()
                    }
                    .addDisposableTo(disposeBag)
            }

            expect(subject.enabled) == false
        }
        
        it("disposes of old action subscriptions when re-set") {
            let subject = UIAlertAction.Action("Hi", style: .Default)
            
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