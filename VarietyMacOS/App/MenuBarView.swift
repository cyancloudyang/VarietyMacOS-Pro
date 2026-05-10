import SwiftUI
import Combine

/// Main menu bar view for the Variety wallpaper app
struct MenuBarView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared
@StateObject private var screenManager = ScreenManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "photo.fill")
                    .font(.title2)
                Text("Variety Pro")
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
Button("Preferences...") {
NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
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


