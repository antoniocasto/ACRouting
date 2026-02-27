//
//  AppAlert.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

struct AnyAppAlert {
    // MARK: - Initializers

    /// Generic alert intializer
    init(title: String, subtitle: String? = nil, buttons: (@Sendable () -> AnyView)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.buttons = buttons
    }

    /// Alert initializer for errors
    init(error: Error, buttons: (@Sendable () -> AnyView)? = nil) {
        self.title = "Error"
        self.subtitle = error.localizedDescription
        self.buttons = buttons
    }

    // MARK: - Properties

    var title: String
    var subtitle: String?
    var buttons: (@Sendable () -> AnyView)?
}
