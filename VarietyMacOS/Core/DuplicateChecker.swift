import Foundation

/// Checks for duplicate wallpapers based on recent history
@MainActor
final class DuplicateChecker {
    static let shared = DuplicateChecker()
    
    private init() {}
    
    /// Check if a wallpaper was recently applied within the specified time window
    func isDuplicate(_ wallpaper: Wallpaper, in history: [HistoryEntry], within window: TimeInterval) -> Bool {
        let cutoffDate = Date().addingTimeInterval(-window)
        
        for entry in history where entry.timestamp >= cutoffDate {
            if entry.wallpaperId == wallpaper.id {
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
