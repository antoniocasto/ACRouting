//
//  View+Any.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 21/02/26.
//

import SwiftUI

public extension View {
    /// Type-erases the current view so heterogeneous routed destinations can share one collection.
    nonisolated func any() -> AnyView {
        AnyView(self)
    }
}
