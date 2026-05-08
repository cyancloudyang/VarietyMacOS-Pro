import Foundation
import AppKit

/// AppleScript command handler for VarietyMacOS
@available(macOS 13.0, *)
class VarietyScripting: NSObject {
    static let shared = VarietyScripting()
    
    private override init() {}
    
    /// Handle AppleScript command
    func handleCommand(_ command: String, withArgument argument: String? = nil) -> String {
        switch command {
        case "next":
            Task { @MainActor in
                await WallpaperManager.shared.nextWallpaper()
            }
            return "OK: Next wallpaper"
            
        case "previous":
            Task { @MainActor in
                await WallpaperManager.shared.previousWallpaper()
            }
            return "OK: Previous wallpaper"
            
        case "pause":
            WallpaperTimer.shared.stop()
            return "OK: Paused"
            
        case "resume":
            WallpaperTimer.shared.start(interval: Preferences.shared.changeInterval)
            return "OK: Resumed"
            
        case "info":
            return getCurrentInfo()
            
        case "set":
            if let arg = argument {
                return setWallpaper(arg)
            } else {
                return "Error: set command requires a path argument"
            }
            
        default:
            return "Error: Unknown command '\(command)'"
        }
    }
    
    private func getCurrentInfo() -> String {
        let manager = WallpaperManager.shared
        guard let wallpaper = manager.currentWallpaper else {
            return "No wallpaper set"
        }
        
        var info = """
        Title: \(wallpaper.title ?? "Unknown")
        Source: \(wallpaper.source.displayName)
        """
        
        if let description = wallpaper.description {
            info += "\nDescription: \(description)"
        }
        
        return info
    }
    
    private func setWallpaper(_ path: String) -> String {
        let fileURL = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: path) else {
            return "Error: File not found: \(path)"
        }
        
        guard let image = NSImage(contentsOf: fileURL) else {
            return "Error: Invalid image: \(path)"
        }
        
        Task { @MainActor in
            let wallpaper = Wallpaper(
                id: UUID().uuidString,
                source: .local,
                localURL: fileURL,
                title: fileURL.lastPathComponent,
                description: nil,
                createdAt: Date()
            )
            
            wallpaper.cachedImage = image
            await WallpaperManager.shared.applyWallpaper(wallpaper)
        }
        
        return "OK: Set wallpaper to \(path)"
    }
}
