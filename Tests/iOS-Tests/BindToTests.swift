import Quick
import Nimble
import RxSwift
import RxCocoa
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

extension UIRefreshControl {
    // Normally I'd use subject.sendActionsForControlEvents(.valueChanged) but it's not working
    func test_executeRefresh() {
        for case let target as NSObject in allTargets {
            for action in actions(forTarget: target, forControlEvent: .valueChanged) ?? [] {
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
			expect(button.allTargets.count) == 1

			button.test_executeTap()

			expect(called).toEventually( beTrue() )
		}

		it("does not retain UIButton") {
			var button: UIButton? = UIButton()
			let action = Action<String, String>(workFactory: { _ in
				return .empty()
			})
			button?.rx.bind(to: action, input: "Hi there!")

			weak var buttonWeakReference = button
			button = nil

			expect(buttonWeakReference).to(beNil())
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
			expect(button.allTargets.count) == 1

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

        it("does not retain UIBarButtonItem") {
          var barButtonItem: UIBarButtonItem? = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
          let action = Action<String, String>(workFactory: { _ in
              return .empty()
          })
          barButtonItem?.rx.bind(to: action, input: "Hi there!")

          weak var barButtonItemWeakReference = barButtonItem
          barButtonItem = nil

          expect(barButtonItemWeakReference).to(beNil())
        }

        it("actives a UIRefreshControl") {
            var called = false
            let item = UIRefreshControl()
            let action = Action<String, String>(workFactory: { _ in
                called = true
                return .empty()
            })
            item.rx.bind(to: action, input: "Hi there!")

            item.test_executeRefresh()

            expect(called).toEventually( beTrue() )
        }

        it("does not retain UIRefreshControl") {
          var refreshControl: UIRefreshControl? = UIRefreshControl()
          let action = Action<String, String>(workFactory: { _ in
              return .empty()
          })
          refreshControl?.rx.bind(to: action, input: "Hi there!")

          weak var refreshControlWeakReference = refreshControl
          refreshControl = nil

          expect(refreshControlWeakReference).to(beNil())
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
				expect(button.allTargets.count) == 1

				button.rx.unbindAction()
				button.test_executeTap()

				expect(button.allTargets.count) == 0
			}

            it("unbinds actions for UIRefreshControl") {
                let refreshControl = UIRefreshControl()
                let action = Action<String, String>(workFactory: { _ in
                    assertionFailure()
                    return .empty()
                })
                refreshControl.rx.bind(to: action, input: "Hi there!")
                // Setting the action has an asynchronous effect of adding a target.
                expect(refreshControl.allTargets.count) == 1

                refreshControl.rx.unbindAction()
                refreshControl.test_executeRefresh()

                expect(refreshControl.allTargets.count) == 0
            }

			it("unbinds actions for UIBarButtonItem") {
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
