import Foundation

/// A serializable routed navigation request.
///
/// The payload is app-owned navigation intent. `ACRouting` stores only this payload value;
/// apps remain responsible for resolving it into a presentation style and concrete view.
public struct RoutedNavigationIntent<Payload>: Codable, Hashable, Sendable where Payload: Codable & Hashable & Sendable {
    /// The app-owned serializable navigation payload.
    public let payload: Payload

    /// Creates a routed navigation intent.
    ///
    /// - Parameter payload: The app-owned serializable payload.
    public init(payload: Payload) {
        self.payload = payload
    }
}

/// The result of attempting to present a routed navigation intent through a resolver.
public enum RoutedNavigationResolution<Payload>: Equatable, Sendable where Payload: Codable & Hashable & Sendable {
    /// The resolver accepted the payload and the router scheduled presentation.
    case presented(RoutedNavigationIntent<Payload>)

    /// The resolver rejected the payload and the router did not present anything.
    case unsupported(RoutedNavigationIntent<Payload>)

    /// The intent associated with this result.
    public var intent: RoutedNavigationIntent<Payload> {
        switch self {
        case .presented(let intent), .unsupported(let intent):
            intent
        }
    }
}
