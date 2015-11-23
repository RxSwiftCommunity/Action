import UIKit
import RxSwift
import RxCocoa
import ObjectiveC

public extension UIBarButtonItem {
	
	/// Binds enabled state of action to bar button item, and subscribes to rx_tap to execute action.
	/// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
	/// them, set the rx_action to nil or another action.
	public var rx_action: CocoaAction? {
		get {
			var action: CocoaAction?
			doLocked {
				action = objc_getAssociatedObject(self, &AssociatedKeys.Action) as? Action
			}
			return action
		}
		
		set {
			doLocked {
				// Store new value.
				objc_setAssociatedObject(self, &AssociatedKeys.Action, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
				
				// This effectively disposes of any existing subscriptions.
				self.resetActionDisposeBag()
				
				// Set up new bindings, if applicable.
				if let action = newValue {
					action
						.enabled
						.bindTo(self.rx_enabled)
						.addDisposableTo(self.actionDisposeBag)
					
					self.rx_tap
						.subscribeNext {
							action.execute()
						}
						.addDisposableTo(self.actionDisposeBag)
				}
			}
		}
	}
}

// Note: Actions performed in this extension are _not_ locked
// So be careful!
private extension UIBarButtonItem {
	private struct AssociatedKeys {
		static var Action = "rx_action"
		static var DisposeBag = "rx_disposeBag"
	}
	
	// A dispose bag to be used exclusively for the instance's rx_action.
	private var actionDisposeBag: DisposeBag {
		var disposeBag: DisposeBag
		
		if let lookup = objc_getAssociatedObject(self, &AssociatedKeys.DisposeBag) as? DisposeBag {
			disposeBag = lookup
		} else {
			disposeBag = DisposeBag()
			objc_setAssociatedObject(self, &AssociatedKeys.DisposeBag, disposeBag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
		
		return disposeBag
	}
	
	// Resets the actionDisposeBag to nil, disposeing of any subscriptions within it.
	private func resetActionDisposeBag() {
		objc_setAssociatedObject(self, &AssociatedKeys.DisposeBag, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	// Uses objc_sync on self to perform a locked operation.
	private func doLocked(closure: () -> Void) {
		objc_sync_enter(self); defer { objc_sync_exit(self) }
		closure()
	}
}
