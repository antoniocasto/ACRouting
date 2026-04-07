# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
