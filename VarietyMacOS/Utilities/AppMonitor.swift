import Foundation
import AppKit

/// Monitors active applications and fullscreen state
@MainActor
final class AppMonitor: ObservableObject {
    static let shared = AppMonitor()
    
    @Published var isPresentationMode: Bool = false
    @Published var isGaming: Bool = false
    @Published var frontmostApp: String = ""
    
    /// List of bundle IDs that indicate presentation mode
    private let presentationApps = [
        "com.apple.Keynote",
        "com.microsoft.Powerpoint",
        "com.apple.iMovie",
        "com.apple.FinalCut"
    ]
    
    /// List of bundle IDs that indicate gaming (should pause wallpaper changes)
    private let gamingApps = [
        "com.apple.Safari",  // Fullscreen video
        "com.google.Chrome",
        "com.brave.Browser"
    ]
    
    private init() {
        updateAppState()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleAppChange() {
        Task { @MainActor in
            updateAppState()
        }
    }
    
    private func updateAppState() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            frontmostApp = ""
            isPresentationMode = false
            isGaming = false
            return
        }
        
        frontmostApp = frontApp.bundleIdentifier ?? ""
        let bundleId = frontApp.bundleIdentifier ?? ""
        
        // Check if in presentation mode
        isPresentationMode = presentationApps.contains(bundleId)
        
        // Check if in gaming mode (simplified: just check if app is in gaming list)
        isGaming = gamingApps.contains(bundleId)
    }
    
    /// Check if wallpaper changes should be paused
    func shouldPauseForApp() -> Bool {
        isPresentationMode || isGaming
    }
    
    /// Start monitoring app changes
    func startMonitoring() {
        // Initial update
        updateAppState()
    }
}
