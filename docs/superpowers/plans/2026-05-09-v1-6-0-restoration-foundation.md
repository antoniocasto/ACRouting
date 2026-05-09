# v1.6.0 Restoration Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a documented, source-compatible restoration foundation that lets apps persist and restore a single `RouterView` push stack from serializable routed navigation intents.

**Architecture:** Persistence storage stays app-owned: `ACRouting` defines Codable restoration models and a `Router.restore(_:using:)` API, but it does not read or write `UserDefaults`, files, SwiftData, Core Data, Keychain, or iCloud. The first implementation restores only push entries inside one routed context; sheets, full-screen covers, overlays, alerts, multi-root tabs, and cross-context restoration remain out of runtime scope for `v1.6.0` because they require a compatibility envelope for multiple `RouterView` roots. Restoration builds on `RoutedNavigationIntent`, `RoutedNavigationIntentResolving`, and the existing `Router.showScreen(_:using:)` extension so app-owned builders keep screen assembly.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Package Manager, Swift Testing, DocC Markdown.

---

## Validated Decision

The proposed direction is a good choice with one important scope correction.

Keep:

- `ACRouting` should not own the storage backend.
- Restoration state should be Codable and versioned.
- App payloads remain app-owned and must stay `Codable & Hashable & Sendable`.
- App-owned resolvers continue to decide support, presentation style, and destination assembly.
- `Router.showScreen(_:using:)` remains the runtime primitive for applying supported intents.

Adjust:

- Do not try to restore routed modal flows in the first implementation. In the current runtime, `.sheet` and `.fullScreenCover` create a fresh routed context with its own local stack, so restoring those correctly requires a nested envelope and lifecycle timing that is larger than a foundation release.
- Do not implement `exportRestorationState()` from arbitrary `RouterView` state in `v1.6.0`. Existing closure-built destinations and `AnyDestination` values are intentionally not serializable. Apps should persist the same intent list they use to drive intent-based navigation.

The first useful, deterministic feature is: app creates or loads a `RoutingRestorationState<Payload>`, decodes it from its chosen storage, then calls `router.restore(state, using: resolver)` to replay supported push entries in order.

## File Structure

- Create `docs/superpowers/specs/2026-05-09-v1-6-0-restoration-foundation-design.md`: design note covering storage ownership, envelope fields, versioning, unsupported payload behavior, single-context scope, and deferred modal/cross-context restoration.
- Create `Sources/ACRouting/Models/RoutingRestorationState.swift`: Codable public restoration envelope and entry models.
- Create `Sources/ACRouting/Models/RoutingRestorationResult.swift`: public result model returned by restoration attempts.
- Modify `Sources/ACRouting/Core/Router.swift`: add `Router.restore(_:using:)` as a protocol extension only.
- Modify `Tests/ACRoutingTests/ModelTests.swift`: add Codable/equality/default-version tests for restoration models.
- Modify `Tests/ACRoutingTests/RouterProtocolTests.swift`: add spy-router coverage for restore sequencing, unsupported payloads, and non-push presentation rejection.
- Modify `Tests/ACRoutingTests/RouterViewIntegrationTests.swift`: add concrete `RouterView` push-stack restoration coverage through an externally tracked inherited stack.
- Modify `Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md`: link deep-link intent modeling to restoration foundation.
- Create `Sources/ACRouting/ACRouting.docc/RestorationFoundation.md`: document supported `v1.6.0` restoration behavior and app-owned persistence examples.
- Modify `Sources/ACRouting/ACRouting.docc/ACRouting.md`: add restoration topic link.
- Modify `README.md`: add a short restoration foundation section.
- Modify `docs/ROADMAP.md`: mark `v1.6.0` design and foundation scope accurately.
- Modify `CHANGELOG.md`: add `Unreleased` bullets for restoration models, restore API, docs, and tests.

## Task 1: Design Note

**Files:**
- Create: `docs/superpowers/specs/2026-05-09-v1-6-0-restoration-foundation-design.md`

- [x] **Step 1: Write the restoration design note**

Create the file with this content:

````markdown
# v1.6.0 Restoration Foundation Design

## Decision

`ACRouting` will provide a Codable, versioned restoration envelope and a `Router.restore(_:using:)` API for replaying a single routed push stack from serializable app-owned payloads.

The package will not choose or manage persistence storage. Applications remain responsible for encoding, saving, loading, decoding, migrating, encrypting, deleting, and syncing restoration data.

## Existing foundation

- `RoutedNavigationIntent<Payload>` already stores only app-owned serializable payloads.
- `RoutedNavigationIntentResolving` already keeps support checks, presentation-style selection, and destination assembly in app-owned code.
- `Router.showScreen(_:using:)` already applies a supported intent through the resolver and returns `.unsupported` without mutating router state when the resolver rejects a payload.

## Supported in v1.6.0

- One restoration envelope for one `RouterView` context.
- A linear list of push entries.
- JSON round-trips through app-owned storage.
- Resolver validation before each entry is applied.
- Early stop when an entry is unsupported.
- Early stop when an entry resolves to `.sheet` or `.fullScreenCover`, because `v1.6.0` restores only the current context push stack.

## Not supported in v1.6.0

- Package-owned storage.
- Exporting arbitrary `RouterView` state.
- Persisting closure-built destinations.
- Persisting `AnyDestination` or `AnyView`.
- Restoring `.sheet`, `.fullScreenCover`, alerts, confirmation dialogs, or custom overlays.
- Restoring multiple tab roots, windows, scenes, or independent `RouterView` roots.
- Cross-context restoration.

## Envelope

```swift
RoutingRestorationState<AppRoute>(
    payloadSchemaVersion: 1,
    resolverPolicyVersion: 1,
    contextID: "main",
    entries: [
        RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .detail(id: 42))),
        RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .comments(id: 42)))
    ]
)
```

## Version responsibilities

- `envelopeVersion` is owned by `ACRouting` and starts at `1`.
- `payloadSchemaVersion` is owned by the app and describes the encoded payload schema.
- `resolverPolicyVersion` is owned by the app and describes how the resolver maps payloads to supported destinations and presentation styles.
- `contextID` is app-owned metadata for identifying the intended routed root.

## Persistence example

```swift
let state = RoutingRestorationState(
    payloadSchemaVersion: 1,
    resolverPolicyVersion: 1,
    contextID: "main",
    entries: [
        RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: AppRoute.detail(id: 42)))
    ]
)

let data = try JSONEncoder().encode(state)
try data.write(to: restorationURL)
```

## Restore example

```swift
let data = try Data(contentsOf: restorationURL)
let state = try JSONDecoder().decode(RoutingRestorationState<AppRoute>.self, from: data)
let result = router.restore(state, using: AppRouteResolver(builder: builder))
```

## Failure behavior

Restoration is incremental and deterministic. Entries are applied in order. If a payload is unsupported or resolves to a non-push presentation style, the router stops and returns a result that includes the entries restored before the stop.
````

- [x] **Step 2: Review the design note for scope drift**

Run:

```bash
rg "UserDefaults|SwiftData|Core Data|iCloud|AnyDestination|fullScreenCover|sheet|cross-context|export" docs/superpowers/specs/2026-05-09-v1-6-0-restoration-foundation-design.md
```

Expected: matches only describe app-owned storage examples, explicit non-goals, or deferred scope. There must be no sentence assigning storage ownership to `ACRouting`.

- [x] **Step 3: Commit the design note**

```bash
git add docs/superpowers/specs/2026-05-09-v1-6-0-restoration-foundation-design.md
git commit -m "docs: add restoration foundation design

- Define app-owned persistence boundary
- Scope v1.6.0 to single-context push restoration"
```

## Task 2: Restoration Models

**Files:**
- Create: `Sources/ACRouting/Models/RoutingRestorationState.swift`
- Modify: `Tests/ACRoutingTests/ModelTests.swift`

- [x] **Step 1: Add failing model tests**

Add this section before `// MARK: - AlertType Tests` in `Tests/ACRoutingTests/ModelTests.swift`:

```swift
// MARK: - RoutingRestorationState Tests

private enum TestRestorationPayload: Codable, Hashable, Sendable {
    case detail(id: Int)
    case comments(id: Int)
}

@Suite("RoutingRestorationState")
struct RoutingRestorationStateTests {

    @Test("State stores version metadata and entries")
    func storesMetadataAndEntries() {
        let detailIntent = RoutedNavigationIntent(payload: TestRestorationPayload.detail(id: 42))
        let state = RoutingRestorationState(
            payloadSchemaVersion: 3,
            resolverPolicyVersion: 7,
            contextID: "main",
            entries: [
                RoutingRestorationEntry(intent: detailIntent)
            ]
        )

        #expect(state.envelopeVersion == RoutingRestorationState<TestRestorationPayload>.currentEnvelopeVersion)
        #expect(state.payloadSchemaVersion == 3)
        #expect(state.resolverPolicyVersion == 7)
        #expect(state.contextID == "main")
        #expect(state.entries == [RoutingRestorationEntry(intent: detailIntent)])
    }

    @Test("State round-trips through JSON")
    func jsonRoundTrip() throws {
        let state = RoutingRestorationState(
            payloadSchemaVersion: 1,
            resolverPolicyVersion: 2,
            contextID: nil,
            entries: [
                RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .detail(id: 42))),
                RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: .comments(id: 42)))
            ]
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(RoutingRestorationState<TestRestorationPayload>.self, from: data)

        #expect(decoded == state)
    }

    @Test("State can decode an explicit envelope version")
    func decodesExplicitEnvelopeVersion() throws {
        let json = """
        {
          "envelopeVersion": 1,
          "payloadSchemaVersion": 4,
          "resolverPolicyVersion": 9,
          "contextID": "main",
          "entries": []
        }
        """

        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(RoutingRestorationState<TestRestorationPayload>.self, from: data)

        #expect(decoded.envelopeVersion == 1)
        #expect(decoded.payloadSchemaVersion == 4)
        #expect(decoded.resolverPolicyVersion == 9)
        #expect(decoded.contextID == "main")
        #expect(decoded.entries.isEmpty)
    }
}
```

- [x] **Step 2: Run model tests and verify they fail**

Run:

```bash
swift test --filter RoutingRestorationState
```

Expected: compile fails because `RoutingRestorationState` and `RoutingRestorationEntry` do not exist.

- [x] **Step 3: Add restoration model implementation**

Create `Sources/ACRouting/Models/RoutingRestorationState.swift`:

```swift
import Foundation

/// A versioned, Codable restoration envelope for one routed context.
///
/// `ACRouting` owns the envelope shape, while applications own payload schema
/// versions, resolver policy versions, and the persistence storage backend.
public struct RoutingRestorationState<Payload>: Codable, Hashable, Sendable where Payload: Codable & Hashable & Sendable {
    /// The current restoration envelope version understood by this package.
    public static var currentEnvelopeVersion: Int { 1 }

    /// The `ACRouting` envelope format version.
    public let envelopeVersion: Int

    /// The app-owned encoded payload schema version.
    public let payloadSchemaVersion: Int

    /// The app-owned resolver policy version.
    public let resolverPolicyVersion: Int

    /// Optional app-owned identifier for the routed root this state belongs to.
    public let contextID: String?

    /// The push entries to restore in order inside one routed context.
    public let entries: [RoutingRestorationEntry<Payload>]

    /// Creates a restoration state for one routed context.
    ///
    /// - Parameters:
    ///   - envelopeVersion: The `ACRouting` envelope format version.
    ///   - payloadSchemaVersion: The app-owned payload schema version.
    ///   - resolverPolicyVersion: The app-owned resolver policy version.
    ///   - contextID: Optional app-owned routed root identifier.
    ///   - entries: The push entries to restore in order.
    public init(
        envelopeVersion: Int = Self.currentEnvelopeVersion,
        payloadSchemaVersion: Int,
        resolverPolicyVersion: Int,
        contextID: String? = nil,
        entries: [RoutingRestorationEntry<Payload>]
    ) {
        self.envelopeVersion = envelopeVersion
        self.payloadSchemaVersion = payloadSchemaVersion
        self.resolverPolicyVersion = resolverPolicyVersion
        self.contextID = contextID
        self.entries = entries
    }
}

/// One restorable push entry inside a routed context.
public struct RoutingRestorationEntry<Payload>: Codable, Hashable, Sendable where Payload: Codable & Hashable & Sendable {
    /// The app-owned routed intent to restore.
    public let intent: RoutedNavigationIntent<Payload>

    /// Creates a restorable push entry.
    ///
    /// - Parameter intent: The app-owned routed intent to restore.
    public init(intent: RoutedNavigationIntent<Payload>) {
        self.intent = intent
    }
}
```

- [x] **Step 4: Run model tests and verify they pass**

Run:

```bash
swift test --filter RoutingRestorationState
```

Expected: all `RoutingRestorationState` tests pass.

- [x] **Step 5: Commit restoration models**

```bash
git add Sources/ACRouting/Models/RoutingRestorationState.swift Tests/ACRoutingTests/ModelTests.swift
git commit -m "feat: add routing restoration state

- Add versioned Codable restoration envelope
- Cover JSON round-trips and metadata"
```

## Task 3: Restore Result and Router API

**Files:**
- Create: `Sources/ACRouting/Models/RoutingRestorationResult.swift`
- Modify: `Sources/ACRouting/Core/Router.swift`
- Modify: `Tests/ACRoutingTests/RouterProtocolTests.swift`

- [x] **Step 1: Add failing restore API tests**

Add this helper enum and resolver near `DeepLinkTestRoute` in `Tests/ACRoutingTests/RouterProtocolTests.swift`:

```swift
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
```

Add these tests near the existing routed intent tests:

```swift
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
```

- [x] **Step 2: Run restore API tests and verify they fail**

Run:

```bash
swift test --filter restore
```

Expected: compile fails because `Router.restore(_:using:)` and `RoutingRestorationResult` do not exist.

- [x] **Step 3: Add restore result type**

Create `Sources/ACRouting/Models/RoutingRestorationResult.swift`:

```swift
import Foundation

/// The result of attempting to restore a routed navigation state.
public enum RoutingRestorationResult<Payload>: Equatable, Sendable where Payload: Codable & Hashable & Sendable {
    /// Every entry in the restoration state was presented.
    case restored([RoutedNavigationResolution<Payload>])

    /// The resolver rejected an entry and restoration stopped before presenting it.
    case unsupported(
        RoutedNavigationIntent<Payload>,
        restored: [RoutedNavigationResolution<Payload>]
    )

    /// An entry resolved to a presentation style outside the supported `v1.6.0` restoration scope.
    case unsupportedPresentation(
        RoutedNavigationIntent<Payload>,
        presentation: SegueOption,
        restored: [RoutedNavigationResolution<Payload>]
    )

    /// The entries restored before restoration stopped or completed.
    public var restoredResolutions: [RoutedNavigationResolution<Payload>] {
        switch self {
        case .restored(let restored),
             .unsupported(_, let restored),
             .unsupportedPresentation(_, _, let restored):
            restored
        }
    }
}
```

- [x] **Step 4: Add `Router.restore(_:using:)` extension**

Add this after the existing `showScreen(_:using:)` extension in `Sources/ACRouting/Core/Router.swift`:

```swift
public extension Router {
    /// Restores a single routed push stack from a versioned restoration state.
    ///
    /// Restoration is intentionally limited to `.push` entries in `v1.6.0`. Sheets,
    /// full-screen covers, overlays, alerts, and cross-context restoration require a
    /// nested envelope and are not replayed by this API.
    ///
    /// - Parameters:
    ///   - state: The app-persisted restoration state to replay.
    ///   - resolver: The app-owned resolver that validates payloads and builds destinations.
    /// - Returns: The restoration result, including entries restored before any stop condition.
    @discardableResult
    func restore<Resolver>(
        _ state: RoutingRestorationState<Resolver.Payload>,
        using resolver: Resolver
    ) -> RoutingRestorationResult<Resolver.Payload> where Resolver: RoutedNavigationIntentResolving {
        var restoredResolutions: [RoutedNavigationResolution<Resolver.Payload>] = []

        for entry in state.entries {
            let intent = entry.intent

            guard resolver.canResolve(intent.payload) else {
                return .unsupported(intent, restored: restoredResolutions)
            }

            let presentation = resolver.presentation(for: intent.payload)
            guard presentation == .push else {
                return .unsupportedPresentation(
                    intent,
                    presentation: presentation,
                    restored: restoredResolutions
                )
            }

            showScreen(.push) { router in
                resolver.destination(for: intent.payload, router: router)
            }
            restoredResolutions.append(.presented(intent))
        }

        return .restored(restoredResolutions)
    }
}
```

- [x] **Step 5: Run restore API tests and verify they pass**

Run:

```bash
swift test --filter restore
```

Expected: the restore tests pass and no non-push entry is presented.

- [x] **Step 6: Commit restore API**

```bash
git add Sources/ACRouting/Models/RoutingRestorationResult.swift Sources/ACRouting/Core/Router.swift Tests/ACRoutingTests/RouterProtocolTests.swift
git commit -m "feat: restore routed push stacks

- Add restoration result type
- Replay supported push intents through app resolvers"
```

## Task 4: Concrete RouterView Restoration Coverage

**Files:**
- Modify: `Tests/ACRoutingTests/RouterViewIntegrationTests.swift`

- [x] **Step 1: Add a push-only resolver for concrete RouterView tests**

Add this near `RouterViewDeepLinkResolver`:

```swift
private enum RouterViewRestorationRoute: String, Codable, Hashable, Sendable {
    case detail
    case comments
}

private struct RouterViewRestorationResolver: RoutedNavigationIntentResolving {
    func canResolve(_ payload: RouterViewRestorationRoute) -> Bool {
        true
    }

    func presentation(for payload: RouterViewRestorationRoute) -> SegueOption {
        .push
    }

    func destination(for payload: RouterViewRestorationRoute, router: any Router) -> some View {
        Text("Restored \(payload.rawValue)")
    }
}
```

- [x] **Step 2: Add concrete stack mutation test**

Add this test inside `RouterViewIntegrationTests`:

```swift
@Test("restore mutates the active RouterView push stack")
func restoreMutatesActiveRouterViewPushStack() {
    let stackBox = StackBox()
    let router = makeChildRouter(stackBox: stackBox)
    let detailIntent = RoutedNavigationIntent(payload: RouterViewRestorationRoute.detail)
    let commentsIntent = RoutedNavigationIntent(payload: RouterViewRestorationRoute.comments)
    let state = RoutingRestorationState(
        payloadSchemaVersion: 1,
        resolverPolicyVersion: 1,
        entries: [
            RoutingRestorationEntry(intent: detailIntent),
            RoutingRestorationEntry(intent: commentsIntent)
        ]
    )

    let result = router.restore(state, using: RouterViewRestorationResolver())

    #expect(result == .restored([
        .presented(detailIntent),
        .presented(commentsIntent)
    ]))
    #expect(stackBox.stack.count == 2)
}
```

- [x] **Step 3: Run concrete RouterView restoration test**

Run:

```bash
swift test --filter restoreMutatesActiveRouterViewPushStack
```

Expected: the test passes and proves `restore(_:using:)` works through concrete `RouterView` stack mutation.

- [x] **Step 4: Commit concrete coverage**

```bash
git add Tests/ACRoutingTests/RouterViewIntegrationTests.swift
git commit -m "test: cover RouterView restoration stack mutation

- Verify restore replays intents through concrete RouterView
- Keep v1.6.0 scope limited to push stacks"
```

## Task 5: Public Documentation

**Files:**
- Create: `Sources/ACRouting/ACRouting.docc/RestorationFoundation.md`
- Modify: `Sources/ACRouting/ACRouting.docc/ACRouting.md`
- Modify: `Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/ROADMAP.md`

- [x] **Step 1: Add DocC restoration article**

Create `Sources/ACRouting/ACRouting.docc/RestorationFoundation.md`:

````markdown
# Restoration Foundation

Persist and restore a single routed push stack from app-owned navigation payloads.

## Overview

`ACRouting` restoration is built on ``RoutedNavigationIntent``. The package stores no views, builders, presenters, interactors, or type-erased destinations in the restoration envelope. Your app persists serializable route payloads and provides a resolver when restoring.

## Create State

```swift
let state = RoutingRestorationState(
    payloadSchemaVersion: 1,
    resolverPolicyVersion: 1,
    contextID: "main",
    entries: [
        RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: AppRoute.detail(id: 42)))
    ]
)
```

## Persist State

Choose storage in your app:

```swift
let data = try JSONEncoder().encode(state)
try data.write(to: restorationURL)
```

## Restore State

```swift
let data = try Data(contentsOf: restorationURL)
let state = try JSONDecoder().decode(RoutingRestorationState<AppRoute>.self, from: data)
let result = router.restore(state, using: AppRouteResolver(builder: builder))
```

## Scope

`v1.6.0` restores push entries inside one routed context. If an entry resolves to `.sheet` or `.fullScreenCover`, restoration stops and returns ``RoutingRestorationResult/unsupportedPresentation(_:presentation:restored:)``.

`ACRouting` does not persist storage, export arbitrary `RouterView` state, serialize `AnyDestination`, or restore multi-root tab/window state in this release.
````

- [x] **Step 2: Add DocC topic link**

In `Sources/ACRouting/ACRouting.docc/ACRouting.md`, add ``RestorationFoundation`` to the topic section beside deep-link input modeling.

- [x] **Step 3: Update deep-link article boundary wording**

In `Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md`, replace:

```markdown
- `ACRouting` does not persist or restore navigation state in `v1.5.3`.
- Future restoration should treat payload schema versions and resolver presentation rules as app-owned compatibility boundaries.
- Multi-step restoration remains future work after the deep-link payload boundary is stable.
```

with:

```markdown
- `ACRouting` restores only single-context push stacks in `v1.6.0`.
- Restoration state stores app-owned payloads plus app-owned payload schema and resolver policy versions.
- Multi-root, cross-context, routed modal, alert, and overlay restoration remain future work.
```

- [x] **Step 4: Add README restoration section**

Add this section after the deep-link or routing intent documentation in `README.md`:

````markdown
## Restoration Foundation

`ACRouting` can restore a single routed push stack from app-owned serializable navigation payloads. The package defines the Codable envelope and replay API, while your app chooses where and when to persist it.

```swift
let state = RoutingRestorationState(
    payloadSchemaVersion: 1,
    resolverPolicyVersion: 1,
    contextID: "main",
    entries: [
        RoutingRestorationEntry(intent: RoutedNavigationIntent(payload: AppRoute.detail(id: 42)))
    ]
)

let data = try JSONEncoder().encode(state)
try data.write(to: restorationURL)
```

When the app is ready to rebuild navigation:

```swift
let data = try Data(contentsOf: restorationURL)
let state = try JSONDecoder().decode(RoutingRestorationState<AppRoute>.self, from: data)
let result = router.restore(state, using: AppRouteResolver(builder: builder))
```

The first restoration release intentionally restores only `.push` entries inside one `RouterView` context. Storage, payload migration, privacy, encryption, and sync remain app-owned.
````

- [x] **Step 5: Update changelog**

Under `## [Unreleased]` in `CHANGELOG.md`, add:

```markdown
### Added

- Added a versioned `RoutingRestorationState` envelope for app-owned navigation payload persistence.
- Added `Router.restore(_:using:)` for replaying supported single-context push stacks through app-owned resolvers.
- Documented the `v1.6.0` restoration foundation scope and app-owned persistence boundary.
```

- [x] **Step 6: Update roadmap**

In `docs/ROADMAP.md`, update the `v1.6.0` milestone to say:

```markdown
Already implemented:

- A design note defines the restoration envelope, payload schema versioning, resolver policy versioning, and unsupported payload behavior.
- `RoutingRestorationState` stores app-owned intent entries for one routed context.
- `Router.restore(_:using:)` replays supported `.push` entries through app-owned resolvers and stops on unsupported or non-push entries.
- Restoration documentation shows app-owned persistence and explicitly defers routed modal, overlay, alert, multi-root, and cross-context restoration.
```

- [x] **Step 7: Run documentation search checks**

Run:

```bash
rg "v1.5.3|does not persist or restore|Future restoration" README.md Sources/ACRouting/ACRouting.docc docs/ROADMAP.md CHANGELOG.md
```

Expected: no stale statement says restoration is wholly future work for the current release. `v1.5.3` may still appear in historical release notes and package-version examples.

- [x] **Step 8: Commit documentation**

```bash
git add README.md CHANGELOG.md docs/ROADMAP.md Sources/ACRouting/ACRouting.docc/ACRouting.md Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md Sources/ACRouting/ACRouting.docc/RestorationFoundation.md
git commit -m "docs: document restoration foundation

- Explain app-owned persistence
- Scope v1.6.0 to single-context push restoration"
```

## Task 6: Final Verification

**Files:**
- Verify: full repository

- [x] **Step 1: Run full local build**

Run:

```bash
swift build
```

Expected: build completes with exit code `0`.

- [x] **Step 2: Run full local test suite**

Run:

```bash
swift test
```

Expected: all Swift Testing suites pass.

- [x] **Step 3: Inspect changed files**

Run:

```bash
git status --short
git diff --stat develop...HEAD
```

Expected: only restoration foundation source, tests, docs, changelog, roadmap, and design note files are changed.

- [x] **Step 4: Push branch**

Run:

```bash
git push origin codex/v1-6-0-restoration-foundation
```

Expected: branch is available on GitHub for a PR targeting `develop`.

## Execution Recommendation

Use subagent-driven execution in the next chat:

- Task 1 can run independently as the design checkpoint.
- Tasks 2 and 3 should run sequentially because the restore API depends on the model.
- Task 4 should run after Task 3 because it validates the concrete router behavior.
- Task 5 should run after the public API shape is final.
- Task 6 should run last and must not be skipped.
