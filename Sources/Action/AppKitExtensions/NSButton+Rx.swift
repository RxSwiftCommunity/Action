#if os(macOS)
import Cocoa
import RxSwift
import RxCocoa
import ObjectiveC

public extension Reactive where Base: NSButton {
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action.
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
                
                // Technically, this file is only included on tv/iOS platforms,
                // so this optional will never be nil. But let's be safe 😉
                let lookupControlEvent: ControlEvent<Void>?
                
                lookupControlEvent = self.controlEvent
                
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
    
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action with given input transform.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, call bindToAction with another action or call unbindAction().
    public func bindTo<Input, Output>(action:Action<Input, Output>, inputTransform: @escaping (Base) -> (Input))   {
        // This effectively disposes of any existing subscriptions.
        unbindAction()
     
        // Technically, this file is only included on tv/iOS platforms,
        // so this optional will never be nil. But let's be safe 😉
        let lookupControlEvent: ControlEvent<Void>?
        
        lookupControlEvent = self.tap
        
        guard let controlEvent = lookupControlEvent else {
            return
        }
        self.bindTo(action: action, controlEvent: controlEvent, inputTransform: inputTransform)
    }
    
    /// Binds enabled state of action to button, and subscribes to rx_tap to execute action with given input value.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, call bindToAction with another action or call unbindAction().
    public func bindTo<Input, Output>(action: Action<Input, Output>, input: Input) {
        self.bindTo(action: action) { _ in input }
    }
}
#endif
