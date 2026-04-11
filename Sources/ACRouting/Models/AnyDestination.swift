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
public struct AnyDestination: Hashable {
    // MARK: - Initializer
    
    /// Wraps a SwiftUI destination view in a type-erased, hashable container.
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

    /// Hash and equality are based only on `id`, not on the wrapped view value.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AnyDestination, rhs: AnyDestination) -> Bool {
        lhs.id == rhs.id
    }
}
