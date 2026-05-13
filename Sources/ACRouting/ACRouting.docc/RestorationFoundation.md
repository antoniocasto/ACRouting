# Ready-To-Use Restoration

Persist, track, and restore a single routed push stack from app-owned navigation payloads.

## Overview

`ACRouting` restoration is built on ``RoutedNavigationIntent``. The package stores no views, builders, presenters, interactors, or type-erased destinations in the restoration envelope. Your app provides serializable route payloads and a resolver, while ``RoutingRestorationController`` keeps the current restorable push stack in sync with an app-selected ``RoutingRestorationStore``.

The closure-based API remains fully supported for immediate navigation, but it is not restorable by itself. A call such as `showScreen(.push) { DetailView(id: 42) }` builds a destination now without giving `ACRouting` a stable payload to persist. Model restorable destinations as intent payloads when they need to survive relaunch.

For a step-by-step integration walkthrough and catalog guidance, see <doc:RestorationExamples>.

## Configure Storage

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

Use ``UserDefaultsRoutingRestorationStore`` for simple local persistence, or implement ``RoutingRestorationStore`` when an app needs files, SwiftData, Core Data, Keychain, CloudKit, encrypted storage, or server sync.

## Present Restorable Pushes

```swift
try router.showScreen(
    RoutedNavigationIntent(payload: AppRoute.detail(id: 42)),
    using: AppRouteResolver(builder: builder),
    restoration: restoration
)
```

``Router/showScreen(_:using:restoration:)`` presents through the same resolver-based API as ``Router/showScreen(_:using:)``. It records and saves the intent only after a supported `.push` presentation. Unsupported payloads and non-push presentations are not tracked in the current push-stack restoration scope.

## Restore State

```swift
let result = try restoration.restoreLoadedState(
    on: router,
    using: AppRouteResolver(builder: builder)
)
```

If restoration stops on an unsupported payload or non-push presentation, the controller synchronizes its tracked stack to only the entries that were actually restored.

## Record Explicit Mutations

When code uses non-restorable router commands directly, record the matching stack change:

```swift
router.pop()
try restoration.recordPop()

router.dismissScreen()
try restoration.recordDismissScreen()

router.popToRoot()
try restoration.recordPopToRoot()
```

The router helpers combine both operations when that is more convenient:

```swift
try router.pop(restoration: restoration)
try router.pop(count: 2, restoration: restoration)
try router.dismissScreen(restoration: restoration)
try router.popToRoot(restoration: restoration)
```

## Scope

`v1.6.0` restores push entries inside one routed context. If an entry resolves to `.sheet` or `.fullScreenCover`, restoration stops and returns ``RoutingRestorationResult/unsupportedPresentation(_:presentation:restored:)``.

`ACRouting` does not serialize `RouterView`, `AnyDestination`, closures, sheets, full-screen covers, overlays, alerts, tabs, windows, scenes, or cross-context state in this release.

Future routed sheet or full-screen restoration needs a nested routed-context envelope: the modal presentation itself has identity, and the presented flow may also have its own push stack. Overlay and alert restoration remain separate non-goals unless a future design proves they need persisted navigation state.
