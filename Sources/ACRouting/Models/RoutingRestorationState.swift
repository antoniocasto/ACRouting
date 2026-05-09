import Foundation

/// A versioned, Codable restoration envelope for one routed context.
///
/// `ACRouting` owns the envelope shape, while applications own payload schema
/// versions, resolver policy versions, and the persistence storage backend.
public struct RoutingRestorationState<Payload>: Codable, Hashable, Sendable where Payload: Codable & Hashable & Sendable {
    /// The current restoration envelope version understood by this package.
    public static var currentEnvelopeVersion: Int { 1 }

    /// The `ACRouting` envelope format version.
    public let envelopeVersion: Int

    /// The app-owned encoded payload schema version.
    public let payloadSchemaVersion: Int

    /// The app-owned resolver policy version.
    public let resolverPolicyVersion: Int

    /// Optional app-owned identifier for the routed root this state belongs to.
    public let contextID: String?

    /// The push entries to restore in order inside one routed context.
    public let entries: [RoutingRestorationEntry<Payload>]

    /// Creates a restoration state for one routed context.
    ///
    /// - Parameters:
    ///   - envelopeVersion: The `ACRouting` envelope format version.
    ///   - payloadSchemaVersion: The app-owned payload schema version.
    ///   - resolverPolicyVersion: The app-owned resolver policy version.
    ///   - contextID: Optional app-owned routed root identifier.
    ///   - entries: The push entries to restore in order.
    public init(
        envelopeVersion: Int = Self.currentEnvelopeVersion,
        payloadSchemaVersion: Int,
        resolverPolicyVersion: Int,
        contextID: String? = nil,
        entries: [RoutingRestorationEntry<Payload>]
    ) {
        self.envelopeVersion = envelopeVersion
        self.payloadSchemaVersion = payloadSchemaVersion
        self.resolverPolicyVersion = resolverPolicyVersion
        self.contextID = contextID
        self.entries = entries
    }
}

/// One restorable push entry inside a routed context.
public struct RoutingRestorationEntry<Payload>: Codable, Hashable, Sendable where Payload: Codable & Hashable & Sendable {
    /// The app-owned routed intent to restore.
    public let intent: RoutedNavigationIntent<Payload>

    /// Creates a restorable push entry.
    ///
    /// - Parameter intent: The app-owned routed intent to restore.
    public init(intent: RoutedNavigationIntent<Payload>) {
        self.intent = intent
    }
}
