//
//  TransitionBehavior.swift
//  LinkInTeam
//
//  Created by Denis Koryttsev on 07/06/2017.
//  Copyright © 2017 Denis Koryttsev. All rights reserved.
//

import Foundation

// MARK: Application based

/// application root, application present
protocol ApplicationBasedTransitionBehavior {
    func isAvailable(in application: UIApplication) -> Bool
    func perform<To: UIViewController>(in application: UIApplication, to viewController: To, animated: Bool)
}

extension UIApplication {
    func isAvailable(transition: ApplicationBasedTransitionBehavior) -> Bool {
        return transition.isAvailable(in: self)
    }
    
    func perform<To: UIViewController>(transition: ApplicationBasedTransitionBehavior, to viewController: To, animated: Bool) {
        return transition.perform(in: self, to: viewController, animated: animated)
    }
    
    @discardableResult
    func perform<To: UIViewController>(transitionIfAvailable transition: ApplicationBasedTransitionBehavior, to viewController: To, animated: Bool) -> Bool {
        guard isAvailable(transition: transition) else { return false }
        
        perform(transition: transition, to: viewController, animated: animated)
        return true
    }
}

struct ApplicationBasedTransition: ApplicationBasedTransitionBehavior {
    let base: ApplicationBasedTransitionBehavior
    
    func isAvailable(in application: UIApplication) -> Bool {
        return base.isAvailable(in: application)
    }
    
    func perform<To>(in application: UIApplication, to viewController: To, animated: Bool) where To : UIViewController {
        base.perform(in: application, to: viewController, animated: animated)
    }
    
    static let root = ApplicationBasedTransition(base: Root())
    struct Root: ApplicationBasedTransitionBehavior {
        func isAvailable(in application: UIApplication) -> Bool {
            return UIApplication.shared.delegate?.window != nil
        }
        
        func perform<To>(in application: UIApplication, to viewController: To, animated: Bool) where To : UIViewController {
            let window = UIApplication.shared.delegate!.window!!
            window.rootViewController?.dismiss(animated: false, completion: nil)
            window.rootViewController = viewController
            window.makeKeyAndVisible()
        }
    }
    
    // TODO: Wrap ViewControllerBasedTransition`s as ApplicationBased ? 
    static let present = ApplicationBasedTransition(base: Present())
    struct Present: ApplicationBasedTransitionBehavior {
        func isAvailable(in application: UIApplication) -> Bool {
            return UIApplication.shared.delegate?.window??.rootViewController != nil
        }
        
        func perform<To>(in application: UIApplication, to viewController: To, animated: Bool) where To : UIViewController {
            let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController!
            rootViewController.present(viewController, animated: animated)
        }
    }
}

struct AnyApplicationBasedTransitionBehavior: ApplicationBasedTransitionBehavior {
    typealias TransitionAvailable<In: UIApplication> = (In) -> Bool
    typealias TransitionAction<In: UIApplication, To: UIViewController> = (In, To, Bool) -> Void
    private let available: TransitionAvailable<UIApplication>
    private let action: TransitionAction<UIApplication, UIViewController>
    
    init(available: @escaping TransitionAvailable<UIApplication>, action: @escaping TransitionAction<UIApplication, UIViewController>) {
        self.available = available
        self.action = action
    }
    
    func isAvailable(in application: UIApplication) -> Bool {
        return available(application)
    }
    
    func perform<To>(in application: UIApplication, to viewController: To, animated: Bool) where To : UIViewController {
        action(application, viewController, animated)
    }
}

// MARK: ViewController based

// TODO: Add preview behavior - UIViewControllerPreviewing

/// push (replace, navigationRoot), present, preview
public protocol ViewControllerBasedTransitionBehavior {
    func isAvailable<In: UIViewController>(in sourceViewController: In) -> Bool
    func perform<In: UIViewController, To: UIViewController>(in sourceViewController: In, to viewControllers: [To], animated: Bool)
}

// TODO: Remove this extension after Apple fixed bug with convert array to variadic parameters
extension ViewControllerBasedTransitionBehavior {
    func perform<In: UIViewController, To: UIViewController>(in sourceViewController: In, to viewControllers: To ..., animated: Bool) {
        perform(in: sourceViewController, to: viewControllers, animated: animated)
    }
}

public protocol PresentConfiguration {
    func isAvailable(in viewController: UIViewController) -> Bool
    func prepare(forPresent controller: UIViewController)
}

public struct ViewControllerBasedTransition: ViewControllerBasedTransitionBehavior {
    let base: ViewControllerBasedTransitionBehavior
    
    public func isAvailable<In>(in sourceViewController: In) -> Bool where In : UIViewController {
        return base.isAvailable(in: sourceViewController)
    }
    
    public func perform<In, To>(in sourceViewController: In, to viewControllers: [To], animated: Bool) where In : UIViewController, To : UIViewController {
        base.perform(in: sourceViewController, to: viewControllers, animated: animated)
    }
    
    public static let push = ViewControllerBasedTransition(base: Push())
    struct Push: ViewControllerBasedTransitionBehavior {
        func isAvailable<In>(in sourceViewController: In) -> Bool where In : UIViewController {
            return sourceViewController.navigationController != nil
        }
        
        func perform<In, To>(in sourceViewController: In, to viewController: [To], animated: Bool) where In : UIViewController, To : UIViewController {
            let navController = sourceViewController.navigationController!
            navController.setViewControllers(navController.viewControllers + viewController,
                                             animated: true)
        }
    }
    
    // TODO: Add Pop behavior?
    
    // TODO: After transition to Swift 4, implement replace with range limited by one side
    public static let replace = ViewControllerBasedTransition(base: Replace(last: 1))
    public static func replace(last: Int) -> ViewControllerBasedTransition {
        return ViewControllerBasedTransition(base: Replace(last: last))
    }
    struct Replace: ViewControllerBasedTransitionBehavior {
        let last: Int
        
        func isAvailable<In>(in sourceViewController: In) -> Bool where In : UIViewController {
            return sourceViewController.navigationController.map { $0.viewControllers.count >= last } ?? false
        }
        
        func perform<In, To>(in sourceViewController: In, to viewControllers: [To], animated: Bool) where In : UIViewController, To : UIViewController {
            let navController = sourceViewController.navigationController!
            let stack = navController.viewControllers
            navController.setViewControllers(stack[0 ..< stack.count - last] + viewControllers,
                                             animated: animated)
        }
    }
    
    public static let navigationRoot = ViewControllerBasedTransition(base: NavigationRoot())
    struct NavigationRoot: ViewControllerBasedTransitionBehavior {
        func isAvailable<In>(in sourceViewController: In) -> Bool where In : UIViewController {
            return sourceViewController.navigationController != nil
        }
        
        func perform<In, To>(in sourceViewController: In, to viewControllers: [To], animated: Bool) where In : UIViewController, To : UIViewController {
            sourceViewController.navigationController!.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    public static let present = ViewControllerBasedTransition(base: Present(config: .common(modalStyle: .fullScreen, transitionStyle: .coverVertical), completion: nil))
    public static func present(as configured: Present.Config, completion: (() -> Void)? = nil) -> ViewControllerBasedTransition {
        return ViewControllerBasedTransition(base: Present(config: configured, completion: completion))
    }
    public struct Present: ViewControllerBasedTransitionBehavior {
        let config: Config
        let completion: (() -> Void)?
        
        public func isAvailable<In>(in sourceViewController: In) -> Bool where In : UIViewController {
            return sourceViewController.presentedViewController != nil && config.isAvailable(in: sourceViewController)
        }
        
        public func perform<In, To>(in sourceViewController: In, to viewControllers: [To], animated: Bool) where In : UIViewController, To : UIViewController {
            config.prepare(forPresent: viewControllers.first!)
            sourceViewController.present(viewControllers.first!, animated: animated, completion: completion)
        }
        
        public struct Config: PresentConfiguration {
            let base: PresentConfiguration
            
            public func isAvailable(in viewController: UIViewController) -> Bool {
                return base.isAvailable(in: viewController)
            }
            
            public func prepare(forPresent controller: UIViewController) {
                base.prepare(forPresent: controller)
            }
            
            public static func common(modalStyle: UIModalPresentationStyle, transitionStyle: UIModalTransitionStyle) -> Config {
                return Config(base: Common(modalStyle: modalStyle, transitionStyle: transitionStyle))
            }
            struct Common: PresentConfiguration {
                let modalStyle: UIModalPresentationStyle
                let transitionStyle: UIModalTransitionStyle
                
                func isAvailable(in viewController: UIViewController) -> Bool {
                    // TODO: add checkers
                    guard transitionStyle == .partialCurl,
                        viewController.isBeingPresented,
                        viewController.modalPresentationStyle != .fullScreen else {
                            return true
                    }
                    
                    return false
                }
                
                func prepare(forPresent controller: UIViewController) {
                    controller.modalPresentationStyle = modalStyle
                    controller.modalTransitionStyle = transitionStyle
                }
            }
            
            public static func popover(config: @escaping (UIPopoverPresentationController) -> Void) -> Config {
                return Config(base: Popover(config: config))
            }
            struct Popover: PresentConfiguration {
                let config: (UIPopoverPresentationController) -> Void
                
                func isAvailable(in viewController: UIViewController) -> Bool {
                    return UIDevice.current.userInterfaceIdiom != .phone
                }
                
                func prepare(forPresent controller: UIViewController) {
                    controller.modalPresentationStyle = .popover
                    config(controller.popoverPresentationController!)
                }
            }
            
            public static func custom(delegate: UIViewControllerTransitioningDelegate) -> Config {
                return Config(base: Custom(delegate: delegate))
            }
            struct Custom: PresentConfiguration {
                let delegate: UIViewControllerTransitioningDelegate
                
                func isAvailable(in viewController: UIViewController) -> Bool {
                    return true // TODO: Change?, custom always available
                }
                
                func prepare(forPresent controller: UIViewController) {
                    controller.modalPresentationStyle = .custom
                    controller.transitioningDelegate = delegate
                }
            }
        }
    }
}

struct AnyViewControllerBasedTransitionBehavior: ViewControllerBasedTransitionBehavior {
    typealias TransitionAvailable<In: UIViewController> = (In) -> Bool
    typealias TransitionAction<In: UIViewController, To: UIViewController> = (_ in: In, _ to: [To], _ animated: Bool) -> Void
    
    private let available: TransitionAvailable<UIViewController>
    private let action: TransitionAction<UIViewController, UIViewController>
    
    init(available: @escaping TransitionAvailable<UIViewController>, action: @escaping TransitionAction<UIViewController, UIViewController>) {
        self.available = available
        self.action = action
    }
    
    func isAvailable<In>(in sourceViewController: In) -> Bool where In : UIViewController {
        return available(sourceViewController)
    }
    
    func perform<In, To>(in sourceViewController: In, to viewControllers: [To], animated: Bool) where In : UIViewController, To : UIViewController {
        action(sourceViewController, viewControllers, animated)
    }
}

public extension UIViewController {
    func isAvailable(transition: ViewControllerBasedTransitionBehavior) -> Bool {
        return transition.isAvailable(in: self)
    }
    
    func perform<To: UIViewController>(transition: ViewControllerBasedTransitionBehavior, to viewControllers: [To], animated: Bool) {
        transition.perform(in: self, to: viewControllers, animated: animated)
    }
    
    @discardableResult
    func perform<To: UIViewController>(transitionIfAvailable transition: ViewControllerBasedTransitionBehavior, to viewControllers: [To], animated: Bool) -> Bool {
        guard isAvailable(transition: transition) else { return false }
        
        perform(transition: transition, to: viewControllers, animated: animated)
        return true
    }
}

public extension UIViewController {
    func perform<To: UIViewController>(presetTransition transition: ViewControllerBasedTransition, to viewControllers: To ..., animated: Bool) {
        transition.perform(in: self, to: viewControllers, animated: animated)
    }
}
