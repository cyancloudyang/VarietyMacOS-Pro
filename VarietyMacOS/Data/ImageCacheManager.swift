import Foundation
@preconcurrency import AppKit
import CoreImage

/// High-performance image cache manager with memory and disk caching
@MainActor
final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    // Memory cache (NSCache auto-manages memory pressure)
    private let memoryCache = NSCache<NSString, NSImage>()
    
    // Disk cache paths
    private let diskCachePath: URL
    private let tempCachePath: URL
    
    // Configuration
    private let maxMemoryItems = 50
    private let maxDiskSizeMB: UInt64 = 500
    
    // Dedicated ephemeral session for image downloads
    // Using ephemeral avoids NSURLError -999 cancellations from shared session reuse
    private let session: URLSession

  // CIContext for hardware-accelerated image processing
  private let ciContext: CIContext

  // Thumbnail pipeline for thumbnail generation
  private let thumbnailPipeline = ThumbnailPipeline()

  private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        memoryCache.countLimit = maxMemoryItems
        
        // Disk cache directory in user's cache
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCachePath = cachesDir.appendingPathComponent("VarietyMacOS/WallpaperCache", isDirectory: true)
        tempCachePath = cachesDir.appendingPathComponent("VarietyMacOS/TempCache", isDirectory: true)
        
        // Create cache directories
        try? FileManager.default.createDirectory(at: diskCachePath, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: tempCachePath, withIntermediateDirectories: true)
        
        // CIContext with GPU acceleration
        ciContext = CIContext(options: [
            .useSoftwareRenderer: false
        ])
        
        // Clean up old cache on init
        Task {
            await cleanupOldCache()
        }
    }
    
    // MARK: - Image Operations
    
    /// Get image with caching (memory -> disk -> download)
    func getImage(for key: String, from url: URL) async throws -> NSImage {
        // 1. Check memory cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            Logger.debug("Cache hit (memory): \(key)")
            return cached
        }
        
        // 2. Check disk cache
        let diskCacheURL = diskCachePath.appendingPathComponent(key)
        if let cached = NSImage(contentsOf: diskCacheURL) {
            Logger.debug("Cache hit (disk): \(key)")
            // Recycle to memory
            memoryCache.setObject(cached, forKey: key as NSString)
            return cached
        }
        
        // 3. Download and cache using dedicated ephemeral session
        Logger.debug("Cache miss, downloading: \(key)")
        let (data, _) = try await session.data(from: url)
        
        // Use Core Image for hardware-accelerated decoding (M-chip optimization)
        guard let image = decodeImageWithCoreImage(data) ?? NSImage(data: data) else {
            throw NSError(domain: "ImageCache", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        // Cache to memory and disk
        memoryCache.setObject(image, forKey: key as NSString)
        try? data.write(to: diskCacheURL)
        
        Logger.debug("Cached: \(key) - Size: \(image.size)")
        return image
    }
    
    /// Get image from local file
    func getImage(from fileURL: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: fileURL) else {
            throw NSError(domain: "ImageCache", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid image file"])
        }
        return image
    }
    
    /// Preload next wallpaper (async, non-blocking)
    func preloadImage(for key: String, from url: URL) {
        Task {
            _ = try? await getImage(for: key, from: url)
        }
    }
    
    /// Clear all caches
    func clearCache() {
        memoryCache.removeAllObjects()

        try? FileManager.default.removeItem(at: diskCachePath)
        try? FileManager.default.createDirectory(at: diskCachePath, withIntermediateDirectories: true)

        try? FileManager.default.removeItem(at: tempCachePath)
        try? FileManager.default.createDirectory(at: tempCachePath, withIntermediateDirectories: true)

        Task { await thumbnailPipeline.clearCache() }

        Logger.info("Cache cleared")
    }
    
    /// Clear memory cache only
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        Task { await thumbnailPipeline.clearCache() }
        Logger.debug("Memory cache cleared")
    }
    
  /// Get cache statistics
  func getCacheStats() -> (memoryCount: Int, diskSizeMB: Double) {
    let memoryCount = 0 // NSCache count not directly accessible

    var diskSizeMB: Double = 0
    if let files = try? FileManager.default.contentsOfDirectory(at: diskCachePath, includingPropertiesForKeys: [.fileSizeKey]) {
      var totalSize: UInt64 = 0
      for file in files {
        if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
          totalSize += UInt64(size)
        }
      }
      diskSizeMB = Double(totalSize) / (1024.0 * 1024.0)
    }

    return (memoryCount, diskSizeMB)
  }

  // MARK: - Thumbnail Pipeline Delegation

  /// Get thumbnail for a wallpaper using the thumbnail pipeline
  func cachedThumbnail(for wallpaper: Wallpaper) async throws -> ThumbnailResult? {
    return try await thumbnailPipeline.thumbnail(for: wallpaper)
  }

  /// Pre-warm thumbnail cache for multiple wallpapers
  func prewarmThumbnails(for wallpapers: [Wallpaper]) async {
    await thumbnailPipeline.prewarmCache(for: wallpapers)
  }

/// Clear all cached thumbnails
    func clearThumbnailCache() async {
        await thumbnailPipeline.clearCache()
    }

// MARK: - Private Methods

/// Decode image using Core Image (M-chip hardware acceleration)
private func decodeImageWithCoreImage(_ data: Data) -> NSImage? {
guard let ciImage = CIImage(data: data) else { return nil }

guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
return nil
}

return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
}

/// Clean up old cache files
private func cleanupOldCache() async {
guard let files = try? FileManager.default.contentsOfDirectory(at: diskCachePath, includingPropertiesForKeys: [.contentAccessDateKey]) else {
return
}

let now = Date()
let thirtyDays = TimeInterval(30 * 24 * 60 * 60)

for file in files {
if let accessDate = try? file.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate,
accessDate < now - thirtyDays {
try? FileManager.default.removeItem(at: file)
Logger.debug("Cleaned up old cache: \(file.lastPathComponent)")
}
}
}
}

// MARK: - Cache Helper

/// Cache helper for wallpaper images
extension Wallpaper {
    /// Get cached image key
    var cacheKey: String {
        if let url = remoteURL {
            return "remote_\(url.host ?? "")_\(url.path)"
        } else if let url = localURL {
            return "local_\(url.path)"
        }
        return "unknown_\(UUID().uuidString)"
    }
}
