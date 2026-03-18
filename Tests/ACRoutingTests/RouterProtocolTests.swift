import Testing
import SwiftUI
@testable import ACRouting

// MARK: - Spy Router

/// A test spy that records every Router method call with its arguments.
/// Used to verify that callers dispatch the correct methods and parameters
/// without needing the full SwiftUI rendering pipeline.
@MainActor
final class SpyRouter: Router {
    // MARK: Recorded calls

    struct ShowScreenCall: @unchecked Sendable {
        let option: SegueOption
    }

    struct ShowAlertCall: @unchecked Sendable {
        let option: AlertType
        let title: String
        let subtitle: String?
        let hasButtons: Bool
    }

    struct ShowErrorAlertCall: @unchecked Sendable {
        let errorDescription: String
        let hasButtons: Bool
    }

    struct ShowModalCall: @unchecked Sendable {
        let backgroundColor: Color
        let backgroundTapDismissesModal: Bool
    }

    private(set) var showScreenCalls: [ShowScreenCall] = []
    private(set) var dismissScreenCallCount = 0
    private(set) var showAlertCalls: [ShowAlertCall] = []
    private(set) var showErrorAlertCalls: [ShowErrorAlertCall] = []
    private(set) var dismissAlertCallCount = 0
    private(set) var showModalCalls: [ShowModalCall] = []
    private(set) var dismissModalCallCount = 0

    // MARK: Router conformance

    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T) {
        showScreenCalls.append(ShowScreenCall(option: option))
    }

    func dismissScreen() {
        dismissScreenCallCount += 1
    }

    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?) {
        showAlertCalls.append(ShowAlertCall(
            option: option,
            title: title,
            subtitle: subtitle,
            hasButtons: buttons != nil
        ))
    }

    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)?) {
        showErrorAlertCalls.append(ShowErrorAlertCall(
            errorDescription: error.localizedDescription,
            hasButtons: buttons != nil
        ))
    }

    func dismissAlert() {
        dismissAlertCallCount += 1
    }

    func showModal<T>(
        backgroundColor: Color,
        backgroundTransition: AnyTransition,
        animation: Animation,
        backgroundTapDismissesModal: Bool,
        screen: @escaping () -> T
    ) where T: View {
        showModalCalls.append(ShowModalCall(
            backgroundColor: backgroundColor,
            backgroundTapDismissesModal: backgroundTapDismissesModal
        ))
    }

    func dismissModal() {
        dismissModalCallCount += 1
    }
}

// MARK: - Router Protocol Default Parameter Tests

@Suite("Router protocol defaults")
@MainActor
struct RouterProtocolDefaultsTests {

    @Test("showAlert can be called with title only")
    func showAlertMinimalParams() {
        let spy = SpyRouter()
        spy.showAlert(.alert, title: "Hello")

        #expect(spy.showAlertCalls.count == 1)
        #expect(spy.showAlertCalls[0].title == "Hello")
        #expect(spy.showAlertCalls[0].subtitle == nil)
        #expect(spy.showAlertCalls[0].hasButtons == false)
    }

    @Test("showAlert can be called with all parameters")
    func showAlertFullParams() {
        let spy = SpyRouter()
        spy.showAlert(.confirmationDialog, title: "Delete", subtitle: "Sure?", buttons: { AnyView(EmptyView()) })

        #expect(spy.showAlertCalls.count == 1)
        #expect(spy.showAlertCalls[0].option == .confirmationDialog)
        #expect(spy.showAlertCalls[0].subtitle == "Sure?")
        #expect(spy.showAlertCalls[0].hasButtons == true)
    }

    @Test("showErrorAlert can be called with error only")
    func showErrorAlertMinimalParams() {
        let spy = SpyRouter()
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Oops"])
        spy.showErrorAlert(error: error)

        #expect(spy.showErrorAlertCalls.count == 1)
        #expect(spy.showErrorAlertCalls[0].errorDescription == "Oops")
        #expect(spy.showErrorAlertCalls[0].hasButtons == false)
    }

    @Test("showModal can be called with screen only (all defaults)")
    func showModalMinimalParams() {
        let spy = SpyRouter()
        spy.showModal { Text("Modal") }

        #expect(spy.showModalCalls.count == 1)
        #expect(spy.showModalCalls[0].backgroundTapDismissesModal == true)
    }

    @Test("showModal can be called with custom parameters")
    func showModalCustomParams() {
        let spy = SpyRouter()
        spy.showModal(
            backgroundColor: .red,
            backgroundTapDismissesModal: false
        ) {
            Text("Modal")
        }

        #expect(spy.showModalCalls.count == 1)
        #expect(spy.showModalCalls[0].backgroundColor == .red)
        #expect(spy.showModalCalls[0].backgroundTapDismissesModal == false)
    }
}

// MARK: - Spy Router Dispatch Tests

@Suite("Router call dispatch")
@MainActor
struct RouterCallDispatchTests {

    @Test("showScreen records the segue option")
    func showScreenRecordsOption() {
        let spy = SpyRouter()
        spy.showScreen(.push) { _ in Text("Pushed") }
        spy.showScreen(.sheet) { _ in Text("Sheet") }
        spy.showScreen(.fullScreenCover) { _ in Text("FullScreen") }

        #expect(spy.showScreenCalls.count == 3)
        #expect(spy.showScreenCalls[0].option == .push)
        #expect(spy.showScreenCalls[1].option == .sheet)
        #expect(spy.showScreenCalls[2].option == .fullScreenCover)
    }

    @Test("dismissScreen increments call count")
    func dismissScreenTracksCount() {
        let spy = SpyRouter()
        spy.dismissScreen()
        spy.dismissScreen()

        #expect(spy.dismissScreenCallCount == 2)
    }

    @Test("dismissAlert increments call count")
    func dismissAlertTracksCount() {
        let spy = SpyRouter()
        spy.dismissAlert()

        #expect(spy.dismissAlertCallCount == 1)
    }

    @Test("dismissModal increments call count")
    func dismissModalTracksCount() {
        let spy = SpyRouter()
        spy.dismissModal()

        #expect(spy.dismissModalCallCount == 1)
    }

    @Test("Multiple alert calls are recorded independently")
    func multipleAlertCalls() {
        let spy = SpyRouter()
        spy.showAlert(.alert, title: "First")
        spy.showAlert(.confirmationDialog, title: "Second", subtitle: "Details")

        #expect(spy.showAlertCalls.count == 2)
        #expect(spy.showAlertCalls[0].option == .alert)
        #expect(spy.showAlertCalls[1].option == .confirmationDialog)
    }
}

// MARK: - MockRouter Tests

@Suite("MockRouter")
@MainActor
struct MockRouterTests {

    @Test("MockRouter is the default environment router")
    func defaultEnvironmentValue() {
        let env = EnvironmentValues()
        let router = env.router

        #expect(router is MockRouter)
    }

    @Test("All MockRouter methods are callable without crash")
    func allMethodsCallable() {
        let mock = MockRouter()

        mock.showScreen(.push) { _ in Text("Screen") }
        mock.dismissScreen()
        mock.showAlert(.alert, title: "Title", subtitle: nil, buttons: nil)
        mock.showErrorAlert(error: NSError(domain: "", code: 0))
        mock.dismissAlert()
        mock.showModal { Text("Modal") }
        mock.dismissModal()
    }
}
