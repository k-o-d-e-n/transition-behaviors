//
//  Extensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 07/06/2017.
//
//

import Foundation

internal func debugAction(_ action: () -> Void) {
    #if DEBUG
        action()
    #endif
}

internal func debugLog(_ message: String, _ file: String = #file, _ line: Int = #line) {
    debugAction {
        debugPrint("File: \(file)")
        debugPrint("Line: \(line)")
        debugPrint("Message: \(message)")
    }
}

func debugFatalError(condition: @autoclosure () -> Bool = true,
                     _ message: String = "", _ file: String = #file, _ line: Int = #line) {
    debugAction {
        if condition() {
            debugLog(message, file, line)
            fatalError(message)
        }
    }
}

extension UIViewController {
    func controllerOnMaxLevel(limited by: Int? = nil, in hierarchy: (UIViewController) -> UIViewController?) -> (Int, UIViewController?) {
        var currentLevel = 0
        var next: UIViewController? = self
        while let parent = hierarchy(next!), (by.map { currentLevel < $0 } ?? true) {
            currentLevel += 1
            next = parent
        }
        return (currentLevel, next)
    }
    
    func hasPresentingViewController(on level: Int) -> Bool {
        return controllerOnMaxLevel(limited: level, in: { $0.presentingViewController }).0 == level
    }
    func presentingViewController(on level: Int) -> UIViewController? {
        let parent = controllerOnMaxLevel(limited: level, in: { $0.presentingViewController })
        return parent.0 == level ? parent.1 : nil
    }
    func hasPresentedViewController(on level: Int) -> Bool {
        return controllerOnMaxLevel(limited: level, in: { $0.presentedViewController }).0 == level
    }
    func presentedViewController(on level: Int) -> UIViewController? {
        let child = controllerOnMaxLevel(limited: level, in: { $0.presentedViewController })
        return child.0 == level ? child.1 : nil
    }
}

extension UINavigationController {
    var isEmpty: Bool { return self.viewControllers.first == nil }
    weak var rootViewController: UIViewController? {
        return self.viewControllers.first
    }
}

extension UIAlertController {
    convenience init(title: String?, message: String?, actions: [UIAlertAction]) {
        self.init(title: title, message: message, preferredStyle: .alert)
        for action: UIAlertAction in actions {
            addAction(action)
        }
    }
}

extension String: Error {}
