//
//  SegueOption.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import Foundation

enum SegueOption {
    case push
    case sheet
    case fullScreenCover

    /// `.sheet` and `.fullScreenCover` create a NEW navigation context.
    /// This means the presented root screen can push further screens without affecting
    /// the underlying stack.
    var shouldAddNewNavigationView: Bool {
        switch self {
        case .push:
            return false
        case .sheet, .fullScreenCover:
            return true
        }
    }
}
