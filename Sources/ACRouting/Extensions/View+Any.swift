//
//  View+Any.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 21/02/26.
//

import SwiftUI

public extension View {
    @MainActor
    func any() -> AnyView {
        AnyView(self)
    }
}
