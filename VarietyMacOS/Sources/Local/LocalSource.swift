import Foundation
@preconcurrency import AppKit

/// Local folder wallpaper source
/// Uses images from a local directory with recursive scanning and pattern matching
struct LocalSource: WallpaperSource, Sendable {
    var sourceID: String { "local" }
    var displayName: String { "Local Folder" }

    private let folderPath: String
    private let recursive: Bool
    private let shuffle: Bool
    private let isEnabled: Bool
    private let weight: Double
    private nonisolated(unsafe) let fileManager = FileManager.default
    private let supportedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic"]

    private var fileNamePatterns: [String] { ["*"] }

    init(folderPath: String = "", recursive: Bool = true, shuffle: Bool = true) {
        self.folderPath = folderPath
        self.recursive = recursive
        self.shuffle = shuffle
        self.isEnabled = true
        self.weight = 1.0
    }

    @MainActor
    init(fromPreferences: Bool) {
        self.folderPath = Preferences.shared.localFolderPath
        self.recursive = Preferences.shared.localRecursive
        self.shuffle = Preferences.shared.localShuffle
        self.isEnabled = Preferences.shared.localEnabled
        self.weight = Preferences.shared.localWeight
    }
    
    // MARK: - WallpaperSource
    
    func fetchWallpaper() async throws -> Wallpaper {
        let wallpapers = try await fetchWallpapers(count: 1)
        guard let first = wallpapers.first else {
            throw WallpaperError.noImageAvailable
        }
        return first
    }
    
    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        guard !folderPath.isEmpty else {
            throw WallpaperError.noImageAvailable
        }

        let folderURL = URL(fileURLWithPath: folderPath)
        let imageURLs = try await scanForImages(in: folderURL)
        
        guard !imageURLs.isEmpty else {
            throw WallpaperError.noImageAvailable
        }
        
        // Randomly select images
        let shuffled = imageURLs.shuffled()
        let selected = Array(shuffled.prefix(min(count, shuffled.count)))
        
        return try selected.compactMap { url in
            try createWallpaper(from: url)
        }
    }
    
    func isAvailable() -> Bool {
        guard !folderPath.isEmpty else { return false }

        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: folderPath, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func configuration() -> SourceConfiguration {
        SourceConfiguration(
            sourceType: .local,
            isEnabled: isEnabled,
            weight: weight,
            customSettings: [
                "folderPath": folderPath,
                "recursive": String(recursive),
                "shuffle": String(shuffle)
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func scanForImages(in folder: URL) async throws -> [URL] {
        var imageURLs: [URL] = []

        let keys: [URLResourceKey] = [.isRegularFileKey, .nameKey, .isHiddenKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]

        if recursive {
            // Recursive scanning with pattern matching
            guard let enumerator = fileManager.enumerator(
                at: folder,
                includingPropertiesForKeys: keys,
                options: options
            ) else {
                return imageURLs
            }

            while let fileURL = enumerator.nextObject() {
                guard let url = fileURL as? URL else { continue }
                
                // Check if file matches pattern and is image
                if isImageFile(url) && matchesPattern(url) {
                    imageURLs.append(url)
                }
            }
        } else {
            // Non-recursive scanning
            let contents = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: keys,
                options: options
            )

            imageURLs = contents.filter { isImageFile($0) && matchesPattern($0) }
        }

        // Sort for consistent ordering
        imageURLs.sort { $0.path < $1.path }

        return imageURLs
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedExtensions.contains(ext)
    }
    
    /// Check if file matches configured patterns (wildcard support)
    private func matchesPattern(_ url: URL) -> Bool {
        let filename = url.lastPathComponent
        
        // If no specific patterns, accept all
        if fileNamePatterns.isEmpty {
            return true
        }
        
        // Check if filename matches any pattern
        for pattern in fileNamePatterns {
            if filenameMatchesPattern(filename, pattern: pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Simple wildcard pattern matching (* and ? support)
    private func filenameMatchesPattern(_ filename: String, pattern: String) -> Bool {
        // Convert wildcard pattern to NSPredicate
        let escaped = pattern.replacingOccurrences(of: "\"", with: "\\\"")
        let predicate = NSPredicate(format: "SELF MATCHES[c] %@", escaped)
        return predicate.evaluate(with: filename)
    }
    
    private func createWallpaper(from url: URL) throws -> Wallpaper {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let creationDate = attributes[.creationDate] as? Date
        let modificationDate = attributes[.modificationDate] as? Date
        
        // Get image dimensions
        let dimensions = getImageDimensions(at: url)
        
        let filename = url.deletingPathExtension().lastPathComponent
        
        return Wallpaper(
            id: "local_\(url.path.sha256().prefix(16))",
            source: .local,
            localURL: url,
            thumbnailURL: url,
            title: filename,
            wallpaperDescription: nil,
            author: nil,
            sourceURL: nil,
            resolution: dimensions,
            fileSize: attributes[.size] as? Int,
            createdAt: creationDate ?? modificationDate
        )
    }
    
    private func getImageDimensions(at url: URL) -> CGSize {
        guard let image = NSImage(contentsOf: url) else {
            return CGSize(width: 1920, height: 1080)
        }
        return image.size
    }
    
    // MARK: - Public Methods

    func getImageCount() async -> Int {
        guard !folderPath.isEmpty else { return 0 }

        let folderURL = URL(fileURLWithPath: folderPath)

        do {
            let urls = try await scanForImages(in: folderURL)
            return urls.count
        } catch {
            Logger.error("Failed to count images: \(error.localizedDescription)")
            return 0
        }
    }

    func getAllImages() async -> [URL] {
        guard !folderPath.isEmpty else { return [] }

        let folderURL = URL(fileURLWithPath: folderPath)

        do {
            return try await scanForImages(in: folderURL)
        } catch {
            Logger.error("Failed to get images: \(error.localizedDescription)")
            return []
        }
    }

    func addImage(_ url: URL) throws {
        guard !folderPath.isEmpty else {
            throw LocalSourceError.noFolderConfigured
        }

        let folderURL = URL(fileURLWithPath: folderPath)
        let destination = folderURL.appendingPathComponent(url.lastPathComponent)
        
        try fileManager.copyItem(at: url, to: destination)
    }
    
    /// Remove an image
    func removeImage(_ url: URL) throws {
        try fileManager.removeItem(at: url)
    }
}

// MARK: - Errors

enum LocalSourceError: LocalizedError, Sendable {
    case noFolderConfigured
    case invalidImageFile
    case copyFailed
    
    var errorDescription: String? {
        switch self {
        case .noFolderConfigured:
            return "No local folder configured"
        case .invalidImageFile:
            return "Invalid image file"
        case .copyFailed:
            return "Failed to copy image file"
        }
    }
}

// MARK: - String Extensions

private extension String {
    func sha256() -> String {
        // Simple hash for demo - in production use CryptoKit
        let data = self.data(using: .utf8) ?? Data()
        return data.base64EncodedString()
    }
}
