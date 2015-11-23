import UIKit
import RxSwift
import RxCocoa
import ObjectiveC

public extension UIButton {

    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action.
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

                    // Technically, this file is only included on tv/iOS platforms,
                    // so this optional will never be nil. But let's be safe 😉
                    let lookupControlEvent: ControlEvent<Void>?

                    #if os(tvOS)
                        lookupControlEvent = self.rx_primaryAction
                    #elseif os(iOS)
                        lookupControlEvent = self.rx_tap
                    #endif

                    guard let controlEvent = lookupControlEvent else {
                        return
                    }

                    controlEvent
                        .subscribeNext { _ -> Void in
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
internal extension NSObject {
    internal struct AssociatedKeys {
        static var Action = "rx_action"
        static var DisposeBag = "rx_disposeBag"
    }

    // A dispose bag to be used exclusively for the instance's rx_action.
    internal var actionDisposeBag: DisposeBag {
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
    internal func resetActionDisposeBag() {
        objc_setAssociatedObject(self, &AssociatedKeys.DisposeBag, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // Uses objc_sync on self to perform a locked operation.
    internal func doLocked(closure: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        closure()
    }
}
