import Foundation

/// Unsplash wallpaper source
/// Fetches high-quality photos from Unsplash API
struct UnsplashSource: WallpaperSource, Sendable {
    var sourceID: String { "unsplash" }
    var displayName: String { "Unsplash" }

    private let accessKey: String?
    private let collections: String?
    private let topics: String?
    private let isEnabled: Bool
    private let weight: Double
    private let baseURL = "https://api.unsplash.com"

    init(accessKey: String? = nil) {
        self.accessKey = accessKey
        self.collections = nil
        self.topics = nil
        self.isEnabled = true
        self.weight = 1.0
    }

    @MainActor
    init(fromPreferences: Bool) {
        self.accessKey = Preferences.shared.unsplashAccessKey
        self.collections = Preferences.shared.unsplashCollections
        self.topics = Preferences.shared.unsplashTopics
        self.isEnabled = Preferences.shared.unsplashEnabled
        self.weight = Preferences.shared.unsplashWeight
    }
    
    // MARK: - WallpaperSource
    
    func fetchWallpaper() async throws -> Wallpaper {
        let wallpapers = try await fetchWallpapers(count: 1)
        guard let first = wallpapers.first else {
            throw WallpaperError.noImageAvailable
        }
        return first
    }
    
    /// Fetch wallpapers from Unsplash
    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        // Use Picsum Photos as reliable free alternative to deprecated source.unsplash.com
        var wallpapers: [Wallpaper] = []
        
        for _ in 0..<count {
            let url = URL(string: "https://picsum.photos/1920/1080")!
            let wallpaper = Wallpaper(
                id: "picsum_\(UUID().uuidString)",
                source: .unsplash,
                remoteURL: url,
                thumbnailURL: URL(string: "https://picsum.photos/400/225")!,
                title: "Picsum Photo",
                wallpaperDescription: "Random photo from Picsum (via Unsplash)",
                author: "Picsum",
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
            isEnabled: isEnabled,
            weight: weight,
            customSettings: [
                "accessKey": accessKey ?? "",
                "collections": collections ?? "",
                "topics": topics ?? ""
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func buildRandomURL() -> URL {
        var components = URLComponents(string: "\(baseURL)/photos/random")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: accessKey!)
        ]

        // Add optional parameters (captured at init time)
        if let collections = collections, !collections.isEmpty {
            queryItems.append(URLQueryItem(name: "collections", value: collections))
        }

        if let topics = topics, !topics.isEmpty {
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
            wallpaperDescription: photo.altDescription,
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
