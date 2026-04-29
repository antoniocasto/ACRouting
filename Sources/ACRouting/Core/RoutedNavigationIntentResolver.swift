import SwiftUI

/// Resolves app-owned navigation payloads into SwiftUI destinations.
///
/// Apps provide this resolver at the composition boundary. The resolver decides whether a
/// payload is supported and remains responsible for creating feature screens, presenters,
/// interactors, and app-specific router adapters.
@MainActor
public protocol RoutedNavigationIntentResolving {
    /// The serializable app-owned payload this resolver understands.
    associatedtype Payload: Codable & Hashable & Sendable

    /// The concrete destination view returned for supported payloads.
    associatedtype Destination: View

    /// Returns whether this resolver can build a destination for the payload.
    ///
    /// Unsupported payloads are not presented by `Router.showScreen(_:using:)`.
    func canResolve(_ payload: Payload) -> Bool

    /// Returns the routed presentation style to use for a supported payload.
    ///
    /// This keeps the decision about push, sheet, or full-screen presentation in the
    /// app-owned resolver instead of serializing it into the navigation payload.
    func presentation(for payload: Payload) -> SegueOption

    /// Builds the destination for a supported payload.
    ///
    /// - Parameters:
    ///   - payload: The app-owned navigation payload.
    ///   - router: The routed context router for the destination.
    @ViewBuilder
    func destination(for payload: Payload, router: any Router) -> Destination
}
