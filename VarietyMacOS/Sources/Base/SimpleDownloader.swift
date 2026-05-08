import Foundation
import AppKit

/// Simple downloader for fetching image data from URLs
@available(macOS 13.0, *)
actor SimpleDownloader {
    static let shared = SimpleDownloader()

    private let session: URLSession
    private var activeDownloads: [URL: Task<Data, Error>] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Download Methods

    /// Download data from URL
    func download(from url: URL) async throws -> Data {
        // Check if there's already a download in progress
        if let existingTask = activeDownloads[url] {
            return try await existingTask.value
        }

        // Create new download task
        let task = Task<Data, Error> {
            defer { self.removeDownload(for: url) }

            let (data, response) = try await self.session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DownloadError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw DownloadError.httpError(httpResponse.statusCode)
            }

            return data
        }

        activeDownloads[url] = task
        return try await task.value
    }

    /// Download image from URL
    func downloadImage(from url: URL) async throws -> NSImage {
        let data = try await download(from: url)

        guard let image = NSImage(data: data) else {
            throw DownloadError.invalidImageData
        }

        return image
    }

    /// Download JSON from URL
    func downloadJSON<T: Decodable>(from url: URL, as type: T.Type) async throws -> T {
        let data = try await download(from: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(type, from: data)
    }

    /// Download to file
    func downloadToFile(from url: URL, to destination: URL) async throws {
        let data = try await download(from: url)
        try data.write(to: destination)
    }

    /// Cancel download for URL
    func cancelDownload(for url: URL) {
        activeDownloads[url]?.cancel()
        activeDownloads.removeValue(forKey: url)
    }

    /// Cancel all downloads
    func cancelAllDownloads() {
        activeDownloads.values.forEach { $0.cancel() }
        activeDownloads.removeAll()
    }

    // MARK: - Private Methods

    private func removeDownload(for url: URL) {
        activeDownloads.removeValue(forKey: url)
    }
}
