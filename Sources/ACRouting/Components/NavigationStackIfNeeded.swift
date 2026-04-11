//
//  NavigationStackIfNeeded.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// Wraps content in a `NavigationStack` only when the current router owns one.
struct NavigationStackIfNeeded<Content: View>: View {
    /// The push path owned by the current router view.
    @Binding var pushPath: [AnyDestination]

    /// Whether the current router should render a local `NavigationStack`.
    var ownsNavigationStack = true

    /// The routed content to render inside or outside the owned navigation stack.
    @ViewBuilder var content: Content

    var body: some View {
        if ownsNavigationStack {
            NavigationStack(path: $pushPath) {
                content
                    // Map the type-erased destination values back to the stored destination views.
                    .navigationDestination(for: AnyDestination.self) { value in
                        value.view
                    }
            }
        } else {
            content
        }
    }
}
