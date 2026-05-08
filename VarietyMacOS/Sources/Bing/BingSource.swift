import Foundation

/// Bing wallpaper source
/// Fetches the daily featured image from Bing
@available(macOS 13.0, *)
struct BingSource: WallpaperSource {
    var sourceID: String { "bing" }
    var displayName: String { "Bing Daily" }
    
    private let baseURL = "https://www.bing.com"
    private let apiEndpoint = "https://www.bing.com/HPImageArchive.aspx"
    
    // MARK: - WallpaperSource
    
    func fetchWallpaper() async throws -> Wallpaper {
        let wallpapers = try await fetchWallpapers(count: 1)
        guard let first = wallpapers.first else {
            throw WallpaperError.noImageAvailable
        }
        return first
    }
    
    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        let url = buildArchiveURL(count: count)
        
        // Build request with proper headers
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Bing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch Bing wallpapers"])
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let bingResponse = try decoder.decode(BingResponse.self, from: data)
        
        let wallpapers = bingResponse.images.compactMap { createWallpaper(from: $0) }
        
        guard !wallpapers.isEmpty else {
            throw NSError(domain: "Bing", code: -2, userInfo: [NSLocalizedDescriptionKey: "No valid wallpapers found"])
        }
        
        return wallpapers
    }
    
    func isAvailable() -> Bool {
        true
    }
    
    func configuration() -> SourceConfiguration {
        SourceConfiguration(
            sourceType: .bing,
            isEnabled: Preferences.shared.bingEnabled,
            weight: Preferences.shared.bingWeight,
            customSettings: [
                "market": Preferences.shared.bingMarket ?? "en-US",
                "resolution": Preferences.shared.bingResolution ?? "UHD"
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func buildArchiveURL(count: Int) -> URL {
        var components = URLComponents(string: apiEndpoint)!
        let market = Preferences.shared.bingMarket ?? "en-US"
        let resolution = Preferences.shared.bingResolution ?? "UHD"
        
        components.queryItems = [
            URLQueryItem(name: "format", value: "js"),
            URLQueryItem(name: "idx", value: "0"),
            URLQueryItem(name: "n", value: String(count)),
            URLQueryItem(name: "mkt", value: market),
            URLQueryItem(name: "uhd", value: resolution == "UHD" ? "1" : "0")
        ]
        
        return components.url!
    }
    
    private func createWallpaper(from image: BingImage) -> Wallpaper? {
        guard let url = URL(string: baseURL + image.url) else { return nil }
        guard let copyrightUrl = URL(string: image.copyrightlink) else { return nil }
        
        // Parse resolution from image dimensions
        let resolution = parseResolution(image.resolution)
        
        return Wallpaper(
            id: "bing_\(image.startdate)",
            source: .bing,
            remoteURL: url,
            thumbnailURL: URL(string: baseURL + image.thumbnailUrl()),
            title: image.title,
            description: image.copyright,
            author: extractAuthor(from: image.copyright),
            sourceURL: copyrightUrl,
            resolution: resolution,
            createdAt: parseDate(image.startdate)
        )
    }
    
    private func parseResolution(_ resolution: String?) -> CGSize {
        guard let res = resolution,
              let width = Int(res.split(separator: "x").first ?? "1920"),
              let height = Int(res.split(separator: "x").last ?? "1080") else {
            return CGSize(width: 1920, height: 1080)
        }
        return CGSize(width: width, height: height)
    }
    
    private func extractAuthor(from copyright: String) -> String? {
        // Extract author name from copyright string like "© John Doe"
        let pattern = "© ([^()]+)"
        if let range = copyright.range(of: pattern, options: .regularExpression) {
            return String(copyright[range]).replacingOccurrences(of: "© ", with: "").trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: dateString)
    }
}

// MARK: - Bing API Models

struct BingResponse: Codable {
    let images: [BingImage]
    let tooltips: BingTooltips?
}

struct BingImage: Codable {
    let startdate: String
    let fullstartdate: String?
    let enddate: String
    let url: String
    let urlbase: String
    let copyright: String
    let copyrightlink: String
    let title: String
    let quiz: String?
    let wp: Bool?
    let hsh: String?
    let bot: Int?
    let hs: [BingHotspot]?
    let msg: [BingMessage]?
    
    var resolution: String? {
        // Extract resolution from URL pattern like "_1920x1080.jpg"
        if let range = url.range(of: "_\\d+x\\d+", options: .regularExpression) {
            return String(url[range]).replacingOccurrences(of: "_", with: "")
        }
        return nil
    }
    
    func thumbnailUrl() -> String {
        // Return thumbnail version
        return "\(urlbase)_400x225.jpg"
    }
}

struct BingHotspot: Codable {
    let desc: String
    let link: String
    let query: String
    let locx: Int
    let locy: Int
}

struct BingMessage: Codable {
    let title: String
    let text: String
    let link: String
}

struct BingTooltips: Codable {
    let loading: String?
    let previous: String?
    let next: String?
    let walle: String?
    let walls: String?
}

// MARK: - Extensions

extension BingSource {
    /// Get wallpaper for a specific date
    func fetchWallpaper(for date: Date) async throws -> Wallpaper {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        
        // Bing API doesn't support specific dates, so we get recent ones
        // and filter (this is a simplified approach)
        let wallpapers = try await fetchWallpapers(count: 8)
        if let wallpaper = wallpapers.first(where: { $0.id.contains(dateString) }) {
            return wallpaper
        }
        
        // Return first available if specific date not found
        guard let first = wallpapers.first else {
            throw WallpaperError.noImageAvailable
        }
        return first
    }
    
    /// Get wallpapers for multiple days
    func fetchWallpapers(days: Int) async throws -> [Wallpaper] {
        return try await fetchWallpapers(count: min(days, 8))
    }
}
