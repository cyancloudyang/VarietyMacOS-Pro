import Foundation
import AppKit

/// Represents a wallpaper with all its metadata
@available(macOS 13.0, *)
final class Wallpaper: Identifiable, Codable, ObservableObject {
    let id: String
    let source: WallpaperSourceType
    let title: String?
    let description: String?
    let author: String?
    let authorURL: URL?
    let sourceURL: URL?
    let resolution: CGSize
    let fileSize: Int?
    let createdAt: Date?
    let upvotes: Int?
    let subreddit: String?
    
    var remoteURL: URL?
    var localURL: URL?
    var thumbnailURL: URL?
    
    @Published var cachedImage: NSImage?
    var downloadDate: Date?
    
    init(
        id: String,
        source: WallpaperSourceType,
        remoteURL: URL? = nil,
        localURL: URL? = nil,
        thumbnailURL: URL? = nil,
        title: String? = nil,
        description: String? = nil,
        author: String? = nil,
        authorURL: URL? = nil,
        sourceURL: URL? = nil,
        resolution: CGSize = CGSize(width: 1920, height: 1080),
        fileSize: Int? = nil,
        createdAt: Date? = nil,
        upvotes: Int? = nil,
        subreddit: String? = nil
    ) {
        self.id = id
        self.source = source
        self.remoteURL = remoteURL
        self.localURL = localURL
        self.thumbnailURL = thumbnailURL
        self.title = title
        self.description = description
        self.author = author
        self.authorURL = authorURL
        self.sourceURL = sourceURL
        self.resolution = resolution
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.upvotes = upvotes
        self.subreddit = subreddit
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, source, title, description, author
        case authorURL, sourceURL, resolution, fileSize, createdAt
        case remoteURL, localURL, thumbnailURL
        case downloadDate, upvotes, subreddit
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        source = try container.decode(WallpaperSourceType.self, forKey: .source)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        authorURL = try container.decodeIfPresent(URL.self, forKey: .authorURL)
        sourceURL = try container.decodeIfPresent(URL.self, forKey: .sourceURL)
        resolution = try container.decode(CGSize.self, forKey: .resolution)
        fileSize = try container.decodeIfPresent(Int.self, forKey: .fileSize)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        remoteURL = try container.decodeIfPresent(URL.self, forKey: .remoteURL)
        localURL = try container.decodeIfPresent(URL.self, forKey: .localURL)
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        downloadDate = try container.decodeIfPresent(Date.self, forKey: .downloadDate)
        upvotes = try container.decodeIfPresent(Int.self, forKey: .upvotes)
        subreddit = try container.decodeIfPresent(String.self, forKey: .subreddit)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(authorURL, forKey: .authorURL)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encode(resolution, forKey: .resolution)
        try container.encodeIfPresent(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(remoteURL, forKey: .remoteURL)
        try container.encodeIfPresent(localURL, forKey: .localURL)
        try container.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
        try container.encodeIfPresent(downloadDate, forKey: .downloadDate)
        try container.encodeIfPresent(upvotes, forKey: .upvotes)
        try container.encodeIfPresent(subreddit, forKey: .subreddit)
    }
    
    // MARK: - Computed Properties
    
    var displayTitle: String {
        title ?? "Wallpaper from \(source.displayName)"
    }
    
    var displayAuthor: String {
        author ?? "Unknown"
    }
    
    var resolutionString: String {
        "\(Int(resolution.width)) x \(Int(resolution.height))"
    }
    
    var fileSizeString: String {
        guard let size = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    var aspectRatio: CGFloat {
        resolution.width / resolution.height
    }
    
    var isDownloaded: Bool {
        guard let localPath = localURL?.path else { return false }
        return FileManager.default.fileExists(atPath: localPath)
    }
    
    var isLandscape: Bool {
        aspectRatio > 1.0
    }
    
    // MARK: - Methods
    
    /// Load the full image
    func loadImage() async throws -> NSImage {
        // Check cache first
        if let cached = cachedImage {
            return cached
        }
        
        // Try local file
        if let localURL = localURL,
           FileManager.default.fileExists(atPath: localURL.path),
           let image = NSImage(contentsOf: localURL) {
            await MainActor.run {
                self.cachedImage = image
            }
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
        
        await MainActor.run {
            self.cachedImage = image
        }
        
        return image
    }
    
    /// Load thumbnail
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

// MARK: - Hashable & Equatable

extension Wallpaper: Hashable {
    static func == (lhs: Wallpaper, rhs: Wallpaper) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
