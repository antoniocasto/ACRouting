import SwiftUI

public extension Router {
    /// Presents a routed intent and records it for restoration only when it resolves to `.push`.
    ///
    /// Persistence errors are thrown after the router has scheduled a supported push
    /// presentation. Non-push presentations remain transient and are not tracked in
    /// the current restoration scope.
    @discardableResult
    func showRestorableScreen<Resolver>(
        _ intent: RoutedNavigationIntent<Resolver.Payload>,
        using resolver: Resolver,
        restoration: RoutingRestorationController<Resolver.Payload>
    ) throws -> RoutedNavigationResolution<Resolver.Payload>
    where Resolver: RoutedNavigationIntentResolving {
        let presentation = resolver.canResolve(intent.payload) ? resolver.presentation(for: intent.payload) : nil
        let result = showScreen(intent, using: resolver)

        if case .presented = result, presentation == .push {
            try restoration.recordPresentedPush(intent)
        }

        return result
    }

    /// Pops one pushed restorable screen and records the matching restoration mutation.
    func popRestorableScreen<Payload>(
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        pop()
        try restoration.recordPop()
    }

    /// Pops pushed restorable screens and records the matching restoration mutation.
    func popRestorableScreens<Payload>(
        count: Int,
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        pop(count: count)
        try restoration.recordPop(count: count)
    }

    /// Dismisses the current pushed restorable screen and records the matching mutation.
    func dismissRestorableScreen<Payload>(
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        dismissScreen()
        try restoration.recordDismissScreen()
    }

    /// Pops the restorable push stack to root and records the matching mutation.
    func popRestorableStackToRoot<Payload>(
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        popToRoot()
        try restoration.recordPopToRoot()
    }
}
