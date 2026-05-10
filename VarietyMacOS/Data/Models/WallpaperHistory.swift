import Foundation
import Combine

/// Manages wallpaper change history
@available(macOS 13.0, *)
final class WallpaperHistory: ObservableObject {
    static let shared = WallpaperHistory()
    
    @Published var entries: [HistoryEntry] = []
    @Published var maxEntries: Int = 100
    
    private let persistence = Persistence.shared
    private let historyKey = "wallpaperHistory"
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// Add a wallpaper to history
    func add(_ wallpaper: Wallpaper) {
        let entry = HistoryEntry(
            wallpaperId: wallpaper.id,
            wallpaper: wallpaper,
            timestamp: Date(),
            source: wallpaper.source
        )
        
        entries.insert(entry, at: 0)

        // Free memory: strip cachedImage from newly added entry
        wallpaper.clearCachedImage()

        // Trim to max size
        if entries.count > maxEntries {
            // Clear cached images from removed entries
            let entriesToRemove = entries[maxEntries...]
            for entry in entriesToRemove {
                entry.wallpaper?.clearCachedImage()
            }
            entries = Array(entries.prefix(maxEntries))
        }
        
        saveHistory()
    }
    
    /// Remove an entry from history
    func remove(_ entry: HistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        saveHistory()
    }
    
    /// Clear all history
    func clear() {
        entries.removeAll()
        saveHistory()
    }
    
    /// Get recent entries
    func recentEntries(count: Int = 10) -> [HistoryEntry] {
        Array(entries.prefix(count))
    }

    /// Prefetch thumbnails for recent history entries
    func prefetchThumbnails() {
        let recentWallpapers = entries.prefix(10).compactMap(\.wallpaper)
        guard !recentWallpapers.isEmpty else { return }
        Task {
            let pipeline = ThumbnailPipeline()
            await pipeline.prewarmCache(for: recentWallpapers)
        }
    }

    /// Get entries from a specific date range
    func entries(from startDate: Date, to endDate: Date) -> [HistoryEntry] {
        entries.filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
    }
    
    /// Get entries for a specific source
    func entries(from source: WallpaperSourceType) -> [HistoryEntry] {
        entries.filter { $0.source == source }
    }
    
    /// Get statistics
    func statistics() -> HistoryStatistics {
        var sourceCounts: [WallpaperSourceType: Int] = [:]
        
        for entry in entries {
            sourceCounts[entry.source, default: 0] += 1
        }
        
        let totalDuration = entries.first?.timestamp.timeIntervalSince(entries.last?.timestamp ?? Date()) ?? 0
        let averageInterval = entries.count > 1 ? totalDuration / Double(entries.count - 1) : 0
        
        return HistoryStatistics(
            totalWallpapers: entries.count,
            uniqueSources: Set(entries.map(\.source)).count,
            sourceDistribution: sourceCounts,
            firstUsed: entries.last?.timestamp,
            lastUsed: entries.first?.timestamp,
            averageInterval: averageInterval
        )
    }
    
    /// Search history
    func search(query: String) -> [HistoryEntry] {
        entries.filter { entry in
            entry.wallpaper?.displayTitle.localizedCaseInsensitiveContains(query) ?? false ||
            entry.wallpaper?.displayAuthor.localizedCaseInsensitiveContains(query) ?? false
        }
    }
    
    // MARK: - Persistence
    
    private func loadHistory() {
        if let data = persistence.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            entries = decoded
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(entries) {
            persistence.set(data, forKey: historyKey)
        }
    }
}

// MARK: - History Entry

struct HistoryEntry: Identifiable, Codable {
    let id: String
    let wallpaperId: String
    let wallpaper: Wallpaper?
    let timestamp: Date
    let source: WallpaperSourceType
    
    init(wallpaperId: String, wallpaper: Wallpaper? = nil, timestamp: Date, source: WallpaperSourceType) {
        self.id = UUID().uuidString
        self.wallpaperId = wallpaperId
        self.wallpaper = wallpaper
        self.timestamp = timestamp
        self.source = source
    }
    
    // Custom coding to handle Wallpaper reference
    enum CodingKeys: String, CodingKey {
        case id, wallpaperId, timestamp, source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        wallpaperId = try container.decode(String.self, forKey: .wallpaperId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        source = try container.decode(WallpaperSourceType.self, forKey: .source)
        wallpaper = nil // Wallpaper is not persisted in history for simplicity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(wallpaperId, forKey: .wallpaperId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(source, forKey: .source)
    }
}

// MARK: - History Statistics

struct HistoryStatistics {
    let totalWallpapers: Int
    let uniqueSources: Int
    let sourceDistribution: [WallpaperSourceType: Int]
    let firstUsed: Date?
    let lastUsed: Date?
    let averageInterval: TimeInterval
    
    var formattedAverageInterval: String {
        let hours = Int(averageInterval) / 3600
        let minutes = (Int(averageInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

// MARK: - Export

extension WallpaperHistory {
    /// Export history to JSON
    func exportToJSON() -> Data? {
        try? JSONEncoder().encode(entries)
    }
    
    /// Import history from JSON
    func importFromJSON(_ data: Data) throws {
        let imported = try JSONDecoder().decode([HistoryEntry].self, from: data)
        entries = imported
        saveHistory()
    }
}
