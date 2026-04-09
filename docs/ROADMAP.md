# ROADMAP

## Goal

Make `ACRouting` a dependable SwiftUI navigation package for production apps, with deterministic state, additive API evolution through `v1.x`, and a clear path toward typed routes, deep links, and restoration.

## Locked Decisions

This roadmap is intended to be the default planning source for future Codex chats. Unless explicitly overridden, treat the following decisions as locked:

- `ACRouting` is a public SwiftUI package, not just an app-local helper.
- `v1.x` stays additive-first; breaking cleanup waits for `v2.0.0`.
- `iOS 16 / macOS 13` remain the deployment floor until explicitly changed.
- The routing core must not require Observation APIs while that deployment floor remains.
- New public APIs should prefer SwiftUI-native semantics and avoid introducing new `AnyView`-based surfaces.
- Environment injection and explicit router passing are both supported patterns.

## Current Assessment

### What already works well

- A single `Router` abstraction keeps navigation concerns out of feature views.
- `RouterView` re-wraps destinations so routing stays available across pushed and presented flows.
- The package already covers the most common presentation styles: push, sheet, full screen, alert, and custom overlay modal.

### Current gaps to address first

- Push dismissal is not fully state-driven because `dismissScreen()` relies on SwiftUI dismissal semantics instead of explicit stack mutation.
- Stack ownership is implicit and currently tied to heuristics such as `screenStack.isEmpty`, which makes behavior harder to reason about and harder to test.
- Modal presentation state is fragmented across multiple slots instead of being modeled as a single normalized presentation state.
- Public API naming is workable, but symbols such as `showScreen` and `SegueOption` are not yet as fluent or Swift-native as they should be for a public package.
- The current model leans on `AnyView` and `AnyDestination`, which keeps it flexible but blocks stronger typed flows for routes, deep links, and restoration.
- Tests mostly validate callability and model basics rather than full navigation behavior across realistic flows.

## Priorities

### 1. Stabilize Deterministic Navigation State

Priority: High

- Make push navigation explicitly state-driven.
- Introduce and standardize stack mutation operations such as `pop()`, `pop(count:)`, and `popToRoot()`.
- Remove internal reliance on dismissal side effects for push flows.
- Clarify root versus child stack ownership without depending on implicit empty-stack checks.

Why it matters:
Future work should build on explicit navigation state, not on view dismissal behavior. If stack mutation is deterministic first, later features can compose on top of a reliable core instead of reinterpreting legacy behavior.

### 2. Normalize Modal and Presentation State

Priority: High

- Define a single normalized model for sheet, full-screen, and overlay presentation state.
- Document which modal layering combinations are supported and which are intentionally out of scope.
- Move future presentation APIs toward enum-driven or item-driven modeling rather than parallel presentation slots.
- Keep macOS behavior aligned with the public API while documenting any platform-specific fallback rules.

Why it matters:
The package already supports several presentation styles, but their lifecycle rules are still implicit. A normalized presentation model reduces hidden coupling and makes modal behavior easier to evolve, test, and document.

### 3. Expand Behavior-Level Test Coverage

Priority: High

- Add tests that verify stack and presentation state transitions, not just method callability.
- Cover mixed flows that combine push and modal transitions.
- Require each feature-bearing release to ship its own behavior tests.
- Add parity tests whenever a new API is introduced alongside a legacy one.

Why it matters:
Navigation regressions are usually behavioral, not syntactic. If tests only prove that methods are callable, the package can still drift into inconsistent runtime behavior without the suite catching it.

### 4. Improve Public API Ergonomics and Documentation

Priority: High

- Refine future public APIs toward fluent Swift call sites, role-based labels, and concise documentation comments.
- Keep both router access styles first-class: environment injection and explicit passing.
- Add preview-safe diagnostics and clearer guidance for missing router injection.
- Publish examples that demonstrate intended usage patterns instead of relying on implementation details.

Why it matters:
For a public package, ergonomics and documentation are part of the product surface. Future features should be introduced in a way that reads naturally in SwiftUI code and does not require consumers to infer behavior from the source.

### 5. Introduce Typed Push Routing

Priority: Medium

- Add additive typed push routes without removing the current destination-builder model.
- Support route-to-view registration for pushed destinations.
- Keep the legacy API working through `v1.x` while typed push flows mature.

Why it matters:
Typed push routing is the first meaningful step away from a view-erased navigation core. It should arrive only after deterministic state and better tests exist, so its semantics are built on stable behavior.

### 6. Introduce Typed Modal Routing

Priority: Medium

- Extend typed routing to sheets, full-screen covers, and overlay presentation state.
- Keep typed modal routing separate from typed push routing in release planning.
- Define how typed modal routes coordinate with an already-pushed stack.

Why it matters:
Push routing and modal routing have different lifecycle rules. Splitting them into separate milestones keeps the implementation smaller, the public API clearer, and the migration path easier to test.

### 7. Add Deep-Link Entry Points

Priority: Medium

- Add APIs to build typed push stacks from route values or URL payloads.
- Support reconstructing entry flows without requiring callers to build `AnyView` destinations manually.
- Document resolver rules and failure behavior for unsupported inputs.

Why it matters:
Deep-link support should consume typed routing, not bypass it. Once typed routes exist, deep links can be implemented as another way to build navigation state rather than as a separate navigation model.

### 8. Add Restoration

Priority: Medium

- Persist and rebuild typed push and presentation state after relaunch.
- Add round-trip tests for restoration of supported flows.
- Keep restoration scoped to routes and presentation state, not arbitrary view reconstruction.

Why it matters:
Restoration depends on deterministic, typed state. It should arrive only after the route model and modal coordination rules are stable enough to serialize and rebuild safely.

### 9. Keep Platform Metadata, SemVer Guidance, and Examples Aligned

Priority: Continuous

- Keep README, roadmap, release notes, and package metadata aligned with the actual implementation.
- Document semantic versioning expectations alongside the roadmap.
- Expand examples as each routing family becomes real, not in advance of implementation.

Why it matters:
Drift between docs, metadata, and behavior creates adoption risk. Keeping these aligned continuously is lower risk than trying to correct them in a large cleanup later.

## Release Policy

- Patch releases are for documentation updates, compatibility fixes, regression fixes, and internal hardening that does not introduce a new public feature family.
- Minor releases are for additive public capabilities that expand the routing surface without forcing migration.
- `v2.0.0` is reserved for cleanup that removes or de-emphasizes legacy APIs after additive replacements exist and are documented.

## Suggested Release Sequence

### v1.3.1

- Truth-sync release: fix roadmap and README wording.
- Document the current routing model, current limits, and current modal behavior.
- Do not add new routing behavior in this release.

Why this version:
This release aligns documentation with reality so later work has a clean baseline.

### v1.3.2

- Internal deterministic push state cleanup only.
- Remove reliance on dismissal semantics for stack mutation where possible.
- Do not add new public navigation-control APIs yet.

Why this version:
This is internal hardening and should land before any public stack-control API is introduced.

### v1.3.3

- Internal modal state normalization only.
- Define supported sheet, full-screen, and overlay rules.
- Add behavior tests for modal lifecycle without introducing typed route concepts yet.

Why this version:
This keeps modal cleanup separate from push cleanup and avoids combining two internal rewrites into one release.

### v1.4.0

- First public navigation-control release.
- Add additive stack APIs such as `pop()`, `pop(count:)`, and `popToRoot()`.
- Keep `dismissScreen()` supported, but document that explicit stack APIs are preferred for push flows.

Why this version:
This is the first release that should expose new public navigation-control APIs.

### v1.4.1

- Docs-and-diagnostics patch.
- Add public documentation comments.
- Improve missing-router diagnostics and tighten README examples.

Why this version:
Once the first explicit stack APIs ship, the package needs better guidance and better failure messages before adding another feature family.

### v1.4.2

- Examples-and-adoption patch.
- Add sample flows.
- Document when to use environment injection versus explicit router passing, including child view model usage.

Why this version:
This keeps adoption guidance separate from feature work and gives future Codex sessions a stable reference point.

### v1.5.0

- Typed push routing release.
- Introduce additive typed push routes and route-to-view registration for pushed destinations.
- Keep legacy destination-builder APIs supported.

Why this version:
Typed push routing is the first new public routing family and should be isolated in its own minor release.

### v1.5.1

- Typed push hardening patch.
- Add parity tests, documentation, and low-risk bug fixes.
- Do not introduce another routing family in this release.

Why this version:
Typed push routing needs one stabilization pass before the package grows into typed modal flows.

### v1.6.0

- Typed modal routing release.
- Extend typed routing to sheet, full-screen, and overlay presentation state.
- Keep modal routing additive alongside legacy presentation APIs.

Why this version:
Typed modal routing is a distinct capability with different lifecycle rules and deserves its own release.

### v1.6.1

- Typed modal hardening patch.
- Fix edge cases, expand regression coverage, and tighten documentation.

Why this version:
This protects the package from stacking another large feature on top of fresh modal-route behavior.

### v1.7.0

- Deep-link push release.
- Add entry points to build push stacks from typed routes or URL payloads.
- Document resolver behavior and supported failure cases.

Why this version:
Deep-link push flows should build on typed push routing rather than inventing a parallel model.

### v1.7.1

- Deep-link push hardening patch.
- Add resolver fixes, regression tests, and documentation updates only.

Why this version:
Deep-link resolution is behavior-heavy and benefits from a dedicated stabilization patch before modal deep-link coordination begins.

### v1.8.0

- Modal deep-link coordination release.
- Support reconstructing modal-first and mixed push-plus-modal flows from typed input.
- Document the supported flow shapes explicitly.

Why this version:
Modal deep-link coordination should follow typed modal routing and typed push deep-linking, not ship ahead of either.

### v1.8.1

- Modal deep-link hardening patch.
- Ship compatibility fixes, regression coverage, and documentation updates only.

Why this version:
This keeps flow-reconstruction hardening separate from restoration work.

### v1.9.0

- Restoration release.
- Persist and rebuild typed stack and typed presentation state after relaunch.
- Add round-trip restoration tests for supported flows.

Why this version:
Restoration is only worth shipping once the route model and deep-link reconstruction paths are already stable.

### v2.0.0

- Cleanup release.
- Remove or de-emphasize legacy `AnyDestination`-first surfaces only if `v1.x` additive APIs fully cover migration.
- Revisit naming such as `showScreen` and `SegueOption` only when the replacement API surface is complete and documented.
- Ship formal migration guidance with any breaking cleanup.

Why this version:
Breaking changes should happen only after the package has already proven an additive migration path through `v1.x`.

## Public API and Type Direction

- `v1.4.0` is the first release allowed to add new public navigation-control APIs.
- Typed routing must arrive in two steps:
  - Push routes first in `v1.5.0`.
  - Modal and presentation routes second in `v1.6.0`.
- No roadmap item before `v2.0.0` may require removing current APIs.
- Future public APIs should favor fluent Swift call sites, role-based parameter labels, concise documentation comments, and additive migration paths.
- Future presentation state should move toward enum-driven or item-driven SwiftUI modeling rather than parallel presentation slots.

## Test Strategy

- Each feature-bearing release should ship with its own behavior tests.
- Do not defer test coverage for a new routing family to a later milestone.
- Keep parity tests between legacy builder APIs and new typed APIs once typed routing begins.

Minimum scenarios to cover explicitly:

- `push -> push -> pop`
- `push -> sheet -> push -> dismiss`
- `push -> fullScreenCover -> dismiss`
- Overlay tap dismissal
- Alert and confirmation dialog lifecycle
- macOS full-screen fallback behavior
- Parity between legacy builder APIs and new typed APIs
- Deep-link reconstruction round-trips once deep links exist
- Restoration round-trips once restoration exists

## Non-Goals for Now

- Raising the deployment floor only to adopt Observation in the routing core.
- Liquid Glass work that is unrelated to routing behavior.
- UIKit bridging unless a concrete integration need appears.
- Rebuilding the package around a global app store before the routing core is deterministic.
- Supporting legacy Apple platform versions below the current floor.
