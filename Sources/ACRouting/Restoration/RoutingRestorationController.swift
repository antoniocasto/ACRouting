import Foundation

private struct AnyRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    private let loadHandler: () throws -> RoutingRestorationState<Payload>?
    private let saveHandler: (RoutingRestorationState<Payload>) throws -> Void
    private let clearHandler: () throws -> Void

    init<Store>(_ store: Store) where Store: RoutingRestorationStore, Store.Payload == Payload {
        loadHandler = store.load
        saveHandler = store.save
        clearHandler = store.clear
    }

    func load() throws -> RoutingRestorationState<Payload>? {
        try loadHandler()
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        try saveHandler(state)
    }

    func clear() throws {
        try clearHandler()
    }
}

/// Tracks and persists the restorable push intent stack for one routed context.
///
/// The controller intentionally records only navigation performed through
/// restorable intent APIs or explicit record methods. It does not inspect or
/// serialize `RouterView`, `AnyDestination`, SwiftUI views, or routed modal state.
@MainActor
public final class RoutingRestorationController<Payload>
where Payload: Codable & Hashable & Sendable {
    private let payloadSchemaVersion: Int
    private let resolverPolicyVersion: Int
    private let contextID: String?
    private let store: AnyRoutingRestorationStore<Payload>
    private var intents: [RoutedNavigationIntent<Payload>] = []

    /// The currently tracked restorable push intents.
    public var trackedIntents: [RoutedNavigationIntent<Payload>] {
        intents
    }

    /// Creates a restoration controller backed by any compatible store.
    ///
    /// - Parameters:
    ///   - payloadSchemaVersion: The app-owned payload schema version to persist.
    ///   - resolverPolicyVersion: The app-owned resolver policy version to persist.
    ///   - contextID: Optional app-owned identifier for this routed root.
    ///   - store: The persistence adapter used for complete restoration states.
    public init<Store>(
        payloadSchemaVersion: Int,
        resolverPolicyVersion: Int,
        contextID: String? = nil,
        store: Store
    ) where Store: RoutingRestorationStore, Store.Payload == Payload {
        self.payloadSchemaVersion = payloadSchemaVersion
        self.resolverPolicyVersion = resolverPolicyVersion
        self.contextID = contextID
        self.store = AnyRoutingRestorationStore(store)
    }

    /// Builds the current restoration state from tracked intents.
    public func currentState() -> RoutingRestorationState<Payload> {
        RoutingRestorationState(
            payloadSchemaVersion: payloadSchemaVersion,
            resolverPolicyVersion: resolverPolicyVersion,
            contextID: contextID,
            entries: intents.map(RoutingRestorationEntry.init(intent:))
        )
    }

    /// Persists the current tracked state.
    public func save() throws {
        try store.save(currentState())
    }

    /// Loads a restoration state from the backing store without replaying it.
    public func loadState() throws -> RoutingRestorationState<Payload>? {
        try store.load()
    }

    /// Loads, replays, and synchronizes the tracked stack to entries actually restored.
    ///
    /// Returns `nil` when no stored restoration state exists.
    @discardableResult
    public func restoreLoadedState<Resolver>(
        on router: any Router,
        using resolver: Resolver
    ) throws -> RoutingRestorationResult<Payload>?
    where Resolver: RoutedNavigationIntentResolving, Resolver.Payload == Payload {
        guard let state = try store.load() else {
            return nil
        }

        let result = router.restore(state, using: resolver)
        intents = result.restoredResolutions.map(\.intent)
        try save()
        return result
    }

    /// Records a successfully presented push intent and persists the updated state.
    public func recordPresentedPush(_ intent: RoutedNavigationIntent<Payload>) throws {
        intents.append(intent)
        try save()
    }

    /// Records removal of one pushed restorable screen.
    public func recordPop() throws {
        try recordPop(count: 1)
    }

    /// Records removal of the requested number of pushed restorable screens.
    public func recordPop(count: Int) throws {
        guard count > 0 else {
            return
        }

        let removalCount = min(count, intents.count)
        guard removalCount > 0 else {
            return
        }

        intents.removeLast(removalCount)
        try save()
    }

    /// Records dismissal of the current pushed restorable screen.
    public func recordDismissScreen() throws {
        try recordPop()
    }

    /// Records returning the current routed context to its root.
    public func recordPopToRoot() throws {
        guard !intents.isEmpty else {
            return
        }

        intents.removeAll()
        try save()
    }

    /// Clears both tracked and persisted restoration state.
    public func clear() throws {
        intents.removeAll()
        try store.clear()
    }
}
