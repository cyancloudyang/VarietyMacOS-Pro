import Foundation

/// Reddit wallpaper source
/// Fetches images from Reddit communities
struct RedditSource: WallpaperSource {
    var sourceID: String { "reddit" }
    var displayName: String { "Reddit" }
    
    private let baseURL = "https://www.reddit.com"
    private let userAgent = "VarietyWallpaperApp/1.0"
    
    // MARK: - WallpaperSource
    
    func fetchWallpaper() async throws -> Wallpaper {
        let wallpapers = try await fetchWallpapers(count: 1)
        guard let first = wallpapers.first else {
            throw WallpaperError.noImageAvailable
        }
        return first
    }
    
    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        let subreddits = Preferences.shared.redditSubreddits.isEmpty
            ? ["earthporn", "CityPorn", "spaceporn", "Art"]
            : Preferences.shared.redditSubreddits
        
        var allWallpapers: [Wallpaper] = []
        
        // Shuffle subreddits for variety
        let shuffledSubreddits = subreddits.shuffled()
        
        for subreddit in shuffledSubreddits {
            if allWallpapers.count >= count { break }
            
            do {
                let remaining = count - allWallpapers.count
                let subredditWallpapers = try await fetchFromSubreddit(subreddit, count: remaining)
                allWallpapers.append(contentsOf: subredditWallpapers)
            } catch {
                Logger.warning("Failed to fetch from r/\(subreddit): \(error.localizedDescription)")
                continue
            }
        }
        
        return allWallpapers
    }
    
    func isAvailable() -> Bool {
        true
    }
    
    func configuration() -> SourceConfiguration {
        SourceConfiguration(
            sourceType: .reddit,
            isEnabled: Preferences.shared.redditEnabled,
            weight: Preferences.shared.redditWeight,
            customSettings: [
                "subreddits": Preferences.shared.redditSubreddits.joined(separator: ","),
                "sort": Preferences.shared.redditSort ?? "hot",
                "time": Preferences.shared.redditTime ?? "day"
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func fetchFromSubreddit(_ subreddit: String, count: Int) async throws -> [Wallpaper] {
        let sort = Preferences.shared.redditSort ?? "hot"
        let time = Preferences.shared.redditTime ?? "day"
        
        let url = buildSubredditURL(subreddit: subreddit, sort: sort, time: time)
        let response: RedditListing = try await downloadRedditJSON(from: url)
        
        return response.data.children.compactMap { child -> Wallpaper? in
            guard let wallpaper = createWallpaper(from: child.data) else { return nil }
            return wallpaper
        }
    }
    
    private func buildSubredditURL(subreddit: String, sort: String, time: String) -> URL {
        var components = URLComponents(string: "\(baseURL)/r/\(subreddit)/\(sort).json")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "t", value: time)
        ]
        return components.url!
    }
    
    private func downloadRedditJSON<T: Decodable>(from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DownloadError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func createWallpaper(from post: RedditPost) -> Wallpaper? {
        // Only use image posts
        guard post.isImagePost else {
            Logger.debug("Reddit post is not an image post: \(post.id)")
            return nil
        }
        
        // Skip over 18 posts
        if post.over18 {
            Logger.debug("Skipping NSFW Reddit post: \(post.id)")
            return nil
        }
        
        let imageUrl: URL?
        if let url = URL(string: post.url), isImageURL(url) {
            imageUrl = url
        } else if let preview = post.preview?.images.first,
            let source = preview.source?.url,
            let url = URL(string: source.replacingOccurrences(of: "&amp;", with: "&")) {
            imageUrl = url
        } else {
            Logger.debug("No valid image URL found for Reddit post: \(post.id)")
            return nil
        }
        
        guard let finalUrl = imageUrl else { return nil }
        
        return Wallpaper(
            id: "reddit_\(post.id)",
            source: .reddit,
            remoteURL: finalUrl,
            thumbnailURL: post.thumbnailURL,
            title: post.title,
            wallpaperDescription: post.selftext?.isEmpty == false ? post.selftext : nil,
            author: post.author,
            sourceURL: URL(string: "\(baseURL)\(post.permalink)"),
            resolution: CGSize(
                width: CGFloat(post.preview?.images.first?.source?.width ?? 1920),
                height: CGFloat(post.preview?.images.first?.source?.height ?? 1080)
            ),
            upvotes: post.ups,
            subreddit: post.subreddit
        )
    }
    
    private func isImageURL(_ url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - Reddit API Models

struct RedditListing: Codable {
    let kind: String
    let data: RedditListingData
}

struct RedditListingData: Codable {
    let after: String?
    let before: String?
    let children: [RedditChild]
    let dist: Int
    let modhash: String?
}

struct RedditChild: Codable {
    let kind: String
    let data: RedditPost
}

struct RedditPost: Codable {
    let id: String
    let name: String
    let title: String
    let author: String
    let subreddit: String
    let permalink: String
    let url: String
    let thumbnail: String
    let preview: RedditPreview?
    let selftext: String?
    let ups: Int
    let downs: Int
    let score: Int
    let createdUtc: Double
    let isVideo: Bool
    let isSelf: Bool
    let postHint: String?
    let linkFlairText: String?
    let over18: Bool
    let spoiler: Bool
    
    var isImagePost: Bool {
        if isVideo || isSelf { return false }
        if postHint == "image" { return true }
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp"]
        return imageExtensions.contains(URL(string: url)?.pathExtension.lowercased() ?? "")
    }
    
    var thumbnailURL: URL? {
        if thumbnail.hasPrefix("http") {
            return URL(string: thumbnail)
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, title, author, subreddit, permalink, url, thumbnail, preview, selftext
        case ups, downs, score
        case createdUtc = "created_utc"
        case isVideo = "is_video"
        case isSelf = "is_self"
        case postHint = "post_hint"
        case linkFlairText = "link_flair_text"
        case over18 = "over_18"
        case spoiler
    }
}

struct RedditPreview: Codable {
    let images: [RedditImagePreview]
    let enabled: Bool
}

struct RedditImagePreview: Codable {
    let source: RedditImageSource?
    let resolutions: [RedditImageSource]
    let id: String
}

struct RedditImageSource: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct RedditImageVariants: Codable {
    // Simplified to avoid recursive type - store GIF/MP4 preview URLs if available
    let gifUrl: String?
    let mp4Url: String?
}

// MARK: - Extensions

extension RedditSource {
    /// Search for wallpapers in a subreddit
    func search(in subreddit: String, query: String, count: Int = 10) async throws -> [Wallpaper] {
        var components = URLComponents(string: "\(baseURL)/r/\(subreddit)/search.json")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "restrict_sr", value: "1"),
            URLQueryItem(name: "limit", value: String(count)),
            URLQueryItem(name: "sort", value: "relevance")
        ]
        
        guard let url = components.url else {
            throw DownloadError.invalidResponse
        }
        
        let response: RedditListing = try await downloadRedditJSON(from: url)
        return response.data.children.compactMap { createWallpaper(from: $0.data) }
    }
    
    /// Get trending subreddits for wallpapers
    func getTrendingSubreddits() -> [String] {
        return [
            "earthporn",
            "CityPorn",
            "spaceporn",
            "Art",
            "wallpaper",
            "wallpapers",
            "MinimalWallpaper",
            "ultrawidemasterrace",
            "WidescreenWallpaper"
        ]
    }
}
