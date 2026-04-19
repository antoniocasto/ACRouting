/// `ACRouting` is a lightweight SwiftUI routing package built around `RouterView` and `Router`.
///
/// The public entry points are intentionally small:
/// - `RouterView` owns the routing runtime and injects a `Router` into the environment;
/// - `Router` exposes presentation and dismissal commands to feature views;
/// - `SegueOption` describes whether a destination should keep the current push stack or start a new routed modal flow.
///
/// Larger apps can keep screen assembly in app-owned builders, factories, or router adapters.
/// `ACRouting` focuses on navigation state and presentation semantics rather than on constructing feature modules.
