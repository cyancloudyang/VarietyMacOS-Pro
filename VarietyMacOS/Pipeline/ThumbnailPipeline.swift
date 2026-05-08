import Foundation
import AppKit

/// Orchestrates thumbnail generation with caching and fallback strategies
@available(macOS 13.0, *)
public actor ThumbnailPipeline {
    private let cache: ThumbnailCache
    private let sourceStrategy: SourceThumbnailStrategy
    private let localStrategy: LocalResizeStrategy
    
    public init() {
        self.cache = ThumbnailCache()
        self.sourceStrategy = SourceThumbnailStrategy()
        self.localStrategy = LocalResizeStrategy()
    }
    
    /// Main entry: returns thumbnail for a wallpaper
    /// Flow: Cache hit → Source download → Local resize
    func thumbnail(for wallpaper: Wallpaper) async throws -> ThumbnailResult {
        let cacheKey = wallpaper.id
        
        // 1. Check cache
        if let cached = await cache.get(key: cacheKey) {
            return ThumbnailResult(image: cached, source: .generated)
        }
        
        // 2. Try source thumbnail
        if let result = try await sourceStrategy.fetchThumbnail(for: wallpaper) {
            try await cache.set(key: cacheKey, image: result.image)
            return result
        }
        
        // 3. Fallback: local resize
        // Use wallpaper.localURL if available, otherwise try remoteURL
        guard let imageURL = wallpaper.localURL ?? wallpaper.remoteURL else {
            throw ThumbnailError.sourceNotFound
        }
        
        let result = try await localStrategy.generateThumbnail(from: imageURL)
        try await cache.set(key: cacheKey, image: result.image)
        return result
    }

    /// Pre-warm cache for multiple wallpapers
    func prewarmCache(for wallpapers: [Wallpaper]) async {
        for wallpaper in wallpapers {
            do {
                _ = try await thumbnail(for: wallpaper)
            } catch {
                // Silently skip failures during prewarming
            }
        }
    }

    /// Clear all cached thumbnails
    public func clearCache() async {
        await cache.clear()
    }
}
