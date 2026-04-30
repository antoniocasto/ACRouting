# ROADMAP

## Goal

Make `ACRouting` a dependable SwiftUI navigation package for production apps that owns navigation state and presentation behavior while application builders remain responsible for assembling screens and modules.

Through `v1.x`, the package should keep navigation deterministic, stay additive, document the real builder-first integration model clearly, and add future deep-link or restoration support only in ways that preserve app-owned screen assembly.

## Locked Decisions

This roadmap is intended to be the default planning source for future Codex chats. Unless explicitly overridden, treat the following decisions as locked:

- `ACRouting` is a public SwiftUI package, not just an app-local helper.
- `v1.x` stays additive-first; breaking cleanup waits for `v2.0.0`.
- `iOS 16 / macOS 13` remain the deployment floor until explicitly changed.
- The routing core must not require Observation APIs while that deployment floor remains.
- `ACRouting` owns navigation state and transition behavior, not feature or module assembly.
- Application builders remain responsible for creating screens, presenters, interactors, and module-specific routers.
- The package must not require a package-owned global route-to-view registry in the core.
- Environment injection and explicit router passing are both supported patterns.
- Multiple independent `RouterView` contexts, such as tab roots, are first-class supported integration patterns.
- Any future data-driven or typed navigation inputs must carry serializable navigation intent only, never concrete `View` types or module dependencies.
- CI must validate the normal contribution path, which means pull requests targeting `develop` as well as protected release branches.
- Restoration must not ship as a broad feature until its persisted payload envelope, schema versioning, and resolver policy versioning are documented.

## Architectural Contract

- `ACRouting` owns push-stack state, routed sheet/full-screen state, overlay state, alert state, and dismissal or pop semantics.
- The application owns screen assembly through builders, factories, or equivalent composition-root mechanisms.
- Feature screens should usually depend on an app-owned router adapter that decides which builder method to call and then uses `ACRouting` to present the resulting screen.
- Future deep-link and restoration flows must rebuild navigation by asking app-owned builders or resolvers to recreate screens, not by moving assembly into `ACRouting`.

## Current Assessment

### What already works well

- A single `Router` abstraction keeps navigation concerns out of feature views.
- `RouterView` re-wraps destinations so routing stays available across pushed and presented flows.
- The current closure-based API already fits builder-first integration naturally because the app decides what to build inside each `showScreen` or `showModal` call.
- The package covers the most common presentation styles: push, sheet, full screen, alert, and custom overlay modal.
- Push navigation is state-driven through explicit stack APIs: `pop()`, `pop(count:)`, and `popToRoot()`.
- Inherited push-stack ownership is now explicit instead of being inferred from empty-stack heuristics.
- Routed `.sheet` and `.fullScreenCover` presentations now share one internal presentation state.
- Pushed child flows can dismiss their first ancestor routed sheet or full-screen cover explicitly through `dismissAncestorModal()`.
- The package already supports multiple independent `RouterView` contexts, which matches tab-based and feature-scoped app architectures well.
- A debug-only preview catalog exists for local Xcode exploration of real package flows and current limits.
- README and DocC now document builder-owned screen assembly as the recommended integration model for larger apps.
- Public examples now show app-owned router adapters layered on top of `ACRouting` instead of moving screen construction into the package core.
- Missing-router fallback behavior now emits debug guidance that explains how to wrap a flow in `RouterView` or pass a real router explicitly.
- Regression coverage now includes builder-assembled push, sheet, full-screen, overlay, and independent router-context stack isolation.
- Deep-link input modeling now stores app-owned serializable payloads and lets app-owned resolvers choose presentation style plus destination assembly.

### Current supported behavior after `v1.5.1`

- Root flow with push navigation.
- One routed `.sheet` flow with its own local push stack.
- One routed `.fullScreenCover` flow with its own local push stack.
- A lightweight `showModal` overlay inside the current router context, including root, pushed, sheet-root, or full-screen-root screens.
- A pushed child inside one routed `.sheet` or `.fullScreenCover` flow calling `dismissAncestorModal()` to close that first ancestor routed modal.
- Builder-first integration through app-owned builders, factories, or router adapters while `ACRouting` owns only navigation state and presentation behavior.
- Multiple independent `RouterView` contexts for tab roots or feature-scoped flows.
- Serializable routed navigation intent payloads resolved through app-owned resolvers.
- Resolver-selected presentation styles for supported typed navigation payloads.

### Current gaps to address after `v1.5.1`

- Builder-first regression coverage is much stronger than before, but follow-up tests should continue locking down any small adapter or multi-context edge cases discovered during use.
- Missing-router diagnostics are actionable, but they should stay preview-safe and avoid becoming noisy.
- CI needs operational hardening so PRs toward `develop` receive the same test signal expected by the repository workflow, and the runner should not depend on uninstalled formatting tools such as `xcpretty`.
- The current automated suite protects core state behavior well, but it still needs thin runtime-level checks for actual SwiftUI presentation wiring on the supported platforms.
- `AnyView`, `AnyDestination`, and `View.any()` still limit future state serialization and reconstruction work, but any cleanup in this area must preserve builder-owned assembly.
- Alert actions and overlay builders are usable, but their `AnyView` and non-`@ViewBuilder` ergonomics should be improved additively before a breaking cleanup is considered.
- `showModal` intentionally differs from routed presentations because it evaluates and stores overlay content in the current router context; docs and tests should make that timing explicit.
- Remaining reconstruction and restoration gaps are persisted payload compatibility, multi-entry deep-link stack reconstruction, and cross-context restoration across multiple `RouterView` roots.

## Priorities

### 1. Document and Harden the Builder-First Integration Model

Priority: High

- Keep builder-owned screen assembly explicit in the roadmap, README, DocC, and examples.
- Maintain guidance for app-owned router adapters that translate feature intents into builder calls plus `ACRouting` commands.
- Keep the closure-based presentation APIs first-class throughout `v1.x`.
- Continue clarifying support for multiple independent `RouterView` contexts and their ownership boundaries as new examples or edge cases appear.

Why it matters:
This is how real consumers already use the package. The roadmap and docs should match that reality before more feature work is layered on top.

### 2. Stabilize CI and Platform Verification

Priority: High

- Run CI for pull requests targeting `develop`, because that is the normal PR base for repository work.
- Keep branch-protection job names stable while aligning workflow triggers with the actual release process.
- Replace, install, or avoid formatter dependencies that are not guaranteed on GitHub-hosted macOS runners.
- Add at least one iOS simulator test lane so non-macOS presentation branches, especially `.fullScreenCover`, are executed in automation.
- Keep macOS execution because it validates the documented sheet-backed full-screen fallback.

Why it matters:
A routing package can look stable locally while the normal PR path has no reliable CI signal. Before restoration or larger API work, the feedback loop must be trustworthy.

### 3. Expand Behavior-Level Test Coverage

Priority: High

- Maintain tests that verify builder-assembled push, sheet, full-screen, overlay, and ancestor modal dismissal flows.
- Extend coverage for multiple independent `RouterView` contexts when new tab-root or feature-scope edge cases are discovered.
- Keep current limits explicitly covered so unsupported behavior is documented and protected from accidental drift.
- Keep binding/helper tests for fast state verification, but add thin runtime-level coverage for real `NavigationStack`, `.sheet`, `.fullScreenCover`, alert, and overlay wiring where feasible.
- Clarify and test the intended `showModal` builder timing so spy-router behavior and concrete `RouterView` behavior do not drift unnoticed.
- Remove or avoid fragile low-value assertions, such as relying on distinct `hashValue` values, when identity or equality already prove the intended behavior.
- Require each feature-bearing release to ship with behavior tests.

Why it matters:
Navigation regressions are behavioral. Tests should protect the real integration patterns package consumers rely on, not only isolated core mechanics.

### 4. Improve Public API Ergonomics and Diagnostics

Priority: High

- Refine public APIs toward fluent Swift call sites, role-based labels, and concise documentation comments where additive improvements are useful.
- Add ergonomic overloads where they reduce type-erasure friction without changing existing behavior, especially `showModal` builder call sites and alert or confirmation actions.
- Treat `AnyDestination` and `View.any()` as low-level supporting API in documentation until a `v2.0.0` cleanup can de-emphasize or replace them safely.
- Keep `showScreen` and `SegueOption` source-stable through `v1.x`; any naming cleanup should be additive first and breaking only in `v2.0.0`.
- Keep both router access styles first-class: environment injection and explicit passing.
- Maintain preview-safe diagnostics and clearer guidance for missing router injection.
- Keep the local preview catalog aligned with current behavior rather than aspirational flows.

Why it matters:
For a public package, ergonomics and diagnostics are part of the product surface. Better guidance reduces integration mistakes without forcing new architecture.

### 5. Define Deep-Link and Restoration Boundaries Around App-Owned Builders

Priority: High

- Keep the payload-only routed intent API additive and avoid moving screen assembly into `ACRouting`.
- Extend the app-owned builder or resolver handoff only where it helps supported deep-link or restoration flows.
- Keep failure behavior for unsupported, partial, or invalid inputs documented and regression-covered.
- Before shipping restoration APIs, publish a short design note that defines the persisted envelope, payload schema versioning, resolver policy versioning, unsupported payload behavior, and ownership of multiple `RouterView` roots.
- Scope the first restoration implementation to a single routed context unless the envelope model has already proven that cross-context restoration can stay deterministic.
- Defer cross-tab, multi-root, and multi-entry stack reconstruction until single-context restoration has behavior tests and compatibility rules.

Why it matters:
Deep links and restoration are still valuable goals, but they must fit the builder-first contract instead of bypassing it.

### 6. Reduce View-Erased Internals Only When It Helps Deterministic State

Priority: Medium

- Prefer more data-driven internal state where it improves testing, restoration readiness, or deterministic behavior.
- Avoid turning internal cleanup into a public requirement for package-owned route registries or view factories.
- Keep current closure-based APIs supported while internals evolve.
- Do not prioritize type purity over the current user-facing value: deterministic routing with app-owned assembly.

Why it matters:
Internal cleanup still matters, but not at the cost of architectural boundaries that package consumers depend on.

### 7. Keep Platform Metadata, SemVer Guidance, and Examples Aligned

Priority: Continuous

- Keep README, roadmap, release notes, and package metadata aligned with the actual implementation.
- Document semantic versioning expectations alongside the roadmap.
- Expand examples only when a behavior or pattern is truly supported.

Why it matters:
Drift between docs, metadata, and behavior creates adoption risk. Keeping them aligned continuously is lower risk than correcting them in a large cleanup later.

## Release Policy

- Patch releases are for documentation updates, compatibility fixes, regression fixes, and internal hardening that does not introduce a new public feature family.
- Minor releases are for additive public capabilities or integration surfaces that expand the routing package without forcing migration.
- `v2.0.0` is reserved for cleanup that removes or de-emphasizes legacy APIs only after additive replacements exist and are documented.

## Planned Design Checkpoints

The following milestones should not be treated as "implement immediately" items when reached. They each require a short design pass first because the implementation direction is not fully locked yet.

- `v1.4.3`: builder-first architecture sync, adapter examples, diagnostics, and regression coverage for real-world integration patterns.
- `v1.5.0`: deep-link input modeling, builder or resolver handoff, and supported failure behavior.
- `v1.5.2`: CI reliability, runtime-test hardening, and documentation of current overlay or API ergonomics limits before the next feature family.
- `v1.6.0`: restoration payload envelope, compatibility rules, and a narrowly scoped single-context reconstruction boundary.
- `v1.7.0`: optional navigation-intent helpers for app-owned routers, only if they provide value without moving assembly into the package.
- `v2.0.0`: migration strategy, naming cleanup, and legacy API de-emphasis timing.

## Suggested Release Sequence

### v1.3.1

- Truth-sync release: fix roadmap and README wording.
- Document the current routing model, current limits, and current modal behavior.
- Do not add new routing behavior in this release.

Why this version:
This release aligned documentation with reality so later work had a cleaner baseline.

### v1.4.0

- First public navigation-control release.
- Add additive stack APIs such as `pop()`, `pop(count:)`, and `popToRoot()`.
- Make inherited push-stack mutation deterministic and explicit.
- Ship behavior tests that lock down the new push-state semantics.
- Keep `dismissScreen()` supported, but document that explicit stack APIs are preferred for push flows.

Why this version:
This was the first release that exposed new public navigation-control APIs.

### v1.4.1

- Docs-and-examples patch.
- Add public documentation comments and tighten README examples.
- Add and maintain a local preview catalog that shows only currently supported flows.
- Keep roadmap, changelog, and package guidance aligned with the branch reality.

Why this version:
Once the first explicit stack APIs shipped, the package needed stronger study material and better documentation before another feature family was added.

### v1.4.2

- Modal semantics hardening patch.
- Clarify supported modal combinations and current limits.
- Add additive ancestor modal dismissal API support in `v1.x`.
- Expand mixed-flow regression coverage only.

Already implemented:

- `dismissAncestorModal()` is additive and does not change `dismissScreen()` semantics.
- Routed `.sheet` and `.fullScreenCover` presentations share one internal routed modal presentation state instead of separate ad hoc storage slots.
- Mixed-flow regression coverage includes pushed-child ancestor modal dismissal, modal-root no-op behavior, and separation between `dismissScreen()` and `dismissAncestorModal()`.
- External `Router` conformers remain source-compatible through a default no-op implementation of `dismissAncestorModal()`.
- `showModal` remains a separate overlay-only mechanism in `v1.x`.

Why this version:
This kept modal semantics cleanup separate from later roadmap work and gave the package a cleaner base for the next planning step.

### v1.4.3

- Builder-first integration release.
- Rewrite the public roadmap, README guidance, and examples so builder-owned screen assembly is the documented default integration model.
- Publish at least one explicit example of an app-owned router adapter that delegates screen creation to builders while using `ACRouting` for presentation.
- Expand regression coverage for builder-assembled push, sheet, full-screen, overlay, and multi-`RouterView` flows.
- Improve missing-router diagnostics and preview-safe guidance without changing the architecture.
- Do not add package-owned typed routing or core route registration in this release.

Already implemented:

- README and DocC document builder-first integration as the default model for larger apps.
- Public examples show an app-owned router adapter delegating screen construction to builders.
- The preview catalog demonstrates the supported `v1.4.3` behavior surface and current layering limits.
- `MockRouter` emits debug diagnostics for missing router injection.
- Regression tests cover builder-assembled push, sheet, full-screen, overlay, and independent router-context stack isolation.

Why this version:
The roadmap needs to match the real way the package is used before deep-link or restoration work is designed on top of it.

### v1.4.4

- Builder-first hardening patch.
- Add low-risk regression fixes, documentation polish, and example refinements only.
- Do not introduce another routing family in this release.

Already implemented:

- README and DocC version markers were updated for the `1.4.4` release.
- README links and modal-layering copy were corrected to avoid stale local paths or version references.
- The roadmap current assessment now reflects the already-released `1.4.3` builder-first documentation, diagnostics, and tests.
- Regression coverage now verifies that an app-owned router adapter forwards follow-up navigation through the routed destination context after a builder-assembled push.

Why this version:
The clarified integration model should get one stabilization pass before new capability work begins.

### v1.5.0

- Deep-link input modeling release.
- Add additive APIs that allow applications to drive navigation from serializable payloads or intent values while keeping screen assembly app-owned.
- Define how payload resolution and presentation style selection are handed off to app-owned builders or resolvers.
- Keep the current closure-based APIs first-class and fully supported.

Already implemented:

- `RoutedNavigationIntent` stores only the app-owned serializable payload.
- `RoutedNavigationIntentResolving` keeps presentation style selection and screen assembly in app-owned builders or resolvers.
- `Router.showScreen(_:using:)` validates support before forwarding supported payloads and resolver-selected presentation styles to the existing closure-based presentation API.
- Unsupported payloads return `.unsupported` without mutating router state.

Deferred to later milestones:

- multi-entry deep-link stack reconstruction
- persisted restoration payload compatibility
- cross-context restoration across multiple `RouterView` roots

Why this version:
Deep-link entry points are valuable, but only if they respect the existing builder-first ownership model.

### v1.5.1

- Deep-link hardening patch.
- Add resolver fixes, regression tests, and documentation updates only.

Why this version:
Input-driven navigation is behavior-heavy and benefits from a dedicated stabilization pass before restoration work is added.

### v1.5.2

- Operational hardening patch before restoration work.
- Align CI triggers with the repository's PR flow toward `develop`.
- Replace, install, or remove reliance on `xcpretty` in GitHub Actions.
- Add an iOS simulator test lane or equivalent automation that executes non-macOS presentation branches.
- Clarify `showModal` overlay builder timing in docs and tests.
- Trim fragile or duplicated tests where they do not protect meaningful behavior.
- Do not introduce a new routing feature family in this release.

Why this version:
The package should have reliable automation and sharper behavioral tests before `v1.6.0` starts persisting or rebuilding navigation state.

### v1.6.0

- Restoration foundation release.
- Publish the restoration design note before implementation, including persisted envelope, payload schema version, resolver policy version, and unsupported payload behavior.
- Persist and rebuild a narrowly scoped single-router-context navigation state using app-owned builders or resolvers.
- Add round-trip restoration tests for the supported single-context flows.
- Keep restoration scoped to navigation state, not arbitrary view reconstruction.
- Defer cross-tab, multi-root, and broad multi-entry stack reconstruction unless the design note proves they can remain deterministic without package-owned screen assembly.

Needs deeper design before implementation:

- what restoration payload format becomes the long-term compatibility boundary
- how versioning and backward compatibility are handled for saved navigation state
- how restoration behaves across multiple `RouterView` contexts such as tab roots
- how apps version payload schema and resolver behavior when presentation rules are not serialized in `RoutedNavigationIntent`
- whether restoration should use an app-owned envelope that records payload type, payload schema version, and resolver policy version before handing payloads back to `ACRouting`

Why this version:
Restoration is only worth shipping once deep-link input and builder handoff rules are stable enough to serialize and rebuild safely.

### v1.6.1

- Restoration hardening patch.
- Fix edge cases, expand regression coverage, and tighten documentation.

Why this version:
State restoration should get one stabilization pass before more optional abstraction work is considered.

### v1.7.0

- Optional navigation-intent helper release.
- Evaluate additive helper APIs for app-owned routers or adapters if real-world integrations show enough repeated boilerplate.
- Keep any such helpers optional, app-scoped, and compatible with builder-owned assembly.
- Do not require package-owned typed routing or global registries in the core.

Needs deeper design before implementation:

- whether the helpers belong in the public package at all or should remain example-level patterns
- how helper inputs stay serializable and architecture-neutral
- how to avoid locking the package into one app architecture's naming or layering conventions

Why this version:
Any data-driven navigation convenience should be proven by real integration pain before it becomes part of the public API.

### v1.7.1

- Navigation-intent helper hardening patch.
- Ship compatibility fixes, regression coverage, and documentation updates only.

Why this version:
If helpers become public, they still need their own stabilization release before cleanup work begins.

### v2.0.0

- Cleanup release.
- Remove or de-emphasize legacy `AnyDestination`-first surfaces only if additive replacements fully cover builder-first migration.
- Revisit naming such as `showScreen` and `SegueOption` only when the replacement API surface is complete and documented.
- Ship formal migration guidance with any breaking cleanup.

Needs deeper design before implementation:

- what the migration path looks like for current package consumers
- which naming changes are worth the source break and which should stay as compatibility shims
- whether legacy APIs are removed entirely or kept as deprecated bridges for one more cycle

Why this version:
Breaking changes should happen only after the package has already proven an additive migration path through `v1.x`.

## Public API and Integration Direction

- `v1.4.0` is the first release allowed to add new public navigation-control APIs.
- The current closure-based builder API remains first-class throughout `v1.x`.
- New `Router` protocol requirements in `v1.x` should keep source compatibility through default implementations.
- Builders own screen assembly; `ACRouting` owns navigation state and transition behavior.
- Future data-driven APIs beyond current intent modeling must hand off rendering to app-owned builders or resolvers and must carry only serializable navigation intent.
- The package must not require a package-owned global route-to-view registry in the core.
- Multiple independent `RouterView` contexts remain supported and should stay documented as such.
- No roadmap item before `v2.0.0` may require removing current APIs.
- Future presentation state can become more data-driven internally, but public integration should remain builder-friendly.
- Public type-erasure surfaces such as `AnyDestination`, `View.any()`, and alert `AnyView` actions should be treated as compatibility debt, not as patterns to expand.
- Additive ergonomic overloads are allowed when they reduce type-erasure friction without changing existing call sites.

## Test Strategy

- Each feature-bearing release should ship with its own behavior tests.
- Do not defer test coverage for a new integration surface to a later milestone.
- Prefer parity between documented integration patterns and core behavior over parity with hypothetical future abstractions.
- CI must run on the branches that actually receive work, including PRs targeting `develop`.
- CI should exercise both macOS behavior and at least one iOS simulator path for platform-conditional presentation code.

Minimum scenarios to cover explicitly:

- A root builder hosting multiple independent `RouterView` contexts, such as tab roots.
- An app-owned router adapter pushing a builder-created screen.
- Sheet and full-screen flows assembled by app-owned builders.
- Overlay presentation assembled by app-owned builders.
- A pushed child dismissing the first ancestor routed modal through `dismissAncestorModal()`.
- `pop()`, `pop(count:)`, and `popToRoot()` through builder-assembled flows.
- Alert and confirmation dialog lifecycle.
- Missing-router diagnostics in previews or isolated tests.
- macOS full-screen fallback behavior.
- iOS full-screen presentation behavior.
- Runtime-level presentation wiring for push, routed modal, alert, and overlay behavior where SwiftUI automation makes this practical.
- `showModal` overlay builder timing and dismissal behavior.
- `RoutedNavigationIntent` Codable round-trips and resolver-selected presentation behavior for deep-link input.
- Deep-link stack reconstruction round-trips once reconstruction APIs exist.
- Single-context restoration round-trips once restoration exists.
- Cross-context restoration round-trips only after the single-context envelope and compatibility rules are proven.

## Non-Goals for Now

- Moving screen assembly into `ACRouting`.
- Requiring a package-owned global route-to-view registry in the core.
- Forcing apps to adopt typed routing inside the package to use push, sheet, full-screen, or overlay APIs.
- Raising the deployment floor only to adopt Observation in the routing core.
- Liquid Glass work that is unrelated to routing behavior.
- UIKit bridging unless a concrete integration need appears.
- Rebuilding the package around a global app store before the routing core is deterministic.
- Supporting legacy Apple platform versions below the current floor.
- Shipping broad restoration, cross-tab restoration, or multi-root reconstruction before a persisted compatibility envelope is defined.
- Expanding public type-erasure requirements when additive ergonomic overloads can hide that detail from consumers.
