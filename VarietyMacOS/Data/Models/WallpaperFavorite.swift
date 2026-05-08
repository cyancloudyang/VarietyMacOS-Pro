import Foundation
import Combine

/// Manages favorite wallpapers
@available(macOS 13.0, *)
final class WallpaperFavorite: ObservableObject {
    static let shared = WallpaperFavorite()
    
    @Published var favorites: [FavoriteEntry] = []
    
    private let persistence = Persistence.shared
    private let favoritesKey = "wallpaperFavorites"
    
    private init() {
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    /// Add a wallpaper to favorites
    func add(_ wallpaper: Wallpaper) {
        guard !isFavorite(wallpaper) else { return }
        
        let entry = FavoriteEntry(
            wallpaperId: wallpaper.id,
            wallpaper: wallpaper,
            dateAdded: Date(),
            tags: [],
            notes: nil
        )
        
        favorites.append(entry)
        saveFavorites()
        
        Logger.info("Added to favorites: \(wallpaper.displayTitle)")
    }
    
    /// Remove a wallpaper from favorites
    func remove(_ wallpaper: Wallpaper) {
        favorites.removeAll { $0.wallpaperId == wallpaper.id }
        saveFavorites()
    }
    
    /// Remove by ID
    func remove(id: String) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }
    
    /// Check if a wallpaper is favorited
    func isFavorite(_ wallpaper: Wallpaper) -> Bool {
        favorites.contains { $0.wallpaperId == wallpaper.id }
    }
    
    /// Toggle favorite status
    func toggle(_ wallpaper: Wallpaper) {
        if isFavorite(wallpaper) {
            remove(wallpaper)
        } else {
            add(wallpaper)
        }
    }
    
    /// Get all favorites
    func allFavorites() -> [FavoriteEntry] {
        favorites.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    /// Get favorites by source
    func favorites(from source: WallpaperSourceType) -> [FavoriteEntry] {
        favorites.filter { $0.wallpaper?.source == source }
            .sorted { $0.dateAdded > $1.dateAdded }
    }
    
    /// Search favorites
    func search(query: String) -> [FavoriteEntry] {
        favorites.filter { entry in
            entry.wallpaper?.displayTitle.localizedCaseInsensitiveContains(query) ?? false ||
            entry.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            (entry.notes?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    /// Get favorites by tag
    func favorites(tagged tag: String) -> [FavoriteEntry] {
        favorites.filter { $0.tags.contains(tag) }
    }
    
    /// Get all tags
    func allTags() -> [String] {
        Set(favorites.flatMap { $0.tags }).sorted()
    }
    
    /// Update tags for a favorite
    func updateTags(for id: String, tags: [String]) {
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            favorites[index].tags = tags
            saveFavorites()
        }
    }
    
    /// Update notes for a favorite
    func updateNotes(for id: String, notes: String?) {
        if let index = favorites.firstIndex(where: { $0.id == id }) {
            favorites[index].notes = notes
            saveFavorites()
        }
    }
    
    /// Clear all favorites
    func clear() {
        favorites.removeAll()
        saveFavorites()
    }
    
    /// Get statistics
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
        if let data = persistence.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([FavoriteEntry].self, from: data) {
            favorites = decoded
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            persistence.set(data, forKey: favoritesKey)
        }
    }
}

// MARK: - Favorite Entry

struct FavoriteEntry: Identifiable, Codable {
    let id: String
    let wallpaperId: String
    let wallpaper: Wallpaper?
    let dateAdded: Date
    var tags: [String]
    var notes: String?
    
    init(wallpaperId: String, wallpaper: Wallpaper? = nil, dateAdded: Date, tags: [String] = [], notes: String? = nil) {
        self.id = UUID().uuidString
        self.wallpaperId = wallpaperId
        self.wallpaper = wallpaper
        self.dateAdded = dateAdded
        self.tags = tags
        self.notes = notes
    }
    
    // Custom coding
    enum CodingKeys: String, CodingKey {
        case id, wallpaperId, dateAdded, tags, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        wallpaperId = try container.decode(String.self, forKey: .wallpaperId)
        dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        tags = try container.decode([String].self, forKey: .tags)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        wallpaper = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(wallpaperId, forKey: .wallpaperId)
        try container.encode(dateAdded, forKey: .dateAdded)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(notes, forKey: .notes)
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

// MARK: - Export/Import

extension WallpaperFavorite {
    /// Export favorites to JSON
    func exportToJSON() -> Data? {
        try? JSONEncoder().encode(favorites)
    }
    
    /// Import favorites from JSON
    func importFromJSON(_ data: Data) throws {
        let imported = try JSONDecoder().decode([FavoriteEntry].self, from: data)
        favorites = imported
        saveFavorites()
    }
}
