import Foundation
import Testing
@testable import ACRouting

private enum StoreTestRoute: String, Codable, Hashable, Sendable {
    case detail
    case unsupportedPayload
}

private final class MemoryRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    private(set) var storedState: RoutingRestorationState<Payload>?
    private(set) var clearCallCount = 0

    init(state: RoutingRestorationState<Payload>? = nil) {
        storedState = state
    }

    func load() throws -> RoutingRestorationState<Payload>? {
        storedState
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        storedState = state
    }

    func clear() throws {
        storedState = nil
        clearCallCount += 1
    }
}

@Suite("RoutingRestorationStore")
struct RoutingRestorationStoreTests {
    @Test("custom memory store can save, load, and clear states")
    func customMemoryStoreConformance() throws {
        let store = MemoryRoutingRestorationStore<StoreTestRoute>()
        let state = RoutingRestorationState<StoreTestRoute>(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 2,
            contextID: "main",
            entries: [
                RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .detail))
            ]
        )

        try store.save(state)
        #expect(try store.load() == state)

        try store.clear()
        #expect(try store.load() == nil)
        #expect(store.clearCallCount == 1)
    }
}

@Suite("UserDefaultsRoutingRestorationStore")
struct UserDefaultsRoutingRestorationStoreTests {
    @Test("load returns nil when no state is stored")
    func loadReturnsNilWhenEmpty() throws {
        let suite = try makeSuite()
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)

        #expect(try store.load() == nil)
    }

    @Test("save and load round-trip a restoration state")
    func saveLoadRoundTrip() throws {
        let suite = try makeSuite()
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)
        let state = RoutingRestorationState<StoreTestRoute>(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 2,
            contextID: "main",
            entries: [
                RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .detail))
            ]
        )

        try store.save(state)

        #expect(try store.load() == state)
    }

    @Test("clear removes stored state")
    func clearRemovesStoredState() throws {
        let suite = try makeSuite()
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)
        let state = RoutingRestorationState<StoreTestRoute>(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            contextID: nil,
            entries: []
        )

        try store.save(state)
        try store.clear()

        #expect(try store.load() == nil)
    }

    @Test("corrupted data throws a typed decoding error")
    func corruptedDataThrowsTypedDecodingError() throws {
        let suite = try makeSuite()
        suite.set(Data([0x00, 0x01, 0x02]), forKey: "route-stack")
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)

        do {
            _ = try store.load()
            Issue.record("Expected corrupted data to throw")
        } catch let error as RoutingRestorationStorageError {
            #expect(error == .decodingFailed)
        }
    }

    @Test("unsupported encoded payload throws a typed decoding error")
    func unsupportedPayloadThrowsTypedDecodingError() throws {
        let suite = try makeSuite()
        let mismatchedState = RoutingRestorationState<String>(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            contextID: "main",
            entries: [
                RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: "legacy"))
            ]
        )
        suite.set(try JSONEncoder().encode(mismatchedState), forKey: "route-stack")
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)

        do {
            _ = try store.load()
            Issue.record("Expected unsupported payload data to throw")
        } catch let error as RoutingRestorationStorageError {
            #expect(error == .decodingFailed)
        }
    }

    private func makeSuite() throws -> UserDefaults {
        let name = "ACRouting.RestorationStoreTests.\(UUID().uuidString)"
        let suite = try #require(UserDefaults(suiteName: name))
        suite.removePersistentDomain(forName: name)
        return suite
    }
}
