//
//  AlertViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func showAlert(_ alert: Binding<(AnyAppAlert)?>, type: AlertType = .alert) -> some View {
        switch type {
        case .alert:
            buildAlert(content: self, alert: alert)
        case .confirmationDialog:
            buildConfirmationDialog(content: self, alert: alert)
        }
        
    }
    
    @ViewBuilder
    private func buildAlert(content: some View, alert: Binding<(AnyAppAlert)?>) -> some View {
        content
            .alert(alert.wrappedValue?.title ?? "", isPresented: Binding(ifNotNil: alert)) {
                if let buttons = alert.wrappedValue?.buttons {
                    buttons()
                }
            } message: {
                if let subtitle = alert.wrappedValue?.subtitle {
                    Text(subtitle)
                }
            }
    }
    
    @ViewBuilder
    private func buildConfirmationDialog(content: some View, alert: Binding<(AnyAppAlert)?>) -> some View {
        content
            .confirmationDialog(alert.wrappedValue?.title ?? "", isPresented: Binding(ifNotNil: alert)) {
                if let buttons = alert.wrappedValue?.buttons {
                    buttons()
                }
            } message: {
                if let subtitle = alert.wrappedValue?.subtitle {
                    Text(subtitle)
                }
            }
    }
}
