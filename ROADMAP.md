# ROADMAP

## Goal

Make `ACRouting` a dependable SwiftUI navigation package for production apps, with predictable state, typed routes, and first-class support for real app flows such as deep links, modal stacks, and testable navigation.

## Current Assessment

### What already works well

- A single `Router` API keeps navigation concerns out of feature views.
- `RouterView` re-wraps destinations so routing stays available across pushes and modal flows.
- The package already covers the most common presentation styles: push, sheet, full screen, alert, and custom modal.

### Current gaps to address first

- Push dismissal is not fully state-driven because `dismissScreen()` relies on SwiftUI dismissal rather than explicit stack mutation.
- The navigation stack stores `AnyDestination`, which makes the API flexible but limits deep linking, restoration, and stronger compile-time guarantees.
- The package manifest advertises `macOS 10.15`, while the implementation uses newer SwiftUI navigation APIs.
- Tests mostly validate callability and simple model behavior, but not real navigation state transitions across full flows.

## Priorities

### 1. Stabilize the Navigation Core

Priority: High

- Make push navigation fully state-driven by introducing explicit pop operations such as `pop()`, `popToRoot()`, and `popTo(count:)`.
- Separate modal dismissal from stack mutation so push, sheet, full screen, and overlay lifecycle remain deterministic.
- Clarify ownership of navigation state between root and child routers to avoid hidden behavior tied to `screenStack.isEmpty`.

Why it matters:
Deterministic state is the foundation for reliable SwiftUI navigation, better testing, and future deep-link support.

### 2. Introduce Typed Routing

Priority: High

- Add a typed route model, for example `Route: Hashable`, alongside or above the current `AnyDestination` approach.
- Support `navigationDestination(for:)` with route values instead of relying only on wrapped destination views.
- Consider a route registry or destination builder that maps route values to views in one place.

Why it matters:
Typed routes improve compiler safety, make large apps easier to reason about, and unlock serialization and restoration scenarios.

### 3. Deep Linking and State Restoration

Priority: High

- Add APIs to build a stack from route values or URL payloads.
- Support opening nested flows directly into push and modal contexts.
- Explore state restoration so apps can rebuild the current navigation stack after relaunch.

Why it matters:
Packages focused on navigation become much more valuable once they can restore and reconstruct user flows.

### 4. Strengthen Modal Navigation

Priority: Medium

- Define clearer behavior for nested sheets, fullscreen flows, and custom overlays.
- Decide whether multiple modal layers are intentionally supported and document the rules.
- Add coordination rules for modal-to-push and push-to-modal transitions within the same routed feature.

Why it matters:
SwiftUI apps often mix stack and modal navigation, and packages become fragile when those rules are implicit.

### 5. Improve Public API Ergonomics

Priority: Medium

- Add convenience APIs for common cases, such as route-based navigation without passing view builders everywhere.
- Review naming around `showScreen` and `SegueOption` to ensure the API reads naturally in SwiftUI codebases.
- Consider environment helpers and preview-safe diagnostics for missing router injection.

Why it matters:
A routing package succeeds when feature code stays small, obvious, and difficult to misuse.

### 6. Expand Test Coverage Around Real Navigation Behavior

Priority: High

- Add tests that verify stack mutation for push/pop behavior instead of only smoke-testing method calls.
- Cover modal lifecycle behavior, including show and dismiss transitions.
- Add regression tests for mixed flows such as push -> sheet -> push -> dismiss.
- Add tests for typed routes and deep-link reconstruction once those APIs exist.

Why it matters:
Navigation regressions are expensive and often subtle, so confidence depends on behavior-level tests.

### 7. Align Platform Support and Package Metadata

Priority: Medium

- Raise the macOS deployment target to match the SwiftUI APIs used, or add compatibility shims if older support is truly required.
- Document platform guarantees explicitly in the README and release notes.
- Prepare semantic versioning guidance for navigation API changes.

Why it matters:
Incorrect platform metadata makes adoption riskier and creates avoidable integration failures.

### 8. Ship Better Examples and Documentation

Priority: Medium

- Add example flows for authentication, tab-root navigation, deep links, and modal subflows.
- Document architectural guidance for when to use environment injection versus explicit router passing.
- Add migration notes for teams moving from direct `NavigationStack` management to `ACRouting`.

Why it matters:
Navigation libraries are adopted through confidence and examples, not just through API surface.

## Suggested Release Sequence

### v1.2

- Fix platform metadata mismatch.
- Add explicit pop APIs.
- Add behavior-level tests for push and dismiss flows.
- Document current routing rules more clearly.

### v1.3

- Introduce typed routes in an additive way.
- Add route-to-view registration.
- Add initial deep-link entry points.

### v1.4

- Add restoration support.
- Expand modal coordination rules.
- Publish a sample app with realistic navigation flows.

## Non-Goals for Now

- Rebuilding the package around a global app store before the routing core is deterministic.
- Adding UIKit bridging unless a concrete integration requirement appears.
- Supporting legacy Apple platform versions that do not match the SwiftUI APIs already used.
