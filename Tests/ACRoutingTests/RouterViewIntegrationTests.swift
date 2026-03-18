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
//      via the screenStack binding).

@Suite("RouterView integration")
@MainActor
struct RouterViewIntegrationTests {

    // MARK: - Initialization

    @Test("RouterView can be initialized with defaults")
    func defaultInit() {
        let _ = RouterView { _ in Text("Root") }
    }

    @Test("RouterView can be initialized with an external screenStack binding")
    func initWithScreenStack() {
        var stack: [AnyDestination] = []
        let binding = Binding<[AnyDestination]>(get: { stack }, set: { stack = $0 })
        let _ = RouterView(screenStack: binding, addNavigationView: false) { _ in
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

    // MARK: - SegueOption determines navigation context wrapping

    @Test("Push wraps destination without new NavigationStack")
    func pushDoesNotAddNavigationView() {
        #expect(SegueOption.push.shouldAddNewNavigationView == false)
    }

    @Test("Sheet wraps destination with new NavigationStack")
    func sheetAddsNavigationView() {
        #expect(SegueOption.sheet.shouldAddNewNavigationView == true)
    }

    @Test("FullScreenCover wraps destination with new NavigationStack")
    func fullScreenCoverAddsNavigationView() {
        #expect(SegueOption.fullScreenCover.shouldAddNewNavigationView == true)
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
