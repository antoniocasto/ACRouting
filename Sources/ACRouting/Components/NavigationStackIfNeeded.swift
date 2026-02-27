//
//  NavigationStackIfNeeded.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// Adds a NavigationStack only when needed.
///
/// Root RouterView uses it.
/// Child RouterViews skip it to avoid nested stacks (for push).
struct NavigationStackIfNeeded<Content: View>: View {
    @Binding var path: [AnyDestination]
    var addNavigationView: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        if addNavigationView {
            NavigationStack(path: $path) {
                content
                    // This maps AnyDestination values in the path to actual views.
                    .navigationDestination(for: AnyDestination.self) { value in
                        value.destination
                    }
            }
        } else {
            content
        }
    }
}
