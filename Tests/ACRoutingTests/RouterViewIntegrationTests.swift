import Testing
import SwiftUI
@testable import ACRouting

// MARK: - RouterView Integration Tests
//
// RouterView is both a View and a Router. Since @State properties cannot be
// inspected outside the SwiftUI render loop, these tests verify the Router
// interface contract by:
//   1. Ensuring RouterView conforms to both View and Router at compile time.
//   2. Exercising every Router method through a RouterView instance to confirm
//      the calls don't trap or fatalError.
//   3. Where possible, verifying observable side effects (e.g. path mutation
//      via an inherited push stack binding).

@Suite("RouterView integration")
@MainActor
struct RouterViewIntegrationTests {
    final class StackBox {
        var stack: [AnyDestination]

        init(_ stack: [AnyDestination] = []) {
            self.stack = stack
        }
    }

    private func makeChildRouter(
        stackBox: StackBox
    ) -> RouterView<Text> {
        let binding = Binding<[AnyDestination]>(
            get: { stackBox.stack },
            set: { stackBox.stack = $0 }
        )

        return RouterView(inheritedPushStack: binding) { _ in
            Text("Child")
        }
    }

    // MARK: - Initialization

    @Test("RouterView can be initialized with defaults")
    func defaultInit() {
        let _ = RouterView { _ in Text("Root") }
    }

    @Test("RouterView can be initialized with an inherited push stack")
    func initWithInheritedPushStack() {
        let stackBox = StackBox()
        let binding = Binding<[AnyDestination]>(get: { stackBox.stack }, set: { stackBox.stack = $0 })
        let _ = RouterView(inheritedPushStack: binding) { _ in
            Text("Child")
        }
    }

    // MARK: - Router method calls (smoke tests)
    //
    // These guarantee that calling any Router method on a RouterView instance
    // does not trap. State changes happen asynchronously via SwiftUI's runtime,
    // so we verify the call completes without error.

    @Test("showScreen(.push) is callable")
    func showScreenPush() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.showScreen(.push) { _ in Text("Pushed") }
    }

    @Test("showScreen(.push) appends to an inherited stack even when it starts empty")
    func showScreenPushMutatesInheritedStack() {
        let stackBox = StackBox()
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.showScreen(.push) { _ in Text("Pushed") }

        #expect(stackBox.stack.count == 1)
    }

    @Test("showScreen(.push) preserves the existing inherited push stack")
    func showScreenPushPreservesExistingInheritedStack() {
        let first = AnyDestination(destination: Text("First"))
        let second = AnyDestination(destination: Text("Second"))
        let stackBox = StackBox([first, second])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.showScreen(.push) { _ in Text("Third") }

        #expect(stackBox.stack.count == 3)
        #expect(Array(stackBox.stack.prefix(2)) == [first, second])
    }

    @Test("showScreen(.sheet) is callable")
    func showScreenSheet() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.showScreen(.sheet) { _ in Text("Sheet") }
    }

    @Test("showScreen(.fullScreenCover) is callable")
    func showScreenFullScreenCover() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.showScreen(.fullScreenCover) { _ in Text("FullScreen") }
    }

    @Test("showAlert is callable")
    func showAlert() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.showAlert(.alert, title: "Test", subtitle: "Detail")
    }

    @Test("showErrorAlert is callable")
    func showErrorAlert() {
        let router: any Router = RouterView { _ in Text("Root") }
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fail"])
        router.showErrorAlert(error: error)
    }

    @Test("dismissAlert is callable")
    func dismissAlert() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.dismissAlert()
    }

    @Test("showModal is callable")
    func showModal() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.showModal { Text("Modal Content") }
    }

    @Test("dismissModal is callable")
    func dismissModal() {
        let router: any Router = RouterView { _ in Text("Root") }
        router.dismissModal()
    }

    @Test("dismissScreen pops the inherited push stack")
    func dismissScreenPopsInheritedStack() {
        let stackBox = StackBox([AnyDestination(destination: Text("First"))])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.dismissScreen()

        #expect(stackBox.stack.isEmpty)
    }

    @Test("dismissScreen removes only the top-most inherited destination")
    func dismissScreenRemovesOnlyTopMostInheritedDestination() {
        let first = AnyDestination(destination: Text("First"))
        let second = AnyDestination(destination: Text("Second"))
        let stackBox = StackBox([first, second])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.dismissScreen()

        #expect(stackBox.stack == [first])
    }

    @Test("dismissScreen is a no-op when the inherited push stack is already empty")
    func dismissScreenOnEmptyInheritedStackIsNoOp() {
        let stackBox = StackBox()
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.dismissScreen()

        #expect(stackBox.stack.isEmpty)
    }

    @Test("pop removes one screen from the inherited push stack")
    func popRemovesOneScreen() {
        let stackBox = StackBox([
            AnyDestination(destination: Text("First")),
            AnyDestination(destination: Text("Second"))
        ])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.pop()

        #expect(stackBox.stack.count == 1)
    }

    @Test(arguments: [0, -1])
    func popCountIgnoresNonPositiveRequests(_ count: Int) {
        let stackBox = StackBox([AnyDestination(destination: Text("Only"))])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.pop(count: count)

        #expect(stackBox.stack.count == 1)
    }

    @Test("pop(count:) removes up to the requested number of screens")
    func popCountRemovesRequestedScreens() {
        let stackBox = StackBox([
            AnyDestination(destination: Text("First")),
            AnyDestination(destination: Text("Second")),
            AnyDestination(destination: Text("Third"))
        ])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.pop(count: 2)

        #expect(stackBox.stack.count == 1)
    }

    @Test("pop(count:) clamps to the current stack depth")
    func popCountClampsToStackDepth() {
        let stackBox = StackBox([AnyDestination(destination: Text("Only"))])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.pop(count: 5)

        #expect(stackBox.stack.isEmpty)
    }

    @Test("popToRoot clears the inherited push stack")
    func popToRootClearsInheritedStack() {
        let stackBox = StackBox([
            AnyDestination(destination: Text("First")),
            AnyDestination(destination: Text("Second"))
        ])
        let router: any Router = makeChildRouter(stackBox: stackBox)

        router.popToRoot()

        #expect(stackBox.stack.isEmpty)
    }

    // MARK: - SegueOption determines navigation stack ownership

    @Test("Push keeps the current routed navigation stack")
    func pushKeepsCurrentNavigationStack() {
        #expect(SegueOption.push.createsNewNavigationStack == false)
    }

    @Test("Sheet starts a fresh routed navigation stack")
    func sheetStartsNewNavigationStack() {
        #expect(SegueOption.sheet.createsNewNavigationStack == true)
    }

    @Test("FullScreenCover starts a fresh routed navigation stack")
    func fullScreenCoverStartsNewNavigationStack() {
        #expect(SegueOption.fullScreenCover.createsNewNavigationStack == true)
    }
}

// MARK: - RouterView Environment Injection Tests

@Suite("RouterView environment injection")
@MainActor
struct RouterViewEnvironmentTests {

    @Test("RouterView conforms to both View and Router")
    func conformance() {
        let routerView = RouterView { _ in Text("Root") }

        // Compile-time check: can be used as a View
        let _: any View = routerView
        // Compile-time check: can be used as a Router
        let _: any Router = routerView
    }

    @Test("RouterView content closure accepts a Router parameter")
    func contentClosureAcceptsRouter() {
        // The content closure signature guarantees a Router is passed.
        // We verify this compiles and the RouterView can be created.
        let _ = RouterView { (router: any Router) in
            Text("Root")
        }
    }
}
