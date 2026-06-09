# Restoration Examples

Learn the ready-to-use restoration workflow from setup to replay.

## Overview

Restoration in `ACRouting` is intent-driven. Your app stores serializable payloads, and your resolver rebuilds views from those payloads when the stack is restored. The package never serializes `RouterView`, `AnyDestination`, SwiftUI views, closures, routed sheets, overlays, alerts, tabs, windows, or cross-context state.

Use closure-based routing for immediate screens that do not need restoration. Use intent-based routing for destinations that need a stable app-owned identity across launches.

## Configure A Store

Use ``UserDefaultsRoutingRestorationStore`` when local JSON persistence is enough:

```swift
let store = UserDefaultsRoutingRestorationStore<AppRoute>(
    key: "main-route-stack"
)

let restoration = RoutingRestorationController(
    payloadSchemaVersion: 1,
    resolverPolicyVersion: 1,
    contextID: "main",
    store: store
)
```

Use a custom ``RoutingRestorationStore`` when you need files, SwiftData, Core Data, Keychain, CloudKit, encryption, or server sync:

```swift
final class SeededRouteStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    private var state: RoutingRestorationState<Payload>?

    init(seed: RoutingRestorationState<Payload>? = nil) {
        state = seed
    }

    func load() throws -> RoutingRestorationState<Payload>? {
        state
    }

    func save(_ state: RoutingRestorationState<Payload>) throws {
        self.state = state
    }

    func clear() throws {
        state = nil
    }
}
```

This shape is useful for tests, encrypted stores that hydrate on launch, or apps that seed an initial route from a server response before local persistence takes over.

## Present A Restorable Push

Route through ``Router/showScreen(_:using:restoration:)`` when a screen should become part of the restorable push stack:

```swift
try router.showScreen(
    RoutedNavigationIntent(payload: AppRoute.detail(id: 42)),
    using: AppRouteResolver(builder: builder),
    restoration: restoration
)
```

The controller records the intent only after the resolver accepts the payload and chooses `.push`. Unsupported payloads are not saved. Payloads that resolve to `.sheet` or `.fullScreenCover` may still present, but they are transient for `v1.6.0` restoration.

Routed sheet and full-screen restoration is a future design area because those presentations create a new routed context with its own possible push stack.

## Record Stack Mutations

When a restorable flow pops, dismisses a pushed screen, or returns to root, keep the controller in sync:

```swift
try router.pop(restoration: restoration)
try router.pop(count: 2, restoration: restoration)
try router.dismissScreen(restoration: restoration)
try router.popToRoot(restoration: restoration)
```

If you call the base router methods directly, record the matching mutation explicitly:

```swift
router.pop()
try restoration.recordPop()

router.popToRoot()
try restoration.recordPopToRoot()
```

## Restore On Flow Start

Load and replay the stored state when the app creates the routed flow:

```swift
let result = try restoration.restoreLoadedState(
    on: router,
    using: AppRouteResolver(builder: builder)
)
```

If restoration stops early because a payload is unsupported or resolves to a non-push presentation, the controller synchronizes itself to the entries that were actually restored.

If the follow-up save fails, the controller restores its previous tracked intents and rethrows. The router pushes that already happened during replay remain visible, so app code should treat restoration persistence as a state-tracking boundary rather than a UI transaction.

For versioning and discard decisions, see <doc:RestorationCompatibility>.

## Preview Catalog

The internal preview catalog includes a Restoration demo in `Sources/ACRouting/Previews/ACRoutingPreviewCatalog.swift`. It uses a preview-only in-memory store so you can inspect the call sites without writing to real app defaults.
