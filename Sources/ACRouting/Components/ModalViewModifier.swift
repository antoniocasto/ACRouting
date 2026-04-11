//
//  ModalViewModifier.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// Presents a lightweight overlay above the current routed context.
///
/// This modifier is intentionally separate from SwiftUI sheet APIs: it keeps the
/// current routed context alive and simply layers additional UI above it.
private struct OverlayPresentationModifier: ViewModifier {
    // MARK: - Properties
    
    @Binding var destination: AnyDestination?
    let backgroundColor: Color
    let backgroundTransition: AnyTransition
    let animation: Animation?
    let tapDismissesOverlay: Bool
    
    // MARK: - Methods
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .zIndex(0)
            
            if let overlayContent = destination?.view {
                backgroundColor
                    .ignoresSafeArea()
                    .zIndex(1)
                    .transition(backgroundTransition)
                    .onTapGesture {
                        if tapDismissesOverlay {
                            destination = nil
                        }
                    }
                
                overlayContent
                    .zIndex(2)
            }
        }
        .animation(animation, value: destination)
    }
}

extension View {
    /// Presents a lightweight overlay above the current routed content.
    func overlayPresentationModifier(
        destination: Binding<AnyDestination?>,
        backgroundColor: Color = Color.black.opacity(0.6),
        backgroundTransition: AnyTransition = .opacity.animation(.smooth),
        animation: Animation? = nil,
        tapDismissesOverlay: Bool = true
    ) -> some View {
        self
            .modifier(
                OverlayPresentationModifier(
                    destination: destination,
                    backgroundColor: backgroundColor,
                    backgroundTransition: backgroundTransition,
                    animation: animation,
                    tapDismissesOverlay: tapDismissesOverlay
                )
            )
    }
}
