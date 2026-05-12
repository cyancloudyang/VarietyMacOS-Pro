import Foundation

/// Wallhaven wallpaper source
/// Fetches wallpapers from wallhaven.cc API
struct WallhavenSource: WallpaperSource, Sendable {
    var sourceID: String { "wallhaven" }
    var displayName: String { "Wallhaven" }

    private let baseURL = "https://wallhaven.cc/api/v1"
    private let apiKey: String?
    private let searchQuery: String
    private let wallhavenEnabled: Bool
    private let wallhavenWeight: Double
    private let sorting: String
    private let topRange: String
    private let categories: String
    private let purity: String
    private let atleastResolution: String
    private let ratio: String

    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    private let maxRetries: Int = 5
    private let retryDelay: TimeInterval = 0.5

    init(apiKey: String? = nil, searchQuery: String = "") {
        self.apiKey = apiKey
        self.searchQuery = searchQuery
        self.wallhavenEnabled = false
        self.wallhavenWeight = 1.0
        self.sorting = "random"
        self.topRange = "1M"
        self.categories = "111"
        self.purity = "100"
        self.atleastResolution = "1920x1080"
        self.ratio = ""
    }

    @MainActor
    init(fromPreferences: Bool) {
        self.apiKey = Preferences.shared.wallhavenAPIKey
        self.searchQuery = Preferences.shared.wallhavenSearchQuery
        self.wallhavenEnabled = Preferences.shared.wallhavenEnabled
        self.wallhavenWeight = Preferences.shared.wallhavenWeight
        self.sorting = Preferences.shared.wallhavenSorting
        self.topRange = Preferences.shared.wallhavenTopRange
        self.categories = Preferences.shared.wallhavenCategories
        self.purity = Preferences.shared.wallhavenPurity
        self.atleastResolution = Preferences.shared.wallhavenResolution.isEmpty ? "1920x1080" : Preferences.shared.wallhavenResolution
        self.ratio = Preferences.shared.wallhavenRatio
    }

    // MARK: - WallpaperSource

    func fetchWallpaper() async throws -> Wallpaper {
        var lastError: Error?
        
        // Retry logic with exponential backoff
        for attempt in 0..<maxRetries {
            do {
                let wallpapers = try await fetchWallpapers(count: 1)
                guard let first = wallpapers.first else {
                    throw WallpaperError.noImageAvailable
                }
                return first
            } catch let error as URLError {
                lastError = error
                // Network error - retry with delay
                if attempt < maxRetries - 1 {
                    let delay = UInt64(retryDelay * pow(2.0, Double(attempt)) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                }
            } catch let error as NSError {
                // Check for HTTP 429 (rate limit) or 5xx (server error)
                if error.code == 429 || error.code >= 500 {
                    lastError = error
                    if attempt < maxRetries - 1 {
                        let delay = UInt64(retryDelay * pow(2.0, Double(attempt)) * 1_000_000_000)
                        try? await Task.sleep(nanoseconds: delay)
                    }
                } else {
                    throw error
                }
            } catch {
                lastError = error
                throw error
            }
        }
        
        throw lastError ?? WallpaperError.noImageAvailable
    }

    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []

        for page in 1...min(count, 5) {
            let url = buildSearchURL(query: searchQuery, page: page)
            
            // Build custom request with proper headers
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "Wallhaven", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            // Handle rate limiting
            if httpResponse.statusCode == 429 {
                throw NSError(domain: "Wallhaven", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limited by Wallhaven"])
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NSError(domain: "Wallhaven", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])
            }
            
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let apiResponse: WallhavenResponse = try decoder.decode(WallhavenResponse.self, from: data)

    for wallpaperData in apiResponse.data {
                if let wallpaper = try? await createWallpaper(from: wallpaperData) {
                    wallpapers.append(wallpaper)
                    if wallpapers.count >= count {
                        break
                    }
                }
            }
        }

        return wallpapers
    }
    
    func isAvailable() -> Bool {
        // Wallhaven doesn't require an API key for basic usage
        true
    }
    
    func configuration() -> SourceConfiguration {
        SourceConfiguration(
            sourceType: .wallhaven,
            isEnabled: wallhavenEnabled,
            weight: wallhavenWeight,
            customSettings: [
                "searchQuery": searchQuery,
                "apiKey": apiKey ?? ""
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func buildSearchURL(query: String, page: Int) -> URL {
        var components = URLComponents(string: "\(baseURL)/search")!

        let randomSeed = Int.random(in: 1..<1000000)

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sorting", value: sorting),
            URLQueryItem(name: "categories", value: categories),
            URLQueryItem(name: "purity", value: purity),
            URLQueryItem(name: "atleast", value: atleastResolution),
            URLQueryItem(name: "seed", value: "\(randomSeed)")
        ]

        if (sorting == "toplist" || sorting == "favorites") && !topRange.isEmpty {
            queryItems.append(URLQueryItem(name: "topRange", value: topRange))
        }

        if !ratio.isEmpty {
            queryItems.append(URLQueryItem(name: "ratios", value: ratio))
        }

        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        if let apiKey = apiKey, !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "apikey", value: apiKey))
        }

        components.queryItems = queryItems
        return components.url!
    }
    
private func createWallpaper(from data: WallhavenWallpaper) async throws -> Wallpaper {
    let wallpaper = Wallpaper(
    id: "wallhaven_\(data.id)",
    source: .wallhaven,
    remoteURL: URL(string: data.path),
    thumbnailURL: URL(string: data.thumbs.large),
    title: data.category,
            wallpaperDescription: data.purity,
    author: data.uploader?.username,
    sourceURL: URL(string: data.url),
    resolution: CGSize(
      width: CGFloat(Int(data.resolution.width) ?? 1920),
      height: CGFloat(Int(data.resolution.height) ?? 1080)
    ),
    fileSize: data.fileSize,
    createdAt: ISO8601DateFormatter().date(from: data.createdAt) ?? Date(),
    tags: data.tags?.map { $0.name },
    colors: data.colors,
    views: data.views,
    favorites: data.favorites,
    fileType: data.fileType
    )
    return wallpaper
  }
}

// MARK: - Wallhaven API Models

struct WallhavenResponse: Codable {
    let data: [WallhavenWallpaper]
    let meta: WallhavenMeta?
}

struct WallhavenWallpaper: Codable {
    let id: String
    let url: String
    let shortUrl: String?
    let views: Int
    let favorites: Int
    let source: String?
    let purity: String
    let category: String
    let dimensionX: Int
    let dimensionY: Int
    let resolution: WallhavenResolution
    let ratio: String
    let fileSize: Int
    let fileType: String
    let createdAt: String
    let colors: [String]?
    let path: String
    let thumbs: WallhavenThumbs
    let tags: [WallhavenTag]?
    let uploader: WallhavenUploader?
}

struct WallhavenResolution: Codable {
    let width: String
    let height: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let resolutionString = try container.decode(String.self)
        let parts = resolutionString.split(separator: "x")
        if parts.count == 2 {
            self.width = String(parts[0])
            self.height = String(parts[1])
        } else {
            self.width = "1920"
            self.height = "1080"
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(width)x\(height)")
    }
}

struct WallhavenThumbs: Codable {
    let large: String
    let original: String
    let small: String
}

struct WallhavenTag: Codable {
    let id: Int
    let name: String
    let alias: String
    let categoryId: Int
    let category: String
    let purity: String
    let createdAt: String
}

struct WallhavenUploader: Codable {
    let username: String
    let group: String
    let avatar: WallhavenAvatar?
}

struct WallhavenAvatar: Codable {
    let `200px`: String
    let `128px`: String
    let `32px`: String
    let `20px`: String
}

struct WallhavenMeta: Codable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int
    let query: String?
    let seed: String?
}
