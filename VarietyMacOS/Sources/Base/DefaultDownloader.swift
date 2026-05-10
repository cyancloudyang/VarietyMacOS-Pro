import Foundation

/// Default downloader with caching and retry capabilities
actor DefaultDownloader {
    static let shared = DefaultDownloader()
    
    private let session: URLSession
    private let cache: URLCache
    private var downloadProgress: [URL: Double] = [:]
    
    private init() {
        // Configure cache
        let cacheSize = 50 * 1024 * 1024 // 50 MB
        self.cache = URLCache(
            memoryCapacity: cacheSize / 4,
            diskCapacity: cacheSize,
            directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        )
        
        // Configure session
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Download Methods
    
    /// Download with automatic retries
    func download(from url: URL, retries: Int = 3) async throws -> Data {
        var lastError: Error?
        
        for attempt in 0..<retries {
            do {
                return try await performDownload(from: url)
            } catch {
                lastError = error
                Logger.warning("Download attempt \(attempt + 1)/\(retries) failed: \(error.localizedDescription)")
                
                if attempt < retries - 1 {
                    // Exponential backoff
                    let delay = pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? DownloadError.unknown
    }
    
    /// Download with progress tracking
    func downloadWithProgress(from url: URL) -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let data = try await self.download(from: url)
                    continuation.yield(data)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Download JSON with caching
    func downloadJSON<T: Decodable>(
        from url: URL,
        as type: T.Type,
        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.cachePolicy = cachePolicy
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DownloadError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(type, from: data)
    }
    
    /// Check if URL is cached
    func isCached(_ url: URL) -> Bool {
        let request = URLRequest(url: url)
        return cache.cachedResponse(for: request) != nil
    }
    
    /// Clear cache
    func clearCache() {
        cache.removeAllCachedResponses()
        Logger.info("Download cache cleared")
    }
    
    // MARK: - Private Methods
    
    private func performDownload(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DownloadError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 429:
            throw DownloadError.rateLimited
        case 500...599:
            throw DownloadError.serverError(httpResponse.statusCode)
        default:
            throw DownloadError.httpError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Progress
    
    func progress(for url: URL) -> Double {
        downloadProgress[url] ?? 0
    }
}

// Note: DownloadError extension for localized description is now in Utilities/DownloadError.swift
