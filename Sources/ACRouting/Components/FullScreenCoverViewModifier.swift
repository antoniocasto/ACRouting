//
//  FullScreenCoverViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

extension View {
    /// Presents a full screen modal whenever `screen != nil`.
    /// It uses `Binding(ifNotNil:)` so that:
    /// - presenting is driven by setting `screen = AnyDestination(...)`
    /// - dismissing (including swipe-to-dismiss) sets `screen = nil`
    func fullScreenCoverViewModifier(screen: Binding<AnyDestination?>) -> some View {
        self.fullScreenCover(isPresented: Binding(ifNotNil: screen)) {
            ZStack {
                if let screen = screen.wrappedValue {
                    screen.destination
                }
            }
        }
    }
}
