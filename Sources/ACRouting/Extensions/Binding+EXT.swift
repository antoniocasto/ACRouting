//
//  Binding+EXT.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 23/02/26.
//

import SwiftUI

extension Binding where Value == Bool {
    /// Creates a Boolean binding that reflects whether an optional binding currently contains a value.
    ///
    /// Setting the Boolean binding to `false` clears the optional. Setting it to `true`
    /// leaves the optional untouched because there is no value to synthesize automatically.
    @MainActor
    init<T>(ifNotNil value: Binding<T?>) {
        self.init {
            value.wrappedValue != nil
        } set: { newValue in
            if !newValue {
                value.wrappedValue = nil
            }
        }
    }
}
