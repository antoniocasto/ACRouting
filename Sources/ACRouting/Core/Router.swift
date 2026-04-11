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
@MainActor
public protocol Router {
    /// Presents a destination using the requested segue style.
    ///
    /// - Parameters:
    ///   - option: The presentation style to use for the destination.
    ///   - destination: A builder that creates the presented view and receives the router for that destination context.
    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T)
    
    /// Dismisses the current presentation context.
    ///
    /// In pushed child flows this removes the current pushed destination from the inherited stack.
    /// In root or modal contexts it delegates to SwiftUI dismissal.
    func dismissScreen()

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
    /// Convenience wrapper for removing a single pushed destination.
    func pop() {
        pop(count: 1)
    }

    /// Convenience wrapper for presenting an alert without a subtitle or custom actions.
    func showAlert(_ option: AlertType, title: String, subtitle: String? = nil, buttons: (@Sendable () -> AnyView)? = nil) {
        showAlert(option, title: title, subtitle: subtitle, buttons: buttons)
    }
    
    /// Convenience wrapper for presenting an error alert without custom actions.
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)? = nil) {
        showErrorAlert(error: error, buttons: buttons)
    }
    
    /// Convenience wrapper for presenting a custom overlay with package defaults.
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

// MARK: - Router environment injection

public extension EnvironmentValues {
    /// The router available to views inside a `RouterView`.
    ///
    /// The default `MockRouter` prevents runtime crashes when a view is rendered outside a routed
    /// context, for example in previews or isolated tests. Production code should expect a real
    /// router injected by `RouterView`.
    @Entry var router: Router = MockRouter()
}

/// Fallback router used when a view reads `EnvironmentValues.router` outside `RouterView`.
struct MockRouter: Router {
    func showScreen<T: View>(
        _ option: SegueOption,
        @ViewBuilder destination: @escaping (any Router) -> T
    ) {
        print("MockRouter does not work")
    }
    
    func dismissScreen() {
        print("MockRouter does not work")
    }

    func pop() {
        print("MockRouter does not work")
    }

    func pop(count: Int) {
        print("MockRouter does not work")
    }

    func popToRoot() {
        print("MockRouter does not work")
    }
    
    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?) {
        print("MockRouter does not work")
    }
    
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)? = nil) {
        print("MockRouter does not work")
    }
    
    func dismissAlert() {
        print("MockRouter does not work")
    }
    
    func showModal<T>(
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation = .smooth,
        backgroundTapDismissesModal: Bool = true,
        screen: @escaping () -> T
    ) where T : View {
        print("MockRouter does not work")
    }
    
    func dismissModal() {
        print("MockRouter does not work")
    }
}
