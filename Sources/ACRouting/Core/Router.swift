//
//  Router.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// Navigation API exposed to screens.
///
/// Key idea:
/// - Screens never touch NavigationStack / sheets directly.
/// - They only call `router.showScreen(...)` or `router.dismissScreen()`.
///
/// The destination builder receives a router instance:
/// each pushed/presented screen receives a router that will route to the correct stack/context.
@MainActor
public protocol Router {
    func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T)
    
    func dismissScreen()
    
    func showAlert(_ option: AlertType, title: String, subtitle: String?, buttons: (@Sendable () -> AnyView)?)
    
    func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)?)
    
    func dismissAlert()
    
    func showModal<T>(
        backgroundColor: Color,
        backgroundTransition: AnyTransition,
        animation: Animation,
        backgroundTapDismissesModal: Bool,
        screen: @escaping () -> T
    ) where T : View
    
    func dismissModal()
}

extension Router {
    func showAlert(_ option: AlertType, title: String, subtitle: String? = nil, buttons: (@Sendable () -> AnyView)? = nil) {
        showAlert(option, title: title, subtitle: subtitle, buttons: buttons)
    }
    
    func showModal<T>(
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation = .easeInOut,
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
    /// ⚠️ NOTE ABOUT `@Entry` + default value:
    /// - The default `MockRouter()` is ONLY a fallback to avoid runtime crashes if a screen
    ///   is rendered outside a RouterView.
    /// - In production you expect `.environment(\.router, self)` to always override this.
    /// - If you see "MockRouter does not work" in console, it means the view is not inside RouterView.
    @Entry var router: Router = MockRouter()
}


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
        screen: @escaping () -> T
    ) where T : View {
        print("MockRouter does not work")
    }
    
    func dismissModal() {
        print("MockRouter does not work")
    }
}
