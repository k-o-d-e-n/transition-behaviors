import UIKit
import XCTest
@testable import TransitionBehaviors

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}

protocol TransitionContext {}

protocol Transition {
    associatedtype Source
    associatedtype Context
    func isAvailable(in source: Source) -> Bool
    func perform(in source: Source, use context: Context)
}
protocol VCBasedTransition: Transition where Source: UIViewController {}

struct Push: VCBasedTransition {
    func isAvailable(in source: UIViewController) -> Bool {
        return source.navigationController != nil
    }

    struct Context {
        let pushed: () -> UIViewController
        let animated: Bool

        init(pushed: @autoclosure @escaping () -> UIViewController, animated: Bool) {
            self.pushed = pushed
            self.animated = animated
        }
    }

    func perform(in source: UIViewController, use context: Context) {
        debugFatalError(condition: !isAvailable(in: source),
                        "Performing transition on not available source, result is undefined")

        source.navigationController?.pushViewController(context.pushed(), animated: context.animated)
    }
}

class ParameterizedViewController: UIViewController {
    let parameter: NSObject

    init(_ parameter: NSObject) {
        self.parameter = parameter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PushParameterized: VCBasedTransition {
    let base = Push()

    struct Context {
        let base: Push.Context

        init(_ parameter: NSObject, _ animated: Bool = true) {
            self.base = .init(pushed: ParameterizedViewController(parameter), animated: animated)
        }
    }

    func isAvailable(in source: Push.Source) -> Bool {
        return base.isAvailable(in: source)
    }

    func perform(in source: Push.Source, use context: Context) {
        base.perform(in: source, use: context.base)
    }
}

struct PushParameterized2: VCBasedTransition {
    let base = Push()

    func isAvailable(in source: Push.Source) -> Bool {
        return base.isAvailable(in: source)
    }

    func perform(in source: Push.Source, use context: NSObject) {
        base.perform(in: source, use: .init(pushed: ParameterizedViewController(context), animated: false))
    }
}

struct AnyTransition<Source, Context>: Transition {
    let available: (Source) -> Bool
    let perform: (Source, Context) -> Void

    init<T: Transition>(_ transition: T) where T.Source == Source, T.Context == Context {
        self.available = transition.isAvailable
        self.perform = transition.perform
    }

    func isAvailable(in source: Source) -> Bool {
        return available(source)
    }

    func perform(in source: Source, use context: Context) {
        perform(source, context)
    }

    func unsafeCasted<S, C>() -> AnyTransition<S, C> {
        return unsafeBitCast(self, to: AnyTransition<S, C>.self)
    }
}

class ContextProvidedViewController: UIViewController {
    struct Context {
        unowned var source: ContextProvidedViewController
        var parameter: NSObject

        func getSourceView() -> UIView {
            return source.view
        }
    }

    var transition1: AnyTransition<ContextProvidedViewController, Context>?

    func move() {
        let context = Context(source: self, parameter: NSObject())
        transition1?.perform(in: self, use: context)
    }
}

extension Tests {
    func testTransition() {
        let sourceViewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: sourceViewController)
        let transition = PushParameterized()
        let context = PushParameterized.Context(NSObject(), false)

        XCTAssertTrue(transition.isAvailable(in: sourceViewController))
        XCTAssertNotNil(sourceViewController.navigationController)
        XCTAssertTrue(navigationController.viewControllers.count == 1)

        transition.perform(in: sourceViewController, use: context)

        XCTAssertTrue(navigationController.viewControllers.count == 2)
    }
    func testTransition2() {
        let sourceViewController = ContextProvidedViewController()
        let navigationController = UINavigationController(rootViewController: sourceViewController)
        let transition = PushParameterized2()

        sourceViewController.transition1 = AnyTransition(transition).unsafeCasted()

        XCTAssertTrue(transition.isAvailable(in: sourceViewController))
        XCTAssertNotNil(sourceViewController.navigationController)
        XCTAssertTrue(navigationController.viewControllers.count == 1)

        sourceViewController.move()

        XCTAssertTrue(navigationController.viewControllers.count == 2)
    }
}


class AppLocation {
    var parent: AppLocation?
    let childs: [String: () -> AppLocation]

    init(_ childs: [String: () -> AppLocation]) {
        self.childs = childs
    }

    func location(by reference: String) -> AppLocation? {
        return reference
            .split(separator: "/")
            .reduce(self) { (current, ref) -> AppLocation? in
                return current?.childs[String(ref)]?()
        }
    }
}

extension Tests {
    func testAppLocations() {
        let root = AppLocation([
            "main": {
                return AppLocation([
                    "first": { AppLocation([:]) },
                    "second": { AppLocation([:]) }
                ])
            }
        ])

        XCTAssertNotNil(root.location(by: "main/second"))
        XCTAssertNil(root.location(by: "main/third"))
    }
}
