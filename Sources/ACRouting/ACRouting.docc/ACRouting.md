# ``ACRouting``

Build predictable SwiftUI navigation flows while keeping screen assembly in your application.

## Overview

`ACRouting` is a small SwiftUI routing package centered on two public entry points:

- ``RouterView`` owns the routing runtime for one flow.
- ``Router`` exposes navigation commands to the screens inside that flow.

## Current Package Version

The currently documented public package release is `1.5.2`.

The hosted documentation at [acrouting.acasto.dev](https://acrouting.acasto.dev) is published from `main`, while this version marker reflects the latest tagged package release that includes the current public API surface.

The package intentionally separates responsibilities:

- `ACRouting` owns navigation state, push semantics, routed modal presentation, overlays, and alert state.
- Your app remains free to assemble screens through builders, factories, or composition-root logic.

This makes the package a good fit for both small SwiftUI apps and larger codebases that want explicit composition boundaries.

## Credits

This package was built while following the **SwiftUI Advanced Architectures** course by [Nick Sarno](https://github.com/SwiftfulThinking).

- YouTube: [@SwiftfulThinking](https://www.youtube.com/@SwiftfulThinking)
- Course: SwiftUI Advanced Architectures

## Builder-First By Default

The recommended integration model is builder-first:

1. Wrap a flow root in ``RouterView``.
2. Create an app-owned router adapter if the feature should not depend on ``Router`` directly.
3. Let your builder or factory assemble the next screen inside ``Router/showScreen(_:destination:)`` or ``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)``.

`ACRouting` should not become a package-owned screen registry or feature factory. It only turns those app-owned destinations into predictable navigation state.

For a complete example, see <doc:BuilderFirstIntegration>.

## Presentation Model

`ACRouting` supports three routed presentation styles through ``SegueOption``:

- ``SegueOption/push`` continues mutating the current push stack.
- ``SegueOption/sheet`` starts a fresh routed modal flow.
- ``SegueOption/fullScreenCover`` starts a fresh routed full-screen flow on iOS and falls back to a sheet-backed presentation on macOS.

Custom overlays created with ``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)`` are intentionally separate from routed sheet or full-screen flows. They reuse the current router context instead of creating a new one.

For behavior details and supported limits, see <doc:PresentationSemantics>.

## Topics

### Essentials

- ``RouterView``
- ``Router``
- ``SegueOption``
- ``AlertType``

### Navigation Commands

- ``Router/showScreen(_:destination:)``
- ``Router/showScreen(_:using:)``
- ``Router/dismissScreen()``
- ``Router/dismissAncestorModal()``
- ``Router/pop()``
- ``Router/pop(count:)``
- ``Router/popToRoot()``

### Alerts And Overlays

- ``Router/showAlert(_:title:subtitle:buttons:)``
- ``Router/showErrorAlert(error:buttons:)``
- ``Router/dismissAlert()``
- ``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)``
- ``Router/dismissModal()``

### Supporting Types

- ``AnyDestination``
- ``RoutedNavigationIntent``
- ``RoutedNavigationResolution``
- ``RoutedNavigationIntentResolving``
- ``View/any()``
- ``EnvironmentValues/router``

### Articles

- <doc:BuilderFirstIntegration>
- <doc:DeepLinkInputModeling>
- <doc:PresentationSemantics>
