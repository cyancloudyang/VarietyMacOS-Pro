//
// VarietyMacOSApp.swift
// VarietyMacOS
//
// Main application entry point with window support
//

import SwiftUI
import AppKit

@main
struct VarietyMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Use the shared singleton directly
    private var wallpaperManager: WallpaperManager {
        WallpaperManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wallpaperManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 450, height: 550)

        Settings {
            SettingsView()
        }
    }
}

// MARK: - Content View (Redesigned)

@available(macOS 13.0, *)
struct ContentView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @State private var showingSettings = false
    @State private var currentStatus = "Ready"
    @State private var debugMode = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()
            
            Divider()
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Current wallpaper preview (main feature)
                    currentWallpaperCard
                        .padding()
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                    
                    // Quick actions
                    quickActionsCard
                        .padding()
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                    
                    // Debug/Test tools (collapsible)
                    if debugMode {
                        debugToolsCard
                            .padding()
                            .background(Color(.windowBackgroundColor))
                            .cornerRadius(12)
                    }
                    
                    // Sources info
                    sourcesCard
                        .padding()
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "photo.fill")
                .font(.title)
                .foregroundColor(.accentColor)
            Text("Variety")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Text(currentStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Current Wallpaper Card (Main Feature)
    
    private var currentWallpaperCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Wallpaper")
                    .font(.headline)
                Spacer()
                if let wallpaper = wallpaperManager.currentWallpaper {
                    Text(wallpaper.source.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
if let wallpaper = wallpaperManager.currentWallpaper,
            let image = wallpaper.cachedImage {
                // Image with improved display
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .cornerRadius(8)
                    .clipped()
                
                // Wallpaper information panel
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(wallpaper.title ?? "Unknown")
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    // Source badge
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
                    
                    // Description if available
                    if let description = wallpaper.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Image info
                    HStack(spacing: 12) {
                        Text("\(image.size.width.toInt())x\(image.size.height.toInt())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(Int(image.size.width * image.size.height * 4 / 1024)) KB")
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
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
// MARK: - Quick Actions Card

private var quickActionsCard: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Quick Actions")
            .font(.headline)
        
        HStack(spacing: 12) {
            // Next Wallpaper button (primary action)
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
            
            // Previous button
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
        }
        
        // Status indicator with more details
        HStack {
            Circle()
                .fill(wallpaperManager.isLoading ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            
            Text(wallpaperManager.isLoading ? "Loading..." : "Ready")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Show enabled sources count
            Text("\(Preferences.shared.enabledSources.count) sources active")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if debugMode {
                Text("• History: \(wallpaperManager.debugHistoryCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        
        // Error message if available
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
}
    
    // MARK: - Debug Tools Card (for development)
    
    private var debugToolsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug Tools")
                .font(.headline)
            
            TestSourceCard()
        }
    }
    
    // MARK: - Sources Card
    
    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Enabled Sources")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings = true }) {
                    Text("Edit")
                        .font(.caption)
                }
            }
            
            if let sources = Preferences.shared.enabledSources as? [WallpaperSourceType], !sources.isEmpty {
                FlowLayout {
                    ForEach(sources, id: \.self) { sourceType in
                        HStack {
                            Image(systemName: sourceType.iconName)
                            Text(sourceType.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            } else {
                Text("No sources enabled")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Test Source Card (Debug Tool)

@available(macOS 13.0, *)
struct TestSourceCard: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @State private var isTesting = false
    @State private var testResult: String? = nil
    @State private var previewImage: NSImage? = nil
    @State private var tempFileURL: URL? = nil
    @State private var wallpaperInfo: String? = nil
    @State private var fetchedWallpaper: Wallpaper? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    Task {
                        await runTest()
                    }
                }) {
                    HStack {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Image(systemName: isTesting ? "arrow.clockwise" : "arrow.down.circle")
                        Text(isTesting ? "Testing..." : "Test Fetch")
                    }
                }
                .disabled(isTesting)

                if let result = testResult {
                    Text(result)
                        .foregroundColor(result.starts(with: "✓") ? .green : .red)
                        .font(.caption)
                }

                Spacer()
            }

            if let image = previewImage {
                Divider()
                HStack {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 94)
                        .cornerRadius(6)
                        .clipped()

                    VStack(alignment: .leading, spacing: 6) {
                        if let info = wallpaperInfo {
                            Text(info)
                                .font(.caption)
                                .lineLimit(2)
                        }

                        HStack(spacing: 6) {
                            Button("Via Manager") {
                                Task {
                                    await applyViaManager()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button("Direct") {
                                Task {
                                    await applyToDesktop()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func runTest() async {
        isTesting = true
        defer {
            isTesting = false
        }
        testResult = nil
        previewImage = nil
        wallpaperInfo = nil
        tempFileURL = nil
        fetchedWallpaper = nil

        do {
            let source = BingSource()
            print("📥 Fetching from Bing...")

            let wallpaper = try await source.fetchWallpaper()
            print("✓ Got: \(wallpaper.title ?? "Untitled")")

            guard let url = wallpaper.remoteURL else {
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No remote URL"])
            }

            print("🔗 Downloading: \(url)")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("📊 Downloaded \(data.count) bytes")

            guard let image = NSImage(data: data) else {
                throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
            }
            print("✓ Image: \(image.size)")

            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            try data.write(to: tempURL)
            print("✓ Saved: \(tempURL)")

            previewImage = image
            tempFileURL = tempURL
            fetchedWallpaper = wallpaper
            wallpaperInfo = "\(wallpaper.title ?? "Unknown")"
            testResult = "✓ Ready"

        } catch {
            print("✗ Error: \(error.localizedDescription)")
            testResult = "✗ \(error.localizedDescription)"
        }
    }

    private func applyViaManager() async {
        guard let wallpaper = fetchedWallpaper else {
            testResult = "✗ No wallpaper"
            return
        }

        print("🖼️ Applying via WallpaperManager...")
        await wallpaperManager.applyWallpaper(wallpaper)
        testResult = "✓ Applied!"
        print("✓ Applied via manager")
    }

    private func applyToDesktop() async {
        guard let tempURL = tempFileURL else {
            testResult = "✗ No image"
            return
        }

        do {
            for screen in NSScreen.screens {
                try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [:])
            }
            testResult = "✓ Applied Direct!"
            print("✓ Applied to desktop directly")
        } catch {
            testResult = "✗ \(error.localizedDescription)"
            print("✗ Apply failed: \(error)")
        }
    }
}

// MARK: - Sources Card

@available(macOS 13.0, *)
struct SourcesCard: View {
    @StateObject private var preferences = Preferences.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Enabled Sources")
                    .font(.headline)
                Spacer()
            }

            if preferences.enabledSources.isEmpty {
                Text("No sources enabled")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                FlowLayout {
                    ForEach(preferences.enabledSources, id: \.self) { sourceType in
                        HStack {
                            Image(systemName: sourceType.iconName)
                            Text(sourceType.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Helper Extensions

private extension CGFloat {
    func toInt() -> Int {
        Int(self)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > (proposal.width ?? .infinity) {
                currentX = 0
                currentY += lineHeight + 8
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX + size.width)
            currentX += size.width + 8
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + 8
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .init(size))
            currentX += size.width + 8
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WallpaperManager.shared)
    }
}
