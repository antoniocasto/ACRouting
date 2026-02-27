//
//  View+Any.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 21/02/26.
//

import SwiftUI

extension View {
    func any() -> AnyView {
        AnyView(self)
    }
}
