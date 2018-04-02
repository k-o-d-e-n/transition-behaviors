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
public protocol ApplicationBasedTransitionBehavior {
    func isAvailable(in application: UIApplication) -> Bool
    func perform<To: UIViewController>(in application: UIApplication, to viewController: To, animated: Bool)
}

public extension UIApplication {
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
public extension UIApplication {
    func perform(presetTransition transition: ApplicationBasedTransition, to viewController: UIViewController, animated: Bool) {
        perform(transition: transition, to: viewController, animated: animated)
    }
}

public struct ApplicationBasedTransition: ApplicationBasedTransitionBehavior {
    let base: ApplicationBasedTransitionBehavior
    
    public func isAvailable(in application: UIApplication) -> Bool {
        return base.isAvailable(in: application)
    }
    
    public func perform<To>(in application: UIApplication, to viewController: To, animated: Bool) where To : UIViewController {
        base.perform(in: application, to: viewController, animated: animated)
    }
    
    public static let root = ApplicationBasedTransition(base: Root())
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
    public static let present = ApplicationBasedTransition(base: Present())
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
// TODO: Implement isAvailable by one agreement, or add yet method for evaluate state for ready
// TODO: Remove 'to viewControllers' parameter from main function, use it in concrete behavior

/// push (replace, navigationRoot), present, preview
public protocol ViewControllerBasedTransitionBehavior {
    associatedtype Source: UIViewController
    associatedtype Target: UIViewController
    func isAvailable(in sourceViewController: Source) -> Bool
    func perform(in sourceViewController: Source, to viewControllers: [Target], animated: Bool)
}

// TODO: Remove this extension after Apple fixed bug with convert array to variadic parameters
extension ViewControllerBasedTransitionBehavior {
    func perform(in sourceViewController: Source, to viewControllers: Target ..., animated: Bool) {
        perform(in: sourceViewController, to: viewControllers, animated: animated)
    }
}

public protocol PresentConfiguration {
    func isAvailable(in viewController: UIViewController) -> Bool
    func prepare(forPresent controller: UIViewController)
}

public struct ViewControllerBasedTransition<Source: UIViewController, Target: UIViewController>: ViewControllerBasedTransitionBehavior {
    fileprivate typealias This = ViewControllerBasedTransition
    let isAvailable: (Source) -> Bool
    let action: (Source, [Target], Bool) -> Void
    
    init<T: ViewControllerBasedTransitionBehavior>(base: T) where T.Source == Source, T.Target == Target {
        isAvailable = base.isAvailable
        action = base.perform
    }
    
    public func isAvailable(in sourceViewController: Source) -> Bool {
        return isAvailable(sourceViewController)
    }
    
    public func perform(in sourceViewController: Source, to viewControllers: [Target], animated: Bool) {
        action(sourceViewController, viewControllers, animated)
    }
}

// MARK: ViewControllerBased - UIViewController

extension ViewControllerBasedTransition {
    public static func addChilds(layout: ((UIView, [UIView]) -> Void)? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AddChilds(layout: layout))
    }
    /// Add child view controller to source view controller, with define layout.
    struct AddChilds: ViewControllerBasedTransitionBehavior {
        let layout: ((UIView, [UIView]) -> Void)?
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return true
        }
        func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
            viewControllers.forEach { viewController in
                sourceViewController.addChildViewController(viewController)
                sourceViewController.view.addSubview(viewController.view)
                viewController.didMove(toParentViewController: sourceViewController)
            }
            layout?(sourceViewController.view, viewControllers.map { $0.view })
        }
    }
    public static var removeChilds: ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: RemoveChilds())
    }
    
    /// Remove child view controller from source view controller.
    struct RemoveChilds: ViewControllerBasedTransitionBehavior {
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.childViewControllers.count > 0
        }
        func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
            let removed = viewControllers.count > 0 ? viewControllers : sourceViewController.childViewControllers
            removed.forEach { viewController in
                viewController.willMove(toParentViewController: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParentViewController()
            }
        }
    }
}

// MARK: ViewControllerBased - UINavigationController

extension ViewControllerBasedTransition {
    struct AnyChildNavigation<T: ViewControllerBasedTransitionBehavior>: ViewControllerBasedTransitionBehavior where T.Source == UINavigationController {
        let navigationBehavior: T
        
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.navigationController.map { navigationBehavior.isAvailable(in: $0) } ?? false
        }
        func perform(in sourceViewController: UIViewController, to viewControllers: [T.Target], animated: Bool) {
            navigationBehavior.perform(in: sourceViewController.navigationController!, to: viewControllers, animated: animated)
        }
    }
    
    public static var push: ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Push())
    }
    struct Push: ViewControllerBasedTransitionBehavior {
        func isAvailable(in sourceViewController: UINavigationController) -> Bool {
            return true
        }
        
        func perform(in sourceViewController: UINavigationController, to viewController: [UIViewController], animated: Bool) {
            sourceViewController.setViewControllers(sourceViewController.viewControllers + viewController,
                                                    animated: true)
        }
    }
    public static var navigationPush: ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.push))
    }
    /* Uncomment if require additional behavior instead AnyChildNavigation
    struct ChildPush: ViewControllerBasedTransitionBehavior {
        let navigationPush: Push
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.navigationController.map { navigationPush.isAvailable(in: $0) } ?? false
        }
        
        func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
            navigationPush.perform(in: sourceViewController.navigationController!, to: viewControllers, animated: animated)
        }
    }
     */
    
    public static func pop(popped: UnsafeMutablePointer<UIViewController?>? = nil) -> ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Pop(popped: popped))
    }
    public static func popToRoot(popped: UnsafeMutablePointer<[UIViewController]?>? = nil) -> ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Pop.Root(popped: popped))
    }
    public static func popTo(popped: UnsafeMutablePointer<[UIViewController]?>? = nil) -> ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Pop.To(popped: popped))
    }
    public static func pop(back: Int, popped: UnsafeMutablePointer<[UIViewController]?>? = nil) -> ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Pop.Back(back: back, popped: popped))
    }
    struct Pop: ViewControllerBasedTransitionBehavior {
        let popped: UnsafeMutablePointer<UIViewController?>?
        func isAvailable(in sourceViewController: UINavigationController) -> Bool {
            return sourceViewController.viewControllers.count > 0
        }
        func perform(in sourceViewController: UINavigationController, to viewControllers: [UIViewController], animated: Bool) {
            popped?.pointee = sourceViewController.popViewController(animated: animated)
        }
        struct To: ViewControllerBasedTransitionBehavior {
            let popped: UnsafeMutablePointer<[UIViewController]?>?
            func isAvailable(in sourceViewController: UINavigationController) -> Bool {
                return sourceViewController.viewControllers.count > 1
            }
            func perform(in sourceViewController: UINavigationController, to viewControllers: [UIViewController], animated: Bool) {
                popped?.pointee = sourceViewController.popToViewController(viewControllers.first!, animated: animated)
            }
        }
        struct Back: ViewControllerBasedTransitionBehavior {
            let back: Int
            let popped: UnsafeMutablePointer<[UIViewController]?>?
            func isAvailable(in sourceViewController: UINavigationController) -> Bool {
                return sourceViewController.viewControllers.count >= back
            }
            func perform(in sourceViewController: UINavigationController, to viewControllers: [UIViewController], animated: Bool) {
                let stack = sourceViewController.viewControllers
                sourceViewController.setViewControllers(Array(stack.dropLast(back)), animated: animated)
                popped?.pointee = Array(stack.suffix(back))
            }
        }
        struct Root: ViewControllerBasedTransitionBehavior {
            let popped: UnsafeMutablePointer<[UIViewController]?>?
            func isAvailable(in sourceViewController: UINavigationController) -> Bool {
                return true
            }
            func perform(in sourceViewController: UINavigationController, to viewControllers: [UIViewController], animated: Bool) {
                popped?.pointee = sourceViewController.popToRootViewController(animated: animated)
            }
        }
    }
    public static func navigationPop(popped: UnsafeMutablePointer<UIViewController?>? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.pop(popped: popped)))
    }
    public static func navigationPop(back: Int, popped: UnsafeMutablePointer<[UIViewController]?>? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.pop(back: back, popped: popped)))
    }
    public static func navigationPopToRoot(popped: UnsafeMutablePointer<[UIViewController]?>? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.popToRoot(popped: popped)))
    }
    
    // TODO: After transition to Swift 4, implement replace with range limited by one side
    public static var replace: ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .replace(last: 1)
    }
    public static func replace(last: Int) -> ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Replace(last: last))
    }
    struct Replace: ViewControllerBasedTransitionBehavior {
        let last: Int
        
        func isAvailable(in sourceViewController: UINavigationController) -> Bool {
            return sourceViewController.viewControllers.count >= last
        }
        
        func perform(in sourceViewController: UINavigationController, to viewControllers: [UIViewController], animated: Bool) {
            let stack = sourceViewController.viewControllers
            sourceViewController.setViewControllers(stack.dropLast(last) + viewControllers,
                                                    animated: animated)
        }
    }
    public static var navigationReplace: ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.replace))
    }
    public static func navigationReplace(last: Int) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.replace(last: last)))
    }
    /* Uncomment if require additional behavior instead AnyChildNavigation
    struct ChildReplace: ViewControllerBasedTransitionBehavior {
        let navigationReplace: Replace
        
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.navigationController.map { navigationReplace.isAvailable(in: $0) } ?? false
        }
        
        func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
            navigationReplace.perform(in: sourceViewController.navigationController!, to: viewControllers, animated: true)
        }
    }
     */
    
    public static var root: ViewControllerBasedTransition<UINavigationController, UIViewController> {
        return .init(base: Root())
    }
    struct Root: ViewControllerBasedTransitionBehavior {
        func isAvailable(in sourceViewController: UINavigationController) -> Bool {
            return true
        }
        
        func perform(in sourceViewController: UINavigationController, to viewControllers: [UIViewController], animated: Bool) {
            sourceViewController.setViewControllers(viewControllers, animated: animated)
        }
    }
    public static var navigationRoot: ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildNavigation(navigationBehavior: This.root))
    }
    /* Uncomment if require additional behavior instead AnyChildNavigation
    struct NavigationRoot: ViewControllerBasedTransitionBehavior {
        let navigationRoot: Root
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.navigationController.map { navigationRoot.isAvailable(in: $0) } ?? false
        }
        
        func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
            navigationRoot.perform(in: sourceViewController.navigationController!, to: viewControllers, animated: animated)
        }
    }
     */
}

// MARK: ViewControllerBased - Presentation

extension ViewControllerBasedTransition {
    public static var present: ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .present(as: .common(modalStyle: .fullScreen, transitionStyle: .coverVertical))
    }
    public static func present(as configured: Present.Config, completion: (() -> Void)? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: Present(config: configured, completion: completion))
    }
    public struct Present: ViewControllerBasedTransitionBehavior {
        let config: Config
        let completion: (() -> Void)?
        
        public func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.presentedViewController != nil && config.isAvailable(in: sourceViewController)
        }
        
        public func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
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
    
    public static func dismiss(completion: (() -> Void)? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: Dismiss(completion: completion))
    }
    public static func dismissParent(on level: Int, completion: (() -> Void)? = nil) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: Dismiss.Parent(level: level, completion: completion))
    }
    struct Dismiss: ViewControllerBasedTransitionBehavior {
        let completion: (() -> Void)?
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.presentedViewController != nil || sourceViewController.presentingViewController != nil
        }
        func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
            sourceViewController.dismiss(animated: animated, completion: completion)
        }
        struct Parent: ViewControllerBasedTransitionBehavior {
            let level: Int
            let completion: (() -> Void)?
            func isAvailable(in sourceViewController: UIViewController) -> Bool {
                return sourceViewController.hasPresentingViewController(on: level)
            }
            func perform(in sourceViewController: UIViewController, to viewControllers: [UIViewController], animated: Bool) {
                sourceViewController
                    .presentingViewController(on: level)?
                    .dismiss(animated: animated, completion: completion)
            }
        }
    }
}

// MARK: ViewControllerBased - UITabBarController

extension ViewControllerBasedTransition {
    public static func addRemove(added: IndexSet = [], removed: IndexSet = []) -> ViewControllerBasedTransition<UITabBarController, UIViewController> {
        return .init(base: TabBarAddRemove(addRemove: .init(added: added, removed: removed)))
    }
    
    struct TabBarAddRemove: ViewControllerBasedTransitionBehavior {
        let addRemove: AddRemove
        struct AddRemove {
            let added: IndexSet
            let removed: IndexSet
            
            func isConsistent<T>(with source: [T], addedEntities: [T]) -> Bool {
                guard isConsistentRemoved(source: source) else { return false }
                guard added.count == addedEntities.count else { return false }
                guard added.count > 0 else { return true }
                guard added.last! <= source.count else {
                    var prev = source.count
                    while let next = added.integerGreaterThan(prev) {
                        guard prev == next - 1 else {
                            return false
                        }
                        prev = next
                    }
                    return true
                }
                
                return true
            }
            
            func isConsistentRemoved<T>(source: [T]) -> Bool {
                guard let max = removed.last else { return true }
                
                return source.endIndex >= max
            }
            
            func apply<T>(for array: [T], added entities: [T]) -> [T] {
                var array = array
                removed.reversed().forEach { array.remove(at: $0) }
                var iterator = entities.makeIterator()
                added.forEach { array.insert(iterator.next()!, at: $0) }
                
                return array
            }
        }
        
        func isAvailable(in sourceViewController: UITabBarController) -> Bool {
            return true
        }
        
        func perform(in sourceViewController: UITabBarController, to viewControllers: [UIViewController], animated: Bool) {
            let controllers = sourceViewController.viewControllers!
            guard addRemove.isConsistent(with: controllers, addedEntities: viewControllers) else { return }
            
            sourceViewController.setViewControllers(addRemove.apply(for: controllers, added: viewControllers),
                                                    animated: animated)
        }
    }
    
    public static func tabBarAddRemove(added: IndexSet = [], removed: IndexSet = []) -> ViewControllerBasedTransition<UIViewController, UIViewController> {
        return .init(base: AnyChildTabBar(tabBarBehavior: This.addRemove(added: added, removed: removed)))
    }
    struct AnyChildTabBar<T: ViewControllerBasedTransitionBehavior>: ViewControllerBasedTransitionBehavior where T.Source == UITabBarController {
        let tabBarBehavior: T
        
        func isAvailable(in sourceViewController: UIViewController) -> Bool {
            return sourceViewController.tabBarController.map { tabBarBehavior.isAvailable(in: $0) } ?? false
        }
        
        func perform(in sourceViewController: UIViewController, to viewControllers: [T.Target], animated: Bool) {
            tabBarBehavior.perform(in: sourceViewController.tabBarController!, to: viewControllers, animated: animated)
        }
    }
}

// MARK: UIViewController - Extensions

public extension UIViewController {
    func isAvailable<T: ViewControllerBasedTransitionBehavior>(transition: T) -> Bool {
        return transition.isAvailable(in: self as! T.Source)
    }
    
    func perform<T: ViewControllerBasedTransitionBehavior>(transition: T, to viewControllers: [T.Target], animated: Bool) {
        transition.perform(in: self as! T.Source,
                           to: viewControllers,
                           animated: animated)
    }
}

public extension UIViewController {
    func perform(presetTransition transition: ViewControllerBasedTransition<UIViewController, UIViewController>, to viewControllers: UIViewController? ..., animated: Bool) {
        transition.perform(in: self, to: viewControllers.flatMap { $0 }, animated: animated)
    }
    
    @discardableResult
    func perform(presetTransitionIfAvailable transition: ViewControllerBasedTransition<UIViewController, UIViewController>, to viewControllers: UIViewController? ..., animated: Bool, reserved: (ViewControllerBasedTransition<UIViewController, UIViewController>, Bool)) -> Bool {
        let to = viewControllers.flatMap { $0 }
        guard isAvailable(transition: transition) else {
            perform(transition: reserved.0, to: to, animated: reserved.1)
            return false
        }
        
        perform(transition: transition, to: to, animated: animated)
        return true
    }
}

public extension UINavigationController {
    func perform(navigationTransition transition: ViewControllerBasedTransition<UINavigationController, UIViewController>, to viewControllers: UIViewController? ..., animated: Bool) {
        transition.perform(in: self, to: viewControllers.flatMap { $0 }, animated: animated)
    }
}

public extension UITabBarController {
    func perform(tabBarTransition transition: ViewControllerBasedTransition<UITabBarController, UIViewController>, to viewControllers: UIViewController? ..., animated: Bool) {
        transition.perform(in: self, to: viewControllers.flatMap { $0 }, animated: animated)
    }
}

// MARK: Undepended

public struct AnyViewControllerBasedTransitionBehavior<S: UIViewController, T: UIViewController>: ViewControllerBasedTransitionBehavior {
    public typealias TransitionAvailable = (Source) -> Bool
    public typealias TransitionAction = (Source, [Target], Bool) -> Void
    
    private let available: TransitionAvailable
    private let action: TransitionAction
    
    public init(available: @escaping TransitionAvailable, action: @escaping TransitionAction) {
        self.available = available
        self.action = action
    }
    
    public func isAvailable(in sourceViewController: S) -> Bool {
        return available(sourceViewController)
    }
    
    public func perform(in sourceViewController: S, to viewControllers: [T], animated: Bool) {
        action(sourceViewController, viewControllers, animated)
    }
}

