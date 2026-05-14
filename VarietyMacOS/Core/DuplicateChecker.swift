import Foundation

/// Checks for duplicate wallpapers based on recent history
@MainActor
final class DuplicateChecker {
    static let shared = DuplicateChecker()
    
    private init() {}
    
    /// Check if a wallpaper was recently applied within the specified time window
    func isDuplicate(_ wallpaper: Wallpaper, in history: [HistoryEntry], within window: TimeInterval) -> Bool {
        let cutoffDate = Date().addingTimeInterval(-window)
        let wallpaperURLString = wallpaper.remoteURL?.absoluteString

        for entry in history where entry.timestamp >= cutoffDate {
            // Compare by remote URL string to avoid ID collisions from same-source fetches
            if let entryURLString = entry.wallpaper?.remoteURL?.absoluteString,
               let wallpaperURLString = wallpaperURLString,
               entryURLString == wallpaperURLString {
                return true
            }
        }

        return false
    }
    
    /// Get list of recently applied wallpaper IDs
    func recentWallpaperIds(in history: [HistoryEntry], within window: TimeInterval) -> Set<String> {
        let cutoffDate = Date().addingTimeInterval(-window)
        return Set(history.filter { $0.timestamp >= cutoffDate }.map { $0.wallpaperId })
    }
}
