#if os(macOS)
	import Cocoa
	import RxSwift
	import RxCocoa
	import ObjectiveC
	
	public extension Reactive where Base: NSButton {
		/// Binds enabled state of action to button, and subscribes to rx.tap to execute action.
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
						.bind(to: self.isEnabled)
						.disposed(by: self.base.actionDisposeBag)
					
					self.tap
						.subscribe(onNext: {
							action.execute()
						})
						.disposed(by: self.base.actionDisposeBag)
				}
			}
		}
		
		/// Binds enabled state of action to button, and subscribes to rx.tap to execute action with given input transform.
		/// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
		/// them, call bindToAction with another action or call unbindAction().
		public func bind<Input, Output>(to action: Action<Input, Output>, inputTransform: @escaping (Base) -> (Input))   {
			// This effectively disposes of any existing subscriptions.
			unbindAction()
			self.bind(to: action, controlEvent: self.tap, inputTransform: inputTransform)
		}
		
		/// Binds enabled state of action to button, and subscribes to rx.tap to execute action with given input value.
		/// These subscriptions are managed in a private, inaccessible dispose bag. To cancel
		/// them, call bindToAction with another action or call unbindAction().
		public func bind<Input, Output>(to action: Action<Input, Output>, input: Input) {
			self.bind(to: action) { _ in input }
		}
	}
#endif

