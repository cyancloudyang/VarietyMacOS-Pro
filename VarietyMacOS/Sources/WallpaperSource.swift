import Foundation

/// Protocol defining a wallpaper source
@MainActor
protocol WallpaperSource: Sendable {
    /// Unique identifier for the source
    var sourceID: String { get }
    
    /// Display name of the source
    var displayName: String { get }
    
    /// Fetch a wallpaper from this source
    func fetchWallpaper() async throws -> Wallpaper
    
    /// Fetch multiple wallpapers from this source
    func fetchWallpapers(count: Int) async throws -> [Wallpaper]
    
    /// Check if the source is available/configured
    func isAvailable() -> Bool
    
    /// Get source-specific configuration
    func configuration() -> SourceConfiguration
}

// MARK: - Default Implementations

extension WallpaperSource {
    var sourceID: String {
        String(describing: type(of: self))
    }
    
    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        for _ in 0..<count {
            let wallpaper = try await fetchWallpaper()
            wallpapers.append(wallpaper)
        }
        return wallpapers
    }
    
    func isAvailable() -> Bool {
        true
    }
}

// MARK: - Wallpaper Source Types

/// Enum representing different wallpaper source types
enum WallpaperSourceType: String, CaseIterable, Codable, Identifiable, Sendable {
    case unsplash = "unsplash"
    case bing = "bing"
    case wallhaven = "wallhaven"
    case reddit = "reddit"
    case local = "local"
    case artstation = "artstation"

    var id: String { rawValue }
    
    /// Display name for the source type
    var displayName: String {
        switch self {
        case .unsplash:
            return "Unsplash"
        case .bing:
            return "Bing Daily"
        case .wallhaven:
            return "Wallhaven"
        case .reddit:
            return "Reddit"
        case .local:
            return "Local Folder"
        case .artstation:
            return "ArtStation"
        }
    }
    
    /// Icon name for the source type
    var iconName: String {
        switch self {
        case .unsplash:
            return "camera.fill"
        case .bing:
            return "globe"
        case .wallhaven:
            return "photo.fill"
        case .reddit:
            return "bubble.left.fill"
        case .local:
            return "folder.fill"
        case .artstation:
            return "paintbrush.fill"
        }
    }
    
    /// Description of the source
    var description: String {
        switch self {
        case .unsplash:
            return "High-quality photos from Unsplash"
        case .bing:
            return "Bing's daily featured image"
        case .wallhaven:
            return "Community wallpapers from Wallhaven"
        case .reddit:
            return "Images from Reddit communities"
        case .local:
            return "Your local image collection"
        case .artstation:
            return "Trending digital art and wallpapers"
        }
    }
    
    /// Create an instance of the source with default settings
    @MainActor
    func createSource() -> WallpaperSource {
        switch self {
        case .unsplash:
            return UnsplashSource()
        case .bing:
            return BingSource()
        case .wallhaven:
            return WallhavenSource()
        case .reddit:
            return RedditSource()
        case .local:
            return LocalSource()
        case .artstation:
            return ArtStationSource()
        }
    }

    /// Create an instance of the source with current preferences
    @MainActor
    func createSourceFromPreferences() -> WallpaperSource {
        switch self {
        case .unsplash:
            return UnsplashSource(fromPreferences: true)
        case .bing:
            return BingSource(fromPreferences: true)
        case .wallhaven:
            return WallhavenSource(fromPreferences: true)
        case .reddit:
            return RedditSource(fromPreferences: true)
        case .local:
            return LocalSource(fromPreferences: true)
        case .artstation:
            return ArtStationSource(fromPreferences: true)
        }
    }
}

// MARK: - Source Configuration

/// Configuration for a wallpaper source
struct SourceConfiguration: Codable, Sendable {
    var sourceType: WallpaperSourceType
    var isEnabled: Bool
    var weight: Double // Probability weight for random selection
    var customSettings: [String: String]
    
    init(
        sourceType: WallpaperSourceType,
        isEnabled: Bool = true,
        weight: Double = 1.0,
        customSettings: [String: String] = [:]
    ) {
        self.sourceType = sourceType
        self.isEnabled = isEnabled
        self.weight = weight
        self.customSettings = customSettings
    }
}

// MARK: - Source Priority

/// Manages source selection based on weights
struct SourceSelector: Sendable {
    private var configurations: [SourceConfiguration]
    
    init(configurations: [SourceConfiguration]) {
        self.configurations = configurations.filter { $0.isEnabled }
    }
    
    /// Select a random source based on weights
    @MainActor
    func selectSource() -> WallpaperSource? {
        let totalWeight = configurations.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        
        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulativeWeight: Double = 0
        
        for config in configurations {
            cumulativeWeight += config.weight
            if randomValue < cumulativeWeight {
                return config.sourceType.createSource()
            }
        }
        
        return configurations.last?.sourceType.createSource()
    }
}
