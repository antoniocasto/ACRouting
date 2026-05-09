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
