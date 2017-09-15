import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class AlertActionTests: QuickSpec {
    override func spec() {
        it("is nil by default") {
            let subject = UIAlertAction.Action("Hi", style: .default)
            expect(subject.rx.action).to( beNil() )
        }

        it("respects setter") {
            var subject = UIAlertAction.Action("Hi", style: .default)

            let action = emptyAction()

            subject.rx.action = action

            expect(subject.rx.action) === action
        }

        it("disables the alert action while executing") {
            var subject = UIAlertAction.Action("Hi", style: .default)

            var observer: AnyObserver<Void>!
            let action = CocoaAction(workFactory: { _ in
                return Observable.create { (obsv) -> Disposable in
                    observer = obsv
                    return Disposables.create()
                }
            })

            subject.rx.action = action

            action.execute(())
            expect(subject.isEnabled).toEventually( beFalse() )

            observer.onCompleted()
            expect(subject.isEnabled).toEventually( beTrue() )
        }

        it("disables the alert action if the Action is disabled") {
            var subject = UIAlertAction.Action("Hi", style: .default)
            let disposeBag = DisposeBag()

            subject.rx.action = emptyAction(.just(false))
            waitUntil { done in
                subject.rx.observe(Bool.self, "enabled")
                    .take(1)
                    .subscribe(onNext: { _ in
                        done()
                    })
                    .disposed(by: disposeBag)
            }

            expect(subject.isEnabled) == false
        }
        
        it("disposes of old action subscriptions when re-set") {
            var subject = UIAlertAction.Action("Hi", style: .default)
            
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
