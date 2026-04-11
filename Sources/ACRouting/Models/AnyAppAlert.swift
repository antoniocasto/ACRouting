//
//  AppAlert.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import SwiftUI

/// Stores the normalized data needed to build a SwiftUI alert or confirmation dialog.
///
/// The public router API still talks about `subtitle` and `buttons` for source compatibility,
/// but this internal model uses the more direct `message` and `actions` terminology.
struct AnyAppAlert {
    // MARK: - Initializers

    /// Creates an alert configuration from a title, optional message, and optional custom actions.
    init(title: String, message: String? = nil, actions: (@Sendable () -> AnyView)? = nil) {
        self.title = title
        self.message = message
        self.actions = actions
    }

    /// Creates an alert configuration from an error value.
    init(error: Error, actions: (@Sendable () -> AnyView)? = nil) {
        self.title = "Error"
        self.message = error.localizedDescription
        self.actions = actions
    }

    // MARK: - Properties

    /// The primary alert title.
    var title: String

    /// Secondary text shown below the title.
    var message: String?

    /// Optional custom alert actions.
    var actions: (@Sendable () -> AnyView)?
}
