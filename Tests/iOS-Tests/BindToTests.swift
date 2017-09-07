import Quick
import Nimble
import RxSwift
import RxCocoa
import RxBlocking
import RxTest
import Action

extension UIButton {
	// Normally I'd use subject.sendActionsForControlEvents(.TouchUpInside) but it's not working
	func test_executeTap() {
		for case let target as NSObject in allTargets {
			for action in actions(forTarget: target, forControlEvent: .touchUpInside) ?? [] {
				target.perform(Selector(action), with: self)
			}
		}
	}
}

class BindToTests: QuickSpec {
	override func spec() {
		it("actives a UIButton") {
			var called = false
			let button = UIButton()
			let action = Action<String, String>(workFactory: { _ in
				called = true
				return .empty()
			})
			button.rx.bind(to: action, input: "Hi there!")
			// Setting the action has an asynchronous effect of adding a target.
			expect(button.allTargets).toEventuallyNot( beEmpty() )
			
			button.test_executeTap()
			
			expect(called).toEventually( beTrue() )
		}
		
		it("activates a generic control event") {
			var called = false
			let button = UIButton()
			let action = Action<String, String>(workFactory: { _ in
				called = true
				return .empty()
			})
			button.rx.bind(to: action, controlEvent: button.rx.tap, inputTransform: { input in "\(input)" })
			// Setting the action has an asynchronous effect of adding a target.
			expect(button.allTargets).toEventuallyNot( beEmpty() )
			
			button.test_executeTap()
			
			expect(called).toEventually( beTrue() )
		}
		
		it("actives a UIBarButtonItem") {
			var called = false
			let item = UIBarButtonItem()
			let action = Action<String, String>(workFactory: { _ in
				called = true
				return .empty()
			})
			item.rx.bind(to: action, input: "Hi there!")
			
			_ = item.target!.perform(item.action!, with: item)
			
			expect(called).toEventually( beTrue() )
		}
		
		describe("unbinding") {
			it("unbinds actions for UIButton") {
				let button = UIButton()
				let action = Action<String, String>(workFactory: { _ in
					assertionFailure()
					return .empty()
				})
				button.rx.bind(to: action, input: "Hi there!")
				// Setting the action has an asynchronous effect of adding a target.
				expect(button.allTargets).toEventuallyNot( beEmpty() )
				
				button.rx.unbindAction()
				button.test_executeTap()
				
				expect(button.allTargets).toEventually( beEmpty() )
			}
			
			it("actives a UIBarButtonItem") {
				var called = false
				let item = UIBarButtonItem()
				let action = Action<String, String>(workFactory: { _ in
					called = true
					return .empty()
				})
				item.rx.bind(to: action, input: "Hi there!")
				
				item.rx.unbindAction()
				_ = item.target?.perform(item.action!, with: item)
				
				expect(called).to( beFalse() )
			}
		}
	}
}

