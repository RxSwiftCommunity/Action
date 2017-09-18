import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class BarButtonTests: QuickSpec {
	override func spec() {
		
		it("is nil by default") {
			let subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
			expect(subject.rx.action).to( beNil() )
		}
		
		it("respects setter") {
			var subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
			
			let action = emptyAction()
			
			subject.rx.action = action
			
			expect(subject.rx.action) === action
		}
		
		it("disables the button while executing") {
			var subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
			
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
		
		it("disables the button if the Action is disabled") {
			var subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
			
			subject.rx.action = emptyAction(.just(false))
            expect(subject.target).toEventuallyNot( beNil() )
			
			expect(subject.isEnabled) == false
		}
		
		it("doesn't execute a disabled action when tapped") {
			var subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
			
			var executed = false
			subject.rx.action = CocoaAction(enabledIf: .just(false), workFactory: { _ in
				executed = true
				return .empty()
			})

			_ = subject.target?.perform(subject.action, with: subject)
			
			expect(executed) == false
		}
		
		it("executes the action when tapped") {
			var subject = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
			
			var executed = false
			let action = CocoaAction(workFactory: { _ in
				executed = true
				return .empty()
			})
			subject.rx.action = action
            // Setting the action has the asynchronous effect of adding a target.
            expect(subject.target).toEventuallyNot( beNil() )

			_ = subject.target?.perform(subject.action, with: subject)
			
			expect(executed) == true
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
