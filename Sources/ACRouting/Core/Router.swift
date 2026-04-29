//
//  Router.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// Navigation commands exposed to routed feature views.
///
/// The package keeps SwiftUI navigation state inside `RouterView`.
/// Screens only receive a `Router` and issue navigation commands through this protocol.
///
/// Every destination builder receives another `Router` instance so pushed and presented
/// views can keep routing without learning about the underlying stack implementation.
/// This keeps `ACRouting` focused on navigation while applications remain free to assemble
/// screens through their own builders, factories, or router adapters.
@MainActor
public protocol Router {
    /// Presents a destination using the requested segue style.
    ///
    /// - Parameters:
    ///   - option: The presentation style to use for the destination.
    ///   - destination: A builder that creates the presented view and receives the router for that destination context.
    ///
    /// Use this API to keep screen assembly at the call site or inside an app-owned adapter.
    /// `ACRouting` owns only the presentation state created from that destination.
    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T)
    
    /// Dismisses the current presentation context.
    ///
    /// In pushed child flows this removes the current pushed destination from the inherited stack.
    /// In root or modal contexts it delegates to SwiftUI dismissal.
    func dismissScreen()

    /// Dismisses the first ancestor routed modal from a pushed child flow.
    ///
    /// This API targets only routed modal containers created with `.sheet` or
    /// `.fullScreenCover`. It does not dismiss lightweight overlays shown with
    /// `showModal()`, and it is a no-op when no ancestor routed modal exists.
    ///
    /// Use this only from a pushed child that needs to close the first ancestor routed modal
    /// while keeping push semantics explicit.
    func dismissAncestorModal()

    /// Removes the top-most destination from the current push stack.
    func pop()

    /// Removes the given number of destinations from the current push stack.
    ///
    /// Non-positive counts are ignored. Counts larger than the current stack depth clamp to the available number of destinations.
    ///
    /// - Parameter count: The number of pushed destinations to remove.
    func pop(count: Int)

    /// Removes all pushed destinations from the current push stack.
    func popToRoot()
    
    /// Presents a standard alert or confirmation dialog.
    ///
    /// - Parameters:
    ///   - option: The SwiftUI alert presentation style to use.
    ///   - title: The alert title.
    ///   - subtitle: Optional secondary message text shown below the title.
    ///   - buttons: Optional custom action views rendered by SwiftUI.
    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?)
    
    /// Presents an alert configured from an error value.
    ///
    /// - Parameters:
    ///   - error: The error whose localized description becomes the alert message.
    ///   - buttons: Optional custom action views rendered by SwiftUI.
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)?)
    
    /// Dismisses the currently presented alert, if one exists.
    func dismissAlert()
    
    /// Presents a custom overlay above the current routed context.
    ///
    /// Unlike `.sheet` and `.fullScreenCover`, this API is intended for lightweight overlays
    /// such as custom alerts, blocking loaders, or bottom-sheet style presentations that should
    /// stay inside the current routed context.
    ///
    /// - Parameters:
    ///   - backgroundColor: The overlay background color.
    ///   - backgroundTransition: The transition used for the overlay background.
    ///   - animation: The animation applied when the overlay appears or disappears.
    ///   - backgroundTapDismissesModal: Whether tapping the dimmed background dismisses the overlay.
    ///   - screen: A builder that creates the overlay content.
    func showModal<T>(
        backgroundColor: Color,
        backgroundTransition: AnyTransition,
        animation: Animation,
        backgroundTapDismissesModal: Bool,
        screen: @escaping () -> T
    ) where T : View
    
    /// Dismisses the custom overlay shown by `showModal`, if one exists.
    func dismissModal()
}

public extension Router {
    /// Default no-op implementation so additive protocol evolution stays source-compatible.
    func dismissAncestorModal() {
        #if DEBUG
        RouterDiagnostics.emit(
            RouterDiagnostics.unsupportedAncestorModalDismissalMessage(
                conformer: String(reflecting: Self.self)
            )
        )
        #endif
    }

    /// Removes a single pushed destination from the current stack.
    func pop() {
        pop(count: 1)
    }

    /// Presents an alert or confirmation dialog without custom actions or secondary text.
    func showAlert(_ option: AlertType, title: String, subtitle: String? = nil, buttons: (@Sendable () -> AnyView)? = nil) {
        showAlert(option, title: title, subtitle: subtitle, buttons: buttons)
    }
    
    /// Presents an error alert without custom actions.
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)? = nil) {
        showErrorAlert(error: error, buttons: buttons)
    }
    
    /// Presents a lightweight overlay using the package's default presentation configuration.
    ///
    /// - Parameters:
    ///   - backgroundColor: The overlay background color. The default is a semi-opaque black.
    ///   - backgroundTransition: The transition applied to the overlay background.
    ///   - animation: The animation used when the overlay appears or disappears.
    ///   - backgroundTapDismissesModal: A Boolean value indicating whether tapping the background dismisses the overlay.
    ///   - screen: A builder that creates the overlay content.
    func showModal<T>(
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation = .smooth,
        backgroundTapDismissesModal: Bool = true,
        screen: @escaping () -> T
    ) where T : View {
        showModal(
            backgroundColor: backgroundColor,
            backgroundTransition: backgroundTransition,
            animation: animation,
            backgroundTapDismissesModal: backgroundTapDismissesModal
        ) {
            screen()
        }
    }
}

public extension Router {
    /// Presents a serializable routed navigation intent through an app-owned resolver.
    ///
    /// The resolver validates the payload before presentation. Supported payloads delegate to
    /// `showScreen(_:destination:)`, keeping the existing closure-based routing API as the runtime
    /// primitive. Unsupported payloads return `.unsupported` and do not change router state.
    ///
    /// - Parameters:
    ///   - intent: The serializable navigation intent to present.
    ///   - resolver: The app-owned resolver that validates and builds the destination.
    /// - Returns: The resolution result for the intent.
    @discardableResult
    func showScreen<Resolver>(
        _ intent: RoutedNavigationIntent<Resolver.Payload>,
        using resolver: Resolver
    ) -> RoutedNavigationResolution<Resolver.Payload> where Resolver: RoutedNavigationIntentResolving {
        guard resolver.canResolve(intent.payload) else {
            return .unsupported(intent)
        }

        showScreen(intent.presentation) { router in
            resolver.destination(for: intent.payload, router: router)
        }

        return .presented(intent)
    }
}

// MARK: - Router environment injection

public extension EnvironmentValues {
    /// The router available to views inside a `RouterView`.
    ///
    /// The default `MockRouter` prevents runtime crashes when a view is rendered outside a routed
    /// context, for example in previews or isolated tests. Production code should expect a real
    /// router injected by `RouterView`.
    ///
    /// Feature views can read this environment value directly, while larger applications can still
    /// prefer explicit dependency passing if they want tighter composition boundaries.
    @Entry var router: Router = MockRouter()
}

/// Fallback router used when a view reads `EnvironmentValues.router` outside `RouterView`.
enum RouterDiagnostics {
    static func missingRouterMessage(action: String) -> String {
        """
        ACRouting MockRouter intercepted \(action). This usually means a view read @Environment(\\.router) outside RouterView. Wrap that flow in RouterView or pass a real Router explicitly.
        """
    }

    static func unsupportedAncestorModalDismissalMessage(conformer: String) -> String {
        """
        dismissAncestorModal() is unavailable for Router conformer \(conformer). Provide a custom implementation if that conformer should support ancestor modal dismissal.
        """
    }

    static func emit(_ message: String) {
        #if DEBUG
        debugPrint(message)
        #endif
    }
}

struct MockRouter: Router {
    private func report(_ action: String) {
        RouterDiagnostics.emit(RouterDiagnostics.missingRouterMessage(action: action))
    }

    func showScreen<T: View>(
        _ option: SegueOption,
        @ViewBuilder destination: @escaping (any Router) -> T
    ) {
        report("showScreen(_:destination:)")
    }
    
    func dismissScreen() {
        report("dismissScreen()")
    }

    func dismissAncestorModal() {
        report("dismissAncestorModal()")
    }

    func pop() {
        report("pop()")
    }

    func pop(count: Int) {
        report("pop(count:)")
    }

    func popToRoot() {
        report("popToRoot()")
    }
    
    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?) {
        report("showAlert(_:title:subtitle:buttons:)")
    }
    
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)? = nil) {
        report("showErrorAlert(error:buttons:)")
    }
    
    func dismissAlert() {
        report("dismissAlert()")
    }
    
    func showModal<T>(
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation = .smooth,
        backgroundTapDismissesModal: Bool = true,
        screen: @escaping () -> T
    ) where T : View {
        report("showModal(backgroundColor:backgroundTransition:animation:backgroundTapDismissesModal:screen:)")
    }
    
    func dismissModal() {
        report("dismissModal()")
    }
}
