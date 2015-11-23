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

class ViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var workingLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var disposableBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Demo: add an action to a button in the view
        let action = CocoaAction { _ in
            return create { observer -> Disposable in
                // Do whatever work here.
                print("Doing work for button at \(NSDate())")
                observer.onCompleted()
                return NopDisposable.instance
            }
        }
        button.rx_action = action

        // Demo: add an action to a UIBarButtonItem in the navigation item
        self.navigationItem.rightBarButtonItem!.rx_action = CocoaAction {
            print("Bar button item was pressed, simulating a 2 second action")
            return empty().delaySubscription(2, MainScheduler.sharedInstance)
        }

        // Demo: obseve the output of both actions, spin an activity indicator
        // while performing the work
        combineLatest(
            button.rx_action!.executing,
            self.navigationItem.rightBarButtonItem!.rx_action!.executing) {
                // we combine two boolean observable and output one boolean
                a,b in
                return a || b
            }
            .distinctUntilChanged()
            .subscribeNext {
                // every time the execution status changes, spin an activity indicator
                [weak self] executing in
                self?.workingLabel.hidden = !executing
                if (executing) {
                    self?.activityIndicator.startAnimating()
                }
                else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .addDisposableTo(self.disposableBag)
    }
}
