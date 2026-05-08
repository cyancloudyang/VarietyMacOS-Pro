import Foundation
import AppKit

/// Downloads thumbnails from remote wallpaper source URLs with deduplication
@available(macOS 13.0, *)
public actor SourceThumbnailStrategy {
    private var activeDownloads: [String: Task<NSImage, Error>] = [:]
    private let cache = ThumbnailCache()
    
    /// Returns nil if wallpaper.thumbnailURL is nil (caller falls back to LocalResizeStrategy)
    public func fetchThumbnail(for wallpaper: Wallpaper) async throws -> ThumbnailResult? {
        guard let thumbnailURL = wallpaper.thumbnailURL else {
            return nil
        }
        
        let dedupKey = "\(wallpaper.id)-thumb"
        
        // Check cache first
        if let cached = cache.get(key: dedupKey) {
            return ThumbnailResult(image: cached, source: .remote(thumbnailURL))
        }
        
        // Check if download is already in progress
        if let existingTask = activeDownloads[dedupKey] {
            do {
                let image = try await existingTask.value
                return ThumbnailResult(image: image, source: .remote(thumbnailURL))
            } catch {
                activeDownloads.removeValue(forKey: dedupKey)
                throw error
            }
        }
        
        // Start new download
        let task = Task<NSImage, Error> {
            defer {
                Task { @Sendable in
                    await self.activeDownloads.removeValue(forKey: dedupKey)
                }
            }
            
            let (data, _) = try await URLSession.shared.data(from: thumbnailURL)
            guard let image = NSImage(data: data) else {
                throw ThumbnailError.invalidImageData
            }
            
            // Cache the result
            await self.cache.set(key: dedupKey, image: image)
            
            return image
        }
        
        activeDownloads[dedupKey] = task
        
        do {
            let image = try await task.value
            return ThumbnailResult(image: image, source: .remote(thumbnailURL))
        } catch {
            activeDownloads.removeValue(forKey: dedupKey)
            throw error
        }
    }
    
    public func cancelDownload(for wallpaper: Wallpaper) {
        let dedupKey = "\(wallpaper.id)-thumb"
        activeDownloads[dedupKey]?.cancel()
        activeDownloads.removeValue(forKey: dedupKey)
    }
    
    public func cancelAllDownloads() {
        activeDownloads.values.forEach { $0.cancel() }
        activeDownloads.removeAll()
    }
}
