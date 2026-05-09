# v1.6.0 Ready-to-Use Restoration Design

## Decision

`v1.6.0` should ship restoration as a usable feature, not only as a low-level foundation. `ACRouting` will keep the existing intent-based restoration core, then add:

- a storage abstraction for restoration persistence;
- a built-in `UserDefaults` store adapter;
- an intent-stack controller that keeps app-owned payload history in sync with restorable navigation actions;
- convenience APIs that present, track, persist, load, restore, and clear a single routed push stack.

The restoration system remains intent-driven. `ACRouting` will not attempt to serialize SwiftUI views, `AnyDestination`, closures, feature builders, tabs, scenes, alerts, overlays, sheets, or full-screen routed modal contexts.

## Product Goal

An app developer should be able to make one `RouterView` push stack restorable with a small amount of setup:

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

try router.showScreen(
    RoutedNavigationIntent(payload: .detail(id: 42)),
    using: AppRouteResolver(builder: builder),
    restoration: restoration
)
```

On launch or flow creation, the app can load and replay:

```swift
let result = try restoration.restoreLoadedState(
    on: router,
    using: AppRouteResolver(builder: builder)
)
```

## Storage Abstraction

Introduce a public protocol for storage backends:

```swift
public protocol RoutingRestorationStore<Payload> {
    associatedtype Payload: Codable & Hashable & Sendable

    func load() throws -> RoutingRestorationState<Payload>?
    func save(_ state: RoutingRestorationState<Payload>) throws
    func clear() throws
}
```

The protocol is intentionally small. It stores complete restoration envelopes rather than individual entries so custom adapters can use any persistence technology: files, SwiftData, Core Data, Keychain, CloudKit, server sync, encrypted storage, or test memory stores.

## UserDefaults Adapter

Provide a ready-to-use store:

```swift
public struct UserDefaultsRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable
```

Configuration:

- `key: String`
- `userDefaults: UserDefaults = .standard`
- `encoder: JSONEncoder = JSONEncoder()`
- `decoder: JSONDecoder = JSONDecoder()`

Behavior:

- `save(_:)` encodes the state as JSON data and stores it under the key.
- `load()` returns `nil` when no data exists.
- `load()` throws a typed restoration storage error when stored data cannot decode.
- `clear()` removes the key.

The adapter lives in the main `ACRouting` target because `UserDefaults` is Foundation-level and does not add a heavy dependency or platform-specific framework beyond what the package already uses.

## Restoration Controller

Introduce a public controller that owns the current restorable intent stack:

```swift
@MainActor
public final class RoutingRestorationController<Payload>
where Payload: Codable & Hashable & Sendable
```

The controller is generic only over `Payload`. Its initializer accepts any matching store and type-erases that store internally so call sites do not need to carry the store type:

```swift
public init<Store>(
    payloadSchemaVersion: Int,
    resolverPolicyVersion: Int,
    contextID: String? = nil,
    store: Store
) where Store: RoutingRestorationStore, Store.Payload == Payload
```

Responsibilities:

- keep an ordered `[RoutedNavigationIntent<Payload>]` for the current routed push stack;
- expose the tracked intents for inspection without exposing mutable storage;
- produce `RoutingRestorationState<Payload>`;
- save the current state through a store;
- load a state through a store;
- restore a loaded state using `Router.restore(_:using:)`;
- synchronize the tracked stack to the entries actually restored when restoration stops early;
- append an intent only after successful `.push` presentation;
- remove the last tracked intent when the app explicitly records a pop or dismiss;
- clear tracked state when the app explicitly records `popToRoot()`.

The controller will not observe arbitrary `RouterView` mutations automatically in `v1.6.0`. Automatic observation would require coupling `RouterView` path mutation to payload identity and would be unreliable for closure-built destinations. Instead, the controller supports an official restorable workflow: navigation that should be restored must go through restorable intent APIs.

## Convenience Router APIs

Add Router extension helpers that follow the existing `Router` verb style and use a `restoration:` label for the restorable variant:

```swift
@discardableResult
func showScreen<Resolver>(
    _ intent: RoutedNavigationIntent<Resolver.Payload>,
    using resolver: Resolver,
    restoration: RoutingRestorationController<Resolver.Payload>
) throws -> RoutedNavigationResolution<Resolver.Payload>
where Resolver: RoutedNavigationIntentResolving
```

Expected behavior:

- inspect the resolver presentation before presenting;
- call the existing `showScreen(_:using:)`;
- if the result is `.presented(intent)` and the presentation is `.push`, append and save through the controller;
- if the resolver rejects the payload, do not track or save;
- if the resolver chooses `.sheet` or `.fullScreenCover`, do not track it as part of the current push-stack restoration scope.

The helper should be explicit about `throws` because persistence can fail. It may still present non-push routes for compatibility with resolver behavior, but those routes are transient from the restoration controller's point of view. The non-restorable `showScreen(_:using:)` remains available for transient navigation.

## Pop And Clear Tracking

Restoration cannot infer all stack changes from arbitrary router calls without coupling payload state to `AnyDestination`. Provide explicit controller APIs:

```swift
func recordPop() throws
func recordPop(count: Int) throws
func recordPopToRoot() throws
func recordDismissScreen() throws
```

These APIs update the tracked intent stack and save it. Documentation should show calling them next to matching router commands:

```swift
router.pop()
try restoration.recordPop()
```

This is intentionally explicit for `v1.6.0`. A later release can explore wrappers that combine `router.pop()` and `recordPop()` if real integrations show the pattern is too noisy.

## Error Model

Introduce a small public error enum:

```swift
public enum RoutingRestorationStorageError: Error, Equatable, Sendable {
    case encodingFailed
    case decodingFailed
}
```

The `UserDefaults` store can wrap underlying encoder/decoder failures without exposing unstable error payloads. Tests can assert deterministic error categories.

## Testing

Add coverage for:

- memory-backed custom store conformance in tests;
- `UserDefaultsRoutingRestorationStore` save/load/clear round-trip using an isolated suite name;
- decode failure when `UserDefaults` contains invalid data;
- controller appends only after supported push presentation;
- controller does not append unsupported payloads;
- controller does not append `.sheet` or `.fullScreenCover`;
- controller records pop, pop count, dismiss, and pop-to-root;
- controller exports `RoutingRestorationState` with correct metadata;
- controller restores loaded state through concrete router behavior;
- public examples compile against the intended APIs.

## Documentation

Update the existing restoration docs so the primary path is ready-to-use:

1. Create a `UserDefaultsRoutingRestorationStore`.
2. Create a `RoutingRestorationController`.
3. Navigate with `showScreen(_:using:restoration:)`.
4. Record explicit stack mutations when using `pop`, `dismissScreen`, or `popToRoot`.
5. Restore loaded state on app/flow start.

The docs must keep the core boundary clear: apps can replace the store, but restorable navigation is still intent-driven.

## Deferred

Not part of `v1.6.0`:

- automatic export of `RouterView` state;
- automatic observation of every `Router` command;
- serializing closure-built destinations or `AnyDestination`;
- restoring sheets, full-screen covers, overlays, alerts, confirmation dialogs, tabs, scenes, windows, or multiple independent `RouterView` roots;
- migrations beyond exposing app-owned payload schema and resolver policy versions in the envelope.
