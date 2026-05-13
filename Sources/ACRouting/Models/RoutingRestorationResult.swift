import Foundation

/// The result of attempting to restore a routed navigation state.
public enum RoutingRestorationResult<Payload>: Equatable, Sendable where Payload: Codable & Hashable & Sendable {
    /// Every entry in the restoration state was presented.
    case restored([RoutedNavigationResolution<Payload>])

    /// The resolver rejected an entry and restoration stopped before presenting it.
    case unsupported(
        RoutedNavigationIntent<Payload>,
        restored: [RoutedNavigationResolution<Payload>]
    )

    /// An entry resolved to a presentation style outside the supported `v1.6.0` restoration scope.
    case unsupportedPresentation(
        RoutedNavigationIntent<Payload>,
        presentation: SegueOption,
        restored: [RoutedNavigationResolution<Payload>]
    )

    /// The entries restored before restoration stopped or completed.
    public var restoredResolutions: [RoutedNavigationResolution<Payload>] {
        switch self {
        case .restored(let restored),
             .unsupported(_, let restored),
             .unsupportedPresentation(_, _, let restored):
            restored
        }
    }
}
