//
// CurrentWallpaperView.swift
// VarietyMacOS
//
// Displays the current wallpaper with controls and quick actions
//

import SwiftUI
@preconcurrency import AppKit

// MARK: - Preference Key for Scroll Offset

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CurrentWallpaperView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @Binding var selectedWallpaper: Wallpaper?
    @State private var scrollOffset: CGFloat = 0
    @State private var currentStatus = "Ready"
    @State private var debugMode = false
    @State private var sampleWallpapers: [Wallpaper] = []
    @State private var isLoadingSamples = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .scrollView).origin.y
                        )
                }
                .frame(height: 0)
                
                currentWallpaperSection
                quickActionsSection
                
                if debugMode {
                    debugSection
                }
            }
            .padding()
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                scrollOffset = offset * 0.3 // 阻尼系数
            }
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
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
                }
            }

        if let wallpaper = wallpaperManager.currentWallpaper, let image = wallpaper.cachedImage {
          // Simple image display (halo moved to DetailPlaceholderView)
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: 300)
            .cornerRadius(8)
            .clipped()
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            .onTapGesture {
              selectedWallpaper = wallpaper
            }
        } else if let wallpaper = wallpaperManager.currentWallpaper {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading wallpaper image...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .task {
                await reloadCurrentWallpaperImage(wallpaper)
            }
} else {
    EmptyWallpaperStateView(
        sampleWallpapers: $sampleWallpapers,
        isLoadingSamples: $isLoadingSamples,
        onNextWallpaper: {
            Task { @MainActor in
                if !wallpaperManager.isLoading {
                    currentStatus = "Fetching..."
                    await wallpaperManager.nextWallpaper()
                    currentStatus = "Done"
                }
            }
        },
        onSampleSelected: { wallpaper in
            selectedWallpaper = wallpaper
        }
    )
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
                HStack(spacing: 8) {
                    if wallpaperManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
          } else {
            Image(systemName: "arrow.right.circle.fill")
              .font(.system(size: 14))
          }
Text(wallpaperManager.isLoading ? "Fetching..." : "Next Wallpaper")
.font(.system(size: 12, weight: .medium))
}
.frame(minHeight: 18, alignment: .center)
.frame(minWidth: 140, alignment: .center)
                .contentShape(Rectangle())
                .onHover { _ in }
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
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: wallpaperManager.isLoading)

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
                .background(.ultraThinMaterial)
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

    @MainActor
    private func reloadCurrentWallpaperImage(_ wallpaper: Wallpaper) async {
        do {
            let _ = try await wallpaper.loadImage()
            wallpaperManager.objectWillChange.send()
        } catch {
            print("Failed to reload current wallpaper image: \(error)")
        }
    }
}

// MARK: - Empty Wallpaper State View

struct EmptyWallpaperStateView: View {
    @Binding var sampleWallpapers: [Wallpaper]
    @Binding var isLoadingSamples: Bool
    let onNextWallpaper: () -> Void
    let onSampleSelected: (Wallpaper) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with icon and title
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Text("No wallpaper set yet")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Get started with beautiful wallpapers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Get Wallpaper Button
            Button(action: onNextWallpaper) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Get Wallpaper")
                        .fontWeight(.medium)
                }
                .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Sample wallpapers section
            if !sampleWallpapers.isEmpty {
                VStack(spacing: 12) {
                    Text("Or try these samples")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    sampleWallpapersGrid
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            if isLoadingSamples {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onAppear {
            loadSampleWallpapersIfNeeded()
        }
    }
    
    private var sampleWallpapersGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(sampleWallpapers.prefix(6), id: \.id) { wallpaper in
                SampleWallpaperThumbnail(
                    wallpaper: wallpaper,
                    onSelect: { onSampleSelected(wallpaper) }
                )
            }
        }
        .padding(.top, 4)
    }
    
    private func loadSampleWallpapersIfNeeded() {
        guard sampleWallpapers.isEmpty && !isLoadingSamples else { return }
        isLoadingSamples = true
        
        Task {
            // Create sample wallpapers from enabled sources
            let samples = await createSampleWallpapers()
            await MainActor.run {
                sampleWallpapers = samples
                isLoadingSamples = false
            }
        }
    }
    
    private func createSampleWallpapers() async -> [Wallpaper] {
        let preferences = Preferences.shared
        let enabledSources = preferences.enabledSources
        var samples: [Wallpaper] = []
        
        // Create sample wallpapers for each enabled source
        for sourceType in enabledSources.prefix(3) {
            let sample = Wallpaper(
                source: sourceType,
                remoteURL: nil,
                title: "Sample from \(sourceType.displayName)"
            )
            samples.append(sample)
        }
        
        // If no enabled sources, show generic samples
        if samples.isEmpty {
            samples = [
                Wallpaper(source: .unsplash, remoteURL: nil, title: "Sample Unsplash"),
                Wallpaper(source: .bing, remoteURL: nil, title: "Sample Bing"),
                Wallpaper(source: .wallhaven, remoteURL: nil, title: "Sample Wallhaven")
            ]
        }
        
        return samples
    }
}

// MARK: - Sample Wallpaper Thumbnail

struct SampleWallpaperThumbnail: View {
    let wallpaper: Wallpaper
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Placeholder image with source color
                RoundedRectangle(cornerRadius: 6)
                    .fill(sourceColor)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: wallpaper.source.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.9))
                    )
                
                // Source name
                Text(wallpaper.source.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: true)
    }
    
    private var sourceColor: Color {
        switch wallpaper.source {
        case .unsplash:
            return Color.purple.opacity(0.8)
        case .bing:
            return Color.blue.opacity(0.8)
        case .wallhaven:
            return Color.orange.opacity(0.8)
        case .reddit:
            return Color.red.opacity(0.8)
        case .local:
            return Color.green.opacity(0.8)
        case .artstation:
            return Color.pink.opacity(0.8)
        }
    }
}
