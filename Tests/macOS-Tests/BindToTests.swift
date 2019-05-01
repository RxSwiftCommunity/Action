import Quick
import Nimble
import RxSwift
import RxCocoa
import RxBlocking
import RxTest
import Action

extension NSButton {
	func test_executeAction() {
		if let target = self.target as? NSObject, let action = self.action {
			target.perform(action, with: self)
		}
	}
}

class BindToTests: QuickSpec {
	override func spec() {
		it("actives a NSButton") {
			var called = false
			let button = NSButton()
			let action = Action<String, String>(workFactory: { _ in
				called = true
				return .empty()
			})
			button.rx.bind(to: action, input: "Hi there!")
			// Setting the action has an asynchronous effect of adding a target.
			expect(button.target).toEventuallyNot( beNil() )

			button.test_executeAction()

			expect(called).toEventually( beTrue() )
		}

		it("activates a generic control event") {
			var called = false
			let button = NSButton()
			let action = Action<String, String>(workFactory: { _ in
				called = true
				return .empty()
			})
			button.rx.bind(to: action, controlEvent: button.rx.tap, inputTransform: { input in "\(input)" })
			// Setting the action has an asynchronous effect of adding a target.
			expect(button.target).toEventuallyNot( beNil() )

			button.test_executeAction()

			expect(called).toEventually( beTrue() )
		}

		describe("unbinding") {
			it("unbinds actions for UIButton") {
				let button = NSButton()
				let action = Action<String, String>(workFactory: { _ in
					assertionFailure()
					return .empty()
				})
				button.rx.bind(to: action, input: "Hi there!")
				// Setting the action has an asynchronous effect of adding a target.
				expect(button.target).toEventuallyNot( beNil() )

				button.rx.unbindAction()
				button.test_executeAction()

				expect(button.target).toEventually( beNil() )
			}
		}
	}
}
