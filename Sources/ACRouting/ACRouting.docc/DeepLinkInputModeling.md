# Deep-Link Input Modeling

Model deep-link requests as serializable app-owned payloads, then resolve those payloads through app-owned builders.

## Overview

`ACRouting` keeps screen assembly outside the package. A routed intent stores only the app-owned payload:

```swift
enum AppRoute: Codable, Hashable, Sendable {
    case detail(id: Int)
    case settings
}

let intent = RoutedNavigationIntent(payload: AppRoute.detail(id: 42))
```

Your app provides a resolver that decides whether the payload is supported, how it should be presented, and what destination to build for the routed context:

```swift
struct AppRouteResolver: RoutedNavigationIntentResolving {
    let builder: AppFeatureBuilder

    func canResolve(_ payload: AppRoute) -> Bool {
        switch payload {
        case .detail, .settings:
            true
        }
    }

    func presentation(for payload: AppRoute) -> SegueOption {
        switch payload {
        case .detail:
            .push
        case .settings:
            .sheet
        }
    }

    func destination(for payload: AppRoute, router: any Router) -> some View {
        switch payload {
        case .detail(let id):
            builder.makeDetail(id: id, router: AppFeatureRouter(router: router, builder: builder))
        case .settings:
            builder.makeSettings(router: AppFeatureRouter(router: router, builder: builder))
        }
    }
}
```

Then present the intent through the current router with ``Router/showScreen(_:using:)``:

```swift
let result = router.showScreen(intent, using: AppRouteResolver(builder: builder))
```

If the resolver rejects the payload, the router returns `.unsupported(intent)` and does not present anything.

## Boundaries

- `RoutedNavigationIntent` payloads must conform to `Codable`, `Hashable`, and `Sendable`.
- Presentation style selection belongs to the app-owned resolver.
- `ACRouting` does not decode URLs directly.
- `ACRouting` does not own a global route registry.
- `ACRouting` does not persist or restore navigation state in `v1.5.0`.
- Multi-step restoration remains future work after the deep-link payload boundary is stable.
