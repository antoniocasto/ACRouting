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
