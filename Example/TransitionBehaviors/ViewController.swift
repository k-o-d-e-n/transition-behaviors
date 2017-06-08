//
//  ViewController.swift
//  TransitionBehaviors
//
//  Created by k-o-d-e-n on 06/07/2017.
//  Copyright (c) 2017 k-o-d-e-n. All rights reserved.
//

import UIKit
import TransitionBehaviors

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func openViewController(_ sender: UIButton) {
        let vc = PopoverContentViewController()
        perform(presetTransition:
            .present(as:
                .popover(config: { (popover) in
                    popover.sourceView = self.view
                    popover.sourceRect = sender.frame
                }), completion: {
                    debugPrint(vc.presentingViewController ?? "no presentation")
            }),
                to: vc,
                animated: true)
    }
    
    @IBAction func presentViewController(_ sender: UIButton) {
        let vc = UIViewController.closedViewController()
        definesPresentationContext = true
        perform(presetTransition:
            .present(as:
                .common(modalStyle: .overCurrentContext, transitionStyle: .crossDissolve),
                     completion: {
            debugPrint(vc.presentingViewController ?? "no presentation")
        }),
                to: vc,
                animated: true)
    }
    
    
    @IBAction func replaceViewController(_ sender: UIButton) {
        perform(presetTransition: .replace(last: 2), to: self, UIViewController.closedViewController(), animated: false)
    }
    
    @IBAction func navigationRoot(_ sender: UIButton) {
        perform(presetTransition: .navigationRoot, to: self, animated: true)
    }
    
    @IBAction func preview(_ sender: UIButton) {
        // TODO:
        
        customTransitionBehavior()
    }
    
    func customTransitionBehavior() {
        perform(transition: CustomTransitionBehavior(), to: [PopoverContentViewController()], animated: true)
        //        perform(transition: AnyViewControllerBasedTransitionBehavior<ViewController, PopoverContentViewController>(available: { _ in true }, action: { s, t, a in
        //            s.navigationRoot(UIButton())
        //        }), to: [PopoverContentViewController()], animated: true)
    }
    
    static let transitioningDelegate = SlideInPresentationManager()
    @IBAction func customTransition(_ sender: UIButton) {
        perform(presetTransition: .present(as: .custom(delegate: ViewController.transitioningDelegate)),
                to: UIViewController.closedViewController(),
                animated: true)
    }
}

extension UIViewController {
    class func closedViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        let btn = UIButton(frame: CGRect(x: 0, y: 100, width: 100, height: 50))
        btn.setTitle("Close", for: .normal)
        btn.addTarget(vc, action: #selector(close(_:)), for: .touchUpInside)
        vc.view.addSubview(btn)
        
        return vc
    }
    
    func close(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

class PopoverContentViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        let btn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 50)))
        btn.setTitle("Open", for: .normal)
        btn.addTarget(self, action: #selector(open(_:)), for: .touchUpInside)
        view.addSubview(btn)
    }
    
    func open(_ sender: UIButton) {
        let vc = UIViewController.closedViewController()
        vc.view.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        definesPresentationContext = true
        perform(presetTransition:
            .present(as:
                .common(modalStyle: .overCurrentContext, transitionStyle: .crossDissolve), completion: {
                    debugPrint(self.definesPresentationContext)
                    debugPrint(vc.presentingViewController ?? "no presentation")
                    debugPrint(vc.parent ?? "no parent")
            }),
                to: vc,
                animated: true)
    }
    
}

struct CustomTransitionBehavior: ViewControllerBasedTransitionBehavior {
    typealias Source = ViewController
    func isAvailable(in sourceViewController: ViewController) -> Bool {
        return true
    }
    
    func perform(in sourceViewController: ViewController, to viewControllers: [PopoverContentViewController], animated: Bool) {
        sourceViewController.openViewController(UIButton())
    }
}
