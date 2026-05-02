# v1.5.3 API Ergonomics Design

## Goal

Ship a source-compatible `v1.5.3` patch that improves the public call-site ergonomics for overlays, alerts, and confirmation dialogs while keeping the existing builder-first routing model unchanged.

This release should make the preferred examples less dependent on direct `AnyView` wrapping, update the preview catalog to show the new call sites, and document existing type-erased surfaces as compatibility tools rather than recommended app-facing patterns.

## Scope

`v1.5.3` includes:

- additive `Router` extension overloads for more natural overlay and alert call sites
- a dedicated confirmation-dialog convenience API
- README and DocC updates that promote the ergonomic overloads
- preview catalog updates in the existing alerts and overlays demo
- focused tests that protect source compatibility and current runtime semantics

`v1.5.3` does not include:

- restoration APIs
- persisted payload envelopes
- multi-entry stack reconstruction
- route registries or package-owned typed route-to-view mapping
- deprecations or renames for `showScreen`, `SegueOption`, `AnyDestination`, `View.any()`, or existing alert APIs

## API Design

### Overlay Ergonomics

Improve the existing ergonomic overlay helper on `Router` as a protocol extension, not as a new protocol requirement.

The existing trailing-closure spelling remains valid and should become more capable for multi-view overlays:

```swift
router.showModal {
    MyCustomOverlay()
}

router.showModal(backgroundTapDismissesModal: false) {
    Text("Confirm")
    ConfirmingOverlay()
}
```

The default protocol-extension helper should add `@ViewBuilder` support to its existing `screen` closure and continue delegating to the existing `showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)` requirement. Existing conformers do not need to implement anything new.

Semantic constraint: concrete `RouterView` should still evaluate and store overlay content in the current routed context when `showModal` is called. The helper must not turn overlays into routed modal flows.

### Alert Action Ergonomics

Add `@ViewBuilder` action overloads for `showAlert` and `showErrorAlert` on `Router` extensions.

Preferred call sites:

```swift
router.showAlert(
    .alert,
    title: "Delete item",
    subtitle: "This action cannot be undone."
) {
    Button("Cancel", role: .cancel) {}
    Button("Delete", role: .destructive) {}
}

router.showErrorAlert(error: error) {
    Button("OK", role: .cancel) {}
}
```

The overloads should erase the action builder to `AnyView` internally and forward to the existing protocol requirements. This keeps source compatibility for external conformers and preserves existing alert storage.

### Confirmation Dialog Convenience

Add a dedicated `showConfirmationDialog` convenience on `Router` as a protocol extension.

Preferred call site:

```swift
router.showConfirmationDialog(
    title: "Archive Draft Flow",
    message: "This can be restored later."
) {
    Button("Archive") {}
    Button("Cancel", role: .cancel) {}
}
```

The convenience delegates to `showAlert(.confirmationDialog, title:subtitle:buttons:)`. It should use `message` as the public argument label because that matches SwiftUI alert and dialog terminology better than the current compatibility label `subtitle`.

## Documentation Design

Update public docs to make the ergonomic APIs the default learning path while preserving the existing API surface.

README updates:

- bump current examples and supported-modal wording from `1.5.2` to `1.5.3`
- replace alert examples that manually wrap `AnyView`
- add a confirmation-dialog convenience example
- show the simple trailing-closure overlay call site with multi-view builder content when useful
- add a short compatibility note for `AnyView`, `AnyDestination`, and `View.any()`

DocC updates:

- update the current-version overview in `ACRouting.md`
- add the new overloads and convenience API to the relevant topic lists
- expand `PresentationSemantics.md` alert and overlay sections
- add a short builder-first note that ergonomic overlay builders do not move screen assembly into `ACRouting`
- update any version boundary notes that refer specifically to `v1.5.2`

Documentation should continue to state that `showModal` is a lightweight overlay in the current routed context. It must not imply that overlays are routed modal containers or dismissal targets for `dismissAncestorModal()`.

## Preview Catalog Design

Update the existing `OverlayAndAlertsDemoRoot` in `ACRoutingPreviewCatalog.swift`.

Changes:

- replace `.any()` usage in the primary alert and confirmation examples with the new action-builder overloads
- change the confirmation demo to call `showConfirmationDialog`
- keep the custom overlay demo in place and continue using the existing `showModal { ... }` spelling
- avoid adding a new full demo flow because the preview catalog is already large

The preview catalog remains a study tool for currently supported behavior, not a marketing surface for unsupported future routing.

## Test Design

Add focused tests in the existing Swift Testing suite.

Router protocol tests should cover:

- `showAlert` action-builder overload forwards option, title, message, and actions
- `showErrorAlert` action-builder overload forwards error and actions
- `showConfirmationDialog` forwards as `.confirmationDialog`
- the preferred `showModal` `@ViewBuilder` helper forwards defaults and custom configuration
- existing `AnyView`-based alert APIs remain callable

Router view integration tests should continue to cover concrete `showModal` timing:

- spy-router forwarding does not eagerly evaluate stored builders
- concrete `RouterView.showModal` still evaluates overlay content immediately

No new simulator-only UI automation is required for this patch unless an implementation detail changes runtime presentation behavior.

## Compatibility

All new APIs should be additive protocol extension conveniences. No external `Router` conformer should need source changes.

The existing `AnyView`-based alert requirements, `AnyDestination`, and `View.any()` remain available. The documentation should describe them as low-level compatibility and type-erasure surfaces, not as the preferred call-site style for new application code.

## Acceptance Criteria

- New ergonomic APIs compile from a value typed as `any Router`.
- Existing `Router` conformers remain source-compatible.
- README, DocC, and the preview catalog use the new preferred call sites.
- Tests verify forwarding behavior and preserve existing `showModal` timing semantics.
- `swift test` and `swift build` pass locally.
