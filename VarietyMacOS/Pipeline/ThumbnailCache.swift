import Foundation
@preconcurrency import AppKit

@MainActor
public final class ThumbnailCache {
    private let memoryCache = NSCache<NSString, NSImage>()
    private let diskCacheURL: URL
    
    public init() {
        memoryCache.countLimit = 50
        
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cachesDir
            .appendingPathComponent("VarietyMacOS", isDirectory: true)
            .appendingPathComponent("ThumbnailCache", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    /// Get image from cache (memory first, then disk)
    /// - Parameter key: Unique string identifier
    /// - Returns: Cached NSImage or nil if not found
    public func get(key: String) -> NSImage? {
        let nsKey = key as NSString
        
        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }
        
        let fileURL = diskCacheURL.appendingPathComponent(key)
        if let cached = NSImage(contentsOf: fileURL) {
            memoryCache.setObject(cached, forKey: nsKey)
            return cached
        }
        
        return nil
    }
    
    public func set(key: String, image: NSImage) throws {
        let nsKey = key as NSString
        memoryCache.setObject(image, forKey: nsKey)
        
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            return
        }
        
        try jpegData.write(to: fileURL)
    }
    
    public func remove(key: String) {
        let nsKey = key as NSString
        memoryCache.removeObject(forKey: nsKey)
        
        let fileURL = diskCacheURL.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    public func clear() {
        memoryCache.removeAllObjects()
        
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    public func clearMemory() {
        memoryCache.removeAllObjects()
    }
}
