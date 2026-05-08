import Foundation

/// Unsplash wallpaper source
/// Fetches high-quality photos from Unsplash API
@available(macOS 13.0, *)
struct UnsplashSource: WallpaperSource {
    var sourceID: String { "unsplash" }
    var displayName: String { "Unsplash" }
    
    private let accessKey: String?
    private let baseURL = "https://api.unsplash.com"
    
    init(accessKey: String? = nil) {
        self.accessKey = accessKey ?? Preferences.shared.unsplashAccessKey
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
        // For demo purposes, using the source.unsplash API (no key required)
        // In production, use the official API with access key
        let url = URL(string: "https://source.unsplash.com/random/1920x1080")!
        
        var wallpapers: [Wallpaper] = []
        
        for _ in 0..<count {
            let wallpaper = Wallpaper(
                id: "unsplash_\(UUID().uuidString)",
                source: .unsplash,
                remoteURL: url,
                thumbnailURL: url,
                title: "Unsplash Photo",
                description: "Random photo from Unsplash",
                author: "Unsplash Photographer",
                sourceURL: url,
                resolution: CGSize(width: 1920, height: 1080)
            )
            wallpapers.append(wallpaper)
        }
        
        return wallpapers
    }
    
    func fetchWallpapersWithAPI(count: Int) async throws -> [Wallpaper] {
        guard let accessKey = accessKey, !accessKey.isEmpty else {
            return try await fetchWallpapers(count: count)
        }
        
        var wallpapers: [Wallpaper] = []
        
        // Fetch using official API
        for _ in 0..<count {
            let url = buildRandomURL()
            let photo: UnsplashPhoto = try await DefaultDownloader.shared.downloadJSON(from: url, as: UnsplashPhoto.self)
            
            if let wallpaper = createWallpaper(from: photo) {
                wallpapers.append(wallpaper)
            }
        }
        
        return wallpapers
    }
    
    func isAvailable() -> Bool {
        true
    }
    
    func configuration() -> SourceConfiguration {
        SourceConfiguration(
            sourceType: .unsplash,
            isEnabled: Preferences.shared.unsplashEnabled,
            weight: Preferences.shared.unsplashWeight,
            customSettings: [
                "accessKey": Preferences.shared.unsplashAccessKey ?? "",
                "collections": Preferences.shared.unsplashCollections ?? "",
                "topics": Preferences.shared.unsplashTopics ?? ""
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func buildRandomURL() -> URL {
        var components = URLComponents(string: "\(baseURL)/photos/random")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: accessKey!)
        ]
        
        // Add optional parameters
        if let collections = Preferences.shared.unsplashCollections, !collections.isEmpty {
            queryItems.append(URLQueryItem(name: "collections", value: collections))
        }
        
        if let topics = Preferences.shared.unsplashTopics, !topics.isEmpty {
            queryItems.append(URLQueryItem(name: "topics", value: topics))
        }
        
        // Request high-quality image
        queryItems.append(URLQueryItem(name: "orientation", value: "landscape"))
        
        components.queryItems = queryItems
        return components.url!
    }
    
    private func createWallpaper(from photo: UnsplashPhoto) -> Wallpaper? {
        guard let url = URL(string: photo.urls.full) else { return nil }
        guard let sourceURL = URL(string: photo.links.html) else { return nil }
        
        // Convert ISO8601 string to Date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = photo.createdAt.flatMap { dateFormatter.date(from: $0) }
        
        return Wallpaper(
            id: "unsplash_\(photo.id)",
            source: .unsplash,
            remoteURL: url,
            thumbnailURL: URL(string: photo.urls.small),
            title: photo.description ?? photo.altDescription,
            description: photo.altDescription,
            author: photo.user.name,
            authorURL: URL(string: photo.user.links.html),
            sourceURL: sourceURL,
            resolution: CGSize(
                width: CGFloat(photo.width),
                height: CGFloat(photo.height)
            ),
            createdAt: createdAt
        )
    }
}

// MARK: - Unsplash API Models

struct UnsplashPhoto: Codable {
    let id: String
    let createdAt: String?
    let updatedAt: String?
    let width: Int
    let height: Int
    let color: String?
    let blurHash: String?
    let downloads: Int?
    let likes: Int?
    let description: String?
    let altDescription: String?
    let urls: UnsplashUrls
    let links: UnsplashLinks
    let user: UnsplashUser
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case width, height, color
        case blurHash = "blur_hash"
        case downloads, likes, description
        case altDescription = "alt_description"
        case urls, links, user
    }
}

struct UnsplashUrls: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
    let smallS3: String?
    
    enum CodingKeys: String, CodingKey {
        case raw, full, regular, small, thumb
        case smallS3 = "small_s3"
    }
}

struct UnsplashLinks: Codable {
    let own: String?
    let html: String
    let download: String?
    let downloadLocation: String?
    
    enum CodingKeys: String, CodingKey {
        case own = "self"
        case html, download
        case downloadLocation = "download_location"
    }
}

struct UnsplashUser: Codable {
    let id: String
    let updatedAt: String?
    let username: String
    let name: String
    let firstName: String?
    let lastName: String?
    let twitterUsername: String?
    let portfolioUrl: String?
    let bio: String?
    let location: String?
    let links: UnsplashUserLinks
    let profileImage: UnsplashProfileImage?
    let totalCollections: Int?
    let totalLikes: Int?
    let totalPhotos: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case updatedAt = "updated_at"
        case username, name
        case firstName = "first_name"
        case lastName = "last_name"
        case twitterUsername = "twitter_username"
        case portfolioUrl = "portfolio_url"
        case bio, location, links
        case profileImage = "profile_image"
        case totalCollections = "total_collections"
        case totalLikes = "total_likes"
        case totalPhotos = "total_photos"
    }
}

struct UnsplashUserLinks: Codable {
    let own: String?
    let html: String
    let photos: String?
    let likes: String?
    let portfolio: String?
    let following: String?
    let followers: String?
    
    enum CodingKeys: String, CodingKey {
        case own = "self"
        case html, photos, likes, portfolio, following, followers
    }
}

struct UnsplashProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

// MARK: - Search Response

struct UnsplashSearchResponse: Codable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhoto]
    
    enum CodingKeys: String, CodingKey {
        case total
        case totalPages = "total_pages"
        case results
    }
}
