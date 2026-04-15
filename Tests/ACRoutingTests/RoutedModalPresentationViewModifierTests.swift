import Testing
import SwiftUI
@testable import ACRouting

@Suite("Routed modal presentation modifier")
@MainActor
struct RoutedModalPresentationViewModifierTests {
    final class PresentationStateBox {
        var presentationState: RouterPresentationState?
    }

    private func makeBinding(_ box: PresentationStateBox) -> Binding<RouterPresentationState?> {
        Binding(
            get: { box.presentationState },
            set: { box.presentationState = $0 }
        )
    }

    @Test("Sheet binding exposes only a sheet presentation")
    func sheetBindingExposesOnlySheetPresentation() {
        let box = PresentationStateBox()
        let destination = AnyDestination(destination: Text("Sheet"))
        box.presentationState = RouterPresentationState(
            routedModalStyle: .sheet,
            routedModalDestination: destination
        )

        let sheetBinding = RoutedModalPresentationModifier.makeSheetDestinationBindingForTesting(
            presentationState: makeBinding(box)
        )
        let fullScreenBinding = RoutedModalPresentationModifier.makeFullScreenCoverDestinationBindingForTesting(
            presentationState: makeBinding(box)
        )

        #expect(sheetBinding.wrappedValue == destination)
        #expect(fullScreenBinding.wrappedValue == nil)
    }

    @Test("Sheet binding writes back into the unified presentation state")
    func sheetBindingWritesBackIntoPresentationState() throws {
        let box = PresentationStateBox()
        let destination = AnyDestination(destination: Text("Sheet"))

        let sheetBinding = RoutedModalPresentationModifier.makeSheetDestinationBindingForTesting(
            presentationState: makeBinding(box)
        )
        sheetBinding.wrappedValue = destination

        let presentationState = try #require(box.presentationState)
        #expect(presentationState.routedModalStyle == .sheet)
        #expect(presentationState.routedModalDestination == destination)
    }

    @Test("Clearing the sheet binding does not remove a full-screen presentation")
    func clearingSheetBindingDoesNotRemoveFullScreenPresentation() throws {
        let box = PresentationStateBox()
        let destination = AnyDestination(destination: Text("Full screen"))
        box.presentationState = RouterPresentationState(
            routedModalStyle: .fullScreenCover,
            routedModalDestination: destination
        )

        let sheetBinding = RoutedModalPresentationModifier.makeSheetDestinationBindingForTesting(
            presentationState: makeBinding(box)
        )
        sheetBinding.wrappedValue = nil

        let presentationState = try #require(box.presentationState)
        #expect(presentationState.routedModalStyle == .fullScreenCover)
        #expect(presentationState.routedModalDestination == destination)
    }

    @Test("Full-screen binding clears only a full-screen presentation")
    func fullScreenBindingClearsOnlyFullScreenPresentation() {
        let box = PresentationStateBox()
        box.presentationState = RouterPresentationState(
            routedModalStyle: .fullScreenCover,
            routedModalDestination: AnyDestination(destination: Text("Full screen"))
        )

        let fullScreenBinding = RoutedModalPresentationModifier.makeFullScreenCoverDestinationBindingForTesting(
            presentationState: makeBinding(box)
        )
        fullScreenBinding.wrappedValue = nil

        #expect(box.presentationState == nil)
    }
}
