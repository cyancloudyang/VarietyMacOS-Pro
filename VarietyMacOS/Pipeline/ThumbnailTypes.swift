import Foundation
@preconcurrency import AppKit

/// Represents the source of a thumbnail image
public enum ThumbnailSource: Sendable {
    case remote(URL)
    case local(URL)
    case generated
}

/// Contains the generated thumbnail image and its source
public struct ThumbnailResult: Sendable {
    public let image: NSImage
    public let source: ThumbnailSource
}

/// Error types that can occur during thumbnail generation
public enum ThumbnailError: LocalizedError {
    case sourceNotFound
    case downloadFailed(Error)
    case resizeFailed
    case invalidImageData
    case cacheWriteFailed

    public var errorDescription: String? {
        switch self {
        case .sourceNotFound:
            return "Thumbnail source not found"
        case .downloadFailed(let error):
            return "Failed to download thumbnail: \(error.localizedDescription)"
        case .resizeFailed:
            return "Failed to resize thumbnail image"
        case .invalidImageData:
            return "Invalid image data for thumbnail"
        case .cacheWriteFailed:
            return "Failed to write thumbnail to cache"
        }
    }
}
