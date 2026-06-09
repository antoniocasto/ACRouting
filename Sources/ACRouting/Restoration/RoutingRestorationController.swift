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
/// If persistence fails after a tracked-stack mutation, the controller restores
/// its previous in-memory stack before rethrowing the storage error.
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
    /// If the follow-up save fails, the tracked stack rolls back to its previous
    /// value while already scheduled router navigation remains visible.
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
        try persistTrackedIntentMutation {
            intents = result.restoredResolutions.map(\.intent)
        }
        return result
    }

    /// Records a successfully presented push intent and persists the updated state.
    ///
    /// If persistence fails, the tracked stack rolls back to its previous value.
    public func recordPush(_ intent: RoutedNavigationIntent<Payload>) throws {
        try persistTrackedIntentMutation {
            intents.append(intent)
        }
    }

    /// Records removal of one pushed restorable screen.
    public func recordPop() throws {
        try recordPop(count: 1)
    }

    /// Records removal of the requested number of pushed restorable screens.
    ///
    /// If persistence fails, the tracked stack rolls back to its previous value.
    public func recordPop(count: Int) throws {
        guard count > 0 else {
            return
        }

        let removalCount = min(count, intents.count)
        guard removalCount > 0 else {
            return
        }

        try persistTrackedIntentMutation {
            intents.removeLast(removalCount)
        }
    }

    /// Records dismissal of the current pushed restorable screen.
    public func recordDismissScreen() throws {
        try recordPop()
    }

    /// Records returning the current routed context to its root.
    ///
    /// If persistence fails, the tracked stack rolls back to its previous value.
    public func recordPopToRoot() throws {
        guard !intents.isEmpty else {
            return
        }

        try persistTrackedIntentMutation {
            intents.removeAll()
        }
    }

    /// Clears both tracked and persisted restoration state.
    ///
    /// If clearing the store fails, the tracked stack rolls back to its previous value.
    public func clear() throws {
        try persistTrackedIntentMutation(
            {
                intents.removeAll()
            },
            persist: store.clear
        )
    }

    private func persistTrackedIntentMutation(
        _ mutation: () -> Void,
        persist: () throws -> Void
    ) throws {
        let previousIntents = intents
        mutation()

        do {
            try persist()
        } catch {
            intents = previousIntents
            throw error
        }
    }

    private func persistTrackedIntentMutation(_ mutation: () -> Void) throws {
        try persistTrackedIntentMutation(mutation, persist: save)
    }
}
