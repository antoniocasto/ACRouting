# Builder-First Integration

Keep screen assembly in your app while letting `ACRouting` own navigation behavior.

## Overview

`ACRouting` works well when views know only about an app-owned routing interface instead of the package router directly.

That integration usually looks like this:

1. A flow root creates a ``RouterView``.
2. The root builds an app-owned router adapter from the injected ``Router``.
3. A builder or factory assembles the feature screen and receives that app-owned adapter.
4. When the feature wants to navigate, the adapter decides which builder method to call and which `ACRouting` command to use.

This keeps the package architecture-agnostic. `ACRouting` does not need to know about your modules, feature graph, or screen dependencies.

## Example

```swift
import SwiftUI
import ACRouting

protocol CatalogRouting {
    func showProfile(userID: UUID)
    func showSettings()
}

struct CatalogBuilder {
    func makeHomeScreen(router: any CatalogRouting) -> some View {
        CatalogHomeView(router: router)
    }

    func makeProfileScreen(userID: UUID, router: any CatalogRouting) -> some View {
        ProfileView(userID: userID, router: router)
    }

    func makeSettingsScreen(router: any CatalogRouting) -> some View {
        SettingsView(router: router)
    }
}

struct CatalogRouterAdapter: CatalogRouting {
    let acRouter: any Router
    let builder: CatalogBuilder

    func showProfile(userID: UUID) {
        acRouter.showScreen(.push) { router in
            let featureRouter = CatalogRouterAdapter(acRouter: router, builder: builder)
            builder.makeProfileScreen(userID: userID, router: featureRouter)
        }
    }

    func showSettings() {
        acRouter.showScreen(.sheet) { router in
            let featureRouter = CatalogRouterAdapter(acRouter: router, builder: builder)
            builder.makeSettingsScreen(router: featureRouter)
        }
    }
}

struct AppRoot: View {
    private let builder = CatalogBuilder()

    var body: some View {
        RouterView { router in
            let featureRouter = CatalogRouterAdapter(acRouter: router, builder: builder)
            builder.makeHomeScreen(router: featureRouter)
        }
    }
}
```

## Why This Pattern Works

- The feature screen depends on a domain-specific routing interface instead of on package details.
- The builder stays responsible for constructing screens and dependencies.
- ``Router/showScreen(_:destination:)`` still receives the `Router` for the new routed context, so the adapter can recreate itself for the next screen.
- Push, sheet, full-screen, alert, and overlay semantics remain centralized in `ACRouting`.

## When To Skip The Adapter

Small flows can use ``Router`` directly if that is simpler. The package supports both patterns:

- direct environment access through ``EnvironmentValues/router``
- explicit dependency passing of ``Router``
- app-owned adapters layered on top of ``Router``

Choose the smallest approach that still preserves the composition boundaries your app needs.
