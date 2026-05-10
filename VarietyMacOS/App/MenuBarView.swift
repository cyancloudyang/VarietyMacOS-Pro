import SwiftUI
import Combine

/// Main menu bar view for the Variety wallpaper app
struct MenuBarView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared
    @StateObject private var screenManager = ScreenManager.shared
    @State private var showingSettings = false
    @State private var showingHistory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "photo.fill")
                    .font(.title2)
                Text("Variety")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 4)

            Divider()

            // Current wallpaper info
            if let currentWallpaper = wallpaperManager.currentWallpaper {
                WallpaperPreviewView(wallpaper: currentWallpaper)
            } else {
                Text("No wallpaper set")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }

            Divider()

            // Quick actions
            VStack(alignment: .leading, spacing: 8) {
                Button("Next Wallpaper") {
                    Task {
                        await wallpaperManager.nextWallpaper()
                    }
                }
                .buttonStyle(MenuBarButtonStyle())

                Button("Previous Wallpaper") {
                    Task {
                        await wallpaperManager.previousWallpaper()
                    }
                }
                .buttonStyle(MenuBarButtonStyle())

                Button("Pause/Resume") {
                    wallpaperManager.toggleTimer()
                }
                .buttonStyle(MenuBarButtonStyle())
            }

            Divider()

            // Screen selection
            ScreenSelectionView()

            Divider()

            // Menu items
            VStack(alignment: .leading, spacing: 8) {
                Button("History...") {
                    showingHistory = true
                }
                .buttonStyle(MenuBarButtonStyle())

                Button("Preferences...") {
                    showingSettings = true
                }
                .buttonStyle(MenuBarButtonStyle())

                Divider()
                    .padding(.vertical, 4)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(MenuBarButtonStyle())
            }
        }
        .padding()
        .frame(width: 280)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingHistory) {
            HistorySheetView()
        }
    }
}

/// Preview of current wallpaper
struct WallpaperPreviewView: View {
    let wallpaper: Wallpaper

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = wallpaper.cachedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
                    .cornerRadius(8)
                    .overlay(
                        ProgressView()
                    )
            }

            Text(wallpaper.source.displayName)
                .font(.caption)
                .foregroundColor(.secondary)

            if let title = wallpaper.title {
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Screen selection dropdown
struct ScreenSelectionView: View {
    @ObservedObject private var screenManager = ScreenManager.shared

    var body: some View {
        HStack {
            Text("Screen:")
                .font(.caption)

            Picker("", selection: $screenManager.selectedScreen) {
                ForEach(screenManager.availableScreens, id: \.self) { screen in
                    Text(screen.displayName)
                        .tag(screen as NSScreen?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .labelsHidden()
        }
    }
}

// MARK: - Button Style

struct MenuBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(4)
    }
}

/// History sheet view showing recent wallpaper entries
struct HistorySheetView: View {
    @Environment(\.dismiss) private var dismiss
    private let recentEntries = WallpaperHistory.shared.recentEntries(count: 20)

    var body: some View {
        NavigationStack {
            if recentEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(recentEntries) { entry in
                        HStack(spacing: 12) {
                            if let wallpaper = entry.wallpaper {
                                ThumbnailImageView(wallpaper: wallpaper)
                                    .frame(width: 48, height: 48)
                            } else {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.secondary)
                                    .frame(width: 48, height: 48)
                            }

                            ViewThatFits(in: .horizontal) {
                                // Full view (wider sheet)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.wallpaper?.displayTitle ?? "Untitled")
                                        .font(.body)
                                        .lineLimit(1)

                                    HStack(spacing: 8) {
                                        if let author = entry.wallpaper?.author {
                                            Text("by \(author)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(entry.wallpaper?.resolutionString ?? "")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        if let fileType = entry.wallpaper?.fileType {
                                            Text(fileTypeDisplay(fileType: fileType))
                                                .font(.caption2)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.accentColor.opacity(0.1))
                                                .cornerRadius(3)
                                        }
                                    }

                                    HStack(spacing: 8) {
                                        if let views = entry.wallpaper?.views {
                                            Text("\(NumberFormatter().string(from: NSNumber(value: views)) ?? "\(views)") views")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        if let favorites = entry.wallpaper?.favorites {
                                            Text("❤️ \(NumberFormatter().string(from: NSNumber(value: favorites)) ?? "\(favorites)")")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    if let colors = entry.wallpaper?.colors, !colors.isEmpty {
                                        HStack(spacing: 3) {
                                            ForEach(Array(colors.prefix(6)), id: \.self) { hex in
                                                Circle()
                                                    .fill(hexColor(hex: hex))
                                                    .frame(width: 12, height: 12)
                                                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                                            }
                                            if colors.count > 6 {
                                                Text("+\(colors.count - 6)")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    Text(entry.timestamp, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                // Compact view (narrow sheet)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.wallpaper?.displayTitle ?? "Untitled")
                                        .font(.body)
                                        .lineLimit(1)
                                    Text(entry.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(minWidth: 380, idealWidth: 440, minHeight: 400, idealHeight: 500)
        .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                WallpaperHistory.shared.prefetchThumbnails()
            }
        }

    private func fileTypeDisplay(fileType: String) -> String {
        if fileType.contains("jpeg") { return "JPEG" }
        if fileType.contains("png") { return "PNG" }
        if fileType.contains("gif") { return "GIF" }
        if fileType.contains("webp") { return "WebP" }
        return fileType.uppercased()
    }
}
