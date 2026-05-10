//
//  SidebarView.swift
//  VarietyMacOS
//
//  Sidebar navigation for the main NavigationSplitView
//

import SwiftUI

/// Sidebar navigation for the main NavigationSplitView
struct SidebarView: View {
    @Binding var selectedSection: AppNavigationView.AppSection?
    @StateObject private var preferences = Preferences.shared

    var body: some View {
        List(AppNavigationView.AppSection.allCases, selection: $selectedSection) { section in
            Label(section.rawValue, systemImage: section.iconName)
                .tag(section)
        }
        .listStyle(.sidebar)
        .navigationTitle("Variety Pro")
    }
}
