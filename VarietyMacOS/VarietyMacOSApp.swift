//
// VarietyMacOSApp.swift
// VarietyMacOS
//
// Main application entry point with window support
//

import SwiftUI
@preconcurrency import AppKit
import SwiftData

@main
struct VarietyMacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var wallpaperManager: WallpaperManager {
        WallpaperManager.shared
    }

    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environmentObject(wallpaperManager)
        }
        .modelContainer(DataContainer.modelContainer)
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)

        Settings {
            SettingsView()
        }
        .modelContainer(DataContainer.modelContainer)
    }
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
        defer { isTesting = false }
        testResult = nil
        previewImage = nil
        wallpaperInfo = nil
        tempFileURL = nil
        fetchedWallpaper = nil

        do {
            let source = BingSource()

            let wallpaper = try await source.fetchWallpaper()

            guard let url = wallpaper.remoteURL else {
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No remote URL"])
            }

            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = NSImage(data: data) else {
                throw NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
            }

            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
            try data.write(to: tempURL)

            previewImage = image
            tempFileURL = tempURL
            fetchedWallpaper = wallpaper
            wallpaperInfo = "\(wallpaper.title ?? "Unknown")"
            testResult = "✓ Ready"

        } catch {
            testResult = "✗ \(error.localizedDescription)"
        }
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
