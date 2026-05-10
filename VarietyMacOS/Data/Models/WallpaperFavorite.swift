import Foundation
import Combine
import SwiftData

/// Manages favorite wallpapers
final class WallpaperFavorite: ObservableObject {
    static let shared = WallpaperFavorite()

    @Published var favorites: [FavoriteEntry] = []

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadFavorites()
    }

    // MARK: - Public Methods

    func add(_ wallpaper: Wallpaper) {
        guard !isFavorite(wallpaper) else { return }

        let entry = FavoriteEntry(
            wallpaperId: wallpaper.id,
            wallpaper: wallpaper,
            dateAdded: Date(),
            tags: [],
            notes: nil
        )

        guard let context = modelContext else { return }
        context.insert(entry)
        favorites.append(entry)
        try? context.save()

        Logger.info("Added to favorites: \(wallpaper.displayTitle)")
    }

    func remove(_ wallpaper: Wallpaper) {
        guard let context = modelContext else { return }
        let wallpaperId = wallpaper.id
        favorites.removeAll { $0.wallpaperId == wallpaperId }
        let descriptor = FetchDescriptor<FavoriteEntry>(
            predicate: #Predicate { $0.wallpaperId == wallpaperId }
        )
        if let matching = try? context.fetch(descriptor) {
            for entry in matching {
                context.delete(entry)
            }
        }
        try? context.save()
    }

    func remove(id: String) {
        guard let context = modelContext else { return }
        favorites.removeAll { $0.id == id }
        let descriptor = FetchDescriptor<FavoriteEntry>(
            predicate: #Predicate { $0.id == id }
        )
        if let matching = try? context.fetch(descriptor) {
            for entry in matching {
                context.delete(entry)
            }
        }
        try? context.save()
    }

    func isFavorite(_ wallpaper: Wallpaper) -> Bool {
        favorites.contains { $0.wallpaperId == wallpaper.id }
    }

    func toggle(_ wallpaper: Wallpaper) {
        if isFavorite(wallpaper) {
            remove(wallpaper)
        } else {
            add(wallpaper)
        }
    }

    func allFavorites() -> [FavoriteEntry] {
        favorites.sorted { $0.dateAdded > $1.dateAdded }
    }

    func favorites(from source: WallpaperSourceType) -> [FavoriteEntry] {
        favorites.filter { $0.wallpaper?.source == source }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    func search(query: String) -> [FavoriteEntry] {
        favorites.filter { entry in
            entry.wallpaper?.displayTitle.localizedCaseInsensitiveContains(query) ?? false ||
            entry.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            (entry.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    func favorites(tagged tag: String) -> [FavoriteEntry] {
        favorites.filter { $0.tags.contains(tag) }
    }

    func allTags() -> [String] {
        Set(favorites.flatMap { $0.tags }).sorted()
    }

    func updateTags(for id: String, tags: [String]) {
        guard let context = modelContext else { return }
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            favorites[index].tags = tags
            try? context.save()
        }
    }

    func updateNotes(for id: String, notes: String?) {
        guard let context = modelContext else { return }
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            favorites[index].notes = notes
            try? context.save()
        }
    }

    func clear() {
        guard let context = modelContext else { return }
        for entry in favorites {
            context.delete(entry)
        }
        favorites.removeAll()
        try? context.save()
    }

    func statistics() -> FavoriteStatistics {
        var sourceCounts: [WallpaperSourceType: Int] = [:]
        var tagCounts: [String: Int] = [:]

        for entry in favorites {
            if let source = entry.wallpaper?.source {
                sourceCounts[source, default: 0] += 1
            }
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }

        return FavoriteStatistics(
            totalFavorites: favorites.count,
            uniqueSources: sourceCounts.count,
            uniqueTags: tagCounts.count,
            sourceDistribution: sourceCounts,
            tagDistribution: tagCounts
        )
    }

    // MARK: - Persistence

    private func loadFavorites() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<FavoriteEntry>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        if let result = try? context.fetch(descriptor) {
            favorites = result
        }
    }

    /// Export favorites to JSON
    func exportToJSON() -> Data? {
        // TODO: Implement SwiftData-compatible export
        nil
    }

    /// Import favorites from JSON
    func importFromJSON(_ data: Data) throws {
        // TODO: Implement SwiftData-compatible import
    }
}

// MARK: - Favorite Entry

@Model
final class FavoriteEntry {
    var id: String
    var wallpaperId: String
    var wallpaper: Wallpaper?
    var dateAdded: Date
    var tags: [String]
    var notes: String?

    init(
        id: String = UUID().uuidString,
        wallpaperId: String,
        wallpaper: Wallpaper? = nil,
        dateAdded: Date,
        tags: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.wallpaperId = wallpaperId
        self.wallpaper = wallpaper
        self.dateAdded = dateAdded
        self.tags = tags
        self.notes = notes
    }
}

// MARK: - Favorite Statistics

struct FavoriteStatistics {
    let totalFavorites: Int
    let uniqueSources: Int
    let uniqueTags: Int
    let sourceDistribution: [WallpaperSourceType: Int]
    let tagDistribution: [String: Int]

    var mostUsedSource: WallpaperSourceType? {
        sourceDistribution.max { $0.value < $1.value }?.key
    }

    var mostUsedTags: [String] {
        Array(tagDistribution.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
    }
}
