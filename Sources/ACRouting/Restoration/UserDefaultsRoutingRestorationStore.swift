import Foundation

/// A JSON-backed restoration store that persists a single routed stack in `UserDefaults`.
public struct UserDefaultsRoutingRestorationStore<Payload>: RoutingRestorationStore
where Payload: Codable & Hashable & Sendable {
    /// The `UserDefaults` key used for the encoded restoration envelope.
    public let key: String

    /// The `UserDefaults` instance backing this store.
    public let userDefaults: UserDefaults

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a `UserDefaults` restoration store.
    ///
    /// - Parameters:
    ///   - key: The `UserDefaults` key used for the encoded restoration envelope.
    ///   - userDefaults: The defaults suite to use. Defaults to `.standard`.
    ///   - encoder: The JSON encoder used to persist states.
    ///   - decoder: The JSON decoder used to load states.
    public init(
        key: String,
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.key = key
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    public func load() throws -> RoutingRestorationState<Payload>? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        do {
            return try decoder.decode(RoutingRestorationState<Payload>.self, from: data)
        } catch {
            throw RoutingRestorationStorageError.decodingFailed
        }
    }

    public func save(_ state: RoutingRestorationState<Payload>) throws {
        do {
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: key)
        } catch {
            throw RoutingRestorationStorageError.encodingFailed
        }
    }

    public func clear() throws {
        userDefaults.removeObject(forKey: key)
    }
}
