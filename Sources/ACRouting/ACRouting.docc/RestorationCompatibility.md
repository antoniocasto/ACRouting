# Restoration Compatibility

Use restoration metadata to decide whether stored navigation state is still safe to replay.

## Overview

``RoutingRestorationState`` is an `ACRouting` envelope around app-owned navigation payloads. The package owns the envelope format version, while your app owns three compatibility fields:

- `payloadSchemaVersion`: the encoded shape and meaning of your route payloads.
- `resolverPolicyVersion`: the resolver behavior that decides whether a payload is supported and which presentation style it uses.
- `contextID`: the routed root that owns the stored stack, such as a tab, scene, account, or feature root.

Treat these values as replay gates. If a stored state no longer matches the app version, user context, or resolver policy that will rebuild the stack, migrate it before replay or discard it.

## Gate A Stored State

```swift
let state = try restoration.loadState()

guard let state,
      state.payloadSchemaVersion == AppRoute.currentSchemaVersion,
      state.resolverPolicyVersion == AppRouteResolver.currentPolicyVersion,
      state.contextID == "main-tab" else {
    try restoration.clear()
    return
}

let result = router.restore(state, using: AppRouteResolver(builder: builder))
```

Use this pattern when the app wants explicit control before replay. ``RoutingRestorationController/restoreLoadedState(on:using:)`` is still appropriate when the store already contains only compatible state.

## Migrate Or Discard

Payload schema changes are app-owned. If a new app version can map old payloads to new payloads, decode the old state in your store or app migration layer and save a new ``RoutingRestorationState`` before replay.

Resolver policy changes should be treated separately from payload schema changes. A route payload may still decode successfully while a new resolver version no longer supports that screen, changes it from `.push` to `.sheet`, or requires a different account or feature flag. In those cases, discard the stored state or save only the prefix that remains valid for the current resolver policy.

`contextID` prevents replaying a valid stack into the wrong routed root. Use stable values for tabs, scenes, accounts, or feature roots when the same payload type can be restored in more than one context.

## Seed A Custom Store

Custom stores can seed a complete envelope from encrypted storage, a file, a database, or a server-provided route:

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

The store should save and clear complete envelopes. Partial entry updates make version and context checks harder to reason about and can leave stale route data behind.

## Persistence Failures

``RoutingRestorationController`` rolls back its tracked in-memory intent stack if persistence fails after a record, restore, or clear operation. The thrown error is preserved so the app can log, retry, or surface recovery UI.

Router navigation is not transactional. If ``Router/showScreen(_:using:restoration:)`` schedules a push and the store then fails to save, the controller restores its tracked intents to the previous state, but the visible push is not automatically undone. Apps that require strict persistence-before-navigation should run their own persistence preflight before calling the restorable router helper.
