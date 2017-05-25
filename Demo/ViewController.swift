//
//  ViewController.swift
//  Demo
//
//  Created by Ash Furrow on 2015-11-14.
//  Copyright © 2015 Ash Furrow. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action

enum SharedInput {
    case button(String)
    case barButton
}

class ViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var workingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    
    var disposableBag = DisposeBag()
    let sharedAction = Action<SharedInput, String> { input in
        switch input {
        case .barButton: return Observable.just("UIBarButtonItem with 3 seconds delay").delaySubscription(3, scheduler: MainScheduler.instance)
        case .button(let title): return .just("UIButton " + title)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Demo: add an action to a button in the view
        let action = CocoaAction {
			print("Button was pressed, showing an alert and keeping the activity indicator spinning while alert is displayed")
            return Observable.create { [weak self] observer -> Disposable in
				// Demo: show an alert and complete the view's button action once the alert's OK button is pressed
				let alertController = UIAlertController(title: "Hello world", message: "This alert was triggered by a button action", preferredStyle: .alert)
				var ok = UIAlertAction.Action("OK", style: .default)
				ok.rx.action = CocoaAction {
					print("Alert's OK button was pressed")
					observer.onCompleted()
					return .empty()
				}
				alertController.addAction(ok)
				self?.present(alertController, animated: true, completion: nil)

				return Disposables.create()
            }
        }
        
        button.rx.action = action

        // Demo: add an action to a UIBarButtonItem in the navigation item
        self.navigationItem.rightBarButtonItem?.rx.action = CocoaAction {
            print("Bar button item was pressed, simulating a 2 second action")
            return Observable.empty().delaySubscription(2, scheduler: MainScheduler.instance)
        }

        // Demo: observe the output of both actions, spin an activity indicator
        // while performing the work
        Observable.combineLatest(
            button.rx.action!.executing,
            self.navigationItem.rightBarButtonItem!.rx.action!.executing) { a,b in
                // we combine two boolean observable and output one boolean
                return a || b
            }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] executing in
                // every time the execution status changes, spin an activity indicator
                self?.workingLabel.isHidden = !executing
                if (executing) {
                    self?.activityIndicator.startAnimating()
                }
                else {
                    self?.activityIndicator.stopAnimating()
                }
            })
            .disposed(by: self.disposableBag)

        button1.rx.bind(to: sharedAction, input: .button("Button 1"))

        button2.rx.bind(to: sharedAction) { _ in
            return .button("Button 2")
        }
        self.navigationItem.leftBarButtonItem?.rx.bind(to: sharedAction, input: .barButton)

        sharedAction.executing.debounce(0, scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] executing in
            if (executing) {
                self?.activityIndicator.startAnimating()
            }
            else {
                self?.activityIndicator.stopAnimating()
            }
        })
        .disposed(by: self.disposableBag)

        sharedAction.elements.subscribe(onNext: { string in
            print(string  + " pressed")
        })
        .disposed(by: self.disposableBag)
    }
}
