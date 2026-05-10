//
// CurrentWallpaperView.swift
// VarietyMacOS
//
// Displays the current wallpaper with controls and quick actions
//

import SwiftUI
@preconcurrency import AppKit

struct CurrentWallpaperView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedWallpaper: Wallpaper?
    @State private var currentStatus = "Ready"
    @State private var debugMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                currentWallpaperSection
                quickActionsSection

                if debugMode {
                    debugSection
                }
            }
            .padding()
        }
        .navigationTitle("Current Wallpaper")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { debugMode.toggle() }) {
                    Image(systemName: debugMode ? "ladybug.fill" : "ladybug")
                }
                .help("Toggle debug tools")
            }
        }
    }

    // MARK: - Current Wallpaper Section

    private var currentWallpaperSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Wallpaper")
                    .font(.headline)
                Spacer()
                if let wallpaper = wallpaperManager.currentWallpaper {
                    HStack(spacing: 4) {
                        Image(systemName: wallpaper.source.iconName)
                            .font(.caption2)
                        Text(wallpaper.source.displayName)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
                }
            }

            if let wallpaper = wallpaperManager.currentWallpaper,
               let image = wallpaper.cachedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .cornerRadius(8)
                    .clipped()
                    .onTapGesture {
                        selectedWallpaper = wallpaper
                    }

                ViewThatFits(in: .horizontal) {
                    // Full metadata view
                    VStack(alignment: .leading, spacing: 6) {
                        Text(wallpaper.title ?? "Unknown")
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(2)

                        HStack {
                            Image(systemName: wallpaper.source.iconName)
                                .font(.caption2)
                            Text(wallpaper.source.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)

                        if let author = wallpaper.author {
                            Text("by \(author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let colors = wallpaper.colors, !colors.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(Array(colors.prefix(6)), id: \.self) { hex in
                                    Circle()
                                        .fill(hexColor(hex: hex))
                                        .frame(width: 16, height: 16)
                                }
                                if colors.count > 6 {
                                    Text("+\(colors.count - 6)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 2)
                        }

                        HStack(spacing: 12) {
                            Text(wallpaper.resolutionString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let views = wallpaper.views {
                                Text("\(NumberFormatter().string(from: NSNumber(value: views)) ?? "\(views)") views")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if let favorites = wallpaper.favorites {
                                Text("\u{2764}\u{FE0F} \(NumberFormatter().string(from: NSNumber(value: favorites)) ?? "\(favorites)")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Compact metadata view
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wallpaper.title ?? "Unknown")
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack {
                            Image(systemName: wallpaper.source.iconName)
                                .font(.caption2)
                            Text(wallpaper.source.displayName)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)

                        Text(wallpaper.resolutionString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No wallpaper set yet")
                        .foregroundColor(.secondary)
                    Text("Click 'Next Wallpaper' to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Button(action: {
                    Task { @MainActor in
                        if !wallpaperManager.isLoading {
                            currentStatus = "Fetching..."
                            await wallpaperManager.nextWallpaper()
                            currentStatus = "Done"
                        }
                    }
                }) {
                    HStack {
                        if wallpaperManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Image(systemName: wallpaperManager.isLoading ? "arrow.clockwise" : "arrow.right.circle.fill")
                        Text(wallpaperManager.isLoading ? "Fetching..." : "Next Wallpaper")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(wallpaperManager.isLoading)

                Button(action: {
                    Task { @MainActor in
                        await wallpaperManager.previousWallpaper()
                        currentStatus = "Done"
                    }
                }) {
                    Image(systemName: "arrow.left.circle.fill")
                    Text("Previous")
                }
                .buttonStyle(.bordered)
                .disabled(wallpaperManager.debugHistoryCount <= 1)

                Button(action: {
                    wallpaperManager.toggleTimer()
                }) {
                    Image(systemName: "pause.circle.fill")
                    Text("Pause/Resume")
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Circle()
                    .fill(wallpaperManager.isLoading ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)

                Text(wallpaperManager.isLoading ? "Loading..." : "Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Preferences.shared.enabledSources.count) sources active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let error = wallpaperManager.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Debug Section

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug Tools")
                .font(.headline)

            TestSourceCard()
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}
