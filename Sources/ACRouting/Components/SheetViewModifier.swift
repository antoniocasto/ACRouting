//
//  SheetViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

extension View {
    /// Presents a modal whenever `screen != nil`.
    /// It uses `Binding(ifNotNil:)` so that:
    /// - presenting is driven by setting `screen = AnyDestination(...)`
    /// - dismissing (including swipe-to-dismiss) sets `screen = nil`
    func sheetViewModifier(screen: Binding<AnyDestination?>) -> some View {
        self.sheet(isPresented: Binding(ifNotNil: screen)) {
            ZStack {
                if let screen = screen.wrappedValue {
                    screen.destination
                }
            }
        }
    }
}
