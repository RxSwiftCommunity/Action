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
