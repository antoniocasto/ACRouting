import Foundation

/// Stores complete restoration envelopes for app-owned navigation payloads.
///
/// The protocol is intentionally small so applications can back restoration with
/// files, databases, keychain storage, cloud sync, or test doubles.
public protocol RoutingRestorationStore<Payload> {
    associatedtype Payload: Codable & Hashable & Sendable

    /// Loads the latest persisted restoration state, or `nil` when none exists.
    func load() throws -> RoutingRestorationState<Payload>?

    /// Persists a complete restoration state.
    func save(_ state: RoutingRestorationState<Payload>) throws

    /// Removes any persisted restoration state.
    func clear() throws
}

/// Stable storage error categories surfaced by built-in restoration stores.
public enum RoutingRestorationStorageError: Error, Equatable, Sendable {
    /// The restoration state could not be encoded for persistence.
    case encodingFailed

    /// Persisted restoration data could not be decoded as the requested payload type.
    case decodingFailed
}
