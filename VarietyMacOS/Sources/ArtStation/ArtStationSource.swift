import Foundation

/// ArtStation wallpaper source - uses RSS feed for featured artworks
/// Reference: Variety's ArtStationDownloader uses RSS feed from artstation.com
final class ArtStationSource: WallpaperSource {
    var displayName: String { "ArtStation" }
    var sourceID: String { "artstation" }
    
    // User agent to avoid being blocked
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    // ArtStation RSS feed for featured artwork
    private let rssFeedURL = URL(string: "https://www.artstation.com/featured.rss")!
    
    // Fallback to API if RSS fails
    private let apiURL = URL(string: "https://www.artstation.com/api/v2/projects/trending.json")!
    
    private var fetchCount: Int = 0

    func fetchWallpaper() async throws -> Wallpaper {
        // Try RSS feed first (like Variety does)
        do {
            if let wallpaper = try await fetchFromRSS() {
                return wallpaper
            }
        } catch {
            Logger.warning("ArtStation RSS failed, falling back to API: \(error.localizedDescription)")
        }
        
        // Fallback to API
        return try await fetchFromAPI()
    }
    
    private func fetchFromRSS() async throws -> Wallpaper? {
        let url = rssFeedURL
        var request = URLRequest(url: url)
        request.setValue("application/rss+xml", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ArtStation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch RSS feed"])
        }
        
        // Parse RSS feed
        let rssString = String(data: data, encoding: .utf8) ?? ""
        let items = parseRSSFeed(rssString)
        
        guard !items.isEmpty else {
            throw NSError(domain: "ArtStation", code: -2, userInfo: [NSLocalizedDescriptionKey: "No items in RSS feed"])
        }
        
        // Select random item, increment counter for rotation
        let index = (fetchCount % items.count)
        fetchCount += 1
        let item = items[index]
        
        // Validate we have an image URL
        guard let imageUrl = item.imageUrl else {
            return nil
        }
        
        return Wallpaper(
            id: "artstation_\(UUID().uuidString)",
            source: .artstation,
            remoteURL: imageUrl,
            title: item.title,
            wallpaperDescription: item.description,
            author: item.author,
            sourceURL: item.link
        )
    }
    
    private func fetchFromAPI() async throws -> Wallpaper {
        var request = URLRequest(url: apiURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "ArtStation", code: -1, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        let apiResponse = try decoder.decode(APIResponse.self, from: data)
        
        guard let project = apiResponse.data.randomElement() else {
            throw NSError(domain: "ArtStation", code: -2, userInfo: [NSLocalizedDescriptionKey: "No projects found"])
        }
        
        // Get the best image URL
        guard let imageUrl = project.cover?.largeImageURL ?? project.cover?.mediumImageURL ?? project.cover?.smallImageURL else {
            throw NSError(domain: "ArtStation", code: -3, userInfo: [NSLocalizedDescriptionKey: "No image URL"])
        }
        
        return Wallpaper(
            id: "artstation_\(UUID().uuidString)",
            source: .artstation,
            remoteURL: imageUrl,
            title: project.title,
            wallpaperDescription: project.user?.fullName,
            author: project.user?.fullName,
            sourceURL: nil
        )
    }
    
    // MARK: - RSS Parsing
    
    private func parseRSSFeed(_ rssString: String) -> [ArtStationItem] {
        var items: [ArtStationItem] = []
        
        // Simple RSS parsing - extract items between <item> tags
        let itemPattern = #"<item>(.*?)</item>"#
        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern, options: [.dotMatchesLineSeparators]) else {
            return items
        }
        
        let range = NSRange(rssString.startIndex..., in: rssString)
        let matches = itemRegex.matches(in: rssString, options: [], range: range)
        
        for match in matches {
            if let itemRange = Range(match.range(at: 1), in: rssString) {
                let itemContent = String(rssString[itemRange])
                if let item = parseItem(itemContent) {
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    private func parseItem(_ content: String) -> ArtStationItem? {
        guard let title = extractTag("title", from: content),
              let description = extractTag("description", from: content),
              let link = extractTag("link", from: content),
              let imageUrl = extractImageURL(from: content) else {
            return nil
        }
        
        let author = extractTag("creator", from: content) ?? "Unknown"
        
        return ArtStationItem(title: title, description: description, link: URL(string: link), imageUrl: imageUrl, author: author)
    }
    
    private func extractTag(_ tagName: String, from content: String) -> String? {
        let pattern = "<\(tagName)>(.*?)</\(tagName)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(content.startIndex..., in: content)
        if let match = regex.firstMatch(in: content, options: [], range: range) {
            if let textRange = Range(match.range(at: 1), in: content) {
                var result = String(content[textRange])
                // Clean up CDATA and HTML entities
                result = result.replacingOccurrences(of: "<![CDATA[", with: "")
                result = result.replacingOccurrences(of: "]]>", with: "")
                result = result.replacingOccurrences(of: "&amp;", with: "&")
                result = result.replacingOccurrences(of: "&lt;", with: "<")
                result = result.replacingOccurrences(of: "&gt;", with: ">")
                return result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
    
    private func extractImageURL(from content: String) -> URL? {
        // Look for enclosure or media:content
        if let url = extractURL(from: content, pattern: #"<enclosure[^>]*url=["']([^"']+)["']"#) {
            return url
        }
        if let url = extractURL(from: content, pattern: #"<media:content[^>]*url=["']([^"']+)["']"#) {
            return url
        }
        // Look for image in description
        if let url = extractURL(from: content, pattern: #"<img[^>]*src=["']([^"']+)["']"#) {
            return url
        }
        return nil
    }
    
    private func extractURL(from content: String, pattern: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(content.startIndex..., in: content)
        if let match = regex.firstMatch(in: content, options: [], range: range) {
            if let urlRange = Range(match.range(at: 1), in: content) {
                return URL(string: String(content[urlRange]))
            }
        }
        return nil
    }

    func configuration() -> SourceConfiguration {
        SourceConfiguration(sourceType: .artstation)
    }
}

// MARK: - ArtStation Item Model

private struct ArtStationItem {
    let title: String
    let description: String
    let link: URL?
    let imageUrl: URL?
    let author: String
}

// MARK: - API Response Models

/// ArtStation trending response
struct APIResponse: Codable {
    let data: [ArtStationProject]
}

/// ArtStation project
struct ArtStationProject: Codable {
    let title: String
    let cover: ArtStationCover?
    let user: ArtStationUser?
    let publishedAt: Date?
}

/// ArtStation cover image
struct ArtStationCover: Codable {
    let largeImageURL: URL?
    let mediumImageURL: URL?
    let smallImageURL: URL?

    enum CodingKeys: String, CodingKey {
        case largeImageURL = "large_square_url"
        case mediumImageURL = "medium_square_url"
        case smallImageURL = "small_square_url"
    }
}

/// ArtStation user
struct ArtStationUser: Codable {
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
    }
}
