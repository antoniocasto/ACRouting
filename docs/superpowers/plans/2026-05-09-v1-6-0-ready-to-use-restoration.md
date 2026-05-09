# v1.6.0 Ready-to-Use Restoration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete v1.6.0 restoration by adding a ready-to-use, intent-driven storage/controller layer above the existing restoration foundation.

**Architecture:** Keep the existing low-level `RoutingRestorationState` envelope and `Router.restore(_:using:)` replay API as the runtime foundation. Add a small persistence protocol, a `UserDefaults` adapter, a main-actor controller that tracks only successful push intents, and router convenience APIs that combine presentation, tracking, persistence, restoration, and explicit pop clearing without serializing SwiftUI views or routed modal contexts.

**Tech Stack:** Swift 6.2, SwiftUI, Foundation `UserDefaults`, Swift Package Manager, Swift Testing, DocC Markdown.

---

## File Structure

- Create `Sources/ACRouting/Restoration/RoutingRestorationStore.swift`: public storage protocol plus deterministic storage error categories.
- Create `Sources/ACRouting/Restoration/UserDefaultsRoutingRestorationStore.swift`: ready-to-use JSON-backed `UserDefaults` adapter.
- Create `Sources/ACRouting/Restoration/RoutingRestorationController.swift`: public `@MainActor` controller with type-erased store, tracked intent stack, save/load/restore, pop/dismiss/root tracking, and state export.
- Create `Sources/ACRouting/Restoration/Router+Restoration.swift`: router convenience APIs for `showRestorableScreen(...)` and optional combined pop/dismiss helpers.
- Create `Tests/ACRoutingTests/RoutingRestorationStoreTests.swift`: memory-store conformance, `UserDefaults` round-trip, clear, corrupted data, and unsupported payload decode tests.
- Create `Tests/ACRoutingTests/RoutingRestorationControllerTests.swift`: controller tracking, metadata export, pop/dismiss/root tracking, restore synchronization, load behavior, and unsupported/non-push handling.
- Modify `Tests/ACRoutingTests/RouterProtocolTests.swift`: convenience API behavior on concrete router spies and storage failure propagation.
- Modify `Sources/ACRouting/ACRouting.docc/RestorationFoundation.md`: turn the primary guide into ready-to-use restoration while retaining foundation boundaries.
- Modify `Sources/ACRouting/ACRouting.docc/ACRouting.md`: add new public symbols to topic lists.
- Modify `README.md`: replace foundation-only examples with the ready-to-use `UserDefaults` flow and explicit stack mutation tracking.
- Modify `CHANGELOG.md`: add ready-to-use restoration bullets under Unreleased.
- Modify `docs/ROADMAP.md`: update v1.6.0 status from foundation-only to ready-to-use restoration.
- Modify this plan after each completed step by changing the relevant checkbox from `[ ]` to `[x]`.

## Task 1: Storage Protocol And UserDefaults Store

**Files:**
- Create: `Sources/ACRouting/Restoration/RoutingRestorationStore.swift`
- Create: `Sources/ACRouting/Restoration/UserDefaultsRoutingRestorationStore.swift`
- Create: `Tests/ACRoutingTests/RoutingRestorationStoreTests.swift`
- Modify: `docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md`

- [x] **Step 1: Write failing storage tests**

Add tests that prove the intended public API:

```swift
private enum StoreTestRoute: String, Codable, Hashable, Sendable {
    case detail
    case unsupportedPayload
}

private struct MemoryRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    var state: RoutingRestorationState<Payload>?
    func load() throws -> RoutingRestorationState<Payload>? { state }
    func save(_ state: RoutingRestorationState<Payload>) throws {}
    func clear() throws {}
}

@Suite("UserDefaultsRoutingRestorationStore")
struct UserDefaultsRoutingRestorationStoreTests {
    @Test("load returns nil when no state is stored")
    func loadReturnsNilWhenEmpty() throws {
        let suite = try #require(UserDefaults(suiteName: "ACRouting.empty.\(UUID().uuidString)"))
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)

        #expect(try store.load() == nil)
    }

    @Test("save and load round-trip a restoration state")
    func saveLoadRoundTrip() throws {
        let suite = try #require(UserDefaults(suiteName: "ACRouting.roundtrip.\(UUID().uuidString)"))
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)
        let state = RoutingRestorationState(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 2,
            contextID: "main",
            entries: [RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .detail))]
        )

        try store.save(state)

        #expect(try store.load() == state)
    }

    @Test("clear removes stored state")
    func clearRemovesStoredState() throws {
        let suite = try #require(UserDefaults(suiteName: "ACRouting.clear.\(UUID().uuidString)"))
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
        let suite = try #require(UserDefaults(suiteName: "ACRouting.corrupt.\(UUID().uuidString)"))
        suite.set(Data([0x00, 0x01, 0x02]), forKey: "route-stack")
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)

        #expect(throws: RoutingRestorationStorageError.decodingFailed) {
            _ = try store.load()
        }
    }

    @Test("unsupported encoded payload throws a typed decoding error")
    func unsupportedPayloadThrowsTypedDecodingError() throws {
        let suite = try #require(UserDefaults(suiteName: "ACRouting.unsupported.\(UUID().uuidString)"))
        let mismatchedState = RoutingRestorationState<String>(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 1,
            contextID: "main",
            entries: [RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: "legacy"))]
        )
        suite.set(try JSONEncoder().encode(mismatchedState), forKey: "route-stack")
        let store = UserDefaultsRoutingRestorationStore<StoreTestRoute>(key: "route-stack", userDefaults: suite)

        #expect(throws: RoutingRestorationStorageError.decodingFailed) {
            _ = try store.load()
        }
    }
}
```

- [x] **Step 2: Run RED storage tests**

Run:

```bash
swift test --filter UserDefaultsRoutingRestorationStore
```

Expected: compile fails because `RoutingRestorationStore`, `UserDefaultsRoutingRestorationStore`, and `RoutingRestorationStorageError` do not exist.

- [x] **Step 3: Implement storage protocol, error model, and UserDefaults adapter**

Create `RoutingRestorationStore.swift`:

```swift
import Foundation

public protocol RoutingRestorationStore<Payload> {
    associatedtype Payload: Codable & Hashable & Sendable

    func load() throws -> RoutingRestorationState<Payload>?
    func save(_ state: RoutingRestorationState<Payload>) throws
    func clear() throws
}

public enum RoutingRestorationStorageError: Error, Equatable, Sendable {
    case encodingFailed
    case decodingFailed
}
```

Create `UserDefaultsRoutingRestorationStore.swift`:

```swift
import Foundation

public struct UserDefaultsRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    public let key: String
    public let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        key: String,
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.key = key
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() throws -> RoutingRestorationState<Payload>? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(RoutingRestorationState<Payload>.self, from: data)
        } catch {
            throw RoutingRestorationStorageError.decodingFailed
        }
    }

    public func save(_ state: RoutingRestorationState<Payload>) throws {
        do {
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: key)
        } catch {
            throw RoutingRestorationStorageError.encodingFailed
        }
    }

    public func clear() throws {
        userDefaults.removeObject(forKey: key)
    }
}
```

- [x] **Step 4: Run GREEN storage tests**

Run:

```bash
swift test --filter UserDefaultsRoutingRestorationStore
```

Expected: all `UserDefaultsRoutingRestorationStore` tests pass.

- [x] **Step 5: Commit storage layer**

Run:

```bash
git add Sources/ACRouting/Restoration Tests/ACRoutingTests/RoutingRestorationStoreTests.swift docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md
git commit -m "feat: add restoration storage adapters"
```

## Task 2: Restoration Controller

**Files:**
- Create: `Sources/ACRouting/Restoration/RoutingRestorationController.swift`
- Modify: `Tests/ACRoutingTests/RoutingRestorationControllerTests.swift`
- Modify: `docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md`

- [x] **Step 1: Write failing controller tests**

Add tests for:

```swift
@MainActor
final class RecordingRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    var state: RoutingRestorationState<Payload>?
    private(set) var savedStates: [RoutingRestorationState<Payload>] = []
    private(set) var clearCallCount = 0

    func load() throws -> RoutingRestorationState<Payload>? { state }
    func save(_ state: RoutingRestorationState<Payload>) throws {
        self.state = state
        savedStates.append(state)
    }
    func clear() throws {
        state = nil
        clearCallCount += 1
    }
}
```

Required tests:

```swift
@Test("controller exports metadata and tracked push intents")
func controllerExportsMetadataAndTrackedIntents() throws { ... }

@Test("controller records pop, pop count, dismiss, and pop to root")
func controllerRecordsStackMutations() throws { ... }

@Test("restoreLoadedState loads state, replays router pushes, and synchronizes restored intents")
func restoreLoadedStateSynchronizesRestoredIntents() throws { ... }

@Test("restoreLoadedState returns nil when no stored state exists")
func restoreLoadedStateReturnsNilWhenEmpty() throws { ... }

@Test("unsupported entries synchronize the controller to entries actually restored")
func restoreLoadedStateSynchronizesAfterUnsupportedPayload() throws { ... }

@Test("non-push entries synchronize the controller to entries actually restored")
func restoreLoadedStateSynchronizesAfterNonPushPayload() throws { ... }
```

Each assertion must check `trackedIntents`, `state`, store saves, and spy-router show-screen calls where applicable.

- [x] **Step 2: Run RED controller tests**

Run:

```bash
swift test --filter RoutingRestorationController
```

Expected: compile fails because `RoutingRestorationController` does not exist.

- [x] **Step 3: Implement controller and internal store type erasure**

Create `RoutingRestorationController.swift` with:

```swift
@MainActor
public final class RoutingRestorationController<Payload>
where Payload: Codable & Hashable & Sendable {
    public var trackedIntents: [RoutedNavigationIntent<Payload>] { intents }

    public init<Store>(
        payloadSchemaVersion: Int,
        resolverPolicyVersion: Int,
        contextID: String? = nil,
        store: Store
    ) where Store: RoutingRestorationStore, Store.Payload == Payload

    public func currentState() -> RoutingRestorationState<Payload>
    public func save() throws
    public func loadState() throws -> RoutingRestorationState<Payload>?
    @discardableResult public func restoreLoadedState<Resolver>(on router: any Router, using resolver: Resolver) throws -> RoutingRestorationResult<Payload>? where Resolver: RoutedNavigationIntentResolving, Resolver.Payload == Payload
    public func recordPresentedPush(_ intent: RoutedNavigationIntent<Payload>) throws
    public func recordPop() throws
    public func recordPop(count: Int) throws
    public func recordDismissScreen() throws
    public func recordPopToRoot() throws
    public func clear() throws
}
```

Implementation notes:

- Store closures internally as `AnyRoutingRestorationStore<Payload>`.
- `currentState()` builds entries from `trackedIntents`.
- `recordPresentedPush(_:)` appends then saves.
- `recordPop(count:)` ignores non-positive counts and removes at most the tracked count.
- `recordDismissScreen()` delegates to `recordPop()`.
- `recordPopToRoot()` clears tracked intents and saves an empty state.
- `clear()` clears tracked intents and calls store `clear()`.
- `restoreLoadedState(on:using:)` loads through the store, calls `router.restore`, then replaces `trackedIntents` with `result.restoredResolutions.map(\.intent)` and saves the synchronized state.

- [x] **Step 4: Run GREEN controller tests**

Run:

```bash
swift test --filter RoutingRestorationController
```

Expected: controller tests pass.

- [x] **Step 5: Commit controller layer**

Run:

```bash
git add Sources/ACRouting/Restoration/RoutingRestorationController.swift Tests/ACRoutingTests/RoutingRestorationControllerTests.swift docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md
git commit -m "feat: add restoration controller"
```

## Task 3: Router Convenience API

**Files:**
- Create: `Sources/ACRouting/Restoration/Router+Restoration.swift`
- Modify: `Tests/ACRoutingTests/RouterProtocolTests.swift`
- Modify: `docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md`

- [x] **Step 1: Write failing router convenience tests**

Add tests proving:

```swift
@Test("showRestorableScreen tracks and saves supported push intents")
func showRestorableScreenTracksSupportedPushIntents() throws { ... }

@Test("showRestorableScreen does not track unsupported payloads")
func showRestorableScreenDoesNotTrackUnsupportedPayloads() throws { ... }

@Test("showRestorableScreen presents but does not track sheets")
func showRestorableScreenDoesNotTrackNonPushPresentations() throws { ... }

@Test("restorable pop helpers mutate router and controller together")
func restorablePopHelpersMutateRouterAndControllerTogether() throws { ... }

@Test("showRestorableScreen propagates storage save failures")
func showRestorableScreenPropagatesStorageFailures() throws { ... }
```

- [x] **Step 2: Run RED router convenience tests**

Run:

```bash
swift test --filter showRestorableScreen
```

Expected: compile fails because `showRestorableScreen` and helper APIs do not exist.

- [x] **Step 3: Implement router convenience APIs**

Create `Router+Restoration.swift` with:

```swift
import SwiftUI

public extension Router {
    @discardableResult
    func showRestorableScreen<Resolver>(
        _ intent: RoutedNavigationIntent<Resolver.Payload>,
        using resolver: Resolver,
        restoration: RoutingRestorationController<Resolver.Payload>
    ) throws -> RoutedNavigationResolution<Resolver.Payload>
    where Resolver: RoutedNavigationIntentResolving {
        let presentation = resolver.canResolve(intent.payload) ? resolver.presentation(for: intent.payload) : nil
        let result = showScreen(intent, using: resolver)
        if case .presented = result, presentation == .push {
            try restoration.recordPresentedPush(intent)
        }
        return result
    }

    func popRestorableScreen<Payload>(restoration: RoutingRestorationController<Payload>) throws { ... }
    func popRestorableScreens<Payload>(count: Int, restoration: RoutingRestorationController<Payload>) throws { ... }
    func dismissRestorableScreen<Payload>(restoration: RoutingRestorationController<Payload>) throws { ... }
    func popRestorableStackToRoot<Payload>(restoration: RoutingRestorationController<Payload>) throws { ... }
}
```

Helper behavior:

- `popRestorableScreen` calls `pop()` then `recordPop()`.
- `popRestorableScreens(count:)` calls `pop(count:)` then `recordPop(count:)`.
- `dismissRestorableScreen` calls `dismissScreen()` then `recordDismissScreen()`.
- `popRestorableStackToRoot` calls `popToRoot()` then `recordPopToRoot()`.

- [x] **Step 4: Run GREEN router convenience tests**

Run:

```bash
swift test --filter showRestorableScreen
swift test --filter restorable
```

Expected: router convenience tests pass.

- [x] **Step 5: Commit router convenience API**

Run:

```bash
git add Sources/ACRouting/Restoration/Router+Restoration.swift Tests/ACRoutingTests/RouterProtocolTests.swift docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md
git commit -m "feat: add restorable router conveniences"
```

## Task 4: Documentation

**Files:**
- Modify: `README.md`
- Modify: `Sources/ACRouting/ACRouting.docc/RestorationFoundation.md`
- Modify: `Sources/ACRouting/ACRouting.docc/ACRouting.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md`

- [x] **Step 1: Update docs and examples**

Update docs to show:

```swift
let store = UserDefaultsRoutingRestorationStore<AppRoute>(key: "main-route-stack")
let restoration = RoutingRestorationController(
    payloadSchemaVersion: 1,
    resolverPolicyVersion: 1,
    contextID: "main",
    store: store
)

try router.showRestorableScreen(
    RoutedNavigationIntent(payload: .detail(id: 42)),
    using: AppRouteResolver(builder: builder),
    restoration: restoration
)

let result = try restoration.restoreLoadedState(
    on: router,
    using: AppRouteResolver(builder: builder)
)
```

Also document:

- app-owned custom stores via `RoutingRestorationStore`;
- `UserDefaultsRoutingRestorationStore`;
- `RoutingRestorationController`;
- explicit mutation tracking through `recordPop`, `recordDismissScreen`, `recordPopToRoot`, and router helper methods;
- unsupported/deferred scope: no serialization of `RouterView`, `AnyDestination`, closures, sheets, fullScreenCover, overlay, alert, tabs, windows, or cross-context restoration.

- [x] **Step 2: Verify documentation symbol references**

Run:

```bash
rg "RoutingRestorationStore|UserDefaultsRoutingRestorationStore|RoutingRestorationController|showRestorableScreen|popRestorable|recordPop|recordDismissScreen|recordPopToRoot" README.md Sources/ACRouting/ACRouting.docc CHANGELOG.md docs/ROADMAP.md
```

Expected: matches show all new public API in user-facing docs.

- [x] **Step 3: Commit documentation**

Run:

```bash
git add README.md Sources/ACRouting/ACRouting.docc CHANGELOG.md docs/ROADMAP.md docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md
git commit -m "docs: document ready-to-use restoration"
```

## Task 5: Full Verification And PR Update

**Files:**
- Modify: `docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md`

- [ ] **Step 1: Run full build**

Run:

```bash
swift build
```

Expected: build exits 0.

- [ ] **Step 2: Run full test suite**

Run:

```bash
swift test
```

Expected: test suite exits 0.

- [ ] **Step 3: Review diff and status**

Run:

```bash
git status --short
git diff --stat
git log --oneline -5
```

Expected: only intentional ready-to-use restoration files are modified, and recent commits are coherent.

- [ ] **Step 4: Commit final plan checkbox updates if needed**

Run:

```bash
git add docs/superpowers/plans/2026-05-09-v1-6-0-ready-to-use-restoration.md
git commit -m "docs: complete ready-to-use restoration plan"
```

Expected: commit is created only if the plan has uncommitted checkbox updates.

- [ ] **Step 5: Push branch and update draft PR #50**

Run:

```bash
git push origin codex/v1-6-0-restoration-foundation
gh pr view 50 --json number,title,state,isDraft,baseRefName,headRefName,url
gh pr edit 50 --body-file <updated-pr-body-file>
```

Expected: branch is pushed, PR #50 remains draft, base is `develop`, and the PR body mentions ready-to-use restoration APIs, docs, and verification.
