//
//  View+Any.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 21/02/26.
//

import SwiftUI

public extension View {
    /// Type-erases the current view.
    ///
    /// `ACRouting` uses this helper internally so heterogeneous routed destinations can share one
    /// push stack or presentation slot without exposing view-type details.
    ///
    /// - Returns: An `AnyView` wrapping the current view.
    nonisolated func any() -> AnyView {
        AnyView(self)
    }
}
