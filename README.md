# ACRouting

A lightweight SwiftUI navigation and routing library for iOS and macOS, built on top of `NavigationStack`.

## Features

- Stack-based navigation with type-safe destinations
- Sheet, full-screen cover, and modal presentation
- Built-in alert management (`AnyAppAlert`)
- Composable `RouterView` for easy integration
- Swift 6 concurrency support

## Requirements

- iOS 16.0+
- macOS 10.15+
- Swift 6.2+

## Installation

### Swift Package Manager

Add ACRouting to your project via Xcode (**File → Add Package Dependencies…**) or directly in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/antoniocasto/ACRouting.git", from: "1.1.0")
]
```

## Usage

Wrap your root view with `RouterView`, then use the injected `Router` to navigate:

```swift
import ACRouting

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RouterView { _ in
                ContentView()
            }
        }
    }
}
```

Push destinations, present sheets or full-screen covers, and show alerts:

```swift
// Push a destination onto the navigation stack
router.push(MyDestination.detail)

// Present a sheet
router.presentSheet(MyDestination.settings)

// Present a full-screen cover
router.presentFullScreenCover(MyDestination.onboarding)

// Show an alert
router.showAlert(.init(
    title: "Error",
    subtitle: "Something went wrong.",
    buttons: nil
))
```

## Credits

This package was built while following the **SwiftUI Advanced Architectures** course by [Nick Sarno](https://github.com/SwiftfulThinking).

- YouTube: [@SwiftfulThinking](https://www.youtube.com/@SwiftfulThinking)
- Course: SwiftUI Advanced Architectures

## License

ACRouting is available under the MIT License. See [LICENSE.md](LICENSE.md) for details.
