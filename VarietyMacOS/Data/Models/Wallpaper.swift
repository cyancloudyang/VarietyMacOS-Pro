import Foundation
@preconcurrency import AppKit
import SwiftData

/// Represents a wallpaper with all its metadata
@Model
final class Wallpaper {
    var id: String
    var source: WallpaperSourceType
    var title: String?
    var wallpaperDescription: String?
    var author: String?
    var authorURL: URL?
    var sourceURL: URL?

    // CGSize decomposed into Double pairs for SwiftData compatibility
    var resolutionWidth: Double
    var resolutionHeight: Double

    var fileSize: Int?
    var createdAt: Date?
    var upvotes: Int?
    var subreddit: String?
    var tags: [String]?
    var colors: [String]?
    var views: Int?
    var favorites: Int?
    var fileType: String?

    var remoteURL: URL?
    var localURL: URL?
    var thumbnailURL: URL?

    @Transient
    var cachedImage: NSImage?

    var downloadDate: Date?

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \HistoryEntry.wallpaper)
    var historyEntries: [HistoryEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \FavoriteEntry.wallpaper)
    var favoriteEntries: [FavoriteEntry] = []

    // MARK: - Computed Properties

    var resolution: CGSize {
        get { CGSize(width: resolutionWidth, height: resolutionHeight) }
        set {
            resolutionWidth = newValue.width
            resolutionHeight = newValue.height
        }
    }

    var displayTitle: String {
        title ?? "Wallpaper from \(source.displayName)"
    }

    var displayAuthor: String {
        author ?? "Unknown"
    }

    var resolutionString: String {
        "\(Int(resolutionWidth)) x \(Int(resolutionHeight))"
    }

    var fileSizeString: String {
        guard let size = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    var aspectRatio: CGFloat {
        guard resolutionHeight > 0 else { return 1.0 }
        return CGFloat(resolutionWidth / resolutionHeight)
    }

    var isDownloaded: Bool {
        guard let localPath = localURL?.path else { return false }
        return FileManager.default.fileExists(atPath: localPath)
    }

    var isLandscape: Bool {
        aspectRatio > 1.0
    }

    var colorSwatchesHex: [String] {
        guard let colors = colors else { return [] }
        return colors.prefix(6).map { hex in
            hex.hasPrefix("#") ? hex : "#\(hex)"
        }
    }

    var fileTypeDisplay: String {
        guard let fileType = fileType else { return "Unknown" }
        if fileType.contains("jpeg") { return "JPEG" }
        if fileType.contains("png") { return "PNG" }
        if fileType.contains("gif") { return "GIF" }
        if fileType.contains("webp") { return "WebP" }
        return fileType.uppercased()
    }

    var viewsDisplay: String {
        guard let views = views else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: views)) ?? "\(views)"
    }

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        source: WallpaperSourceType,
        remoteURL: URL? = nil,
        localURL: URL? = nil,
        thumbnailURL: URL? = nil,
        title: String? = nil,
        wallpaperDescription: String? = nil,
        author: String? = nil,
        authorURL: URL? = nil,
        sourceURL: URL? = nil,
        resolution: CGSize = CGSize(width: 1920, height: 1080),
        fileSize: Int? = nil,
        createdAt: Date? = nil,
        upvotes: Int? = nil,
        subreddit: String? = nil,
        tags: [String]? = nil,
        colors: [String]? = nil,
        views: Int? = nil,
        favorites: Int? = nil,
        fileType: String? = nil
    ) {
        self.id = id
        self.source = source
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.thumbnailURL = thumbnailURL
        self.title = title
        self.wallpaperDescription = wallpaperDescription
        self.author = author
        self.authorURL = authorURL
        self.sourceURL = sourceURL
        self.resolutionWidth = Double(resolution.width)
        self.resolutionHeight = Double(resolution.height)
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.subreddit = subreddit
        self.tags = tags
        self.colors = colors
        self.views = views
        self.favorites = favorites
        self.fileType = fileType
    }

    // MARK: - Methods

    /// Clear the cached image to free memory
    func clearCachedImage() {
        cachedImage = nil
    }

    /// Load the full image
    @MainActor
    func loadImage() async throws -> NSImage {
        // Check cache first
        if let cached = cachedImage {
            return cached
        }

        // Try local file
        if let localURL = localURL,
           FileManager.default.fileExists(atPath: localURL.path),
           let image = NSImage(contentsOf: localURL) {
            self.cachedImage = image
            return image
        }

        // Download from remote
        guard let remoteURL = remoteURL else {
            throw WallpaperError.noImageAvailable
        }

        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        guard let image = NSImage(data: data) else {
            throw WallpaperError.invalidImage
        }

        self.cachedImage = image

        return image
    }

    /// Load thumbnail
    @MainActor
    func loadThumbnail() async throws -> NSImage {
        guard let thumbnailURL = thumbnailURL else {
            return try await loadImage()
        }

        let (data, _) = try await URLSession.shared.data(from: thumbnailURL)
        guard let image = NSImage(data: data) else {
            throw WallpaperError.invalidImage
        }

        return image
    }

    /// Save to local storage
    func saveToDisk() async throws -> URL {
        guard let remoteURL = remoteURL else {
            throw WallpaperError.noImageAvailable
        }

        let downloadsDir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Variety")

        try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)

        let destination = downloadsDir.appendingPathComponent("\(id).jpg")

        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        try data.write(to: destination)

        localURL = destination
        downloadDate = Date()

        return destination
    }

    /// Delete local copy
    func deleteLocalCopy() throws {
        guard let localURL = localURL else { return }
        try FileManager.default.removeItem(at: localURL)
        self.localURL = nil
    }
}
