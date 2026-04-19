//
//  AlertType.swift
//  ArchitectureBootcamp
//
//  Created by Antonio Casto on 24/02/26.
//

import Foundation

/// The SwiftUI alert presentation styles supported by ``Router/showAlert(_:title:subtitle:buttons:)``.
public enum AlertType {
    /// Presents a standard alert.
    case alert

    /// Presents a confirmation dialog.
    case confirmationDialog
}
