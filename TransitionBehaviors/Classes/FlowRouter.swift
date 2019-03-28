//
//  FlowRouter.swift
//  LinkInTeam
//
//  Created by Denis Koryttsev on 04/01/17.
//  Copyright © 2017 Denis Koryttsev. All rights reserved.
//

import UIKit

public protocol FlowRouterBehavior {
    associatedtype Payload
    func isAvailable(for router: FlowRouter) -> Bool
    func perform(in router: FlowRouter, with payload: Payload)
}

public struct FlowRouterPush: FlowRouterBehavior {
    let navigationPush = ViewControllerBasedTransition.Push()
    
    public init() {}
    
    public func isAvailable(for router: FlowRouter) -> Bool{
        return router.currentNavigationController != nil
    }

    public func perform(in router: FlowRouter, with payload: (viewControllers: [UIViewController], animated: Bool)) {
        navigationPush.perform(in: router.currentNavigationController!, to: payload.viewControllers, animated: payload.animated)
        router.currentViewController = payload.viewControllers.last
    }
}

// TODO: Rewrite FlowRouter, apply ViewControllerBasedBehaviors

/// TODO: Add animation behaviors, can be use Behavior as transition coordinator
open class FlowRouter: NSObject, UINavigationControllerDelegate {
    
    /// Behavior contains types view presentation behavior.
    public struct Behavior {
        /// Change root controller
        public static let root = Behavior { (router, viewController, _) in // TODO: Not completed, not use now. Create setter in rootViewController property. What ?
            router.dissmissPresentedViewControllerIfNeeded(animated: false)
            router.appWindow??.rootViewController = viewController
            router.appWindow??.makeKeyAndVisible()
            router.currentViewController = viewController
            if (viewController is UINavigationController) {
                router.mainNavigationController = (viewController as! UINavigationController)
            }
        }
        /// Change root controller in current navigation controller
        public static let rootCurrentNavigation = Behavior(available: { $0.currentNavigationController != nil }, insert: { (router, viewController, _) in
            if router.currentNavigationController?.presentingViewController != nil {
                router.set(presentedViewController: viewController)
            } else {
                router.set(currentViewController: viewController)
            }
            router.currentNavigationController?.setViewControllers([viewController], animated: false)
        })
        /// Change root controller in main navigation controller
        public static let rootMainNavigation = Behavior(available: { $0.mainNavigationController != nil }, insert: { (router, viewController, _) in
            router.currentViewController = viewController
            router.mainNavigationController?.setViewControllers([viewController], animated: false)
        })
        /// Simple push view to navigation controller, if navigation controller not exists - not effect.
        public static let push = Behavior(available: { $0.currentNavigationController != nil }, insert: { (router, viewController, animated) in
            router.currentNavigationController?.pushViewController(viewController, animated: animated)
        })
        /// Simple present view on current view controller, if current view controller is presented - not effect.
        public static let present = Behavior(available: { $0.topViewController != nil && $0.topViewController!.definesPresentationContext },
                                      insert: { (router, viewController, animated) in
            router.isInPerformPresentationTime = true
            router.topViewController?.present(viewController, animated: animated) {
                router.set(presentedViewController: viewController)
                router.isInPerformPresentationTime = false
            }
        })
        /// Removes last view controller from stack and push new controller without animation
        public static let replace = Behavior(available: { $0.currentNavigationController != nil && $0.currentNavigationController!.isEmpty }, insert: { (router, viewController, _) in
            var stack = router.currentNavigationController!.viewControllers
            stack[stack.count - 1] = viewController
            router.currentNavigationController?.viewControllers = stack
        })
        /// Use push behavior, if navigation controller exists, else present behavior
//        case show
        
        private let availableCheck: ((FlowRouter) -> Bool)?
        private let insertAction: (FlowRouter, UIViewController, Bool) -> Void
        
        public init(available: ((FlowRouter) -> Bool)? = nil, insert: @escaping (FlowRouter, UIViewController, Bool) -> Void) {
            availableCheck = available
            insertAction = insert
        }
        
        public func isAvailable(for router: FlowRouter) -> Bool {
            return availableCheck?(router) ?? true
        }
        
        public func perform(in router: FlowRouter, viewController: UIViewController, animated: Bool = true) {
            insertAction(router, viewController, animated)
        }
    }
    
    // MARK: Class
    
    public static let appRouter = FlowRouter()
    
    // MARK: Instance
    
    public override init() {
        super.init()
        currentViewController = rootViewController
        if let navController = currentViewController as? UINavigationController {
            mainNavigationController = navController
        }
        presentedViewController = rootViewController?.presentedViewController
    }
    
    // stored
    public weak var mainNavigationController: UINavigationController? {
        didSet {
            mainNavigationController?.delegate = self
        }
    }
    public weak var currentViewController: UIViewController?
    public weak var presentedViewController: UIViewController?
    public var isInPerformPresentationTime = false // TODO: Added scheduled presentations
    
    // calculated
    public weak var topViewController: UIViewController? { return presentedViewController ?? currentViewController ?? rootViewController }
    public weak var currentNavigationController: UINavigationController? {
        return presentedViewController?.navigationController ??
            currentViewController?.navigationController ??
        mainNavigationController
    }
    public var appWindow: UIWindow?? { return UIApplication.shared.delegate?.window }
    public weak var rootViewController: UIViewController? {
        return appWindow??.rootViewController
    }
    
    // MARK: Methods
    
    private func set(presentedViewController newValue: UIViewController?) {
        if (newValue is UINavigationController) {
            presentedViewController = (newValue as! UINavigationController).topViewController ?? newValue
        } else {
            presentedViewController = newValue
        }
    }
    
    private func set(currentViewController newValue: UIViewController?) {
        if (newValue is UINavigationController) {
            currentViewController = (currentViewController as! UINavigationController).topViewController ?? newValue
        } else {
            currentViewController = newValue
        }
    }
    
    public func isAvailable(behavior: Behavior) -> Bool {
        return behavior.isAvailable(for: self)
    }
    
    public func dissmissPresentedViewControllerIfNeeded(animated: Bool) {
        if presentedViewController != nil {
            let prevPresentViewController = presentedViewController?.presentingViewController?.presentingViewController != nil ? presentedViewController?.presentingViewController : nil
            presentedViewController!.dismiss(animated: animated, completion: {() -> Void in
                self.set(presentedViewController: prevPresentViewController)
            })
        }
    }
    
    /// strongly should use for replace, and for other if required
    public func showIfAvailable(_ viewController: UIViewController, using behavior: Behavior) -> Bool {
        guard isAvailable(behavior: behavior) else { return false }
        
        show(viewController, using: behavior)
        
        return true
    }
    
    public func show(_ viewController: UIViewController, using behavior: Behavior) {
        behavior.perform(in: self, viewController: viewController)
    }
    
    public func perform<T: FlowRouterBehavior>(transitionUsing behavior: T, with payload: T.Payload) {
        behavior.perform(in: self, with: payload)
    }
    
    // MARK: - UINavigationControllerDelegate
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if currentViewController?.presentedViewController != nil {
            set(presentedViewController: viewController)
        } else {
            set(currentViewController: viewController)
        }
    }
}

extension FlowRouter {
    public func presentSimpleAlert(withTitle title: String? = nil, message: String?, completion: ((UIAlertAction) -> Swift.Void)? = nil) {
        presentAlert(withTitle: title, message: message, actions: [UIAlertAction(title: "OK", style: .default, handler: completion)])
    }
    
    public func presentAlert(withTitle title: String?, message: String?, confirmTitle: String, cancelTitle: String, agreeCompletion completion: ((UIAlertAction) -> Swift.Void)?) {
        let yesAction = UIAlertAction(title: confirmTitle, style: .default, handler: completion)
        let noAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        presentAlert(withTitle: title, message: message, actions: [yesAction, noAction])
    }
    
    public func presentAlert(withTitle title: String?, message: String?, actions: [UIAlertAction]) {
        guard !isInPerformPresentationTime, isAvailable(behavior: .present) else { return }
        
        let alertViewController = UIAlertController(title: title, message: message, actions: actions)
        alertViewController.definesPresentationContext = false
        show(alertViewController, using: .present)
    }
}


