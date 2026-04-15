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
- Push navigation is now state-driven through explicit stack APIs: `pop()`, `pop(count:)`, and `popToRoot()`.
- Inherited push-stack ownership is now explicit instead of being inferred from empty-stack heuristics.
- The package now has behavior-level regression tests for push-stack mutation and protocol forwarding.
- A debug-only preview catalog exists for local Xcode exploration of real package flows and current limits.

### Current gaps to address first

- Modal presentation state is fragmented across multiple slots instead of being modeled as a single normalized presentation state.
- There is no dedicated API to dismiss an ancestor modal container from deep inside a pushed child flow.
- Public API naming is workable, but symbols such as `showScreen` and `SegueOption` are not yet as fluent or Swift-native as they should be for a public package.
- The current model leans on `AnyView` and `AnyDestination`, which keeps it flexible but blocks stronger typed flows for routes, deep links, and restoration.
- Missing-router behavior is safe, but diagnostics are still lightweight and could do more than the current `MockRouter` fallback.
- The test suite is much better than before, but mixed modal-plus-push behavior still needs broader coverage before typed routing arrives.

## Priorities

### 1. Normalize Modal and Presentation State

Priority: High

- Define a single normalized model for sheet, full-screen, and overlay presentation state.
- Document which modal layering combinations are supported and which are intentionally out of scope.
- Move future presentation APIs toward enum-driven or item-driven modeling rather than parallel presentation slots.
- Keep macOS behavior aligned with the public API while documenting any platform-specific fallback rules.
- Decide whether ancestor modal dismissal should be introduced as an additive API or documented as intentionally unsupported through `v1.x`.

Why it matters:
The package already has a deterministic push stack, but modal semantics are still spread across separate storage slots and implicit container rules. Typed routing and deeper flow reconstruction should build on a normalized presentation model rather than on parallel ad hoc state.

### 2. Expand Behavior-Level Test Coverage

Priority: High

- Add tests that verify mixed push-plus-modal flows, not just pure push behavior.
- Cover the current limits explicitly so unsupported behavior is documented and protected from accidental drift.
- Require each feature-bearing release to ship its own behavior tests.
- Add parity tests whenever a new API is introduced alongside a legacy one.

Why it matters:
Navigation regressions are usually behavioral, not syntactic. The current suite is much stronger than before, but modal interaction rules still need more coverage before more feature families are layered on top.

### 3. Improve Public API Ergonomics and Documentation

Priority: High

- Refine future public APIs toward fluent Swift call sites, role-based labels, and concise documentation comments.
- Keep both router access styles first-class: environment injection and explicit passing.
- Add preview-safe diagnostics and clearer guidance for missing router injection.
- Keep the local preview catalog aligned with current behavior rather than aspirational flows.
- Publish examples that demonstrate intended usage patterns instead of relying on implementation details.

Why it matters:
For a public package, ergonomics and documentation are part of the product surface. The package now has a better internal study aid, but public docs and diagnostics still need to close the gap between implementation details and intended usage.

### 4. Introduce Typed Push Routing

Priority: Medium

- Add additive typed push routes without removing the current destination-builder model.
- Support route-to-view registration for pushed destinations.
- Keep the legacy API working through `v1.x` while typed push flows mature.

Why it matters:
Typed push routing is the first meaningful step away from a view-erased navigation core. It should arrive only after deterministic state and better tests exist, so its semantics are built on stable behavior.

### 5. Introduce Typed Modal Routing

Priority: Medium

- Extend typed routing to sheets, full-screen covers, and overlay presentation state.
- Keep typed modal routing separate from typed push routing in release planning.
- Define how typed modal routes coordinate with an already-pushed stack.

Why it matters:
Push routing and modal routing have different lifecycle rules. Splitting them into separate milestones keeps the implementation smaller, the public API clearer, and the migration path easier to test.

### 6. Add Deep-Link Entry Points

Priority: Medium

- Add APIs to build typed push stacks from route values or URL payloads.
- Support reconstructing entry flows without requiring callers to build `AnyView` destinations manually.
- Document resolver rules and failure behavior for unsupported inputs.

Why it matters:
Deep-link support should consume typed routing, not bypass it. Once typed routes exist, deep links can be implemented as another way to build navigation state rather than as a separate navigation model.

### 7. Add Restoration

Priority: Medium

- Persist and rebuild typed push and presentation state after relaunch.
- Add round-trip tests for restoration of supported flows.
- Keep restoration scoped to routes and presentation state, not arbitrary view reconstruction.

Why it matters:
Restoration depends on deterministic, typed state. It should arrive only after the route model and modal coordination rules are stable enough to serialize and rebuild safely.

### 8. Keep Platform Metadata, SemVer Guidance, and Examples Aligned

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

## Planned Design Checkpoints

The following milestones should not be treated as "implement immediately" items when reached. They each require a short design pass first, because the implementation direction is not fully locked yet.

- `v1.4.2`: modal semantics, ancestor modal dismissal, and supported modal layering rules.
- `v1.5.0`: typed push route modeling, route registration, and coexistence with the legacy builder API.
- `v1.6.0`: typed modal route modeling and coordination between modal state and an already-pushed stack.
- `v1.7.0`: deep-link resolver inputs, failure behavior, and stack construction rules.
- `v1.9.0`: restoration serialization format, compatibility rules, and scope boundaries.
- `v2.0.0`: migration strategy, naming cleanup, and legacy API de-emphasis timing.

## Suggested Release Sequence

### v1.3.1

- Truth-sync release: fix roadmap and README wording.
- Document the current routing model, current limits, and current modal behavior.
- Do not add new routing behavior in this release.

Why this version:
This release aligns documentation with reality so later work has a clean baseline.

### v1.4.0

- First public navigation-control release.
- Add additive stack APIs such as `pop()`, `pop(count:)`, and `popToRoot()`.
- Make inherited push-stack mutation deterministic and explicit.
- Ship behavior tests that lock down the new push-state semantics.
- Keep `dismissScreen()` supported, but document that explicit stack APIs are preferred for push flows.

Why this version:
This is the first release that should expose new public navigation-control APIs.

### v1.4.1

- Docs-and-examples patch.
- Add public documentation comments and tighten README examples.
- Add and maintain a local preview catalog that shows only currently supported flows.
- Keep roadmap, changelog, and package guidance aligned with the branch reality.

Why this version:
Once the first explicit stack APIs ship, the package needs stronger study material and better documentation before another feature family is added.

### v1.4.2

- Modal semantics hardening patch.
- Clarify supported modal combinations and current limits.
- Add additive ancestor modal dismissal API support in `v1.x`.
- Expand mixed-flow regression coverage only.

Already decided:
- `dismissAncestorModal()` is the additive API name for dismissing the first ancestor routed modal from a pushed child flow.
- The API targets only the first ancestor `sheet` or `fullScreenCover`.
- `showModal` overlays are explicitly out of scope for this API.
- Calls made without an ancestor routed modal should be a no-op with debug-only diagnostics.
- `dismissScreen()` keeps its current semantics and does not dismiss ancestor modals implicitly.
- `v1.4.2` support and regression coverage are currently scoped to one ancestor routed modal at a time.

Already implemented on this branch:
- `dismissAncestorModal()` is implemented additively without changing `dismissScreen()` semantics.
- Routed `.sheet` and `.fullScreenCover` presentations now share one internal routed modal presentation state instead of separate ad hoc storage slots.
- Mixed-flow regression coverage now includes pushed-child ancestor modal dismissal, modal-root no-op behavior, and separation between `dismissScreen()` and `dismissAncestorModal()`.
- External `Router` conformers remain source-compatible through a default no-op implementation of `dismissAncestorModal()`.
- Routed modal presentation state is wrapped behind a dedicated internal modifier, while `showModal` remains a separate overlay-only mechanism.

Still open design questions:
- which modal layering combinations are first-class and which stay explicitly out of scope
- whether overlay presentation participates in future normalized presentation state or remains a separate overlay-only mechanism

Why this version:
This keeps modal semantics cleanup separate from typed-routing work and gives the package a cleaner base for later route typing.

### v1.5.0

- Typed push routing release.
- Introduce additive typed push routes and route-to-view registration for pushed destinations.
- Keep legacy destination-builder APIs supported.

Needs deeper design before implementation:
- the route model shape, including associated data and hashing requirements
- how route-to-view registration is declared and scoped
- how typed push routing coexists with legacy destination builders during `v1.x`

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

Needs deeper design before implementation:
- whether sheet, full-screen, and overlay routes share one presentation enum or remain separated
- how typed modal state coordinates with an already-active push stack
- whether overlay routing should stay lightweight or join the typed modal model fully

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

Needs deeper design before implementation:
- how URLs or external payloads map to typed routes
- what the resolver returns on partial or invalid input
- whether deep-link reconstruction is all-or-nothing or can degrade to partial stacks

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

Needs deeper design before implementation:
- what restoration payload format becomes the long-term compatibility boundary
- how versioning and backward compatibility are handled for saved navigation state
- whether restoration includes only routes and presentation state or also selected transient UI state

Why this version:
Restoration is only worth shipping once the route model and deep-link reconstruction paths are already stable.

### v2.0.0

- Cleanup release.
- Remove or de-emphasize legacy `AnyDestination`-first surfaces only if `v1.x` additive APIs fully cover migration.
- Revisit naming such as `showScreen` and `SegueOption` only when the replacement API surface is complete and documented.
- Ship formal migration guidance with any breaking cleanup.

Needs deeper design before implementation:
- what the migration path looks like for current package consumers
- which naming changes are worth the source break and which should stay as compatibility shims
- whether legacy APIs are removed entirely or kept as deprecated bridges for one more cycle

Why this version:
Breaking changes should happen only after the package has already proven an additive migration path through `v1.x`.

## Public API and Type Direction

- `v1.4.0` is the first release allowed to add new public navigation-control APIs.
- The current branch already uses explicit push-stack control as the baseline for future work.
- Typed routing must arrive in two steps:
  - Push routes first in `v1.5.0`.
  - Modal and presentation routes second in `v1.6.0`.
- No roadmap item before `v2.0.0` may require removing current APIs.
- Future public APIs should favor fluent Swift call sites, role-based parameter labels, concise documentation comments, and additive migration paths.
- Future presentation state should move toward enum-driven or item-driven SwiftUI modeling rather than parallel presentation slots.
- Internal examples and previews should continue to demonstrate only flows that are truly supported by the current implementation.

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
