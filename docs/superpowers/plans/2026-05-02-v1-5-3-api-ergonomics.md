# v1.5.3 API Ergonomics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship additive `Router` ergonomics for overlays, alerts, and confirmation dialogs, then update docs and preview examples to make those call sites the preferred public path.

**Architecture:** New alert and confirmation behavior lives in `Router` protocol extensions so existing external conformers remain source-compatible. The alert overloads erase builder output to existing `AnyView` requirements internally, and the default `showModal(...screen:)` helper gains `@ViewBuilder` support while preserving current state storage and overlay timing semantics.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Testing, Swift Package Manager, DocC Markdown.

---

## File Structure

- `Sources/ACRouting/Core/Router.swift`: add additive protocol-extension overloads and documentation comments.
- `Tests/ACRoutingTests/RouterProtocolTests.swift`: add forwarding/source-compatibility coverage for the new overloads.
- `Tests/ACRoutingTests/RouterViewIntegrationTests.swift`: add concrete `RouterView` timing coverage for the `@ViewBuilder` overlay helper.
- `README.md`: update current examples and compatibility guidance for `1.5.3`.
- `Sources/ACRouting/ACRouting.docc/ACRouting.md`: update current version notes and topic links.
- `Sources/ACRouting/ACRouting.docc/PresentationSemantics.md`: document alert and overlay ergonomics.
- `Sources/ACRouting/ACRouting.docc/BuilderFirstIntegration.md`: add a short builder-first note for ergonomic overlays.
- `Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md`: update any `v1.5.2` boundary wording to `v1.5.3` where it describes the current release boundary.
- `Sources/ACRouting/Previews/ACRoutingPreviewCatalog.swift`: update the existing alerts/overlay demo in place.
- `CHANGELOG.md`: add `Unreleased` bullets for the new APIs/docs/tests.
- `docs/ROADMAP.md`: mark `v1.5.3` as implemented after the work lands.

## Task 1: API and Protocol Tests

**Files:**
- Modify: `Sources/ACRouting/Core/Router.swift`
- Modify: `Tests/ACRoutingTests/RouterProtocolTests.swift`
- Modify: `Tests/ACRoutingTests/RouterViewIntegrationTests.swift`

- [ ] **Step 1: Add failing protocol tests for alert action-builder overloads**

Add tests near the existing alert tests:

```swift
@Test("showAlert action-builder overload erases actions and forwards")
func showAlertActionBuilderOverloadForwards() {
    let spy = SpyRouter()

    spy.showAlert(.alert, title: "Delete", subtitle: "Cannot be undone") {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {}
    }

    #expect(spy.showAlertCalls.count == 1)
    #expect(spy.showAlertCalls[0].option == .alert)
    #expect(spy.showAlertCalls[0].title == "Delete")
    #expect(spy.showAlertCalls[0].subtitle == "Cannot be undone")
    #expect(spy.showAlertCalls[0].hasButtons == true)
}

@Test("showErrorAlert action-builder overload erases actions and forwards")
func showErrorAlertActionBuilderOverloadForwards() {
    let spy = SpyRouter()
    let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Oops"])

    spy.showErrorAlert(error: error) {
        Button("OK", role: .cancel) {}
    }

    #expect(spy.showErrorAlertCalls.count == 1)
    #expect(spy.showErrorAlertCalls[0].errorDescription == "Oops")
    #expect(spy.showErrorAlertCalls[0].hasButtons == true)
}
```

- [ ] **Step 2: Add failing protocol tests for confirmation and overlay ergonomics**

Add tests near the existing default-parameter tests:

```swift
@Test("showConfirmationDialog forwards as confirmation dialog")
func showConfirmationDialogForwardsAsConfirmationDialog() {
    let spy = SpyRouter()

    spy.showConfirmationDialog(title: "Archive", message: "Restore later") {
        Button("Archive") {}
        Button("Cancel", role: .cancel) {}
    }

    #expect(spy.showAlertCalls.count == 1)
    #expect(spy.showAlertCalls[0].option == .confirmationDialog)
    #expect(spy.showAlertCalls[0].title == "Archive")
    #expect(spy.showAlertCalls[0].subtitle == "Restore later")
    #expect(spy.showAlertCalls[0].hasButtons == true)
}

@Test("showModal view-builder overload forwards defaults")
func showModalViewBuilderOverloadForwardsDefaults() {
    let spy = SpyRouter()

    spy.showModal {
        Text("Title")
        Button("Continue") {}
    }

    #expect(spy.showModalCalls.count == 1)
    #expect(spy.showModalCalls[0].backgroundColor == Color.black.opacity(0.6))
    #expect(spy.showModalCalls[0].backgroundTapDismissesModal == true)
}

@Test("showModal view-builder overload forwards custom configuration")
func showModalViewBuilderOverloadForwardsCustomConfiguration() {
    let spy = SpyRouter()

    spy.showModal(
        backgroundColor: .red,
        backgroundTapDismissesModal: false
    ) {
        Text("Modal")
    }

    #expect(spy.showModalCalls.count == 1)
    #expect(spy.showModalCalls[0].backgroundColor == .red)
    #expect(spy.showModalCalls[0].backgroundTapDismissesModal == false)
}
```

- [ ] **Step 3: Run targeted tests and confirm they fail**

Run:

```bash
swift test --filter RouterProtocolTests
```

Expected: compile fails because `showConfirmationDialog` does not exist yet, the alert action-builder overloads do not exist yet, or multi-view `showModal` content cannot compile through the existing non-`@ViewBuilder` helper.

- [ ] **Step 4: Implement additive overloads in `Router.swift`**

Add protocol-extension methods without changing the `Router` requirements:

```swift
private struct SendableErasedView: @unchecked Sendable {
    let view: AnyView
}

/// Presents an alert or confirmation dialog with SwiftUI action content.
func showAlert<Actions: View>(
    _ option: AlertType,
    title: String,
    subtitle: String? = nil,
    @ViewBuilder actions: @escaping @Sendable () -> Actions
) {
    let erasedActions = SendableErasedView(view: AnyView(actions()))
    showAlert(option, title: title, subtitle: subtitle, buttons: {
        erasedActions.view
    })
}

/// Presents an error alert with SwiftUI action content.
func showErrorAlert<Actions: View>(
    error: any Error,
    @ViewBuilder actions: @escaping @Sendable () -> Actions
) {
    let erasedActions = SendableErasedView(view: AnyView(actions()))
    showErrorAlert(error: error, buttons: {
        erasedActions.view
    })
}

/// Presents a confirmation dialog with SwiftUI action content.
func showConfirmationDialog<Actions: View>(
    title: String,
    message: String? = nil,
    @ViewBuilder actions: @escaping @Sendable () -> Actions
) {
    let erasedActions = SendableErasedView(view: AnyView(actions()))
    showAlert(.confirmationDialog, title: title, subtitle: message, buttons: {
        erasedActions.view
    })
}

/// Presents a lightweight overlay using the package's default presentation configuration.
func showModal<Content: View>(
    backgroundColor: Color = Color.black.opacity(0.6),
    backgroundTransition: AnyTransition = .opacity.animation(.smooth),
    animation: Animation = .smooth,
    backgroundTapDismissesModal: Bool = true,
    @ViewBuilder screen: @escaping () -> Content
) {
    showModal(
        backgroundColor: backgroundColor,
        backgroundTransition: backgroundTransition,
        animation: animation,
        backgroundTapDismissesModal: backgroundTapDismissesModal,
        screen: screen
    )
}
```

- [ ] **Step 5: Add concrete timing test for multi-view `showModal`**

Add near the existing concrete timing test:

```swift
@Test("Concrete RouterView showModal view-builder overload evaluates overlay builder immediately")
func concreteShowModalViewBuilderOverloadEvaluatesOverlayBuilderImmediately() {
    let router: any Router = RouterView { _ in Text("Root") }
    var builderEvaluationCount = 0

    func countedContent() -> some View {
        builderEvaluationCount += 1
        return Text("Modal Content")
    }

    router.showModal {
        countedContent()
        Button("Continue") {}
    }

    #expect(builderEvaluationCount == 1)
}
```

- [ ] **Step 6: Run targeted tests and commit**

Run:

```bash
swift test --filter RouterProtocolTests
swift test --filter RouterViewIntegrationTests
```

Expected: both pass.

Commit:

```bash
git add Sources/ACRouting/Core/Router.swift Tests/ACRoutingTests/RouterProtocolTests.swift Tests/ACRoutingTests/RouterViewIntegrationTests.swift
git commit -m "feat: add router ergonomics overloads"
```

## Task 2: Documentation and Preview Catalog

**Files:**
- Modify: `README.md`
- Modify: `Sources/ACRouting/ACRouting.docc/ACRouting.md`
- Modify: `Sources/ACRouting/ACRouting.docc/PresentationSemantics.md`
- Modify: `Sources/ACRouting/ACRouting.docc/BuilderFirstIntegration.md`
- Modify: `Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md`
- Modify: `Sources/ACRouting/Previews/ACRoutingPreviewCatalog.swift`
- Modify: `CHANGELOG.md`
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Update README examples**

In `README.md`, update `1.5.2` references that describe the current supported examples to `1.5.3`.

Replace the alert example with:

```swift
router.showAlert(
    .alert,
    title: "Delete item",
    subtitle: "This action cannot be undone."
) {
    Button("Cancel", role: .cancel) {}
    Button("Delete", role: .destructive) {}
}
```

Add confirmation convenience example:

```swift
router.showConfirmationDialog(
    title: "Archive draft",
    message: "You can restore it later."
) {
    Button("Archive") {}
    Button("Cancel", role: .cancel) {}
}
```

Add an overlay builder example:

```swift
router.showModal {
    Text("Confirm")
    Button("Continue") {}
}
```

Add compatibility note:

```markdown
`AnyDestination`, `View.any()`, and `AnyView` alert actions remain available for source compatibility and internal type erasure, but new application call sites should prefer the typed builder overloads above.
```

- [ ] **Step 2: Update DocC pages**

Update `ACRouting.md` version notes and topic lists to include:

```markdown
- ``Router/showConfirmationDialog(title:message:actions:)``
- ``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)``
```

Update `PresentationSemantics.md` to explain:

```markdown
The `@ViewBuilder` overlay helper is an ergonomic wrapper over the existing overlay API. It still stores overlay content in the current routed context and does not create a routed modal container.

Alert and confirmation dialog action-builder overloads erase their actions internally, so application call sites do not need to wrap actions in `AnyView`.
```

Update `BuilderFirstIntegration.md` with one sentence:

```markdown
Ergonomic alert and overlay builders keep assembly at the app boundary; they do not move screen or action construction into `ACRouting`.
```

Update `DeepLinkInputModeling.md` only where a current-version boundary explicitly says `v1.5.2`.

- [ ] **Step 3: Update preview catalog**

In `OverlayAndAlertsDemoRoot`, replace the standard alert button action with:

```swift
router.showAlert(
    .alert,
    title: "Routing Saved",
    subtitle: "This alert is driven by router state."
) {
    Button("Close", role: .cancel) {
        router.dismissAlert()
    }
}
```

Replace confirmation dialog action with:

```swift
router.showConfirmationDialog(
    title: "Archive Draft Flow",
    message: "Confirmation dialogs are also modeled through the router."
) {
    Button("Archive") {
        router.dismissAlert()
    }

    Button("Cancel", role: .cancel) {
        router.dismissAlert()
    }
}
```

Keep the simple existing `showModal { OverlayExampleCard() }` style in the preview catalog because that demo presents a single overlay view. The README and DocC examples will show the same trailing-closure spelling with multi-view overlay content.

- [ ] **Step 4: Update changelog and roadmap**

In `CHANGELOG.md`, under `Unreleased`, add:

```markdown
### Added

- Added source-compatible `Router` overloads for typed alert actions, error-alert actions, confirmation dialogs, and multi-view overlay content.

### Changed

- Updated README, DocC, and preview catalog examples to prefer typed builder call sites over manual `AnyView` wrapping.
```

In `docs/ROADMAP.md`, add an `Already implemented` subsection under `v1.5.3` after implementation is complete:

```markdown
Already implemented:

- Additive `Router` extension overloads now support typed alert actions, error-alert actions, and confirmation dialogs, while the default `showModal` helper now supports multi-view `@ViewBuilder` overlay content.
- README, DocC, and the preview catalog now show the ergonomic call sites as the preferred public examples.
- Compatibility guidance now treats `AnyDestination`, `View.any()`, and `AnyView` alert actions as low-level type-erasure surfaces rather than preferred app-facing patterns.
```

- [ ] **Step 5: Parse changed Swift and commit**

Run:

```bash
swiftc -parse Sources/ACRouting/Previews/ACRoutingPreviewCatalog.swift
```

Expected: parse succeeds.

Commit:

```bash
git add README.md Sources/ACRouting/ACRouting.docc/ACRouting.md Sources/ACRouting/ACRouting.docc/PresentationSemantics.md Sources/ACRouting/ACRouting.docc/BuilderFirstIntegration.md Sources/ACRouting/ACRouting.docc/DeepLinkInputModeling.md Sources/ACRouting/Previews/ACRoutingPreviewCatalog.swift CHANGELOG.md docs/ROADMAP.md
git commit -m "docs: document 1.5.3 ergonomics"
```

## Task 3: Final Verification

**Files:**
- Inspect all changed files.

- [ ] **Step 1: Run full package tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [ ] **Step 2: Run package build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 3: Inspect diff for scope**

Run:

```bash
git status --short --branch
git diff --stat HEAD~2..HEAD
git log --oneline --decorate -5 --no-color
```

Expected: only planned API, tests, docs, preview catalog, roadmap, changelog, spec, and plan files changed.

- [ ] **Step 4: Commit plan status update after checklist edits**

After this plan checklist is updated during execution, commit the plan update:

```bash
git add docs/superpowers/plans/2026-05-02-v1-5-3-api-ergonomics.md
git commit -m "docs: update 1.5.3 implementation plan"
```
