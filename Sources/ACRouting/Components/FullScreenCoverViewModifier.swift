//
//  FullScreenCoverViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

extension View {
    /// Presents a full-screen routed destination whenever one is available.
    ///
    /// `Binding(ifNotNil:)` keeps the optional destination as the presentation source of truth.
    /// On macOS, the public API is preserved while the implementation falls back to `.sheet`
    /// because SwiftUI does not provide `fullScreenCover`.
    func fullScreenCoverDestinationModifier(destination: Binding<AnyDestination?>) -> some View {
        #if os(macOS)
        self.sheet(isPresented: Binding(ifNotNil: destination)) {
            ZStack {
                if let destination = destination.wrappedValue {
                    destination.view
                }
            }
        }
        #else
        self.fullScreenCover(isPresented: Binding(ifNotNil: destination)) {
            ZStack {
                if let destination = destination.wrappedValue {
                    destination.view
                }
            }
        }
        #endif
    }
}
