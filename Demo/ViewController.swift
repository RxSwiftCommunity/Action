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

enum Input {
    case button
    case barButton
    var title:String{
        switch self {
        case .barButton:
            return "UIBarButtonItem"
        default:
            return "UIButton"
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var workingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var disposableBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Demo: add an action to a button in the view
        let action = Action<Input,Void> { input in
			print("\(input.title) was pressed")
            if (input != .button) {
                return .empty()
            }
            
            
            return Observable.create {
				[weak self] observer -> Disposable in

				// Demo: show an alert and complete the view's button action once the alert's OK button is pressed
				let alertController = UIAlertController(title: "Hello world", message: "This alert was triggered by a button action", preferredStyle: .alert)
				var ok = UIAlertAction.Action("OK", style: .default)
				ok.rx.action = CocoaAction {
					print("Alert's OK button was pressed")
					observer.onCompleted()
					return .empty()
				}
				alertController.addAction(ok)
				self!.present(alertController, animated: true, completion: nil)

				return Disposables.create()
            }
        }
        button.rx.controlAction = ControlAction(action, input:.button)

        // Demo: add an action to a UIBarButtonItem in the navigation item
        self.navigationItem.rightBarButtonItem!.rx.controlAction = ControlAction(action, input:.barButton)

        // Demo: observe the output of both actions, spin an activity indicator
        // while performing the work
            action
            .executing
            .distinctUntilChanged()
            .subscribe(onNext: {
                // every time the execution status changes, spin an activity indicator
                [weak self] executing in
                self?.workingLabel.isHidden = !executing
                if (executing) {
                    self?.activityIndicator.startAnimating()
                }
                else {
                    self?.activityIndicator.stopAnimating()
                }
            })
            
            .addDisposableTo(self.disposableBag)
    }
}
