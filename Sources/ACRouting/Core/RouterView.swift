//
//  RouterView.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// A View that also implements `Router`.
///
/// Behavior:
/// - The root RouterView owns the NavigationStack + its `path` state.
/// - Child RouterViews may create a NEW NavigationStack (for modals) or no stack at all (for push),
///   but they still act as a Router and can push onto the correct stack via bindings.
///
/// Why a child RouterView exists at all?
/// - Because we want the next screen to keep having a `Router` available.
/// - So the pushed/presented destination is actually `RouterView<DestinationView>`.
/// 
public struct RouterView<Content: View>: View, Router {
    // MARK: - Initializerr

    /// `screenStack` is optionally provided from a parent RouterView.
    /// If nil, we use a constant empty array (root case).
    public init(screenStack: Binding<[AnyDestination]>? = nil, addNavigationView: Bool = true, content: @escaping (any Router) -> Content) {
        self._screenStack = screenStack ?? .constant([])
        self.addNavigationView = addNavigationView
        self.content = content
    }

    // MARK: Properties

    @Environment(\.dismiss) private var dismiss

    /// Modal destinations.
    /// These are optional because a modal can show at most one screen at a time.
    /// Setting them to `nil` dismisses the modal.
    @State private var showSheet: AnyDestination?
    @State private var showFullScreenCover: AnyDestination?
    @State private var modal: AnyDestination?
    @State private var modalBackgroundColor: Color = Color.black.opacity(0.6)
    @State private var modalBackgroundTransition: any Transition = .opacity
    @State private var modalBackgroundAnimation: Animation = .smooth
    @State private var modalBackgroundTapDismissesModal = true
    
    @State private var alert: AnyAppAlert?
    @State private var alertOption = AlertType.alert

    /// `path` is the "source of truth" for push navigation WHEN this RouterView owns a NavigationStack.
    /// In practice:
    /// - Root RouterView -> `path` drives the NavigationStack.
    /// - Child RouterViews -> `path` is unused if they don't create a NavigationStack.
    @State private var path: [AnyDestination] = []

    /// `screenStack` is a binding to a stack owned by an ancestor RouterView.
    /// This is what allows a pushed screen (wrapped in a child RouterView) to keep pushing
    /// onto the SAME root stack without creating nested NavigationStacks.
    ///
    /// Root case:
    /// - screenStack is `.constant([])` and will stay empty.
    ///
    /// Child case:
    /// - screenStack is bound to the root `path` (or another shared stack),
    ///   so pushes happen on that shared array.
    @Binding private var screenStack: [AnyDestination]

    /// Controls whether this RouterView creates a NavigationStack.
    /// Root: true. Children for push: false (to avoid nested NavigationStacks).
    /// Modals usually: true (new navigation context inside the modal).
    private let addNavigationView: Bool

    /// Content builder. The root content receives `self` as the Router.
    @ViewBuilder private var content: (any Router) -> Content

    // MARK: Body

    public var body: some View {
        // Root creates NavigationStack. Children may or may not, based on `addNavigationView`.
        NavigationStackIfNeeded(path: $path, addNavigationView: addNavigationView) {
            content(self)
                .sheetViewModifier(screen: $showSheet)
                .fullScreenCoverViewModifier(screen: $showFullScreenCover)
                .showAlert($alert, type: alertOption)
        }
        .modalViewModifier(
            modal: $modal,
            backgroundColor: modalBackgroundColor,
            backgroundTransition: modalBackgroundTransition,
            animation: modalBackgroundAnimation,
            backgroundTapDismissesModal: modalBackgroundTapDismissesModal
        )
        // Make the Router available down the view tree.
        .environment(\.router, self)
    }

    // MARK: Router methods

    public func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T) {

        // We always wrap the destination inside another RouterView.
        // Why?
        // - So the pushed/presented screen can keep using the Router API.
        // - That child RouterView will NOT necessarily create a NavigationStack.
        //
        // Stack binding decision:
        // - If `screenStack` is empty => we are the root router => bind to local `path`.
        // - Else => we are already inside a routed flow => propagate the existing binding,
        //   so every push keeps writing to the SAME root stack.
        //
        // NavigationStack creation decision:
        // - `.push` uses `shouldAddNewNavigationView == false`
        //   because the root stack already exists.
        // - `.sheet` / `.fullScreenCover` use `true`
        //   because modals are typically a NEW navigation context (fresh stack inside the modal).
        let wrappedScreen = RouterView<T>(
            screenStack: option.shouldAddNewNavigationView ? nil : ($screenStack.isEmpty ? $path : $screenStack),
            addNavigationView: option.shouldAddNewNavigationView
        ) { newRouter in
            // The pushed/presented view receives `newRouter`.
            // When that view calls showScreen(), it will append to the correct stack binding.
            destination(newRouter)
        }

        // ⚠️ IMPORTANT:
        // `destination` here is NOT the raw screen (SettingsView/AccountView).
        // It is a `RouterView<T>` wrapping that screen.
        // The actual type stored is therefore `AnyDestination(RouterView<T>)`.
        let destination = AnyDestination(destination: wrappedScreen)

        switch option {
        case .push:
            // Decide where to append:
            // - If `screenStack` is empty, this is the root router => append to local `path` (NavigationStack path)
            // - Otherwise, append to the inherited stack binding (which ultimately points to root `path`)
            if screenStack.isEmpty {
                // Root router: path drives the NavigationStack
                path.append(destination)
            } else {
                // Child router: push into the shared stack
                screenStack.append(destination)
            }
        case .sheet:
            showSheet = destination
        case .fullScreenCover:
            showFullScreenCover = destination
        }
    }

    /// Dismiss the current presentation context.
    /// - If called inside a pushed NavigationStack destination, it typically pops.
    /// - If called inside a sheet/fullScreenCover, it dismisses the modal.
    ///
    /// ⚠️ IMPORTANT LIMITATION:
    /// This method does NOT explicitly mutate `path` / `screenStack`.
    /// The navigation state is therefore not fully "state-driven".
    /// If you need deterministic navigation (deep links, tests, sync with state),
    /// prefer implementing pop by mutating the arrays (e.g. `path.removeLast()`).
    public func dismissScreen() {
        dismiss()
    }
    
    public func showAlert(_ option: AlertType, title: String, subtitle: String? = nil, buttons: (@Sendable () -> AnyView)? = nil) {
        alertOption = option
        alert = AnyAppAlert(title: title, subtitle: subtitle, buttons: buttons)
    }
    
    public func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)? = nil) {
        alertOption = .alert
        alert = AnyAppAlert(error: error)
    }
    
    public func dismissAlert() {
        alert = nil
    }
    
    public func showModal<T>(
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: any Transition = .opacity.animation(.smooth),
        animation: Animation = .smooth,
        backgroundTapDismissesModal: Bool = true,
        screen: @escaping () -> T
    ) where T : View {
        self.modalBackgroundColor = backgroundColor
        self.modalBackgroundTransition = backgroundTransition
        self.modalBackgroundAnimation = animation
        self.modalBackgroundTapDismissesModal = backgroundTapDismissesModal
        self.modal = AnyDestination(destination: screen())
    }
    
    public func dismissModal() {
        self.modal = nil
    }
}
