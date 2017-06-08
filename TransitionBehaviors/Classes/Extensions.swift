//
//  Extensions.swift
//  Pods
//
//  Created by Denis Koryttsev on 07/06/2017.
//
//

import Foundation

extension UINavigationController {
    var isEmpty: Bool { return self.viewControllers.first == nil }
    weak var rootViewController: UIViewController? {
        return self.viewControllers.first
    }
}

extension String: Error {}
