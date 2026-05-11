//
// KeyboardShortcuts.swift
// VarietyMacOS
//
// Global and local keyboard shortcut definitions
//

import SwiftUI

/// App-wide keyboard shortcut commands
enum AppShortcut: String, CaseIterable, Sendable {
    case next = "n"
    case previous = "p"
    case favorite = "f"
    case settings = ","
    case search = "k"
    case toggleSidebar = "s"
    
    var displayName: String {
        switch self {
        case .next: "Next Wallpaper"
        case .previous: "Previous Wallpaper"
        case .favorite: "Add to Favorites"
        case .settings: "Settings"
        case .search: "Search"
        case .toggleSidebar: "Toggle Sidebar"
        }
    }
    
    var modifiers: String {
        switch self {
        case .next, .previous, .favorite, .search, .toggleSidebar: "⌘"
        case .settings: "⌘"
        }
    }
    
    var description: String {
        "\(modifiers)\(rawValue.uppercased())"
    }
}

/// Keyboard shortcut helper for building shortcut overlays
struct KeyboardShortcuts {
    /// All available shortcuts for display
    static var allShortcuts: [AppShortcut] {
        AppShortcut.allCases
    }
}
