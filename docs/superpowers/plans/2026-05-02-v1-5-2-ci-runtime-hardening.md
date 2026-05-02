# v1.5.2 CI and Runtime Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a conservative `v1.5.2` hardening patch that makes CI match the repository workflow, removes maintainer-only hosting notes from the public repo, and tightens behavioral documentation/tests before restoration work starts.

**Architecture:** Keep this release additive-free: no new routing APIs, no restoration work, and no package-owned route registry. CI changes stay in `.github/workflows/ci.yml`; public-surface cleanup stays in README/roadmap/docs; behavior coverage stays in the existing Swift Testing suite.

**Tech Stack:** Swift Package Manager, Swift 6.2, SwiftUI, Swift Testing, GitHub Actions, Xcode `xcodebuild`.

---

## Decisions

- [x] Treat `v1.5.2` as operational and behavioral hardening only.
- [x] Run CI on PRs targeting `develop` and `main`.
- [x] Keep the existing stable CI job name shape while adding real iOS simulator test execution.
- [x] Remove `xcpretty` instead of installing it.
- [x] Remove `docs/HostedDocumentation.md` from the repository rather than moving it elsewhere in public docs.
- [x] Document that concrete `RouterView.showModal` evaluates and stores overlay content immediately in the current routed context.
- [x] Defer API ergonomics work to a future `v1.5.3` note instead of adding overloads in `v1.5.2`.

## Task 1: Public Documentation Cleanup

**Files:**
- Modify: `README.md`
- Modify: `docs/ROADMAP.md`
- Modify: `Sources/ACRouting/ACRouting.docc/PresentationSemantics.md`
- Delete: `docs/HostedDocumentation.md`

- [x] Remove the `Docs hosting setup` link from `README.md`.
- [x] Delete `docs/HostedDocumentation.md`.
- [x] Keep the roadmap `v1.5.2` scope focused on hardening.
- [x] Add a detailed `v1.5.3` roadmap note for future API ergonomics, including `showModal` builder overloads and alert action ergonomics.
- [x] Clarify in DocC that `showModal` overlays are evaluated into the current router context by the concrete `RouterView`.

## Task 2: CI Hardening

**Files:**
- Modify: `.github/workflows/ci.yml`

- [x] Change `pull_request.branches` from `[main]` to `[develop, main]`.
- [x] Change `push.branches` from `[develop]` to `[develop, main]`.
- [x] Remove `xcpretty` pipelines from build and test steps.
- [x] Keep macOS test execution.
- [x] Add iOS simulator test execution with an explicit simulator destination using the existing matrix iOS version.
- [x] Keep artifact upload for failing `.xcresult` bundles.

## Task 3: Behavior Tests

**Files:**
- Modify: `Tests/ACRoutingTests/RouterViewIntegrationTests.swift`
- Modify: `Tests/ACRoutingTests/ModelTests.swift`

- [x] Replace fragile hash-value distinctness assertions with identity/equality assertions.
- [x] Add a concrete `RouterView.showModal` characterization test that proves the overlay builder is evaluated by the concrete router call.
- [x] Keep spy-router deferred builder tests because they document adapter behavior before a concrete router receives the call.

## Task 4: Verification

**Commands:**
- `swift test`
- `swift build`
- `swiftc -parse` over changed Swift files if full test execution is blocked.

- [x] Run local verification.
- [x] Inspect `git diff` for unrelated churn.
- [x] Update this checklist as tasks complete.
