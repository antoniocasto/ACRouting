import SwiftUI
import Testing
@testable import ACRouting

@Suite("Presentation modifiers")
@MainActor
struct PresentationModifierTests {

    @Test("Alert presentation binding dismisses alert configuration")
    func alertPresentationBindingDismissesAlertConfiguration() {
        var configuration: AnyAppAlert? = AnyAppAlert(title: "Alert", message: "Message")
        let binding = Binding<AnyAppAlert?>(
            get: { configuration },
            set: { configuration = $0 }
        )

        let isPresented = routerAlertIsPresentedBinding(binding)

        #expect(isPresented.wrappedValue == true)

        isPresented.wrappedValue = false

        #expect(configuration == nil)
    }

    @Test("Alert presentation binding keeps existing confirmation configuration when set true")
    func alertPresentationBindingKeepsExistingConfirmationConfigurationWhenSetTrue() {
        let originalConfiguration = AnyAppAlert(title: "Confirm", message: "Continue?")
        var configuration: AnyAppAlert? = originalConfiguration
        let binding = Binding<AnyAppAlert?>(
            get: { configuration },
            set: { configuration = $0 }
        )

        let isPresented = routerAlertIsPresentedBinding(binding)

        isPresented.wrappedValue = true

        #expect(configuration?.title == originalConfiguration.title)
        #expect(configuration?.message == originalConfiguration.message)
    }

    @Test("Full-screen cover modifier uses the platform presentation backend")
    func fullScreenCoverModifierUsesPlatformPresentationBackend() {
        #if os(macOS)
        #expect(fullScreenCoverDestinationPresentationBackend == .sheet)
        #else
        #expect(fullScreenCoverDestinationPresentationBackend == .fullScreenCover)
        #endif
    }
}
