import Foundation
import Combine
import SwiftData

/// Manages wallpaper change history
final class WallpaperHistory: ObservableObject {
    static let shared = WallpaperHistory()

    @Published var entries: [HistoryEntry] = []
    @Published var maxEntries: Int = 100

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadHistory()
    }

    // MARK: - Public Methods

    func add(_ wallpaper: Wallpaper) {
        let entry = HistoryEntry(
            wallpaperId: wallpaper.id,
            wallpaper: wallpaper,
            timestamp: Date(),
            source: wallpaper.source
        )

        guard let context = modelContext else { return }
        context.insert(entry)
        entries.insert(entry, at: 0)

        wallpaper.clearCachedImage()

        if entries.count > maxEntries {
            let entriesToRemove = entries[maxEntries...]
            for entryToRemove in entriesToRemove {
                entryToRemove.wallpaper?.clearCachedImage()
                context.delete(entryToRemove)
            }
            entries = Array(entries.prefix(maxEntries))
        }

        try? context.save()
    }

    func remove(_ entry: HistoryEntry) {
        guard let context = modelContext else { return }
        entries.removeAll { $0.id == entry.id }
        context.delete(entry)
        try? context.save()
    }

    func clear() {
        guard let context = modelContext else { return }
        for entry in entries {
            context.delete(entry)
        }
        entries.removeAll()
        try? context.save()
    }

    func recentEntries(count: Int = 10) -> [HistoryEntry] {
        Array(entries.prefix(count))
    }

    func prefetchThumbnails() {
        let recentWallpapers = entries.prefix(10).compactMap(\.wallpaper)
        guard !recentWallpapers.isEmpty else { return }
        Task {
            let pipeline = ThumbnailPipeline()
            await pipeline.prewarmCache(for: recentWallpapers)
        }
    }

    func entries(from startDate: Date, to endDate: Date) -> [HistoryEntry] {
        entries.filter { entry in
            entry.timestamp >= startDate && entry.timestamp <= endDate
        }
    }

    func entries(from source: WallpaperSourceType) -> [HistoryEntry] {
        entries.filter { $0.source == source }
    }

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

    func search(query: String) -> [HistoryEntry] {
        entries.filter { entry in
            entry.wallpaper?.displayTitle.localizedCaseInsensitiveContains(query) ?? false ||
            entry.wallpaper?.displayAuthor.localizedCaseInsensitiveContains(query) ?? false
        }
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<HistoryEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let result = try? context.fetch(descriptor) {
            entries = result
        }
    }

    /// Export history to JSON
    func exportToJSON() -> Data? {
        // TODO: Implement SwiftData-compatible export
        nil
    }

    /// Import history from JSON
    func importFromJSON(_ data: Data) throws {
        // TODO: Implement SwiftData-compatible import
    }
}

// MARK: - History Entry

@Model
final class HistoryEntry {
    var id: String
    var wallpaperId: String
    var wallpaper: Wallpaper?
    var timestamp: Date
    var source: WallpaperSourceType

    init(
        id: String = UUID().uuidString,
        wallpaperId: String,
        wallpaper: Wallpaper? = nil,
        timestamp: Date,
        source: WallpaperSourceType
    ) {
        self.id = id
        self.wallpaperId = wallpaperId
        self.wallpaper = wallpaper
        self.timestamp = timestamp
        self.source = source
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
