//
//  MockWallpaperSource.swift
//  VarietyMacOSTests
//
//  Created for testing purposes
//

import Foundation
@testable import VarietyMacOS

/// Mock implementation of WallpaperSource for testing
@available(macOS 13.0, *)
struct MockWallpaperSource: WallpaperSource {
    var sourceID: String
    var displayName: String
    
    /// Configurable mock wallpapers to return
    var mockWallpapers: [Wallpaper] = []
    
    /// Configurable URLs for testing
    var thumbnailURL: URL?
    var remoteURL: URL?
    var localURL: URL?
    
    /// Configuration to return
    var mockConfiguration: SourceConfiguration
    
    /// Optional error to throw
    var fetchError: Error?
    
    /// Whether the source is available
    var isAvailableValue: Bool = true
    
    init(
        sourceID: String = "MockSource",
        displayName: String = "Mock Source",
        mockWallpapers: [Wallpaper] = [],
        mockConfiguration: SourceConfiguration? = nil
    ) {
        self.sourceID = sourceID
        self.displayName = displayName
        self.mockWallpapers = mockWallpapers
        self.mockConfiguration = mockConfiguration ?? SourceConfiguration(
            sourceType: .local,
            isEnabled: true,
            weight: 1.0
        )
    }
    
    func fetchWallpaper() async throws -> Wallpaper {
        if let error = fetchError {
            throw error
        }
        guard let first = mockWallpapers.first else {
            throw MockError.noWallpapersAvailable
        }
        return first
    }
    
    func fetchWallpapers(count: Int) async throws -> [Wallpaper] {
        if let error = fetchError {
            throw error
        }
        if count <= 0 {
            return []
        }
        if mockWallpapers.isEmpty {
            throw MockError.noWallpapersAvailable
        }
        // Return wallpapers, cycling if needed
        return (0..<count).map { index in
            mockWallpapers[index % mockWallpapers.count]
        }
    }
    
    func isAvailable() -> Bool {
        isAvailableValue
    }
    
    func configuration() -> SourceConfiguration {
        mockConfiguration
    }
}

@available(macOS 13.0, *)
extension MockWallpaperSource {
    /// Builder for creating mock wallpapers with common test configurations
    static func builder(
        id: String = "test-wallpaper-1",
        source: WallpaperSourceType = .local,
        title: String? = "Test Wallpaper",
        hasRemoteURL: Bool = true,
        hasLocalURL: Bool = false,
        hasThumbnailURL: Bool = false,
        resolution: CGSize = CGSize(width: 1920, height: 1080)
    ) -> MockWallpaperSource {
        let wallpaper = Wallpaper(
            id: id,
            source: source,
            remoteURL: hasRemoteURL ? URL(string: "https://example.com/image.jpg") : nil,
            localURL: hasLocalURL ? URL(string: "file:///local/image.jpg") : nil,
            thumbnailURL: hasThumbnailURL ? URL(string: "https://example.com/thumb.jpg") : nil,
            title: title,
            resolution: resolution
        )
        
        return MockWallpaperSource(
            sourceID: "MockTestSource",
            displayName: "Mock Test Source",
            mockWallpapers: [wallpaper]
        )
    }
}

// MARK: - Mock Errors

enum MockError: LocalizedError {
    case noWallpapersAvailable
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noWallpapersAvailable:
            return "No mock wallpapers available"
        case .networkError:
            return "Mock network error"
        case .invalidData:
            return "Mock invalid data error"
        }
    }
}
