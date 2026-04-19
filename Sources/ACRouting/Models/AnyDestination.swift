//
//  AnyDestination.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// A hashable wrapper that stores one routed destination inside a navigation path.
///
/// `NavigationStack` requires hashable path elements, while SwiftUI views are not hashable.
/// `AnyDestination` keeps a unique identity alongside a type-erased destination view so routed
/// push stacks can hold heterogeneous screens.
///
/// Most package consumers do not create this type directly. It remains public because the
/// routing runtime uses it in public generic signatures and tests.
public struct AnyDestination: Hashable {
    // MARK: - Initializer
    
    /// Creates a hashable routed destination from a SwiftUI view.
    ///
    /// - Parameter destination: The destination view to type-erase and store in the routed navigation path.
    @MainActor
    public init<T: View>(destination: T) {
        self.view = destination.any()
    }
    
    // MARK: - Properties
    
    /// A unique identity so repeated presentations of the same view type remain distinct.
    let id = UUID().uuidString

    /// The stored destination view, type-erased so a single path can hold many view types.
    var view: AnyView
    
    // MARK: - Methods

    /// Hashes the destination using only its unique identity.
    ///
    /// - Parameter hasher: The hasher to update with this destination's identity.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Returns a Boolean value indicating whether two routed destinations share the same identity.
    public static func == (lhs: AnyDestination, rhs: AnyDestination) -> Bool {
        lhs.id == rhs.id
    }
}
