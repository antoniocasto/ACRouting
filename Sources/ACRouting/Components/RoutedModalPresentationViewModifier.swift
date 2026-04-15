//
//  RoutedModalPresentationViewModifier.swift
//  ACRouting
//
//  Created by Codex on 15/04/26.
//

import SwiftUI

struct RoutedModalPresentationModifier: ViewModifier {
    @Binding var presentationState: RouterPresentationState?

    func body(content: Content) -> some View {
        content
            .sheetDestinationModifier(destination: Self.destinationBinding(for: .sheet, presentationState: $presentationState))
            .fullScreenCoverDestinationModifier(destination: Self.destinationBinding(for: .fullScreenCover, presentationState: $presentationState))
    }

    private static func destinationBinding(
        for style: RouterPresentationState.RoutedModalStyle,
        presentationState: Binding<RouterPresentationState?>
    ) -> Binding<AnyDestination?> {
        Binding(
            get: {
                guard presentationState.wrappedValue?.routedModalStyle == style else {
                    return nil
                }
                return presentationState.wrappedValue?.routedModalDestination
            },
            set: { newValue in
                switch newValue {
                case .some(let destination):
                    presentationState.wrappedValue = RouterPresentationState(
                        routedModalStyle: style,
                        routedModalDestination: destination
                    )
                case nil:
                    guard presentationState.wrappedValue?.routedModalStyle == style else { return }
                    presentationState.wrappedValue = nil
                }
            }
        )
    }
}

extension View {
    /// Applies routed `.sheet` and `.fullScreenCover` presentation from a unified state source.
    func routedModalPresentationModifier(presentationState: Binding<RouterPresentationState?>) -> some View {
        modifier(RoutedModalPresentationModifier(presentationState: presentationState))
    }
}

#if DEBUG
extension RoutedModalPresentationModifier {
    static func makeSheetDestinationBindingForTesting(
        presentationState: Binding<RouterPresentationState?>
    ) -> Binding<AnyDestination?> {
        destinationBinding(for: .sheet, presentationState: presentationState)
    }

    static func makeFullScreenCoverDestinationBindingForTesting(
        presentationState: Binding<RouterPresentationState?>
    ) -> Binding<AnyDestination?> {
        destinationBinding(for: .fullScreenCover, presentationState: presentationState)
    }
}
#endif
