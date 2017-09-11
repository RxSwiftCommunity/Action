#if os(macOS)
import AppKit
import RxSwift
import RxCocoa

public extension Reactive where Base: NSControl {
    /// Binds enabled state of action to control, and subscribes action's execution to provided controlEvents.
    /// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
    /// them, set the rx.action to nil or another action, or call unbindAction().
    public func bindTo<Input, Output>(action: Action<Input, Output>, controlEvent: ControlEvent<Void>, inputTransform: @escaping (Base) -> (Input))   {
        // This effectively disposes of any existing subscriptions.
        unbindAction()

        // For each tap event, use the inputTransform closure to provide an Input value to the action
        controlEvent
            .map { inputTransform(self.base) }
            .bindTo(action.inputs)
            .addDisposableTo(self.base.actionDisposeBag)

        // Bind the enabled state of the control to the enabled state of the action
        action
            .enabled
            .bindTo(self.isEnabled)
            .addDisposableTo(self.base.actionDisposeBag)
    }

    /// Unbinds any existing action, disposing of all subscriptions.
    public func unbindAction() {
        self.base.resetActionDisposeBag()
    }
}

#endif

