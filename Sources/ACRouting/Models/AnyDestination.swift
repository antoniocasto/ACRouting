//
//  AnyDestination.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// A Hashable wrapper used as an element of NavigationStack's `path`.
///
/// NavigationStack requires Hashable elements, but SwiftUI `View` is not Hashable.
/// So we store:
/// - a stable Hashable identity (UUID string)
/// - the actual destination view, type-erased as AnyView
struct AnyDestination: Hashable {
    // MARK: - Initializer
    
    /// Wrap any SwiftUI view into AnyView
    @MainActor
    init<T: View>(destination: T) {
        self.destination = destination.any()
    }
    
    // MARK: - Properties
    
    /// We generate a unique id so every pushed screen is considered different,
    /// even if it shows the same view type.
    let id = UUID().uuidString

    /// Type-erased destination. Needed because `path` must store a single type.
    var destination: AnyView
    
    // MARK: - Methods

    /// Hash/Equatable are based only on `id`.
    /// This means identity is not derived from the view content.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AnyDestination, rhs: AnyDestination) -> Bool {
        lhs.id == rhs.id
    }
}
