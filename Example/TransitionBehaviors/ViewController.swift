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
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        tabBarItem.title = "Controller"
    }

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
        perform(presetTransition: .navigationReplace(last: 2), to: self, UIViewController.closedViewController(), animated: false)
    }
    
    @IBAction func navigationRoot(_ sender: UIButton) {
        perform(presetTransition: .navigationRoot, to: self, animated: true)
    }
    
    @IBAction func preview(_ sender: UIButton) {
        // TODO:
        
        perform(presetTransition: .addChilds(layout: { (superview, subviews) in
            UIView.animate(withDuration: 0.3, animations: { 
                let subviewFrame = superview.frame.inset(by: UIEdgeInsets(top: 100, left: 50, bottom: 100, right: 50))
                subviews.forEach { $0.frame = subviewFrame }
            })
        }),
                to: UIViewController.closedViewController(),
                animated: true)
//        customTransitionBehavior()
    }
    
    @IBAction func pop(_ sender: UIButton) {
        var vc: UIViewController? = nil
        perform(presetTransition: .navigationPop(popped: &vc),
                to: nil,
                animated: true)
        print(vc ?? "no popped")
    }
    @IBAction func push(_ sender: UIButton) {
        let vc = UIViewController()
        vc.title = "Pushed View Controller"
        vc.view.backgroundColor = .gray
        perform(presetTransition: .navigationPush,
                to: vc, storyboard!.instantiateViewController(withIdentifier: "ViewController"),
                animated: true)
    }
    
    func customTransitionBehavior() {
        perform(transition: CustomTransitionBehavior(), to: [PopoverContentViewController()], animated: true)
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
        vc.tabBarItem.title = "Closable"
        
        return vc
    }
    
    @objc func close(_ sender: UIButton) {
        perform(presetTransitionIfAvailable: .dismissParent(on: 2),
                to: self,
                animated: true,
                reserved: (.removeChilds, true))
    }
}

class PopoverContentViewController: UIViewController {
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        tabBarItem.title = "Popover"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        let btn = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 50)))
        btn.setTitle("Open", for: .normal)
        btn.addTarget(self, action: #selector(open(_:)), for: .touchUpInside)
        view.addSubview(btn)
    }
    
    @objc func open(_ sender: UIButton) {
        let vc = UIViewController.closedViewController()
        vc.view.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        definesPresentationContext = true
        perform(presetTransitionIfAvailable:
            .present(as:
                .common(modalStyle: .overCurrentContext, transitionStyle: .partialCurl)),
                to: vc,
                animated: true,
                reserved: (.present(as:
                    .common(modalStyle: .overCurrentContext, transitionStyle: .flipHorizontal), completion: {
                        debugPrint(self.definesPresentationContext)
                        debugPrint(vc.presentingViewController ?? "no presentation")
                        debugPrint(vc.parent ?? "no parent")
                }), true))
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
