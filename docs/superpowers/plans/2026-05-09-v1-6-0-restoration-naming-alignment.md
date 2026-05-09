# v1.6.0 Restoration Naming Alignment Plan

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the ready-to-use restoration API names with the existing `ACRouting` style.

**Decision:** Prefer existing router verbs plus a `restoration:` label over new compound method names. Keep restoration-specific type names where they describe the domain model.

## Task 1: Rename Router Convenience API

- [x] Replace `showRestorableScreen(_:using:restoration:)` with `showScreen(_:using:restoration:)`.
- [x] Replace `popRestorableScreen(restoration:)` with `pop(restoration:)`.
- [x] Replace `popRestorableScreens(count:restoration:)` with `pop(count:restoration:)`.
- [x] Replace `dismissRestorableScreen(restoration:)` with `dismissScreen(restoration:)`.
- [x] Replace `popRestorableStackToRoot(restoration:)` with `popToRoot(restoration:)`.

## Task 2: Rename Controller Tracking API

- [x] Replace `recordPresentedPush(_:)` with `recordPush(_:)`.
- [ ] Keep `recordPop`, `recordDismissScreen`, and `recordPopToRoot` because they mirror existing router verbs and describe explicit tracking.

## Task 3: Update Tests And Documentation

- [x] Update Swift tests to compile against the renamed API.
- [x] Update README, DocC, CHANGELOG, ROADMAP, specs, and the ready-to-use restoration plan references.
- [x] Run `rg` to confirm the old names are gone.

## Task 4: Verification And PR Update

- [x] Run `swift build`.
- [x] Run `swift test`.
- [x] Commit the naming alignment.
- [ ] Push `codex/v1-6-0-restoration-foundation`.
- [ ] Update PR #50 body to use the aligned names.
