//
//  FavoritesContentView.swift
//  VarietyMacOS
//
//  Displays favorited wallpapers in a grid layout
//

import SwiftUI
import SwiftData

/// Displays favorited wallpapers in a grid layout
struct FavoritesContentView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedWallpaper: Wallpaper?
    @Query(sort: \FavoriteEntry.dateAdded, order: .reverse) private var favorites: [FavoriteEntry]
    @State private var searchText = ""

    private var filteredFavorites: [FavoriteEntry] {
        guard !searchText.isEmpty else { return favorites }
        return favorites.filter { entry in
            entry.wallpaper?.displayTitle.localizedCaseInsensitiveContains(searchText) ?? false
                || entry.wallpaper?.displayAuthor.localizedCaseInsensitiveContains(searchText) ?? false
                || entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                || (entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        Group {
            if favorites.isEmpty {
                emptyStateView
            } else {
                favoritesGrid
            }
        }
        .navigationTitle("Favorites")
        .searchable(text: $searchText, prompt: "Search favorites...")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No favorites yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Wallpapers you favorite will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Favorites Grid

    private var favoritesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(filteredFavorites) { entry in
                    favoriteCard(entry: entry)
                }
            }
            .padding()
        }
    }

    // MARK: - Favorite Card

private func favoriteCard(entry: FavoriteEntry) -> some View {
    Button(action: {
        if let wallpaper = entry.wallpaper {
            selectedWallpaper = wallpaper
        }
    }) {
        VStack(alignment: .leading, spacing: 8) {
            if let wallpaper = entry.wallpaper {
                ThumbnailImageView(wallpaper: wallpaper)
                    .frame(height: 100)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.wallpaper?.displayTitle ?? "Untitled")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let author = entry.wallpaper?.author {
                    Text("by \(author)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    if let source = entry.wallpaper?.source {
                        Image(systemName: source.iconName)
                            .font(.system(size: 9))
                        Text(source.displayName)
                            .font(.system(size: 9))
                    }
                }
                .foregroundColor(.secondary)
            }
        }
    }
    .buttonStyle(PlainButtonStyle())
    .contextMenu {
        if let wallpaper = entry.wallpaper {
            contextMenuContent(for: wallpaper, entry: entry)
        }
    }
}

// MARK: - Context Menu

@ViewBuilder
private func contextMenuContent(for wallpaper: Wallpaper, entry: FavoriteEntry) -> some View {
    // Primary action
    Button(action: {
        Task { @MainActor in
            wallpaperManager.currentWallpaper = wallpaper
        }
    }) {
        Label("Set as Desktop", systemImage: "desktopcomputer")
    }
    
    Divider()
    
    // Favorite toggle
    Button(action: {
        WallpaperFavorite.shared.remove(wallpaper)
    }) {
        Label("Remove from Favorites", systemImage: "star.slash")
    }
    
    // Share action
    Button(action: {
        shareWallpaper(wallpaper)
    }) {
        Label("Share", systemImage: "square.and.arrow.up")
    }
    
    Divider()
    
    // View source
    if let url = wallpaper.sourceURL {
        Button(action: {
            NSWorkspace.shared.open(url)
        }) {
            Label("View Source", systemImage: "safari")
        }
    }
}

private func shareWallpaper(_ wallpaper: Wallpaper) {
    // TODO: Implement share functionality
    print("Share wallpaper: \(wallpaper.displayTitle)")
}
}
