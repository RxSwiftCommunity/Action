import UIKit
import RxSwift
import RxCocoa

public extension UIAlertAction {

    public static func Action(title: String?, style: UIAlertActionStyle) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: { action in
            action.rx_action?.execute()
        })
    }

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
                }
            }
        }
    }
}

extension UIAlertAction {
    var rx_enabled: AnyObserver<Bool> {
        return AnyObserver { [weak self] event in
            MainScheduler.ensureExecutingOnScheduler()

            switch event {
            case .Next(let value):
                self?.enabled = value
            case .Error(let error):
                let error = "Binding error to UI: \(error)"
                #if DEBUG
                    rxFatalError(error)
                #else
                    print(error)
                #endif
                break
            case .Completed:
                break
            }
        }
    }
}
