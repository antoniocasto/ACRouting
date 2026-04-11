//
//  SheetViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

extension View {
    /// Presents a sheet whenever a routed destination is available.
    ///
    /// `Binding(ifNotNil:)` keeps the optional destination as the single source of truth:
    /// assigning a destination presents the sheet, and any system dismissal clears it.
    func sheetDestinationModifier(destination: Binding<AnyDestination?>) -> some View {
        self.sheet(isPresented: Binding(ifNotNil: destination)) {
            ZStack {
                if let destination = destination.wrappedValue {
                    destination.view
                }
            }
        }
    }
}
