//
// VarietyMacOSApp.swift
// VarietyMacOS
//
// Main application entry point with window support
//

import SwiftUI
@preconcurrency import AppKit
import SwiftData

// MARK: - App Shortcut

enum AppShortcut: String, CaseIterable, Sendable {
    case next = "n"
    case previous = "p"
    case favorite = "f"
    case settings = ","
    case search = "k"
    case toggleSidebar = "s"
    
    var displayName: String {
        switch self {
        case .next: "Next Wallpaper"
        case .previous: "Previous Wallpaper"
        case .favorite: "Add to Favorites"
        case .settings: "Settings"
        case .search: "Search"
        case .toggleSidebar: "Toggle Sidebar"
        }
    }
    
    var modifiers: String {
        switch self {
        case .next, .previous, .favorite, .search, .toggleSidebar: "⌘"
        case .settings: "⌘"
        }
    }
    
    var description: String {
        "\(modifiers)\(rawValue.uppercased())"
    }
}

@main
struct VarietyMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    private var wallpaperManager: WallpaperManager {
        WallpaperManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environmentObject(wallpaperManager)
                .environmentObject(shortcutManager)
        }
        .modelContainer(DataContainer.modelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 900, height: 600)
        .commands {
            // Global shortcuts
            CommandGroup(replacing: .newItem) {
                Button("Next Wallpaper") {
                    Task {
                        await wallpaperManager.nextWallpaper()
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Previous Wallpaper") {
                    Task {
                        await wallpaperManager.previousWallpaper()
                    }
                }
                .keyboardShortcut("p", modifiers: .command)
                
                Button("Add to Favorites") {
                    Task { @MainActor in
                        wallpaperManager.addToFavorites()
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
                
                Button("Search") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            
            // Settings shortcut
            CommandGroup(replacing: .appSettings) {
                Button("Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
        }
        .modelContainer(DataContainer.modelContainer)
    }
}

// MARK: - Shortcut Manager

@MainActor
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var showShortcutsHelp = false
    
    func handleShortcut(_ shortcut: AppShortcut) {
        switch shortcut {
        case .next:
            Task {
                await WallpaperManager.shared.nextWallpaper()
            }
        case .previous:
            Task {
                await WallpaperManager.shared.previousWallpaper()
            }
        case .favorite:
            Task { @MainActor in
                WallpaperManager.shared.addToFavorites()
            }
        case .settings:
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        case .search:
            NotificationCenter.default.post(name: .focusSearch, object: nil)
        case .toggleSidebar:
            NotificationCenter.default.post(name: .toggleSidebar, object: nil)
        }
    }
}

extension Notification.Name {
    static let focusSearch = Notification.Name("focusSearch")
    static let toggleSidebar = Notification.Name("toggleSidebar")
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

// MARK: - Test Source Card (Debug Tool)

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
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let info = wallpaperInfo {
                            Text(info)
                                .font(.caption)
                        }
                        
                        HStack {
                            Button("Apply via Manager") {
                                Task {
                                    await applyViaManager()
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Apply Direct") {
                                Task {
                                    await applyToDesktop()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(8)
    }
    
    private func runTest() async {
        isTesting = true
        testResult = nil
        previewImage = nil
        
        // Skip actual fetch, just test UI
        do {
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("VarietyTest")
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            
            // Create placeholder test image
            let imageData = Data()
            try imageData.write(to: tempURL)
            
            previewImage = NSImage()
            tempFileURL = tempURL
            wallpaperInfo = "Test Wallpaper"
            testResult = "✓ Ready"
        } catch {
            testResult = "✗ \(error.localizedDescription)"
        }
        
        isTesting = false
    }
    
    private func applyViaManager() async {
        guard let wallpaper = fetchedWallpaper else {
            testResult = "✗ No wallpaper"
            return
        }
        await wallpaperManager.applyWallpaper(wallpaper)
        testResult = "✓ Applied!"
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
        } catch {
            testResult = "✗ \(error.localizedDescription)"
        }
    }
}
