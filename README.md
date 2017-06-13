# TransitionBehaviors

[![CI Status](http://img.shields.io/travis/k-o-d-e-n/TransitionBehaviors.svg?style=flat)](https://travis-ci.org/k-o-d-e-n/TransitionBehaviors)
[![Version](https://img.shields.io/cocoapods/v/TransitionBehaviors.svg?style=flat)](http://cocoapods.org/pods/TransitionBehaviors)
[![License](https://img.shields.io/cocoapods/l/TransitionBehaviors.svg?style=flat)](http://cocoapods.org/pods/TransitionBehaviors)
[![Platform](https://img.shields.io/cocoapods/p/TransitionBehaviors.svg?style=flat)](http://cocoapods.org/pods/TransitionBehaviors)

## Description

TransitionBehaviors is set of often used behaviors for screen transitions, including more difficult transitions than push, pop, present.
How much often you seen such code:
```swift
var viewControllers = self.navigationController!.viewControllers
if viewControllers.count > 3 {
viewControllers = [viewControllers[viewControllers.count - 2]]
self.navigationController!.viewControllers = viewControllers
}
```
TransitionBehaviors is trying decide these problems.

Transitions, are based on view controller API, are defined protocol:
```swift
public protocol ViewControllerBasedTransitionBehavior {
associatedtype Source: UIViewController
associatedtype Target: UIViewController
func isAvailable(in sourceViewController: Source) -> Bool
func perform(in sourceViewController: Source, to viewControllers: [Target], animated: Bool)
}
```

In library implemented basic transitions with extended features, such as:
```swift
.pop(back: Int) - for removing view controllers from navigation stack with user defined number of popped view controllers
.replace(last: Int) - for replace latest view controllers with new controllers
.push - for push one or more view controllers
.root - for replace all stack view controllers.
and other...
```
For view controllers are not subclass UINavigationController, these transitions has prefix 'navigation'

Presentation section has one behavior, which configured with:
```swift
.common(modalStyle: UIModalPresentationStyle, transitionStyle: UIModalTransitionStyle) - common configuration, for system defined presentation types
.popover(config: (UIPopoverPresentationController) -> Void) - popover, is available only on iPad.
.custom(delegate: UIViewControllerTransitioningDelegate) - user defined transition, implemented in transition delegate.
```
For dismissing using behaviors dismiss or dismissParent(on level: Int), where you can specify level parent view controller regarding current view controller.
Also, implemented behaviors for UITabBarController and UIViewController with possible add and/or remove childs.

For correct code completion created extensions for UIViewController, UINavigationController and UITabBarController with prefix 'presetTransition', 'navigationTransition', 'tabBarTransition' correspondingly.

This library has swifty code, and written is using basic swift patterns. This code will be interested for learning juniors.

## Requirements

Xcode 8.3+

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

TransitionBehaviors is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "TransitionBehaviors"
```

## Author

k-o-d-e-n, koden.u8800@gmail.com

In example is used code from 'https://www.raywenderlich.com/139277/uipresentationcontroller-tutorial-getting-started' only for demonstration purposes

## License

TransitionBehaviors is available under the MIT license. See the LICENSE file for more info.
