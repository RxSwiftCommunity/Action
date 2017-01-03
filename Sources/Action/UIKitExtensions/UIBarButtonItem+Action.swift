#if os(iOS) || os(tvOS)
import UIKit
import RxSwift
import RxCocoa
import ObjectiveC

public extension Reactive where Base: UIBarButtonItem {

    /// Binds enabled state of action to bar button item, and subscribes to rx_tap to execute action.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, set the rx.action to nil or another action.
    public var action: CocoaAction? {
        get {
            var action: CocoaAction?
            action = objc_getAssociatedObject(self.base, &AssociatedKeys.Action) as? Action
            return action
        }

        set {
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
                
                self.tap.subscribe(onNext: { (_) in
                    action.execute()
                })
                    .addDisposableTo(self.base.actionDisposeBag)
            }
        }
    }
    public var controlAction: ControlAction? {
        get {
            var controlAction: ControlAction?
            controlAction = objc_getAssociatedObject(self.base, &AssociatedKeys.ControlAction) as? ControlAction
            return controlAction
        }
        
        set {
            // Store new value.
            objc_setAssociatedObject(self.base, &AssociatedKeys.ControlAction, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
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
                        action.execute($0)
                    })
                    .addDisposableTo(self.base.actionDisposeBag)
            }
        }
    }
}
#endif
