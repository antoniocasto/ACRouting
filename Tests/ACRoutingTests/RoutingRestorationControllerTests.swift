import SwiftUI
import Testing
@testable import ACRouting

private enum ControllerTestRoute: String, Codable, Hashable, Sendable {
    case detail
    case comments
    case settings
    case unsupported
}

private enum ControllerTestError: Error, Equatable {
    case saveFailed
    case clearFailed
}

private struct ControllerTestResolver: RoutedNavigationIntentResolving {
    func canResolve(_ payload: ControllerTestRoute) -> Bool {
        payload != .unsupported
    }

    func presentation(for payload: ControllerTestRoute) -> SegueOption {
        switch payload {
        case .detail, .comments, .unsupported:
            .push
        case .settings:
            .sheet
        }
    }

    func destination(for payload: ControllerTestRoute, router: any Router) -> some View {
        Text("Controller \(payload.rawValue)")
    }
}

private final class RecordingRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    var state: RoutingRestorationState<Payload>?
    private(set) var savedStates: [RoutingRestorationState<Payload>] = []
    private(set) var clearCallCount = 0

    init(state: RoutingRestorationState<Payload>? = nil) {
        self.state = state
    }

    func load() throws -> RoutingRestorationState<Payload>? {
        state
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        self.state = state
        savedStates.append(state)
    }

    func clear() throws {
        state = nil
        clearCallCount += 1
    }
}

private final class FailingRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    var state: RoutingRestorationState<Payload>?
    var saveError: ControllerTestError?
    var clearError: ControllerTestError?

    init(state: RoutingRestorationState<Payload>? = nil) {
        self.state = state
    }

    func load() throws -> RoutingRestorationState<Payload>? {
        state
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        if let saveError {
            throw saveError
        }

        self.state = state
    }

    func clear() throws {
        if let clearError {
            throw clearError
        }

        state = nil
    }
}

@MainActor
private final class ControllerSpyRouter: Router {
    private(set) var showScreenCalls: [SegueOption] = []

    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T) {
        showScreenCalls.append(option)
    }

    func dismissScreen() {}
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
    ) where T: View {}
    func dismissModal() {}
}

@Suite("RoutingRestorationController")
@MainActor
struct RoutingRestorationControllerTests {
    @Test("controller exports metadata and tracked push intents")
    func controllerExportsMetadataAndTrackedIntents() throws {
        let store = RecordingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.comments)

        try controller.recordPush(detailIntent)
        try controller.recordPush(commentsIntent)

        #expect(controller.trackedIntents == [detailIntent, commentsIntent])

        let state = controller.currentState()
        #expect(state.payloadSchemaVersion == 3)
        #expect(state.resolverPolicyVersion == 7)
        #expect(state.contextID == "main")
        #expect(state.entries.map(\.intent) == [detailIntent, commentsIntent])
        #expect(store.savedStates.map { $0.entries.map(\.intent) } == [[detailIntent], [detailIntent, commentsIntent]])
    }

    @Test("controller records pop, pop count, dismiss, and pop to root")
    func controllerRecordsStackMutations() throws {
        let store = RecordingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.comments)
        let settingsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.settings)

        try controller.recordPush(detailIntent)
        try controller.recordPush(commentsIntent)
        try controller.recordPush(settingsIntent)
        try controller.recordPop()
        #expect(controller.trackedIntents == [detailIntent, commentsIntent])

        try controller.recordDismissScreen()
        #expect(controller.trackedIntents == [detailIntent])

        try controller.recordPop(count: 5)
        #expect(controller.trackedIntents.isEmpty)

        try controller.recordPush(detailIntent)
        try controller.recordPop(count: 0)
        #expect(controller.trackedIntents == [detailIntent])

        try controller.recordPopToRoot()
        #expect(controller.trackedIntents.isEmpty)
        #expect(store.savedStates.last?.entries.isEmpty == true)
    }

    @Test("clear removes tracked and persisted state")
    func clearRemovesTrackedAndPersistedState() throws {
        let store = RecordingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)

        try controller.recordPush(RoutedNavigationIntent(payload: .detail))
        try controller.clear()

        #expect(controller.trackedIntents.isEmpty)
        #expect(store.state == nil)
        #expect(store.clearCallCount == 1)
    }

    @Test("recordPush rolls back tracked intents when persistence fails")
    func recordPushRollsBackTrackedIntentsWhenPersistenceFails() throws {
        let store = FailingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let intent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        store.saveError = .saveFailed

        do {
            try controller.recordPush(intent)
            Issue.record("Expected save failure to be propagated")
        } catch let error as ControllerTestError {
            #expect(error == .saveFailed)
        }

        #expect(controller.trackedIntents.isEmpty)
        #expect(store.state == nil)
    }

    @Test("recordPop rolls back tracked intents when persistence fails")
    func recordPopRollsBackTrackedIntentsWhenPersistenceFails() throws {
        let store = FailingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.comments)

        try controller.recordPush(detailIntent)
        try controller.recordPush(commentsIntent)
        store.saveError = .saveFailed

        do {
            try controller.recordPop()
            Issue.record("Expected save failure to be propagated")
        } catch let error as ControllerTestError {
            #expect(error == .saveFailed)
        }

        #expect(controller.trackedIntents == [detailIntent, commentsIntent])
        #expect(store.state?.entries.map(\.intent) == [detailIntent, commentsIntent])
    }

    @Test("recordPopToRoot rolls back tracked intents when persistence fails")
    func recordPopToRootRollsBackTrackedIntentsWhenPersistenceFails() throws {
        let store = FailingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.comments)

        try controller.recordPush(detailIntent)
        try controller.recordPush(commentsIntent)
        store.saveError = .saveFailed

        do {
            try controller.recordPopToRoot()
            Issue.record("Expected save failure to be propagated")
        } catch let error as ControllerTestError {
            #expect(error == .saveFailed)
        }

        #expect(controller.trackedIntents == [detailIntent, commentsIntent])
        #expect(store.state?.entries.map(\.intent) == [detailIntent, commentsIntent])
    }

    @Test("restoreLoadedState rolls back tracked intents when persistence fails")
    func restoreLoadedStateRollsBackTrackedIntentsWhenPersistenceFails() throws {
        let store = FailingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let router = ControllerSpyRouter()
        let previousIntent = RoutedNavigationIntent(payload: ControllerTestRoute.settings)
        let restoredIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)

        try controller.recordPush(previousIntent)
        store.state = makeState(intents: [restoredIntent])
        store.saveError = .saveFailed

        do {
            _ = try controller.restoreLoadedState(on: router, using: ControllerTestResolver())
            Issue.record("Expected save failure to be propagated")
        } catch let error as ControllerTestError {
            #expect(error == .saveFailed)
        }

        #expect(router.showScreenCalls == [.push])
        #expect(controller.trackedIntents == [previousIntent])
        #expect(store.state?.entries.map(\.intent) == [restoredIntent])
    }

    @Test("clear rolls back tracked intents when store clearing fails")
    func clearRollsBackTrackedIntentsWhenStoreClearingFails() throws {
        let store = FailingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let intent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)

        try controller.recordPush(intent)
        store.clearError = .clearFailed

        do {
            try controller.clear()
            Issue.record("Expected clear failure to be propagated")
        } catch let error as ControllerTestError {
            #expect(error == .clearFailed)
        }

        #expect(controller.trackedIntents == [intent])
        #expect(store.state?.entries.map(\.intent) == [intent])
    }

    @Test("restoreLoadedState loads state, replays router pushes, and synchronizes restored intents")
    func restoreLoadedStateSynchronizesRestoredIntents() throws {
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let commentsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.comments)
        let storedState = makeState(intents: [detailIntent, commentsIntent])
        let store = RecordingRoutingRestorationStore(state: storedState)
        let controller = makeController(store: store)
        let router = ControllerSpyRouter()

        let result = try controller.restoreLoadedState(on: router, using: ControllerTestResolver())

        #expect(result == .restored([.presented(detailIntent), .presented(commentsIntent)]))
        #expect(router.showScreenCalls == [.push, .push])
        #expect(controller.trackedIntents == [detailIntent, commentsIntent])
        #expect(store.savedStates.last?.entries.map(\.intent) == [detailIntent, commentsIntent])
    }

    @Test("restoreLoadedState returns nil when no stored state exists")
    func restoreLoadedStateReturnsNilWhenEmpty() throws {
        let store = RecordingRoutingRestorationStore<ControllerTestRoute>()
        let controller = makeController(store: store)
        let router = ControllerSpyRouter()

        let result = try controller.restoreLoadedState(on: router, using: ControllerTestResolver())

        #expect(result == nil)
        #expect(router.showScreenCalls.isEmpty)
        #expect(controller.trackedIntents.isEmpty)
        #expect(store.savedStates.isEmpty)
    }

    @Test("unsupported entries synchronize the controller to entries actually restored")
    func restoreLoadedStateSynchronizesAfterUnsupportedPayload() throws {
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let unsupportedIntent = RoutedNavigationIntent(payload: ControllerTestRoute.unsupported)
        let commentsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.comments)
        let store = RecordingRoutingRestorationStore(state: makeState(intents: [
            detailIntent,
            unsupportedIntent,
            commentsIntent
        ]))
        let controller = makeController(store: store)
        let router = ControllerSpyRouter()

        let result = try controller.restoreLoadedState(on: router, using: ControllerTestResolver())

        #expect(result == .unsupported(unsupportedIntent, restored: [.presented(detailIntent)]))
        #expect(router.showScreenCalls == [.push])
        #expect(controller.trackedIntents == [detailIntent])
        #expect(store.savedStates.last?.entries.map(\.intent) == [detailIntent])
    }

    @Test("non-push entries synchronize the controller to entries actually restored")
    func restoreLoadedStateSynchronizesAfterNonPushPayload() throws {
        let detailIntent = RoutedNavigationIntent(payload: ControllerTestRoute.detail)
        let settingsIntent = RoutedNavigationIntent(payload: ControllerTestRoute.settings)
        let store = RecordingRoutingRestorationStore(state: makeState(intents: [
            detailIntent,
            settingsIntent
        ]))
        let controller = makeController(store: store)
        let router = ControllerSpyRouter()

        let result = try controller.restoreLoadedState(on: router, using: ControllerTestResolver())

        #expect(result == .unsupportedPresentation(
            settingsIntent,
            presentation: .sheet,
            restored: [.presented(detailIntent)]
        ))
        #expect(router.showScreenCalls == [.push])
        #expect(controller.trackedIntents == [detailIntent])
        #expect(store.savedStates.last?.entries.map(\.intent) == [detailIntent])
    }

    private func makeController(
        store: RecordingRoutingRestorationStore<ControllerTestRoute>
    ) -> RoutingRestorationController<ControllerTestRoute> {
        RoutingRestorationController(
            payloadSchemaVersion: 3,
            resolverPolicyVersion: 7,
            contextID: "main",
            store: store
        )
    }

    private func makeController(
        store: FailingRoutingRestorationStore<ControllerTestRoute>
    ) -> RoutingRestorationController<ControllerTestRoute> {
        RoutingRestorationController(
            payloadSchemaVersion: 3,
            resolverPolicyVersion: 7,
            contextID: "main",
            store: store
        )
    }

    private func makeState(
        intents: [RoutedNavigationIntent<ControllerTestRoute>]
    ) -> RoutingRestorationState<ControllerTestRoute> {
        RoutingRestorationState(
            payloadSchemaVersion: 3,
            resolverPolicyVersion: 7,
            contextID: "main",
            entries: intents.map(RoutingRestorationEntry.init(intent:))
        )
    }
}
