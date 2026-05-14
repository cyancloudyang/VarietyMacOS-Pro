//
// DetailPlaceholderView.swift
// VarietyMacOS
//
// Detail panel showing wallpaper metadata
//

import SwiftUI
@preconcurrency import AppKit

struct DetailPlaceholderView: View {
    @Bindable var wallpaper: Wallpaper
    @State private var loadedImage: NSImage? = nil
    @State private var isLoading = false
    @StateObject private var wallpaperFavorite = WallpaperFavorite.shared
    @State private var copiedColor: String? = nil
    
    private var isFavorited: Bool {
        wallpaperFavorite.isFavorite(wallpaper)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    previewSection
                    Divider()
                    titleSection
                    RatingStarsView(rating: wallpaper.userRating) { newRating in
                        wallpaper.userRating = newRating
                    }
                    .padding(.vertical, 4)
                    
                    TagEditorView(tags: Binding(
                        get: { wallpaper.userTags ?? [] },
                        set: { wallpaper.userTags = $0 }
                    ))
                    .padding(.vertical, 4)
                    
                    sourceBadge
                    Divider()
                    infoSection
                    
                    if !wallpaper.colorSwatchesHex.isEmpty {
                        colorPaletteSection
                    }
                    
                    statsSection
                    Divider()
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Details")
            .onAppear {
                DetailViewGeometry.shared.frame = geometry.frame(in: .global)
                DetailViewGeometry.shared.isPresented = true
            }
            .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                DetailViewGeometry.shared.frame = newFrame
            }
        }
        .task(id: wallpaper.id) {
            isLoading = true
            loadedImage = nil
            if let cached = wallpaper.cachedImage {
                loadedImage = cached
            } else {
                loadedImage = try? await wallpaper.loadImage()
            }
            isLoading = false
        }
    }

    // MARK: - Preview Section

private var previewSection: some View {
  Group {
    if let image = loadedImage {
      Image(nsImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: 250)
        .cornerRadius(8)
        .clipped()
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    } else if isLoading {
      Rectangle()
        .fill(Color.gray.opacity(0.1))
        .frame(height: 250)
        .cornerRadius(8)
        .overlay(ProgressView())
    } else {
      Rectangle()
        .fill(Color.gray.opacity(0.1))
        .frame(height: 250)
        .cornerRadius(8)
        .overlay(
          Image(systemName: "photo")
            .font(.system(size: 36))
            .foregroundColor(.secondary)
        )
    }
  }
}

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(wallpaper.displayTitle)
                .font(.headline)

            if let author = wallpaper.author {
                HStack(spacing: 4) {
                    Text("by \(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let authorURL = wallpaper.authorURL {
                        Link(destination: authorURL) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Source Badge

    private var sourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: wallpaper.source.iconName)
                .font(.caption)
            Text(wallpaper.source.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Resolution") {
                Text(wallpaper.resolutionString)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            if wallpaper.fileSize != nil {
                LabeledContent("File Size") {
                    Text(wallpaper.fileSizeString)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            if wallpaper.fileType != nil {
                LabeledContent("Type") {
                    Text(wallpaper.fileTypeDisplay)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            if wallpaper.isDownloaded {
                LabeledContent("Local") {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Downloaded")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Color Palette Section

    private var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                ForEach(wallpaper.colorSwatchesHex, id: \.self) { hex in
                    Button(action: {
                        copyToPasteboard(hex)
                        copiedColor = hex
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copiedColor = nil
                        }
                    }) {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                            .overlay(
                                Group {
                                    if copiedColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(hex)
                }
            }
        }
    }

    // MARK: - Tags Section

    private func tagsSection(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline)
                .fontWeight(.medium)

            FlowLayout {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(4)
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            if wallpaper.views != nil {
                Label {
                    Text(wallpaper.viewsDisplay + " views")
                        .font(.caption)
                } icon: {
                    Image(systemName: "eye")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            if let favorites = wallpaper.favorites {
                Label {
                    Text("\(NumberFormatter().string(from: NSNumber(value: favorites)) ?? "\(favorites)") favorites")
                        .font(.caption)
                } icon: {
                    Image(systemName: "heart")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            if let createdAt = wallpaper.createdAt {
                Label {
                    Text(createdAt, style: .date)
                        .font(.caption)
                } icon: {
                    Image(systemName: "calendar")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 10) {
            // Set as Desktop
            Button(action: {
                Task { @MainActor in
                    await WallpaperManager.shared.applyWallpaper(wallpaper)
                }
            }) {
                Label("Set as Desktop", systemImage: "desktoppicture")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 12) {
                // Favorite toggle
                Button(action: {
                    wallpaperFavorite.toggle(wallpaper)
                }) {
                    Label(
                        isFavorited ? "Unfavorite" : "Favorite",
                        systemImage: isFavorited ? "heart.fill" : "heart"
                    )
                }
                .buttonStyle(.bordered)

                // Open in Finder
                if let localURL = wallpaper.localURL {
                    Button(action: {
                        NSWorkspace.shared.selectFile(localURL.path, inFileViewerRootedAtPath: "")
                    }) {
                        Label("Open in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }

                // Open source URL
                if let sourceURL = wallpaper.sourceURL {
                    Button(action: {
                        NSWorkspace.shared.open(sourceURL)
                    }) {
                        Label("View Source", systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Helpers

    private func copyToPasteboard(_ hex: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(hex, forType: .string)
    }
}
