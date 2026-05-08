import Foundation
import AppKit
import CoreImage
import ImageIO

/// Generates thumbnails locally from full-size images using CGImageSource downsampling
public actor LocalResizeStrategy {
    private let targetSize: CGSize
    
    public init(targetSize: CGSize = CGSize(width: 400, height: 225)) {
        self.targetSize = targetSize
    }
    
    /// Generate a thumbnail from a local image URL using efficient downsampling
    /// - Parameters:
    ///   - url: URL to the full-size image
    ///   - targetSize: Maximum dimensions for the thumbnail (preserves aspect ratio)
    /// - Returns: ThumbnailResult with the generated thumbnail
    func generateThumbnail(
        from url: URL,
        targetSize: CGSize? = nil
    ) async throws -> ThumbnailResult {
        let size = targetSize ?? self.targetSize
        
        // Try CGImageSource downsampling first (memory-efficient)
        if let image = downsampleImage(at: url, to: size) {
            return ThumbnailResult(image: image, source: .local(url))
        }
        
        // Fallback: load NSImage and resize
        guard let originalImage = NSImage(contentsOf: url) else {
            throw ThumbnailError.invalidImageData
        }
        
        let resizedImage = originalImage.resized(to: size)
        return ThumbnailResult(image: resizedImage, source: .local(url))
    }
    
    /// Downsample image using CGImageSource (memory-efficient, doesn't load full image)
    /// - Parameters:
    ///   - url: URL to the source image
    ///   - targetSize: Maximum dimensions for the thumbnail
    /// - Returns: Downsampled NSImage or nil if failed
    private func downsampleImage(at url: URL, to targetSize: CGSize) -> NSImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              CGImageSourceGetCount(imageSource) > 0 else {
            return nil
        }
        
        // Calculate the aspect-fit size within target bounds
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
              width > 0, height > 0 else {
            return nil
        }
        
        let aspectRatio = width / height
        var thumbnailWidth = targetSize.width
        var thumbnailHeight = targetSize.height
        
        // Preserve aspect ratio while fitting within target bounds
        let targetAspectRatio = targetSize.width / targetSize.height
        if aspectRatio > targetAspectRatio {
            // Width-constrained
            thumbnailHeight = thumbnailWidth / aspectRatio
        } else {
            // Height-constrained
            thumbnailWidth = thumbnailHeight * aspectRatio
        }
        
        let maxPixelSize = max(thumbnailWidth, thumbnailHeight)
        
        // CGImageSource options for efficient downsampling
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: thumbnailWidth, height: thumbnailHeight))
    }
}

// MARK: - NSImage Extension for Aspect-Fit Resize

extension NSImage {
    /// Resize the image to fit within targetSize while preserving aspect ratio
    /// - Parameter targetSize: Maximum dimensions for the resized image
    /// - Returns: Resized NSImage with aspect-fit dimensions
    func resized(to targetSize: CGSize) -> NSImage {
        let aspectWidth = targetSize.width / size.width
        let aspectHeight = targetSize.height / size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let newSize = NSSize(
            width: size.width * aspectRatio,
            height: size.height * aspectRatio
        )
        
        let resizedImage = NSImage(size: newSize, flipped: false) { rect in
            self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
            return true
        }
        
        resizedImage.isTemplate = isTemplate
        return resizedImage
    }
}
