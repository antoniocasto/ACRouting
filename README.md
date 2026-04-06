<p align="center">
  <img src="Assets/Brand/acrouting-logo.png" alt="ACRouting logo" width="180">
</p>

# ACRouting

<p align="center">
  SwiftUI-first routing package for predictable navigation flows.
</p>

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
- iOS: `16+`
- macOS target in manifest: `10.15`

Note: the current implementation uses APIs such as `NavigationStack` and
`dismiss` that require newer macOS versions at compile time.

## Installation

### Xcode

1. Open `File > Add Package Dependencies...`
2. Use: `https://github.com/antoniocasto/ACRouting.git`
3. Pick your branch/tag/version.

### `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/antoniocasto/ACRouting.git", from: "1.1.0")
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

## Routing Options

- `.push`: appends to the current stack.
- `.sheet`: presents a new modal navigation context.
- `.fullScreenCover`: presents a fullscreen modal navigation context.

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
