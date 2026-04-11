//
//  AlertViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

extension View {
    /// Applies the package alert presentation associated with the current router state.
    @ViewBuilder
    func routerAlertModifier(
        _ configuration: Binding<AnyAppAlert?>,
        type: AlertType = .alert
    ) -> some View {
        switch type {
        case .alert:
            standardAlertPresentation(content: self, configuration: configuration)
        case .confirmationDialog:
            confirmationDialogPresentation(content: self, configuration: configuration)
        }
    }
    
    @ViewBuilder
    private func standardAlertPresentation(
        content: some View,
        configuration: Binding<AnyAppAlert?>
    ) -> some View {
        content
            .alert(configuration.wrappedValue?.title ?? "", isPresented: Binding(ifNotNil: configuration)) {
                if let actions = configuration.wrappedValue?.actions {
                    actions()
                }
            } message: {
                if let message = configuration.wrappedValue?.message {
                    Text(message)
                }
            }
    }
    
    @ViewBuilder
    private func confirmationDialogPresentation(
        content: some View,
        configuration: Binding<AnyAppAlert?>
    ) -> some View {
        content
            .confirmationDialog(configuration.wrappedValue?.title ?? "", isPresented: Binding(ifNotNil: configuration)) {
                if let actions = configuration.wrappedValue?.actions {
                    actions()
                }
            } message: {
                if let message = configuration.wrappedValue?.message {
                    Text(message)
                }
            }
    }
}
