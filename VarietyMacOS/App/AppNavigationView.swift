//
//  AppNavigationView.swift
//  VarietyMacOS
//
//  Main navigation view using NavigationSplitView for sidebar/content/detail layout
//

import SwiftUI
import SwiftData

/// Main navigation view using NavigationSplitView for sidebar/content/detail layout
struct AppNavigationView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSection: AppSection? = .current
    @State private var selectedWallpaper: Wallpaper? = nil

    enum AppSection: String, CaseIterable, Identifiable {
        case current = "Current"
        case favorites = "Favorites"
        case history = "History"
        case sources = "Sources"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .current:
                return "photo.fill"
            case .favorites:
                return "heart.fill"
            case .history:
                return "clock.fill"
            case .sources:
                return "photo.stack.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
        } content: {
            switch selectedSection {
            case .current:
                CurrentWallpaperView(selectedWallpaper: $selectedWallpaper)
            case .favorites:
                FavoritesContentView(selectedWallpaper: $selectedWallpaper)
            case .history:
                HistoryContentView(selectedWallpaper: $selectedWallpaper)
            case .sources:
                SourcesContentView()
            case .none:
                Text("Select a section")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.secondary)
            }
        } detail: {
            if let wallpaper = selectedWallpaper {
                DetailPlaceholderView(wallpaper: wallpaper)
            } else {
                Text("Select a wallpaper to view details")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Configure SwiftData singletons on first appear
            WallpaperHistory.shared.configure(with: modelContext)
            WallpaperFavorite.shared.configure(with: modelContext)
            Preferences.shared.configure(with: modelContext)
            SourceConfigManager.shared.configure(with: modelContext)
            CollectionManager.shared.setContext(modelContext)
            DataContainer.ensureDefaults(in: modelContext)
        }
    }
}
