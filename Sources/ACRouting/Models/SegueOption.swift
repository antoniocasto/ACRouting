//
//  SegueOption.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import Foundation

/// Supported presentation styles for `Router.showScreen`.
public enum SegueOption {
    /// Pushes the destination onto the current routed navigation stack.
    case push
    /// Presents the destination in a sheet with a fresh routed navigation context.
    case sheet
    /// Presents the destination in a full-screen cover with a fresh routed navigation context.
    case fullScreenCover

    /// Indicates whether this presentation style owns a fresh `NavigationStack`.
    ///
    /// `sheet` and `fullScreenCover` start independent routed flows, while `push`
    /// continues mutating the current routed push stack.
    internal var createsNewNavigationStack: Bool {
        switch self {
        case .push:
            return false
        case .sheet, .fullScreenCover:
            return true
        }
    }
}
