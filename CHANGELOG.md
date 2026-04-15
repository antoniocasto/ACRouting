# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Explicit push stack APIs: `pop()`, `pop(count:)`, and `popToRoot()`.
- Additive ancestor modal dismissal API: `dismissAncestorModal()`.
- Behavior-level router tests that verify inherited push stack mutation.
- Additional regression tests that lock down protocol default forwarding, inherited stack preservation, and pushed-screen dismissal semantics.
- A debug-only SwiftUI preview catalog for local Xcode exploration of push, modal, overlay, and mixed routing flows.

### Changed

- Pushed child routers now mutate the inherited stack deterministically instead of relying on the old empty-stack ownership heuristic.
- `dismissScreen()` now uses explicit pop behavior for pushed destinations while keeping modal dismissal behavior intact.
- Pushed child flows inside routed sheets and full-screen covers can now dismiss their first ancestor modal explicitly through `dismissAncestorModal()`.
- `RouterView` now exposes a role-specific public initializer for owned navigation contexts, while inherited push-stack wiring stays internal to the package.
- Internal documentation comments, helper naming, and supporting model terminology were clarified across the routing core.
- README and roadmap guidance were aligned with the current routing behavior, current limitations, and the local preview catalog.
- `showModal` now uses a consistent default animation of `.smooth` across the protocol extension and the concrete router implementation.
- Local planning artifacts under `docs/plans/` are now ignored by Git.

## [1.3.1] - 2026-04-06

### Added

- Package logo assets and README branding.
- A project roadmap document for the routing package.

### Changed

- Documentation and platform notes were refined for the `1.3.1` release.
- Roadmap versioning was aligned after the `1.3.0` release.

### Fixed

- Swift test compatibility on macOS.

## [1.3.0] - 2026-03-18

### Added

- CI workflow with a required test gate for `main`.

### Fixed

- Xcode `26.2` compatibility for Swift tools `6.2`.

## [1.2.0] - 2026-03-18

### Added

- A comprehensive automated test suite for the package.

## [1.1.0] - 2026-03-18

### Added

- A more complete README with usage guidance and project credits.

## [1.0.1] - 2026-02-27

### Added

- README usage examples.

## [1.0.0] - 2026-02-27

### Added

- Initial Swift Package setup for `ACRouting`.
- Public routing APIs for package consumers.
- Default button closure support for alerts.

### Changed

- Routing transitions now use type-erased `AnyTransition` values.

### Fixed

- `@MainActor` and isolation conformance issues in the initial package setup.
- Missing buttons for error alerts.
