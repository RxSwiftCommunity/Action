//
//  ViewController.swift
//  Demo
//
//  Created by Ash Furrow on 2015-11-14.
//  Copyright © 2015 Ash Furrow. All rights reserved.
//

import UIKit
import RxSwift
import Action

class ViewController: UIViewController {
    @IBOutlet weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let action = CocoaAction { _ in
            return create { observer -> Disposable in
                // Do whatever work here. 
                print("Doing work for button at \(NSDate())")
                observer.onCompleted()
                return NopDisposable.instance
            }
        }

        button.rx_action = action
    }

}

