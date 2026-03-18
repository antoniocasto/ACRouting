import Testing
import SwiftUI
@testable import ACRouting

// MARK: - Binding(ifNotNil:) Tests

@Suite("Binding(ifNotNil:)")
@MainActor
struct BindingIfNotNilTests {

    @Test("Returns true when underlying value is non-nil")
    func trueWhenPresent() {
        var value: String? = "hello"
        let optionalBinding = Binding<String?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        #expect(boolBinding.wrappedValue == true)
    }

    @Test("Returns false when underlying value is nil")
    func falseWhenNil() {
        var value: String? = nil
        let optionalBinding = Binding<String?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        #expect(boolBinding.wrappedValue == false)
    }

    @Test("Setting to false nils out the underlying value")
    func setFalseNilsValue() {
        var value: String? = "hello"
        let optionalBinding = Binding<String?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        boolBinding.wrappedValue = false

        #expect(value == nil)
        #expect(boolBinding.wrappedValue == false)
    }

    @Test("Setting to true does not alter the underlying value")
    func setTrueKeepsValue() {
        var value: String? = "hello"
        let optionalBinding = Binding<String?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        boolBinding.wrappedValue = true

        #expect(value == "hello")
    }

    @Test("Setting to true when value is nil keeps it nil")
    func setTrueOnNilKeepsNil() {
        var value: String? = nil
        let optionalBinding = Binding<String?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        boolBinding.wrappedValue = true

        #expect(value == nil)
    }

    @Test("Works with non-String optional types")
    func worksWithIntOptional() {
        var value: Int? = 42
        let optionalBinding = Binding<Int?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        #expect(boolBinding.wrappedValue == true)

        boolBinding.wrappedValue = false
        #expect(value == nil)
    }

    @Test("Reflects changes in the underlying value dynamically")
    func dynamicReflection() {
        var value: String? = nil
        let optionalBinding = Binding<String?>(get: { value }, set: { value = $0 })
        let boolBinding = Binding<Bool>(ifNotNil: optionalBinding)

        #expect(boolBinding.wrappedValue == false)

        value = "now present"
        #expect(boolBinding.wrappedValue == true)

        value = nil
        #expect(boolBinding.wrappedValue == false)
    }
}

// MARK: - View.any() Tests

@Suite("View.any()")
@MainActor
struct ViewAnyExtensionTests {

    @Test("Wraps a Text view in AnyView")
    func wrapsText() {
        let anyView = Text("Hello").any()
        // any() returns AnyView — compile-time guarantee.
        // Verify the call doesn't trap and produces a value.
        let _: AnyView = anyView
    }

    @Test("Wraps an EmptyView in AnyView")
    func wrapsEmptyView() {
        let anyView = EmptyView().any()
        let _: AnyView = anyView
    }

    @Test("Wraps a complex view hierarchy in AnyView")
    func wrapsComplexView() {
        let anyView = VStack {
            Text("Hello")
            Text("World")
        }.any()
        let _: AnyView = anyView
    }
}
