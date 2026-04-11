import Testing
import SwiftUI
@testable import ACRouting

// MARK: - AnyDestination Tests

@Suite("AnyDestination")
@MainActor
struct AnyDestinationTests {

    @Test("Each instance gets a unique id")
    func uniqueIdentity() {
        let a = AnyDestination(destination: Text("A"))
        let b = AnyDestination(destination: Text("B"))

        #expect(a.id != b.id)
    }

    @Test("Two instances wrapping the same view are not equal")
    func notEqualEvenForSameView() {
        let a = AnyDestination(destination: Text("Same"))
        let b = AnyDestination(destination: Text("Same"))

        #expect(a != b)
    }

    @Test("An instance is equal to itself")
    func selfEquality() {
        let destination = AnyDestination(destination: Text("Hello"))

        #expect(destination == destination)
    }

    @Test("Hash values differ for distinct instances")
    func hashUniqueness() {
        let a = AnyDestination(destination: Text("A"))
        let b = AnyDestination(destination: Text("B"))

        #expect(a.hashValue != b.hashValue)
    }

    @Test("Can be used as a Set element")
    func usableInSet() {
        let a = AnyDestination(destination: Text("A"))
        let b = AnyDestination(destination: Text("B"))
        let set: Set<AnyDestination> = [a, b, a]

        #expect(set.count == 2)
    }

    @Test("Can be used as a Dictionary key")
    func usableAsDictionaryKey() {
        let key = AnyDestination(destination: Text("Key"))
        var dict: [AnyDestination: String] = [:]
        dict[key] = "value"

        #expect(dict[key] == "value")
    }

    @Test("Stores an AnyView destination")
    func storesDestination() {
        let destination = AnyDestination(destination: Text("Content"))
        // `view` is intentionally type-erased so mixed destinations can share one path.
        let _: AnyView = destination.view
    }
}

// MARK: - AnyAppAlert Tests

@Suite("AnyAppAlert")
struct AnyAppAlertTests {

    @Test("Init with title only")
    func initWithTitle() {
        let alert = AnyAppAlert(title: "Warning")

        #expect(alert.title == "Warning")
        #expect(alert.message == nil)
        #expect(alert.actions == nil)
    }

    @Test("Init with title and subtitle")
    func initWithTitleAndSubtitle() {
        let alert = AnyAppAlert(title: "Info", message: "Details here")

        #expect(alert.title == "Info")
        #expect(alert.message == "Details here")
    }

    @Test("Init with title, subtitle, and buttons")
    func initWithAllParams() {
        let alert = AnyAppAlert(
            title: "Confirm",
            message: "Are you sure?",
            actions: { AnyView(EmptyView()) }
        )

        #expect(alert.title == "Confirm")
        #expect(alert.message == "Are you sure?")
        #expect(alert.actions != nil)
    }

    @Test("Init from error sets title to Error")
    func initFromError() {
        let error = NSError(domain: "test", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "Something broke"
        ])
        let alert = AnyAppAlert(error: error)

        #expect(alert.title == "Error")
        #expect(alert.message == "Something broke")
        #expect(alert.actions == nil)
    }

    @Test("Init from error with custom buttons")
    func initFromErrorWithButtons() {
        let error = NSError(domain: "test", code: 1)
        let alert = AnyAppAlert(error: error, actions: { AnyView(EmptyView()) })

        #expect(alert.title == "Error")
        #expect(alert.actions != nil)
    }
}

// MARK: - SegueOption Tests

@Suite("SegueOption")
struct SegueOptionTests {

    @Test("Push keeps the current navigation stack")
    func pushKeepsCurrentNavigationStack() {
        #expect(SegueOption.push.createsNewNavigationStack == false)
    }

    @Test("Sheet starts a new navigation stack")
    func sheetStartsNewNavigationStack() {
        #expect(SegueOption.sheet.createsNewNavigationStack == true)
    }

    @Test("FullScreenCover starts a new navigation stack")
    func fullScreenCoverStartsNewNavigationStack() {
        #expect(SegueOption.fullScreenCover.createsNewNavigationStack == true)
    }

    @Test("All three cases are distinct")
    func allCasesDistinct() {
        let push = SegueOption.push
        let sheet = SegueOption.sheet
        let fullScreenCover = SegueOption.fullScreenCover

        #expect(push != sheet)
        #expect(push != fullScreenCover)
        #expect(sheet != fullScreenCover)
    }
}

// MARK: - AlertType Tests

@Suite("AlertType")
struct AlertTypeTests {

    @Test("Alert and confirmationDialog are distinct")
    func casesAreDistinct() {
        #expect(AlertType.alert != AlertType.confirmationDialog)
    }
}
