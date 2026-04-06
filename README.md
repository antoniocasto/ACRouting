# ACRouting

`ACRouting` is a SwiftUI-first routing package built to keep navigation concerns
out of feature views and centralize transitions behind a single `Router` API.

## Why ACRouting

- Single routing abstraction for push, sheet, full screen, alert, and custom modal.
- No direct `NavigationStack` management inside feature screens.
- Router access can be done via environment injection or explicit dependency
  passing.
- Presented destinations are wrapped in `RouterView` so routing remains available
  at every level.

## Platform and Tooling

- Swift tools: `6.2`
- Supported Apple platforms:
  - iOS `16+`
  - macOS `13+`

Notes:
- The package manifest matches the SwiftUI navigation APIs used by the current implementation.
- `showScreen(.fullScreenCover)` uses the native full-screen presentation on iOS.
- On macOS, SwiftUI does not expose `fullScreenCover`, so the package intentionally falls back to `.sheet` while keeping the same public API.

## Installation

### Xcode

1. Open `File > Add Package Dependencies...`
2. Use: `https://github.com/antoniocasto/ACRouting.git`
3. Pick your branch/tag/version.

### `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/antoniocasto/ACRouting.git", from: "1.3.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "ACRouting", package: "ACRouting")
        ]
    )
]
```

## Quick Start

### 1) Wrap your root view with `RouterView`

```swift
import SwiftUI
import ACRouting

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView { _ in
                HomeView()
            }
        }
    }
}
```

### 2) Pick your router access style

Environment injection is supported and convenient, but not mandatory.

#### Option A: Environment (`@Environment(\.router)`)

```swift
import SwiftUI
import ACRouting

struct HomeView: View {
    @Environment(\.router) private var router

    var body: some View {
        VStack(spacing: 12) {
            Button("Push detail") {
                router.showScreen(.push) { _ in
                    DetailView()
                }
            }

            Button("Open sheet") {
                router.showScreen(.sheet) { _ in
                    SheetRootView()
                }
            }

            Button("Open full screen") {
                router.showScreen(.fullScreenCover) { _ in
                    FullScreenRootView()
                }
            }
        }
    }
}
```

#### Option B: Explicit dependency passing

```swift
import SwiftUI
import ACRouting

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView { router in
                HomeView(router: router)
            }
        }
    }
}

struct HomeView: View {
    private let router: any Router

    init(router: any Router) {
        self.router = router
    }

    var body: some View {
        Button("Push detail") {
            router.showScreen(.push) { _ in
                DetailView()
            }
        }
    }
}
```

### 3) Dismiss current context

```swift
@Environment(\.router) private var router

Button("Close") {
    router.dismissScreen()
}
```

Current behavior:
- In a pushed destination, `dismissScreen()` asks SwiftUI to dismiss the current navigation context.
- In a sheet or full-screen flow, it dismisses the presented modal context.
- `1.3.x` does not yet expose explicit stack APIs such as `pop()` or `popToRoot()`.

## Routing Options

- `.push`: appends to the current stack.
- `.sheet`: presents a new modal navigation context with its own routed flow.
- `.fullScreenCover`: presents a fullscreen modal navigation context on iOS and a sheet-backed equivalent on macOS.

## Alerts

Examples below assume you already have a `router` instance (from either option above).

```swift
@Environment(\.router) private var router

router.showAlert(
    .alert,
    title: "Delete item",
    subtitle: "This action cannot be undone."
) {
    AnyView(
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {}
        }
    )
}
```

Error shortcut:

```swift
router.showErrorAlert(error: myError)
```

Dismiss current alert:

```swift
router.dismissAlert()
```

## Custom Overlay Modal

```swift
router.showModal(
    backgroundColor: .black.opacity(0.5),
    backgroundTransition: .opacity,
    animation: .easeInOut,
    backgroundTapDismissesModal: true
) {
    MyCustomModalView()
}
```

Dismiss:

```swift
router.dismissModal()
```

## Architecture Notes

- `RouterView` is both a `View` and a `Router`.
- Child destinations are wrapped again in `RouterView`, so every screen still has
  access to a router.
- Push navigation uses a shared destination stack where appropriate.
- Sheet/fullscreen routes create a fresh navigation context for the presented
  flow.

## Current Routing Model

- Navigation state is currently stored as `AnyDestination`, which wraps concrete SwiftUI views.
- The package is designed to keep routing available across pushes and modal flows, not to model routes as typed values yet.
- `dismissScreen()` currently relies on SwiftUI dismissal semantics rather than explicit stack mutation.
- If a view reads `@Environment(\.router)` outside `RouterView`, the default fallback is a `MockRouter` that avoids crashes but does not perform real navigation.

## Development

```bash
swift build
swift test
```

## Credits

This package was built while following the **SwiftUI Advanced Architectures** course by [Nick Sarno](https://github.com/SwiftfulThinking).

- YouTube: [@SwiftfulThinking](https://www.youtube.com/@SwiftfulThinking)
- Course: SwiftUI Advanced Architectures

## License

MIT. See [LICENSE.md](LICENSE.md).
