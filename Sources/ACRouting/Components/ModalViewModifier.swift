//
//  ModalViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

private struct ModalViewModifier: ViewModifier {
    // MARK: - Properties
    
    @Binding var modal: AnyDestination?
    let backgroundColor: Color
    let backgroundTransition: AnyTransition
    let animation: Animation?
    let backgroundTapDismissesModal: Bool
    
    // MARK: - Methods
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .zIndex(0)
            
            if let modalContent = modal?.destination {
                backgroundColor
                    .ignoresSafeArea()
                    .zIndex(1)
                    .transition(backgroundTransition)
                    .onTapGesture {
                        if backgroundTapDismissesModal {
                            modal = nil
                        }
                    }
                
                modalContent
                    .zIndex(2)
            }
        }
        .animation(animation, value: modal)
    }
}

extension View {
    func modalViewModifier(
        modal: Binding<AnyDestination?>,
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation? = nil,
        backgroundTapDismissesModal: Bool = true
    ) -> some View {
        self
            .modifier(
                ModalViewModifier(
                    modal: modal,
                    backgroundColor: backgroundColor,
                    backgroundTransition: backgroundTransition,
                    animation: animation,
                    backgroundTapDismissesModal: backgroundTapDismissesModal
                )
            )
    }
}
