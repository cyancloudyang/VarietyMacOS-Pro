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
  ZStack {
    NavigationSplitView {
      SidebarView(selectedSection: $selectedSection)
        .background(Color.clear)
    } content: {
      switch selectedSection {
      case .current:
        CurrentWallpaperView(selectedWallpaper: $selectedWallpaper)
          .background(Color.clear)
      case .favorites:
        FavoritesContentView(selectedWallpaper: $selectedWallpaper)
          .background(Color.clear)
      case .history:
        HistoryContentView(selectedWallpaper: $selectedWallpaper)
          .background(Color.clear)
      case .sources:
        SourcesContentView()
          .background(Color.clear)
      case .none:
        Text("Select a section")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .foregroundColor(.secondary)
          .background(Color.clear)
      }
    } detail: {
      if let wallpaper = selectedWallpaper {
        DetailPlaceholderView(wallpaper: wallpaper)
          .background(Color.clear)
      } else {
        Text("Select a wallpaper to view details")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .foregroundColor(.secondary)
          .background(Color.clear)
      }
    }
.onAppear {
  WallpaperHistory.shared.configure(with: modelContext)
  WallpaperFavorite.shared.configure(with: modelContext)
  Preferences.shared.configure(with: modelContext)
  SourceConfigManager.shared.configure(with: modelContext)
  CollectionManager.shared.setContext(modelContext)
  DataContainer.ensureDefaults(in: modelContext)
  selectedWallpaper = wallpaperManager.currentWallpaper
}
.onChange(of: wallpaperManager.currentWallpaper) { _, newWallpaper in
  selectedWallpaper = newWallpaper
}
.task {
  try? await Task.sleep(nanoseconds: 100_000_000)
  if selectedWallpaper !== wallpaperManager.currentWallpaper {
    selectedWallpaper = wallpaperManager.currentWallpaper
  }
}

    AmbilightEffect(
      wallpaper: selectedWallpaper ?? wallpaperManager.currentWallpaper,
      intensity: 1.0
    )
    .allowsHitTesting(false)
    .ignoresSafeArea()
    .blendMode(.screen)
  }
}
}
