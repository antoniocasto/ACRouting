# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Added source-compatible `Router` overloads for typed alert actions, error-alert actions, confirmation dialogs, and `@ViewBuilder` overlay content.

### Changed

- Updated README, DocC, and preview catalog examples to prefer typed builder call sites over manual `AnyView` wrapping.

## [1.5.2] - 2026-05-02

### Changed

- Hardened CI to run for pull requests and pushes targeting both `develop` and `main`.
- Replaced `xcpretty`-dependent workflow steps with raw `xcodebuild` output and separate iOS/macOS result bundles.
- Added real iOS simulator test execution alongside the existing macOS test lane.
- Clarified concrete `RouterView.showModal` overlay builder timing in README and DocC.
- Added a future `v1.5.3` roadmap note for additive API ergonomics around overlays and alert actions.

### Fixed

- Removed fragile hash-value distinctness coverage in favor of identity/equality-based assertions.
- Added coverage that characterizes concrete `RouterView.showModal` overlay builder evaluation.
- Removed maintainer-only hosted documentation setup notes from the public repository surface.

## [1.5.1] - 2026-04-29

### Fixed

- Clarified VIPER/RIB deep-link examples so app-owned router adapters sit at the resolver boundary instead of exposing `ACRouting` through feature presenters or interactors.
- Refined roadmap test guidance to separate current deep-link intent coverage from future stack reconstruction coverage.

## [1.5.0] - 2026-04-29

### Added

- Serializable routed navigation intent models for deep-link input handoff.
- An app-owned resolver protocol and router convenience API for selecting presentation styles and presenting supported typed navigation payloads.
- Documentation for deep-link input modeling boundaries in `v1.5.0`.

## [1.4.4] - 2026-04-21

### Added

- A regression test that verifies app-owned router adapters use the destination router context for follow-up navigation after a builder-assembled push.

### Fixed

- Stabilized the GitHub Actions CI destination so the workflow no longer depends on a specific simulator device being installed on the runner.
- Corrected the README docs-hosting link to use a repository-relative path instead of a local machine path.
- Aligned the roadmap's current assessment with the already-released `1.4.3` builder-first documentation, diagnostics, and tests.

## [1.4.3] - 2026-04-19

### Added

- A builder-first README example that shows app-owned screen assembly through a router adapter layered on top of `ACRouting`.
- A preview-catalog demo that illustrates builder-owned screen assembly without turning `ACRouting` into a screen factory.
- A DocC catalog for the package with module overview, builder-first integration guidance, and presentation-semantics documentation.
- A GitHub Pages workflow that builds and deploys the DocC catalog from `main`.
- Regression tests for builder-assembled push, sheet, full-screen, and overlay flows plus independent router-context stack isolation.

### Changed

- `MockRouter` now emits actionable debug diagnostics explaining how to inject a real router when `@Environment(\.router)` is read outside `RouterView`.
- README guidance and the internal preview catalog now treat builder-owned screen assembly as the default integration model for larger apps.
- The repository now documents the one-time GitHub Pages and DNS setup needed to publish the DocC site at `https://acrouting.acasto.dev`.
- The hosted DocC homepage now surfaces the current package version and the README credits directly in the published documentation.
- The README now links more explicitly to the public documentation site at `https://acrouting.acasto.dev`.

## [1.4.2] - 2026-04-15

### Added

- Explicit push stack APIs: `pop()`, `pop(count:)`, and `popToRoot()`.
- Additive ancestor modal dismissal API: `dismissAncestorModal()`.
- Behavior-level router tests that verify inherited push stack mutation.
- Additional regression tests that lock down protocol default forwarding, inherited stack preservation, and pushed-screen dismissal semantics.
- A debug-only SwiftUI preview catalog for local Xcode exploration of push, modal, overlay, and mixed routing flows.
- Explicit documentation for the modal layering combinations and current limits supported in `v1.4.2`.

### Changed

- Pushed child routers now mutate the inherited stack deterministically instead of relying on the old empty-stack ownership heuristic.
- `dismissScreen()` now uses explicit pop behavior for pushed destinations while keeping modal dismissal behavior intact.
- Pushed child flows inside routed sheets and full-screen covers can now dismiss their first ancestor modal explicitly through `dismissAncestorModal()`.
- `RouterView` now exposes a role-specific public initializer for owned navigation contexts, while inherited push-stack wiring stays internal to the package.
- Internal documentation comments, helper naming, and supporting model terminology were clarified across the routing core.
- README and roadmap guidance were aligned with the current routing behavior, current limitations, and the local preview catalog.
- `showModal` now uses a consistent default animation of `.smooth` across the protocol extension and the concrete router implementation.
- Routed `.sheet` and `.fullScreenCover` remain the only first-class routed modal containers in `v1.4.2`; `showModal` stays an overlay-only mechanism.
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
