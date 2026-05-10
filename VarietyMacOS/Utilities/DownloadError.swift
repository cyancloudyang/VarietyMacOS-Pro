import Foundation

// MARK: - Download Error

enum DownloadError: LocalizedError, Equatable, Sendable {
// Basic errors (from SimpleDownloader)
case invalidResponse
case httpError(Int)
case invalidImageData
case cancelled
case unknown
    
    // Rate limiting and server errors (from DefaultDownloader)
    case rateLimited
    case serverError(Int)
    
    // Download manager errors
    case noRemoteURL
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidImageData:
            return "Downloaded data is not a valid image"
        case .cancelled:
            return "Download was cancelled"
        case .unknown:
            return "Unknown download error"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error: \(code)"
        case .noRemoteURL:
            return "No remote URL available for download"
        case .downloadFailed:
            return "Failed to download wallpaper"
        }
    }
}

// MARK: - DownloadError Localized Description Extension

extension DownloadError {
    var localizedDescription: String {
        switch self {
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidImageData:
            return "Invalid image data"
        case .cancelled:
            return "Cancelled"
        case .unknown:
            return "Unknown error"
        case .noRemoteURL:
            return "No remote URL"
        case .downloadFailed:
            return "Download failed"
        }
    }
}
