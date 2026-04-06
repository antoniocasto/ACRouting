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
    /// - on macOS, the public API is preserved but the implementation falls back to `.sheet`
    func fullScreenCoverViewModifier(screen: Binding<AnyDestination?>) -> some View {
        #if os(macOS)
        // SwiftUI does not provide fullScreenCover on macOS, so we use sheet
        // to keep the API compileable and behaviorally close for desktop hosts.
        self.sheet(isPresented: Binding(ifNotNil: screen)) {
            ZStack {
                if let screen = screen.wrappedValue {
                    screen.destination
                }
            }
        }
        #else
        self.fullScreenCover(isPresented: Binding(ifNotNil: screen)) {
            ZStack {
                if let screen = screen.wrappedValue {
                    screen.destination
                }
            }
        }
        #endif
    }
}
