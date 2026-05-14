import Foundation

/// Checks for duplicate wallpapers based on recent history
@MainActor
final class DuplicateChecker {
    static let shared = DuplicateChecker()
    
    private init() {}
    
    /// Maximum recent entries to check for duplicates (matches Reddit Wallpaper Changer's approach, uses 20 instead of 15)
    private static let maxDuplicateCheckEntries = 20
    
    /// Check if a wallpaper was recently applied within the specified time window
    /// Only checks the most recent `maxDuplicateCheckEntries` entries to avoid
    /// false positives from stale history.
    func isDuplicate(_ wallpaper: Wallpaper, in history: [HistoryEntry], within window: TimeInterval) -> Bool {
        let cutoffDate = Date().addingTimeInterval(-window)
        let wallpaperURLString = wallpaper.remoteURL?.absoluteString
        
        // Filter by time window, sort by most recent first, limit to 20 entries
        let recentEntries = history
            .filter { $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(Self.maxDuplicateCheckEntries)

        for entry in recentEntries {
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
    /// Only considers the most recent `maxDuplicateCheckEntries` entries.
    func recentWallpaperIds(in history: [HistoryEntry], within window: TimeInterval) -> Set<String> {
        let cutoffDate = Date().addingTimeInterval(-window)
        let recentEntries = history
            .filter { $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(Self.maxDuplicateCheckEntries)
        return Set(recentEntries.map { $0.wallpaperId })
    }
}
