//
//  RouterView.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

struct RouterPresentationState {
    var routedModal: RoutedModalPresentation?
}

enum RoutedModalPresentation {
    case sheet(AnyDestination)
    case fullScreenCover(AnyDestination)

    var destination: AnyDestination {
        switch self {
        case .sheet(let destination), .fullScreenCover(let destination):
            return destination
        }
    }

    var option: SegueOption {
        switch self {
        case .sheet:
            return .sheet
        case .fullScreenCover:
            return .fullScreenCover
        }
    }
}

/// A SwiftUI container that owns routing state and exposes it through `Router`.
///
/// `RouterView` is the package's routing runtime:
/// - root and modal router views own a local navigation stack;
/// - pushed child router views inherit the ancestor push stack binding;
/// - every presented destination is wrapped in another `RouterView` so routing stays available throughout the flow.
///
/// This design keeps feature views independent from raw SwiftUI navigation state while still allowing deterministic stack mutation.
public struct RouterView<Content: View>: View, Router {
    // MARK: Initialization

    /// Creates a router view that owns its own navigation context.
    ///
    /// Use this initializer for:
    /// - the root `RouterView` in your app or feature flow;
    /// - modal flow roots created by the package.
    ///
    /// - Parameter content: A view builder that receives the current router.
    public init(@ViewBuilder content: @escaping (any Router) -> Content) {
        self._inheritedPushStack = .constant([])
        self._ancestorRoutedModalPresentation = .constant(nil)
        self.usesInheritedPushStack = false
        self.ownsNavigationStack = true
        self.content = content
    }

    /// Creates a router view that inherits push state from an ancestor router.
    ///
    /// Use this initializer only for pushed child router views that should mutate an existing push stack.
    ///
    /// - Parameters:
    ///   - inheritedPushStack: A mutable push stack inherited from an ancestor router.
    ///   - content: A view builder that receives the current router.
    init(
        inheritedPushStack: Binding<[AnyDestination]>,
        ancestorRoutedModalPresentation: Binding<RoutedModalPresentation?> = .constant(nil),
        @ViewBuilder content: @escaping (any Router) -> Content
    ) {
        self._inheritedPushStack = inheritedPushStack
        self._ancestorRoutedModalPresentation = ancestorRoutedModalPresentation
        self.usesInheritedPushStack = true
        self.ownsNavigationStack = false
        self.content = content
    }

    /// Creates a modal flow root that keeps a binding to the presenter modal state.
    ///
    /// This initializer is internal to the package because only routed modal
    /// presentations should inject an ancestor modal presentation binding.
    init(
        ancestorRoutedModalPresentation: Binding<RoutedModalPresentation?>,
        @ViewBuilder content: @escaping (any Router) -> Content
    ) {
        self._inheritedPushStack = .constant([])
        self._ancestorRoutedModalPresentation = ancestorRoutedModalPresentation
        self.usesInheritedPushStack = false
        self.ownsNavigationStack = true
        self.content = content
    }

    // MARK: Properties

    @Environment(\.dismiss) private var dismiss

    /// Routed modal presentation state for `.sheet` and `.fullScreenCover`.
    @State private var presentationState = RouterPresentationState()

    /// Custom overlay destination presented above the current routed context.
    @State private var overlayDestination: AnyDestination?
    @State private var overlayBackgroundColor: Color = Color.black.opacity(0.6)
    @State private var overlayBackgroundTransition: AnyTransition = .opacity
    @State private var overlayAnimation: Animation = .smooth
    @State private var overlayTapDismisses = true
    
    /// The currently presented SwiftUI alert configuration.
    @State private var activeAlert: AnyAppAlert?
    @State private var activeAlertType = AlertType.alert

    /// `pushPath` is the source of truth for push navigation when this router owns a `NavigationStack`.
    /// In practice:
    /// - root and modal router views drive their own `NavigationStack` with this path;
    /// - pushed child router views ignore this local path and mutate `inheritedPushStack` instead.
    @State private var pushPath: [AnyDestination] = []

    /// `inheritedPushStack` is a binding to a stack owned by an ancestor RouterView.
    /// This is what allows a pushed screen (wrapped in a child RouterView) to keep pushing
    /// onto the SAME root stack without creating nested NavigationStacks.
    @Binding private var inheritedPushStack: [AnyDestination]

    /// A binding to the first ancestor routed modal presentation, when one exists.
    @Binding private var ancestorRoutedModalPresentation: RoutedModalPresentation?

    /// Tracks whether push mutations should target the parent binding or the local stack.
    /// This avoids inferring ownership from the current stack contents.
    private let usesInheritedPushStack: Bool

    /// Indicates whether this router owns a local `NavigationStack`.
    private let ownsNavigationStack: Bool

    /// Content builder. The root content receives `self` as the Router.
    @ViewBuilder private var content: (any Router) -> Content

    // MARK: Body

    public var body: some View {
        NavigationStackIfNeeded(pushPath: $pushPath, ownsNavigationStack: ownsNavigationStack) {
            content(self)
                .sheetDestinationModifier(destination: routedSheetDestinationBinding)
                .fullScreenCoverDestinationModifier(destination: routedFullScreenCoverDestinationBinding)
                .routerAlertModifier($activeAlert, type: activeAlertType)
        }
        .overlayPresentationModifier(
            destination: $overlayDestination,
            backgroundColor: overlayBackgroundColor,
            backgroundTransition: overlayBackgroundTransition,
            animation: overlayAnimation,
            tapDismissesOverlay: overlayTapDismisses
        )
        .environment(\.router, self)
    }

    // MARK: Router methods

    /// Wraps the destination in another router view and presents it using the requested segue style.
    ///
    /// Push presentations inherit the current push stack so nested screens keep mutating the
    /// same navigation state. Modal presentations start a fresh routed flow with their own
    /// local navigation stack.
    public func showScreen<T: View>(_ option: SegueOption, @ViewBuilder destination: @escaping (any Router) -> T) {
        let wrappedScreen: RouterView<T>

        switch option {
        case .push:
            wrappedScreen = RouterView<T>(
                inheritedPushStack: pushStackBinding,
                ancestorRoutedModalPresentation: ancestorRoutedModalPresentationBinding
            ) { newRouter in
                destination(newRouter)
            }
        case .sheet, .fullScreenCover:
            wrappedScreen = RouterView<T>(
                ancestorRoutedModalPresentation: routedModalPresentationBinding
            ) { newRouter in
                destination(newRouter)
            }
        }

        let routedDestination = AnyDestination(destination: wrappedScreen)

        switch option {
        case .push:
            mutatePushStack { stack in
                stack.append(routedDestination)
            }
        case .sheet:
            presentationState.routedModal = .sheet(routedDestination)
        case .fullScreenCover:
            presentationState.routedModal = .fullScreenCover(routedDestination)
        }
    }

    /// Dismisses the current presentation context.
    ///
    /// In pushed child flows this removes the top-most pushed destination from the inherited
    /// stack. In root or modal router views it delegates to SwiftUI dismissal.
    public func dismissScreen() {
        if usesInheritedPushStack {
            pop()
        } else {
            dismiss()
        }
    }

    /// Dismisses the first ancestor routed modal from a pushed child flow.
    ///
    /// This action is available only when the current router was pushed inside a
    /// sheet or full-screen cover flow. Root screens and modal roots should keep
    /// using `dismissScreen()` to close their current presentation context.
    public func dismissAncestorModal() {
        guard usesInheritedPushStack, ancestorRoutedModalPresentation != nil else {
            #if DEBUG
            debugPrint("dismissAncestorModal() called without an ancestor routed modal.")
            #endif
            return
        }

        ancestorRoutedModalPresentation = nil
    }

    /// Removes the top-most destination from the active push stack.
    public func pop() {
        pop(count: 1)
    }

    /// Removes up to `count` destinations from the active push stack.
    ///
    /// Non-positive counts are ignored, and oversized counts clamp to the current stack depth.
    public func pop(count: Int) {
        guard count > 0 else { return }

        mutatePushStack { stack in
            guard !stack.isEmpty else { return }
            let elementsToRemove = min(count, stack.count)
            stack.removeLast(elementsToRemove)
        }
    }

    /// Clears the active push stack, returning the current flow to its routed root.
    public func popToRoot() {
        mutatePushStack { stack in
            stack.removeAll()
        }
    }
    
    /// Stores the data needed to present a standard alert or confirmation dialog.
    public func showAlert(_ option: AlertType, title: String, subtitle: String? = nil, buttons: (@Sendable () -> AnyView)? = nil) {
        activeAlertType = option
        activeAlert = AnyAppAlert(title: title, message: subtitle, actions: buttons)
    }
    
    /// Stores the data needed to present an error alert using the error's localized description.
    public func showErrorAlert(error: any Error, buttons: (@Sendable () -> AnyView)? = nil) {
        activeAlertType = .alert
        activeAlert = AnyAppAlert(error: error, actions: buttons)
    }
    
    /// Clears the currently presented alert configuration.
    public func dismissAlert() {
        activeAlert = nil
    }
    
    /// Stores the configuration for a custom overlay presented above the current routed context.
    ///
    /// Unlike `.sheet` and `.fullScreenCover`, this does not create a new routed flow.
    /// The overlay keeps using the current router context, which makes it suitable for
    /// lightweight UI such as custom alerts, confirmations, or loading states.
    public func showModal<T>(
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation = .smooth,
        backgroundTapDismissesModal: Bool = true,
        screen: @escaping () -> T
    ) where T : View {
        overlayBackgroundColor = backgroundColor
        overlayBackgroundTransition = backgroundTransition
        overlayAnimation = animation
        overlayTapDismisses = backgroundTapDismissesModal
        overlayDestination = AnyDestination(destination: screen())
    }
    
    /// Clears the currently presented overlay configuration.
    public func dismissModal() {
        overlayDestination = nil
    }

    /// Returns the binding that should receive push mutations in the current routed context.
    private var pushStackBinding: Binding<[AnyDestination]> {
        usesInheritedPushStack ? $inheritedPushStack : $pushPath
    }

    /// A binding to the currently presented routed modal owned by this router.
    private var routedModalPresentationBinding: Binding<RoutedModalPresentation?> {
        Binding(
            get: { presentationState.routedModal },
            set: { presentationState.routedModal = $0 }
        )
    }

    /// A binding to the first ancestor routed modal presentation when available.
    private var ancestorRoutedModalPresentationBinding: Binding<RoutedModalPresentation?> {
        Binding(
            get: { ancestorRoutedModalPresentation },
            set: { ancestorRoutedModalPresentation = $0 }
        )
    }

    /// Maps the unified presentation state to the sheet modifier's expected destination binding.
    private var routedSheetDestinationBinding: Binding<AnyDestination?> {
        Binding(
            get: {
                guard case .sheet(let destination)? = presentationState.routedModal else {
                    return nil
                }
                return destination
            },
            set: { newValue in
                switch newValue {
                case .some(let destination):
                    presentationState.routedModal = .sheet(destination)
                case nil:
                    guard case .sheet = presentationState.routedModal else { return }
                    presentationState.routedModal = nil
                }
            }
        )
    }

    /// Maps the unified presentation state to the full-screen modifier's expected destination binding.
    private var routedFullScreenCoverDestinationBinding: Binding<AnyDestination?> {
        Binding(
            get: {
                guard case .fullScreenCover(let destination)? = presentationState.routedModal else {
                    return nil
                }
                return destination
            },
            set: { newValue in
                switch newValue {
                case .some(let destination):
                    presentationState.routedModal = .fullScreenCover(destination)
                case nil:
                    guard case .fullScreenCover = presentationState.routedModal else { return }
                    presentationState.routedModal = nil
                }
            }
        )
    }

    /// Applies a mutation to the active push stack and verifies inherited stack writes in debug builds.
    ///
    /// The assertion documents an internal invariant: pushed child router views must receive
    /// a mutable inherited binding, otherwise their stack mutations would be silently lost.
    private func mutatePushStack(_ update: (inout [AnyDestination]) -> Void) {
        let originalStack = pushStackBinding.wrappedValue
        var updatedStack = originalStack
        update(&updatedStack)
        pushStackBinding.wrappedValue = updatedStack

        guard usesInheritedPushStack, updatedStack != originalStack else { return }
        let persistedStack = inheritedPushStack

        assert(
            persistedStack == updatedStack,
            "RouterView(inheritedPushStack:) requires a mutable binding to an inherited push stack."
        )
    }
}

#if DEBUG
extension RouterView {
    /// Test-only helper that creates the pushed child router used inside the current flow.
    func makePushedChildRouterForTesting() -> RouterView<EmptyView> {
        RouterView<EmptyView>(
            inheritedPushStack: pushStackBinding,
            ancestorRoutedModalPresentation: ancestorRoutedModalPresentationBinding
        ) { _ in
            EmptyView()
        }
    }

    /// Test-only helper that creates a pushed child router wired to an externally tracked routed modal.
    static func makeChildRouterForTesting(
        inheritedPushStack: Binding<[AnyDestination]>,
        ancestorModalDestination: Binding<AnyDestination?>,
        option: SegueOption
    ) -> RouterView<EmptyView> {
        RouterView<EmptyView>(
            inheritedPushStack: inheritedPushStack,
            ancestorRoutedModalPresentation: makeAncestorRoutedModalPresentationBinding(
                destination: ancestorModalDestination,
                option: option
            )
        ) { _ in
            EmptyView()
        }
    }

    /// Test-only helper that wires an external routed modal binding into a modal root and one pushed child.
    static func makePresentedModalFlowForTesting(
        _ option: SegueOption,
        destination: Binding<AnyDestination?>
    ) -> (modalRoot: RouterView<EmptyView>, pushedChild: RouterView<EmptyView>)? {
        guard option != .push else { return nil }

        let ancestorBinding = makeAncestorRoutedModalPresentationBinding(destination: destination, option: option)
        let modalRoot = RouterView<EmptyView>(ancestorRoutedModalPresentation: ancestorBinding) { _ in
            EmptyView()
        }
        destination.wrappedValue = AnyDestination(destination: modalRoot)
        return (modalRoot, modalRoot.makePushedChildRouterForTesting())
    }

    /// Maps an external routed modal destination to the internal presentation enum used by the router.
    private static func makeAncestorRoutedModalPresentationBinding(
        destination: Binding<AnyDestination?>,
        option: SegueOption
    ) -> Binding<RoutedModalPresentation?> {
        Binding(
            get: {
                guard let destination = destination.wrappedValue else { return nil }

                switch option {
                case .push:
                    return nil
                case .sheet:
                    return .sheet(destination)
                case .fullScreenCover:
                    return .fullScreenCover(destination)
                }
            },
            set: { newValue in
                destination.wrappedValue = newValue?.destination
            }
        )
    }
}
#endif
