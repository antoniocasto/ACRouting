#if DEBUG
import SwiftUI

/// Internal preview-only catalog for developers studying `ACRouting` in Xcode.
///
/// The catalog intentionally covers:
/// - basic push navigation and explicit pop APIs;
/// - sheet and full-screen routed flows;
/// - alerts, confirmation dialogs, and custom overlays;
/// - a more complex checkout-style flow that combines multiple presentation styles.
///
/// This file is not part of the public API surface. It exists to make the package easier
/// to explore after cloning the repository and opening it in Xcode.
private struct ACRoutingPreviewCatalogHome: View {
    @Environment(\.router) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                previewHeader

                PreviewExampleCard(
                    title: "Current Semantics",
                    summary: "These previews intentionally document the library as it exists today, including its current limits."
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• `dismissScreen()` pops a pushed screen, but dismisses a sheet or full-screen cover only when you are at that modal flow root.")
                        Text("• `dismissAncestorModal()` lets a pushed child close its first ancestor routed sheet or full-screen cover explicitly.")
                        Text("• `pop()`, `pop(count:)`, and `popToRoot()` control only the current push stack.")
                        Text("• `showModal` is a lightweight overlay on the current router context, not a separate routed flow.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                PreviewExampleCard(
                    title: "Push Navigation",
                    summary: "Shows `showScreen(.push)`, `pop()`, `pop(count:)`, `popToRoot()`, and how `dismissScreen()` behaves inside pushed destinations."
                ) {
                    Button("Open Push Demo") {
                        router.showScreen(.push) { _ in
                            PushFlowDemoRoot()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                PreviewExampleCard(
                    title: "Modal Flows",
                    summary: "Shows that `.sheet` and `.fullScreenCover` start fresh routed flows with their own local navigation stacks."
                ) {
                    Button("Open Modal Demo") {
                        router.showScreen(.sheet) { _ in
                            ModalFlowsDemoRoot()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                PreviewExampleCard(
                    title: "Alerts and Overlays",
                    summary: "Shows the alert APIs and the custom overlay API without leaving the current routed context."
                ) {
                    Button("Open Overlay Demo") {
                        router.showScreen(.sheet) { _ in
                            OverlayAndAlertsDemoRoot()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                PreviewExampleCard(
                    title: "Complex Checkout Flow",
                    summary: "Combines push navigation, a coupon sheet, a payment overlay, and a confirmation full-screen cover to illustrate a realistic multi-step flow."
                ) {
                    Button("Open Complex Flow") {
                        router.showScreen(.push) { _ in
                            ComplexCheckoutDemoRoot()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .navigationTitle("ACRouting Catalog")
    }

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Use these previews as a living catalog while studying the package. Each example is built with the same public routing API that package consumers use.")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("If a behavior looks constrained, that is intentional: the catalog prefers today’s real capabilities over aspirational examples.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PreviewExampleCard<Content: View>: View {
    let title: String
    let summary: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DemoScreen<Content: View>: View {
    let title: String
    let summary: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                content
            }
            .padding(24)
        }
        .navigationTitle(title)
    }
}

// MARK: - Push Demo

private struct PushFlowDemoRoot: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Push Flow",
            summary: "This flow stays on one routed navigation stack. Pushed children inherit the same stack and can use the explicit pop APIs. `dismissScreen()` is shown here only as the compatibility back action for pushed screens."
        ) {
            Button("Push Step 1") {
                router.showScreen(.push) { _ in
                    PushFlowStepScreen(step: 1)
                }
            }
            .buttonStyle(.borderedProminent)

            Text("Tip: once you are inside a pushed screen, `dismissScreen()` behaves like a single pop.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PushFlowStepScreen: View {
    let step: Int

    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Push Step \(step)",
            summary: "This screen is part of the inherited push stack. Every button below mutates that shared stack explicitly."
        ) {
            Button("Push Next Step") {
                router.showScreen(.push) { _ in
                    PushFlowStepScreen(step: step + 1)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Pop One Screen") {
                router.pop()
            }
            .buttonStyle(.bordered)

            Button("Pop Two Screens") {
                router.pop(count: 2)
            }
            .buttonStyle(.bordered)

            Button("Back To Flow Root") {
                router.popToRoot()
            }
            .buttonStyle(.bordered)

            Button("Dismiss Current Pushed Screen") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Modal Demo

private struct ModalFlowsDemoRoot: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Modal Flows",
            summary: "Both buttons below start a fresh routed flow. Inside those flows you can still push more screens, but the push stack stays local to that modal flow."
        ) {
            Button("Open Routed Sheet") {
                router.showScreen(.sheet) { _ in
                    RoutedSheetStartScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Open Routed Full-Screen Cover") {
                router.showScreen(.fullScreenCover) { _ in
                    RoutedFullScreenStartScreen()
                }
            }
            .buttonStyle(.bordered)

            Button("Dismiss This Sheet Root") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct RoutedSheetStartScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Sheet Root",
            summary: "The sheet has its own routed root. From here you can push more screens without touching the parent catalog stack, and `dismissScreen()` closes the entire sheet because you are at the modal root."
        ) {
            Button("Push Sheet Details") {
                router.showScreen(.push) { _ in
                    RoutedSheetDetailScreen(level: 1)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Dismiss Sheet") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct RoutedSheetDetailScreen: View {
    let level: Int

    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Sheet Detail \(level)",
            summary: "This screen is still inside the sheet's local navigation stack. Here `dismissScreen()` only removes the current pushed screen, while `dismissAncestorModal()` closes the ancestor sheet explicitly."
        ) {
            Button("Push Another Sheet Detail") {
                router.showScreen(.push) { _ in
                    RoutedSheetDetailScreen(level: level + 1)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Pop Within Sheet") {
                router.pop()
            }
            .buttonStyle(.bordered)

            Button("Dismiss Current Sheet Screen") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)

            Button("Dismiss Ancestor Sheet") {
                router.dismissAncestorModal()
            }
            .buttonStyle(.bordered)

            Button("Return To Sheet Root") {
                router.popToRoot()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct RoutedFullScreenStartScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Full-Screen Root",
            summary: "Full-screen presentations behave like modal roots too: they get a fresh routed flow with their own navigation stack. On macOS the same API is sheet-backed."
        ) {
            Button("Push Receipt Details") {
                router.showScreen(.push) { _ in
                    FullScreenReceiptScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Dismiss Full-Screen Cover") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct FullScreenReceiptScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Receipt Details",
            summary: "This screen is pushed inside the full-screen modal flow, not the parent catalog flow. Use `dismissAncestorModal()` here when you want to close the full-screen container instead of only popping."
        ) {
            Button("Pop Receipt Screen") {
                router.dismissScreen()
            }
            .buttonStyle(.borderedProminent)

            Button("Dismiss Ancestor Full-Screen Cover") {
                router.dismissAncestorModal()
            }
            .buttonStyle(.bordered)

            Button("Return To Full-Screen Root") {
                router.popToRoot()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Alerts and Overlay Demo

private struct OverlayAndAlertsDemoRoot: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Alerts and Overlays",
            summary: "Alerts and confirmation dialogs use SwiftUI presentation APIs. `showModal` stays on the current router context, so it works well for lightweight overlay UI but does not create a new routed flow."
        ) {
            Button("Show Standard Alert") {
                router.showAlert(
                    .alert,
                    title: "Routing Saved",
                    subtitle: "This alert is driven by router state."
                ) {
                    Button("Close", role: .cancel) {
                        router.dismissAlert()
                    }
                    .any()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Show Confirmation Dialog") {
                router.showAlert(
                    .confirmationDialog,
                    title: "Archive Draft Flow",
                    subtitle: "Confirmation dialogs are also modeled through the router."
                ) {
                    Group {
                        Button("Archive") {
                            router.dismissAlert()
                        }

                        Button("Cancel", role: .cancel) {
                            router.dismissAlert()
                        }
                    }
                    .any()
                }
            }
            .buttonStyle(.bordered)

            Button("Show Custom Overlay") {
                router.showModal(
                    backgroundColor: Color.black.opacity(0.35),
                    backgroundTransition: .opacity.animation(.smooth),
                    animation: .smooth
                ) {
                    OverlayExampleCard()
                }
            }
            .buttonStyle(.bordered)

            Button("Dismiss Demo") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct OverlayExampleCard: View {
    @Environment(\.router) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Custom Overlay")
                .font(.headline)

            Text("This overlay is not a new routed flow. It inherits the current router context and can dismiss itself through `dismissModal()`.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Close Overlay") {
                router.dismissModal()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 18)
    }
}

// MARK: - Complex Flow Demo

private struct ComplexCheckoutDemoRoot: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Complex Checkout",
            summary: "This demo mixes only behaviors that the library supports today: push navigation, a coupon sheet with its own local push stack, a lightweight payment overlay, and a confirmation full-screen cover."
        ) {
            Button("Inspect Featured Product") {
                router.showScreen(.push) { _ in
                    FeaturedProductScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Text("Use this preview to study how routed contexts compose without leaking raw SwiftUI navigation state into feature views.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct FeaturedProductScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Featured Product",
            summary: "The product detail is a regular pushed screen. From here the flow continues deeper into checkout."
        ) {
            Button("Continue To Shipping") {
                router.showScreen(.push) { _ in
                    ShippingStepScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Return To Catalog") {
                router.popToRoot()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct ShippingStepScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Shipping Step",
            summary: "This screen demonstrates how a pushed checkout step can open a modal helper and a lightweight overlay without losing the current push stack. The overlay shares this same router context."
        ) {
            Button("Open Coupon Assistant Sheet") {
                router.showScreen(.sheet) { _ in
                    CouponAssistantStartScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Show Payment Authorization Overlay") {
                router.showModal(
                    backgroundColor: Color.black.opacity(0.3),
                    backgroundTransition: .opacity.animation(.smooth),
                    animation: .smooth
                ) {
                    PaymentAuthorizationOverlay()
                }
            }
            .buttonStyle(.bordered)

            Button("Back To Product") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct CouponAssistantStartScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Coupon Assistant",
            summary: "The sheet starts a brand-new routed flow. It can push its own help screens and dismiss itself when finished."
        ) {
            Button("Read Coupon Terms") {
                router.showScreen(.push) { _ in
                    CouponTermsScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Apply Coupon And Close Sheet") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct CouponTermsScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Coupon Terms",
            summary: "This help screen is pushed inside the coupon sheet flow."
        ) {
            Button("Back To Coupon Assistant") {
                router.dismissScreen()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct PaymentAuthorizationOverlay: View {
    @Environment(\.router) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Authorizing Payment")
                .font(.headline)

            Text("The overlay lives above the shipping screen, but it still uses the same router context. It can dismiss itself or trigger another routed presentation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Simulate Success") {
                router.dismissModal()
                router.showScreen(.fullScreenCover) { _ in
                    OrderConfirmationScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel Authorization") {
                router.dismissModal()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: 380)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 20)
    }
}

private struct OrderConfirmationScreen: View {
    @Environment(\.router) private var router

    var body: some View {
        DemoScreen(
            title: "Order Confirmation",
            summary: "The confirmation is a routed full-screen cover. It can push extra details locally, and `dismissScreen()` closes the full-screen cover because this screen is the modal flow root."
        ) {
            Button("Open Receipt Details") {
                router.showScreen(.push) { _ in
                    FullScreenReceiptScreen()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Dismiss Confirmation") {
                router.dismissScreen()
            }
            .buttonStyle(.bordered)
        }
    }
}

struct ACRoutingPreviewCatalog_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RouterView { _ in
                ACRoutingPreviewCatalogHome()
            }
            .previewDisplayName("Catalog")

            RouterView { _ in
                OverlayAndAlertsDemoRoot()
            }
            .previewDisplayName("Alerts And Overlay")

            RouterView { _ in
                ComplexCheckoutDemoRoot()
            }
            .previewDisplayName("Complex Checkout")
        }
    }
}
#endif
