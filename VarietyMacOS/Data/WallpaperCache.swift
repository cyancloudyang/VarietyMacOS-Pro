import Foundation
import AppKit

/// Cache for wallpaper images
@available(macOS 13.0, *)
class WallpaperCache {
    static let shared = WallpaperCache()
    
    private let cache = NSCache<NSString, NSImage>()
    private let cacheQueue = DispatchQueue(label: "com.variety.cache", attributes: .concurrent)
    
    init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func setImage(_ image: NSImage, forKey key: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.setObject(image, forKey: key as NSString)
        }
    }
    
    func getImage(forKey key: String) -> NSImage? {
        cacheQueue.sync {
            cache.object(forKey: key as NSString)
        }
    }
    
    func removeImage(forKey key: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeObject(forKey: key as NSString)
        }
    }
    
    func removeAllImages() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
    
    static func key(for wallpaper: Wallpaper) -> String {
        if let url = wallpaper.remoteURL {
            return "remote_\(url.host ?? "")_\(url.path)"
        } else if let url = wallpaper.localURL {
            return "local_\(url.path)"
        }
        return "unknown_\(UUID().uuidString)"
    }
}

// MARK: - String Extension

private extension String {
    var sha256: String {
        // Simple hash - in production use CryptoKit
        return self.data(using: .utf8)?.base64EncodedString() ?? self
    }
}
