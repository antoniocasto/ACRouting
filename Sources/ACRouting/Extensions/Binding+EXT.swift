//
//  Binding+EXT.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 23/02/26.
//

import SwiftUI

extension Binding where Value == Bool {
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
