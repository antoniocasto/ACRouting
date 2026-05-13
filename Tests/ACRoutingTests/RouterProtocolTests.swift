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
    private(set) var dismissAncestorModalCallCount = 0
    private(set) var popCallCount = 0
    private(set) var popCountCalls: [Int] = []
    private(set) var popToRootCallCount = 0
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

    func dismissAncestorModal() {
        dismissAncestorModalCallCount += 1
    }

    func pop() {
        popCallCount += 1
        popCountCalls.append(1)
    }

    func pop(count: Int) {
        popCountCalls.append(count)
    }

    func popToRoot() {
        popToRootCallCount += 1
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

/// A minimal router used to verify protocol extension forwarding behavior.
///
/// This type intentionally omits a custom `pop()` implementation so tests can
/// exercise the default `Router.pop()` implementation from the protocol extension.
@MainActor
private final class DefaultPopForwardingRouter: Router {
    private(set) var popCountCalls: [Int] = []

    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T) {}
    func dismissScreen() {}
    func pop(count: Int) { popCountCalls.append(count) }
    func popToRoot() {}
    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?) {}
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)?) {}
    func dismissAlert() {}
    func showModal<T>(
        backgroundColor: Color,
        backgroundTransition: AnyTransition,
        animation: Animation,
        backgroundTapDismissesModal: Bool,
        screen: @escaping () -> T
    ) where T : View {}
    func dismissModal() {}
}

@MainActor
private protocol BuilderDrivenFeatureRouting {
    func showPushedDetail(id: Int)
    func showSheet()
    func showFullScreen()
    func showOverlay()
}

@MainActor
private final class BuilderDrivenFeatureBuilder {
    private(set) var builtScreens: [String] = []
    private(set) var receivedRouters: [any BuilderDrivenFeatureRouting] = []

    func makeDetail(id: Int, router: any BuilderDrivenFeatureRouting) -> some View {
        receivedRouters.append(router)
        builtScreens.append("detail:\(id)")
        return Text("Detail \(id)")
    }

    func makeSheet(router: any BuilderDrivenFeatureRouting) -> some View {
        receivedRouters.append(router)
        builtScreens.append("sheet")
        return Text("Sheet")
    }

    func makeFullScreen(router: any BuilderDrivenFeatureRouting) -> some View {
        receivedRouters.append(router)
        builtScreens.append("fullScreen")
        return Text("Full screen")
    }

    func makeOverlay() -> some View {
        builtScreens.append("overlay")
        return Text("Overlay")
    }
}

@MainActor
private final class DestinationCapturingRouter: Router {
    struct CapturedScreenCall {
        let option: SegueOption
        let destination: (any Router) -> AnyView
    }

    private(set) var screenCalls: [CapturedScreenCall] = []
    private(set) var overlayBuilders: [() -> AnyView] = []

    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T) {
        screenCalls.append(
            CapturedScreenCall(
                option: option,
                destination: { AnyView(destination($0)) }
            )
        )
    }

    func dismissScreen() {}

    func pop() {}

    func pop(count: Int) {}

    func popToRoot() {}

    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?) {}

    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)?) {}

    func dismissAlert() {}

    func showModal<T>(
        backgroundColor: Color,
        backgroundTransition: AnyTransition,
        animation: Animation,
        backgroundTapDismissesModal: Bool,
        screen: @escaping () -> T
    ) where T: View {
        overlayBuilders.append { AnyView(screen()) }
    }

    func dismissModal() {}
}

private struct BuilderDrivenFeatureRouterAdapter: BuilderDrivenFeatureRouting {
    let router: any Router
    let builder: BuilderDrivenFeatureBuilder

    func showPushedDetail(id: Int) {
        router.showScreen(.push) { router in
            let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)
            builder.makeDetail(id: id, router: featureRouter)
        }
    }

    func showSheet() {
        router.showScreen(.sheet) { router in
            let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)
            builder.makeSheet(router: featureRouter)
        }
    }

    func showFullScreen() {
        router.showScreen(.fullScreenCover) { router in
            let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)
            builder.makeFullScreen(router: featureRouter)
        }
    }

    func showOverlay() {
        router.showModal {
            builder.makeOverlay()
        }
    }
}

private enum DeepLinkTestRoute: String, Codable, Hashable, Sendable {
    case detail
    case settings
    case unsupported
}

private struct DeepLinkTestResolver: RoutedNavigationIntentResolving {
    private(set) var supportedRoutes: Set<DeepLinkTestRoute> = [.detail]

    func canResolve(_ payload: DeepLinkTestRoute) -> Bool {
        supportedRoutes.contains(payload) || payload == .settings
    }

    func presentation(for payload: DeepLinkTestRoute) -> SegueOption {
        switch payload {
        case .detail:
            .fullScreenCover
        case .settings:
            .sheet
        case .unsupported:
            .sheet
        }
    }

    func destination(for payload: DeepLinkTestRoute, router: any Router) -> some View {
        Text("Resolved \(payload.rawValue)")
    }
}

private enum RestorationTestRoute: String, Codable, Hashable, Sendable {
    case detail
    case comments
    case settings
    case unsupported
}

private struct RestorationTestResolver: RoutedNavigationIntentResolving {
    func canResolve(_ payload: RestorationTestRoute) -> Bool {
        payload != .unsupported
    }

    func presentation(for payload: RestorationTestRoute) -> SegueOption {
        switch payload {
        case .detail, .comments, .unsupported:
            .push
        case .settings:
            .sheet
        }
    }

    func destination(for payload: RestorationTestRoute, router: any Router) -> some View {
        Text("Restored \(payload.rawValue)")
    }
}

private final class RouterRestorationRecordingStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    var state: RoutingRestorationState<Payload>?
    private(set) var savedStates: [RoutingRestorationState<Payload>] = []

    func load() throws -> RoutingRestorationState<Payload>? {
        state
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        self.state = state
        savedStates.append(state)
    }

    func clear() throws {
        state = nil
    }
}

private enum RouterRestorationTestError: Error, Equatable {
    case saveFailed
}

private struct ThrowingSaveRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    func load() throws -> RoutingRestorationState<Payload>? {
        nil
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        throw RouterRestorationTestError.saveFailed
    }

    func clear() throws {}
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

    @Test("showAlert action-builder overload erases actions and forwards")
    func showAlertActionBuilderOverloadForwards() {
        let spy = SpyRouter()

        spy.showAlert(.alert, title: "Delete", subtitle: "Cannot be undone") {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        }

        #expect(spy.showAlertCalls.count == 1)
        #expect(spy.showAlertCalls[0].option == .alert)
        #expect(spy.showAlertCalls[0].title == "Delete")
        #expect(spy.showAlertCalls[0].subtitle == "Cannot be undone")
        #expect(spy.showAlertCalls[0].hasButtons == true)
    }

    @Test("showAlert action-builder overload works through existential router")
    func showAlertActionBuilderOverloadWorksThroughExistentialRouter() {
        let spy = SpyRouter()
        let router: any Router = spy

        router.showAlert(.alert, title: "Saved") {
            Button("OK", role: .cancel) {}
        }

        #expect(spy.showAlertCalls.count == 1)
        #expect(spy.showAlertCalls[0].title == "Saved")
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

    @Test("showErrorAlert action-builder overload erases actions and forwards")
    func showErrorAlertActionBuilderOverloadForwards() {
        let spy = SpyRouter()
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Oops"])

        spy.showErrorAlert(error: error) {
            Button("OK", role: .cancel) {}
        }

        #expect(spy.showErrorAlertCalls.count == 1)
        #expect(spy.showErrorAlertCalls[0].errorDescription == "Oops")
        #expect(spy.showErrorAlertCalls[0].hasButtons == true)
    }

    @Test("showErrorAlert action-builder overload works through existential router")
    func showErrorAlertActionBuilderOverloadWorksThroughExistentialRouter() {
        let spy = SpyRouter()
        let router: any Router = spy
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Oops"])

        router.showErrorAlert(error: error) {
            Button("OK", role: .cancel) {}
        }

        #expect(spy.showErrorAlertCalls.count == 1)
        #expect(spy.showErrorAlertCalls[0].errorDescription == "Oops")
        #expect(spy.showErrorAlertCalls[0].hasButtons == true)
    }

    @Test("showConfirmationDialog forwards as confirmation dialog")
    func showConfirmationDialogForwardsAsConfirmationDialog() {
        let spy = SpyRouter()

        spy.showConfirmationDialog(title: "Archive", message: "Restore later") {
            Button("Archive") {}
            Button("Cancel", role: .cancel) {}
        }

        #expect(spy.showAlertCalls.count == 1)
        #expect(spy.showAlertCalls[0].option == .confirmationDialog)
        #expect(spy.showAlertCalls[0].title == "Archive")
        #expect(spy.showAlertCalls[0].subtitle == "Restore later")
        #expect(spy.showAlertCalls[0].hasButtons == true)
    }

    @Test("showConfirmationDialog works through existential router")
    func showConfirmationDialogWorksThroughExistentialRouter() {
        let spy = SpyRouter()
        let router: any Router = spy

        router.showConfirmationDialog(title: "Archive", message: "Restore later") {
            Button("Archive") {}
            Button("Cancel", role: .cancel) {}
        }

        #expect(spy.showAlertCalls.count == 1)
        #expect(spy.showAlertCalls[0].option == .confirmationDialog)
        #expect(spy.showAlertCalls[0].subtitle == "Restore later")
        #expect(spy.showAlertCalls[0].hasButtons == true)
    }

    @Test("showModal can be called with screen only (all defaults)")
    func showModalMinimalParams() {
        let spy = SpyRouter()
        spy.showModal { Text("Modal") }

        #expect(spy.showModalCalls.count == 1)
        #expect(spy.showModalCalls[0].backgroundColor == Color.black.opacity(0.6))
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

    @Test("showModal view-builder overload forwards defaults")
    func showModalViewBuilderOverloadForwardsDefaults() {
        let spy = SpyRouter()

        spy.showModal {
            Text("Title")
            Button("Continue") {}
        }

        #expect(spy.showModalCalls.count == 1)
        #expect(spy.showModalCalls[0].backgroundColor == Color.black.opacity(0.6))
        #expect(spy.showModalCalls[0].backgroundTapDismissesModal == true)
    }

    @Test("showModal view-builder overload works through existential router")
    func showModalViewBuilderOverloadWorksThroughExistentialRouter() {
        let spy = SpyRouter()
        let router: any Router = spy

        router.showModal {
            Text("Title")
            Button("Continue") {}
        }

        #expect(spy.showModalCalls.count == 1)
        #expect(spy.showModalCalls[0].backgroundColor == Color.black.opacity(0.6))
        #expect(spy.showModalCalls[0].backgroundTapDismissesModal == true)
    }

    @Test("showModal view-builder overload forwards custom configuration")
    func showModalViewBuilderOverloadForwardsCustomConfiguration() {
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

    @Test("showModal does not eagerly evaluate the overlay builder")
    func showModalDoesNotEagerlyEvaluateScreenBuilder() {
        let spy = SpyRouter()
        var builderEvaluationCount = 0

        spy.showModal {
            builderEvaluationCount += 1
            return Text("Modal")
        }

        #expect(spy.showModalCalls.count == 1)
        #expect(builderEvaluationCount == 0)
    }

    @Test("pop() default implementation forwards to pop(count: 1)")
    func popDefaultImplementationForwardsToSingleCount() {
        let router = DefaultPopForwardingRouter()

        router.pop()

        #expect(router.popCountCalls == [1])
    }

    @Test("dismissAncestorModal has a default no-op implementation for custom conformers")
    func dismissAncestorModalDefaultImplementationIsCallable() {
        let router = DefaultPopForwardingRouter()

        router.dismissAncestorModal()

        #expect(router.popCountCalls.isEmpty)
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

    @Test("dismissAncestorModal increments call count")
    func dismissAncestorModalTracksCount() {
        let spy = SpyRouter()
        spy.dismissAncestorModal()

        #expect(spy.dismissAncestorModalCallCount == 1)
    }

    @Test("pop uses the default single-step stack mutation")
    func popTracksDefaultCount() {
        let spy = SpyRouter()
        spy.pop()

        #expect(spy.popCallCount == 1)
        #expect(spy.popCountCalls == [1])
    }

    @Test("pop(count:) records the requested number of screens")
    func popCountTracksRequestedCount() {
        let spy = SpyRouter()
        spy.pop(count: 2)

        #expect(spy.popCountCalls == [2])
    }

    @Test("popToRoot increments call count")
    func popToRootTracksCount() {
        let spy = SpyRouter()
        spy.popToRoot()

        #expect(spy.popToRootCallCount == 1)
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

@Suite("Builder-first router adapters")
@MainActor
struct BuilderFirstRouterAdapterTests {

    @Test("Push adapter keeps builder-owned assembly deferred until destination rendering")
    func pushAssemblyIsDeferred() {
        let router = DestinationCapturingRouter()
        let builder = BuilderDrivenFeatureBuilder()
        let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)

        featureRouter.showPushedDetail(id: 42)

        #expect(router.screenCalls.count == 1)
        #expect(router.screenCalls[0].option == .push)
        #expect(builder.builtScreens.isEmpty)

        let _: AnyView = router.screenCalls[0].destination(MockRouter())

        #expect(builder.builtScreens == ["detail:42"])
    }

    @Test("Sheet adapter keeps builder-owned assembly deferred until destination rendering")
    func sheetAssemblyIsDeferred() {
        let router = DestinationCapturingRouter()
        let builder = BuilderDrivenFeatureBuilder()
        let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)

        featureRouter.showSheet()

        #expect(router.screenCalls.count == 1)
        #expect(router.screenCalls[0].option == .sheet)
        #expect(builder.builtScreens.isEmpty)

        let _: AnyView = router.screenCalls[0].destination(MockRouter())

        #expect(builder.builtScreens == ["sheet"])
    }

    @Test("Full-screen adapter keeps builder-owned assembly deferred until destination rendering")
    func fullScreenAssemblyIsDeferred() {
        let router = DestinationCapturingRouter()
        let builder = BuilderDrivenFeatureBuilder()
        let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)

        featureRouter.showFullScreen()

        #expect(router.screenCalls.count == 1)
        #expect(router.screenCalls[0].option == .fullScreenCover)
        #expect(builder.builtScreens.isEmpty)

        let _: AnyView = router.screenCalls[0].destination(MockRouter())

        #expect(builder.builtScreens == ["fullScreen"])
    }

    @Test("Overlay adapter keeps builder-owned assembly deferred until overlay rendering")
    func overlayAssemblyIsDeferred() {
        let router = DestinationCapturingRouter()
        let builder = BuilderDrivenFeatureBuilder()
        let featureRouter = BuilderDrivenFeatureRouterAdapter(router: router, builder: builder)

        featureRouter.showOverlay()

        #expect(router.overlayBuilders.count == 1)
        #expect(builder.builtScreens.isEmpty)

        let _: AnyView = router.overlayBuilders[0]()

        #expect(builder.builtScreens == ["overlay"])
    }

    @Test("Destination adapter forwards follow-up navigation through the routed context")
    func destinationAdapterUsesRoutedContextRouter() throws {
        let rootRouter = DestinationCapturingRouter()
        let destinationRouter = DestinationCapturingRouter()
        let builder = BuilderDrivenFeatureBuilder()
        let featureRouter = BuilderDrivenFeatureRouterAdapter(router: rootRouter, builder: builder)

        featureRouter.showPushedDetail(id: 7)

        let pushedDestination = try #require(rootRouter.screenCalls.first)
        let _: AnyView = pushedDestination.destination(destinationRouter)
        let pushedFeatureRouter = try #require(builder.receivedRouters.last)

        pushedFeatureRouter.showSheet()

        #expect(rootRouter.screenCalls.count == 1)
        #expect(destinationRouter.screenCalls.count == 1)
        #expect(destinationRouter.screenCalls[0].option == .sheet)
    }

    @Test("Supported routed intent uses resolver presentation")
    func supportedRoutedIntentUsesResolverPresentation() throws {
        let router = DestinationCapturingRouter()
        let resolver = DeepLinkTestResolver()
        let intent = RoutedNavigationIntent(payload: DeepLinkTestRoute.detail)

        let result = router.showScreen(intent, using: resolver)

        #expect(result == .presented(intent))
        #expect(router.screenCalls.count == 1)
        #expect(router.screenCalls[0].option == .fullScreenCover)

        let _: AnyView = router.screenCalls[0].destination(MockRouter())
    }

    @Test("Supported routed intent can use sheet presentation")
    func supportedRoutedIntentCanUseSheetPresentation() {
        let router = DestinationCapturingRouter()
        let resolver = DeepLinkTestResolver()
        let intent = RoutedNavigationIntent(payload: DeepLinkTestRoute.settings)

        let result = router.showScreen(intent, using: resolver)

        #expect(result == .presented(intent))
        #expect(router.screenCalls.count == 1)
        #expect(router.screenCalls[0].option == .sheet)
    }

    @Test("Unsupported routed intent does not present")
    func unsupportedRoutedIntentDoesNotPresent() {
        let router = DestinationCapturingRouter()
        let resolver = DeepLinkTestResolver()
        let intent = RoutedNavigationIntent(payload: DeepLinkTestRoute.unsupported)

        let result = router.showScreen(intent, using: resolver)

        #expect(result == .unsupported(intent))
        #expect(router.screenCalls.isEmpty)
    }

    @Test("restore replays push entries in order")
    func restoreReplaysPushEntriesInOrder() {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let detailIntent = RoutedNavigationIntent(payload: RestorationTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: RestorationTestRoute.comments)
        let state = RoutingRestorationState(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            entries: [
                RoutingRestorationEntry(intent: detailIntent),
                RoutingRestorationEntry(intent: commentsIntent)
            ]
        )

        let result = router.restore(state, using: resolver)

        #expect(result == .restored([
            .presented(detailIntent),
            .presented(commentsIntent)
        ]))
        #expect(router.screenCalls.map(\.option) == [.push, .push])
    }

    @Test("restore stops when an entry is unsupported")
    func restoreStopsWhenEntryIsUnsupported() {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let detailIntent = RoutedNavigationIntent(payload: RestorationTestRoute.detail)
        let unsupportedIntent = RoutedNavigationIntent(payload: RestorationTestRoute.unsupported)
        let commentsIntent = RoutedNavigationIntent(payload: RestorationTestRoute.comments)
        let state = RoutingRestorationState(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            entries: [
                RoutingRestorationEntry(intent: detailIntent),
                RoutingRestorationEntry(intent: unsupportedIntent),
                RoutingRestorationEntry(intent: commentsIntent)
            ]
        )

        let result = router.restore(state, using: resolver)

        #expect(result == .unsupported(
            unsupportedIntent,
            restored: [.presented(detailIntent)]
        ))
        #expect(router.screenCalls.map(\.option) == [.push])
    }

    @Test("restore rejects non-push presentation in v1.6.0")
    func restoreRejectsNonPushPresentation() {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let detailIntent = RoutedNavigationIntent(payload: RestorationTestRoute.detail)
        let settingsIntent = RoutedNavigationIntent(payload: RestorationTestRoute.settings)
        let state = RoutingRestorationState(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            entries: [
                RoutingRestorationEntry(intent: detailIntent),
                RoutingRestorationEntry(intent: settingsIntent)
            ]
        )

        let result = router.restore(state, using: resolver)

        #expect(result == .unsupportedPresentation(
            settingsIntent,
            presentation: .sheet,
            restored: [.presented(detailIntent)]
        ))
        #expect(router.screenCalls.map(\.option) == [.push])
    }

    @Test("showScreen tracks and saves supported push intents")
    func showScreenTracksSupportedPushIntents() throws {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let store = RouterRestorationRecordingStore<RestorationTestRoute>()
        let restoration = makeRestorationController(store: store)
        let intent = RoutedNavigationIntent(payload: RestorationTestRoute.detail)

        let result = try router.showScreen(
            intent,
            using: resolver,
            restoration: restoration
        )

        #expect(result == .presented(intent))
        #expect(router.screenCalls.map(\.option) == [.push])
        #expect(restoration.trackedIntents == [intent])
        #expect(store.savedStates.last?.entries.map(\.intent) == [intent])
    }

    @Test("showScreen does not track unsupported payloads")
    func showScreenDoesNotTrackUnsupportedPayloads() throws {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let store = RouterRestorationRecordingStore<RestorationTestRoute>()
        let restoration = makeRestorationController(store: store)
        let intent = RoutedNavigationIntent(payload: RestorationTestRoute.unsupported)

        let result = try router.showScreen(
            intent,
            using: resolver,
            restoration: restoration
        )

        #expect(result == .unsupported(intent))
        #expect(router.screenCalls.isEmpty)
        #expect(restoration.trackedIntents.isEmpty)
        #expect(store.savedStates.isEmpty)
    }

    @Test("showScreen presents but does not track sheets")
    func showScreenDoesNotTrackNonPushPresentations() throws {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let store = RouterRestorationRecordingStore<RestorationTestRoute>()
        let restoration = makeRestorationController(store: store)
        let intent = RoutedNavigationIntent(payload: RestorationTestRoute.settings)

        let result = try router.showScreen(
            intent,
            using: resolver,
            restoration: restoration
        )

        #expect(result == .presented(intent))
        #expect(router.screenCalls.map(\.option) == [.sheet])
        #expect(restoration.trackedIntents.isEmpty)
        #expect(store.savedStates.isEmpty)
    }

    @Test("restorable pop helpers mutate router and controller together")
    func restorablePopHelpersMutateRouterAndControllerTogether() throws {
        let router = SpyRouter()
        let store = RouterRestorationRecordingStore<RestorationTestRoute>()
        let restoration = makeRestorationController(store: store)
        let detailIntent = RoutedNavigationIntent(payload: RestorationTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: RestorationTestRoute.comments)
        let settingsIntent = RoutedNavigationIntent(payload: RestorationTestRoute.settings)

        try restoration.recordPush(detailIntent)
        try restoration.recordPush(commentsIntent)
        try restoration.recordPush(settingsIntent)

        try router.pop(restoration: restoration)
        #expect(router.popCallCount == 1)
        #expect(restoration.trackedIntents == [detailIntent, commentsIntent])

        try router.dismissScreen(restoration: restoration)
        #expect(router.dismissScreenCallCount == 1)
        #expect(restoration.trackedIntents == [detailIntent])

        try restoration.recordPush(commentsIntent)
        try router.pop(count: 2, restoration: restoration)
        #expect(router.popCountCalls.contains(2))
        #expect(restoration.trackedIntents.isEmpty)

        try restoration.recordPush(detailIntent)
        try router.popToRoot(restoration: restoration)
        #expect(router.popToRootCallCount == 1)
        #expect(restoration.trackedIntents.isEmpty)
    }

    @Test("showScreen propagates storage save failures")
    func showScreenPropagatesStorageFailures() throws {
        let router = DestinationCapturingRouter()
        let resolver = RestorationTestResolver()
        let restoration = RoutingRestorationController(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            store: ThrowingSaveRoutingRestorationStore<RestorationTestRoute>()
        )
        let intent = RoutedNavigationIntent(payload: RestorationTestRoute.detail)

        do {
            _ = try router.showScreen(
                intent,
                using: resolver,
                restoration: restoration
            )
            Issue.record("Expected storage failure to be propagated")
        } catch let error as RouterRestorationTestError {
            #expect(error == .saveFailed)
        }

        #expect(router.screenCalls.map(\.option) == [.push])
    }

    private func makeRestorationController(
        store: RouterRestorationRecordingStore<RestorationTestRoute>
    ) -> RoutingRestorationController<RestorationTestRoute> {
        RoutingRestorationController(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            contextID: "main",
            store: store
        )
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
        mock.dismissAncestorModal()
        mock.pop()
        mock.pop(count: 2)
        mock.popToRoot()
        mock.showAlert(.alert, title: "Title", subtitle: nil, buttons: nil)
        mock.showErrorAlert(error: NSError(domain: "", code: 0))
        mock.dismissAlert()
        mock.showModal { Text("Modal") }
        mock.dismissModal()
    }

    @Test("Missing-router diagnostics explain how to inject a real router")
    func missingRouterDiagnosticIsActionable() {
        let message = RouterDiagnostics.missingRouterMessage(action: "dismissScreen()")

        #expect(message.contains("dismissScreen()"))
        #expect(message.contains("@Environment(\\.router)"))
        #expect(message.contains("RouterView"))
        #expect(message.contains("real Router"))
    }

    @Test("Unsupported ancestor modal diagnostic names the conformer")
    func unsupportedAncestorModalDiagnosticNamesConformer() {
        let message = RouterDiagnostics.unsupportedAncestorModalDismissalMessage(conformer: "ExampleRouter")

        #expect(message.contains("dismissAncestorModal()"))
        #expect(message.contains("ExampleRouter"))
        #expect(message.contains("custom implementation"))
    }
}
