import SwiftUI

public extension Router {
    /// Presents a routed intent and records it for restoration only when it resolves to `.push`.
    ///
    /// Persistence errors are thrown after the router has scheduled a supported push
    /// presentation. The restoration controller rolls back its tracked stack on
    /// persistence failure, but visible navigation is not automatically reversed.
    /// Non-push presentations remain transient and are not tracked in the current
    /// restoration scope.
    @discardableResult
    func showScreen<Resolver>(
        _ intent: RoutedNavigationIntent<Resolver.Payload>,
        using resolver: Resolver,
        restoration: RoutingRestorationController<Resolver.Payload>
    ) throws -> RoutedNavigationResolution<Resolver.Payload>
    where Resolver: RoutedNavigationIntentResolving {
        let presentation = resolver.canResolve(intent.payload) ? resolver.presentation(for: intent.payload) : nil
        let result = showScreen(intent, using: resolver)

        if case .presented = result, presentation == .push {
            try restoration.recordPush(intent)
        }

        return result
    }

    /// Pops one pushed restorable screen and records the matching restoration mutation.
    func pop<Payload>(
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        pop()
        try restoration.recordPop()
    }

    /// Pops pushed restorable screens and records the matching restoration mutation.
    func pop<Payload>(
        count: Int,
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        pop(count: count)
        try restoration.recordPop(count: count)
    }

    /// Dismisses the current pushed restorable screen and records the matching mutation.
    func dismissScreen<Payload>(
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        dismissScreen()
        try restoration.recordDismissScreen()
    }

    /// Pops the restorable push stack to root and records the matching mutation.
    func popToRoot<Payload>(
        restoration: RoutingRestorationController<Payload>
    ) throws where Payload: Codable & Hashable & Sendable {
        popToRoot()
        try restoration.recordPopToRoot()
    }
}
