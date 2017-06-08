//
//  TabBarItemViewController.swift
//  TransitionBehaviors
//
//  Created by Denis Koryttsev on 08/06/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import TransitionBehaviors

class TabBarItemViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func addItems(_ sender: UIButton) {
        perform(presetTransition: .tabBarAddRemove(added: [1, 2, 3]),
                to: PopoverContentViewController(), UIViewController.closedViewController(), storyboard!.instantiateViewController(withIdentifier: "ViewController"),
                animated: true)
    }
    
    @IBAction func removeItems(_ sender: UIButton) {
        tabBarController!.perform(tabBarTransition: .addRemove(removed: [1]),
                                  to: nil,
                                  animated: true)
    }
    
    @IBAction func addRemoveItems(_ sender: UIButton) {
        perform(presetTransition: .tabBarAddRemove(added: [0, 2], removed: [3, 2]),
                to: PopoverContentViewController(), UIViewController.closedViewController(),
                animated: true)
    }
}
