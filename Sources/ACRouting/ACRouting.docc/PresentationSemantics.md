# Presentation Semantics

Understand how `ACRouting` treats push navigation, routed modals, overlays, and dismissal.

## Routed Push Flows

Use ``Router/showScreen(_:destination:)`` with ``SegueOption/push`` to append a destination to the current routed push stack.

Pushed destinations inherit the ancestor push stack instead of creating nested navigation stacks. Because of that:

- ``Router/pop()`` removes one pushed destination.
- ``Router/pop(count:)`` removes up to the requested number of pushed destinations.
- ``Router/popToRoot()`` clears the current routed push stack.
- ``Router/dismissScreen()`` behaves like a single pop when called from a pushed child.

## Routed Modal Flows

Use ``SegueOption/sheet`` or ``SegueOption/fullScreenCover`` when the next screen should start a fresh routed flow.

Each routed modal root owns:

- its own local push stack
- its own routed modal presentation state
- a fresh router value for screens presented inside that modal flow

When called from a modal root, ``Router/dismissScreen()`` dismisses the current modal presentation instead of mutating an ancestor push stack.

## Ancestor Modal Dismissal

``Router/dismissAncestorModal()`` is an additive API for one specific scenario: a pushed child inside a routed sheet or full-screen flow wants to close the first ancestor routed modal.

Current supported behavior:

- it targets only the first ancestor routed `.sheet` or `.fullScreenCover`
- it does not dismiss overlays created through ``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)``
- it is a no-op when the current routed context has no ancestor routed modal

## Overlays

``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)`` presents a lightweight overlay above the current routed context.

Unlike routed sheets or full-screen covers:

- it does not create a fresh routed flow
- it does not own a separate push stack
- it keeps using the current router context
- the concrete ``RouterView`` evaluates and stores the overlay content when ``Router/showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)`` is called

This makes it a good fit for custom alerts, transient confirmations, and blocking loading UI.

## Alerts

Use ``Router/showAlert(_:title:subtitle:buttons:)`` or ``Router/showErrorAlert(error:buttons:)`` to present SwiftUI alerts from the current routed context. Dismiss them with ``Router/dismissAlert()``.

## Missing Router Diagnostics

If a view reads ``EnvironmentValues/router`` outside ``RouterView``, the package falls back to a `MockRouter`. That fallback avoids crashes and emits debug guidance explaining how to inject a real router.

This behavior is especially useful in previews or isolated tests where a screen may render without the real routing runtime.
