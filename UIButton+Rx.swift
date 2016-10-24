import UIKit
import RxSwift
import RxCocoa
import ObjectiveC

public extension Reactive where Base: UIButton {
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, set the rx_action to nil or another action.
    public var action: CocoaAction? {
        get {
            var action: CocoaAction?
            doLocked {
                action = objc_getAssociatedObject(self.base, &AssociatedKeys.Action) as? Action
            }
            return action
        }

        set {
            doLocked {
                // Store new value.
                objc_setAssociatedObject(self.base, &AssociatedKeys.Action, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                // This effectively disposes of any existing subscriptions.
                self.base.resetActionDisposeBag()

                // Set up new bindings, if applicable.
                if let action = newValue {
                    action
                        .enabled
                        .bindTo(self.isEnabled)
                        .addDisposableTo(self.base.actionDisposeBag)

                    // Technically, this file is only included on tv/iOS platforms,
                    // so this optional will never be nil. But let's be safe 😉
                    let lookupControlEvent: ControlEvent<Void>?

                    #if os(tvOS)
                        lookupControlEvent = self.primaryAction
                    #elseif os(iOS)
                        lookupControlEvent = self.tap
                    #endif

                    guard let controlEvent = lookupControlEvent else {
                        return
                    }

                    controlEvent
                        .subscribe(onNext: {
                            action.execute()
                        })
                        .addDisposableTo(self.base.actionDisposeBag)
                }
            }
        }
    }
}
