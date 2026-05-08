import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for Wallpaper model
@available(macOS 13.0, *)
final class WallpaperTests: XCTestCase {

    // MARK: - Initialization Tests

    func testWallpaperInitialization() {
        let wallpaper = Wallpaper(
            id: "test_123",
            source: .unsplash,
            remoteURL: URL(string: "https://example.com/image.jpg"),
            localURL: nil,
            thumbnailURL: nil,
            title: "Test Wallpaper",
            description: "A test wallpaper",
            author: "Test Author",
            authorURL: URL(string: "https://example.com/author"),
            sourceURL: URL(string: "https://example.com/source"),
            resolution: CGSize(width: 1920, height: 1080),
            fileSize: 1024000,
            createdAt: Date(),
            upvotes: 100,
            subreddit: "test"
        )

        XCTAssertEqual(wallpaper.id, "test_123")
        XCTAssertEqual(wallpaper.source, .unsplash)
        XCTAssertEqual(wallpaper.title, "Test Wallpaper")
        XCTAssertEqual(wallpaper.description, "A test wallpaper")
        XCTAssertEqual(wallpaper.author, "Test Author")
        XCTAssertEqual(wallpaper.resolution, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(wallpaper.fileSize, 1024000)
        XCTAssertEqual(wallpaper.upvotes, 100)
        XCTAssertEqual(wallpaper.subreddit, "test")
    }

    func testWallpaperDefaultValues() {
        let wallpaper = Wallpaper(
            id: "default_test",
            source: .bing
        )

        XCTAssertEqual(wallpaper.id, "default_test")
        XCTAssertEqual(wallpaper.source, .bing)
        XCTAssertNil(wallpaper.title)
        XCTAssertNil(wallpaper.description)
        XCTAssertNil(wallpaper.author)
        XCTAssertNil(wallpaper.remoteURL)
        XCTAssertNil(wallpaper.localURL)
        XCTAssertNil(wallpaper.thumbnailURL)
        XCTAssertEqual(wallpaper.resolution, CGSize(width: 1920, height: 1080))
        XCTAssertNil(wallpaper.fileSize)
        XCTAssertNil(wallpaper.createdAt)
        XCTAssertNil(wallpaper.upvotes)
        XCTAssertNil(wallpaper.subreddit)
    }

    // MARK: - Codable Tests

    func testWallpaperCodable() throws {
        let original = Wallpaper(
            id: "codable_test",
            source: .reddit,
            remoteURL: URL(string: "https://example.com/image.png"),
            localURL: nil,
            thumbnailURL: URL(string: "https://example.com/thumb.png"),
            title: "Codable Test",
            description: "Testing Codable",
            author: "Tester",
            authorURL: URL(string: "https://example.com"),
            sourceURL: nil,
            resolution: CGSize(width: 2560, height: 1440),
            fileSize: 2048000,
            createdAt: Date(),
            upvotes: 50,
            subreddit: "codetest"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Wallpaper.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.source, original.source)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.author, original.author)
        XCTAssertEqual(decoded.resolution, original.resolution)
        XCTAssertEqual(decoded.fileSize, original.fileSize)
        XCTAssertEqual(decoded.upvotes, original.upvotes)
        XCTAssertEqual(decoded.subreddit, original.subreddit)
    }

    // MARK: - Computed Properties Tests

    func testDisplayTitle() {
        let wallpaperWithTitle = Wallpaper(
            id: "title_test",
            source: .unsplash,
            title: "My Title"
        )
        XCTAssertEqual(wallpaperWithTitle.displayTitle, "My Title")

        let wallpaperWithoutTitle = Wallpaper(
            id: "no_title_test",
            source: .bing,
            title: nil
        )
        XCTAssertTrue(wallpaperWithoutTitle.displayTitle.contains("Bing Daily"))
    }

    func testDisplayAuthor() {
        let wallpaperWithAuthor = Wallpaper(
            id: "author_test",
            source: .unsplash,
            author: "John Doe"
        )
        XCTAssertEqual(wallpaperWithAuthor.displayAuthor, "John Doe")

        let wallpaperWithoutAuthor = Wallpaper(
            id: "no_author_test",
            source: .unsplash,
            author: nil
        )
        XCTAssertEqual(wallpaperWithoutAuthor.displayAuthor, "Unknown")
    }

    func testResolutionString() {
        let wallpaper = Wallpaper(
            id: "res_test",
            source: .unsplash,
            resolution: CGSize(width: 3840, height: 2160)
        )
        XCTAssertEqual(wallpaper.resolutionString, "3840 x 2160")
    }

    func testFileSizeString() {
        let wallpaperWithSize = Wallpaper(
            id: "size_test",
            source: .unsplash,
            fileSize: 1048576 // 1 MB
        )
        XCTAssertTrue(wallpaperWithSize.fileSizeString.contains("MB"))

        let wallpaperWithoutSize = Wallpaper(
            id: "no_size_test",
            source: .unsplash,
            fileSize: nil
        )
        XCTAssertEqual(wallpaperWithoutSize.fileSizeString, "Unknown")
    }

    func testAspectRatio() {
        let landscape = Wallpaper(
            id: "landscape",
            source: .unsplash,
            resolution: CGSize(width: 1920, height: 1080)
        )
        XCTAssertEqual(landscape.aspectRatio, 1920.0 / 1080.0)

        let square = Wallpaper(
            id: "square",
            source: .unsplash,
            resolution: CGSize(width: 1000, height: 1000)
        )
        XCTAssertEqual(square.aspectRatio, 1.0)
    }

    func testIsLandscape() {
        let landscape = Wallpaper(
            id: "landscape",
            source: .unsplash,
            resolution: CGSize(width: 1920, height: 1080)
        )
        XCTAssertTrue(landscape.isLandscape)

        let portrait = Wallpaper(
            id: "portrait",
            source: .unsplash,
            resolution: CGSize(width: 1080, height: 1920)
        )
        XCTAssertFalse(portrait.isLandscape)

        let square = Wallpaper(
            id: "square",
            source: .unsplash,
            resolution: CGSize(width: 1000, height: 1000)
        )
        XCTAssertFalse(square.isLandscape)
    }

    // MARK: - Hashable & Equatable Tests

    func testWallpaperEquality() {
        let wallpaper1 = Wallpaper(id: "same_id", source: .unsplash)
        let wallpaper2 = Wallpaper(id: "same_id", source: .bing)
        let wallpaper3 = Wallpaper(id: "different_id", source: .unsplash)

        XCTAssertEqual(wallpaper1, wallpaper2)
        XCTAssertNotEqual(wallpaper1, wallpaper3)
    }

    func testWallpaperHash() {
        let wallpaper1 = Wallpaper(id: "hash_test", source: .unsplash)
        let wallpaper2 = Wallpaper(id: "hash_test", source: .bing)

        XCTAssertEqual(wallpaper1.hashValue, wallpaper2.hashValue)
    }

    func testWallpaperInSet() {
        let wallpaper1 = Wallpaper(id: "set_test", source: .unsplash)
        let wallpaper2 = Wallpaper(id: "set_test", source: .bing)
        let wallpaper3 = Wallpaper(id: "different", source: .unsplash)

        var set = Set([wallpaper1, wallpaper3])
        XCTAssertTrue(set.contains(wallpaper2))
    }

    // MARK: - WallpaperSourceType Tests

    func testWallpaperSourceAllCases() {
        let allSources = WallpaperSourceType.allCases
        XCTAssertEqual(allSources.count, 5)

        XCTAssertTrue(allSources.contains(.unsplash))
        XCTAssertTrue(allSources.contains(.bing))
        XCTAssertTrue(allSources.contains(.wallhaven))
        XCTAssertTrue(allSources.contains(.reddit))
        XCTAssertTrue(allSources.contains(.local))
    }

    func testWallpaperSourceDisplayName() {
        XCTAssertEqual(WallpaperSourceType.unsplash.displayName, "Unsplash")
        XCTAssertEqual(WallpaperSourceType.bing.displayName, "Bing Daily")
        XCTAssertEqual(WallpaperSourceType.wallhaven.displayName, "Wallhaven")
        XCTAssertEqual(WallpaperSourceType.reddit.displayName, "Reddit")
        XCTAssertEqual(WallpaperSourceType.local.displayName, "Local Folder")
    }

    func testWallpaperSourceIconName() {
        XCTAssertEqual(WallpaperSourceType.unsplash.iconName, "camera.fill")
        XCTAssertEqual(WallpaperSourceType.bing.iconName, "globe")
        XCTAssertEqual(WallpaperSourceType.wallhaven.iconName, "photo.fill")
        XCTAssertEqual(WallpaperSourceType.reddit.iconName, "bubble.left.fill")
        XCTAssertEqual(WallpaperSourceType.local.iconName, "folder.fill")
    }

    func testWallpaperSourceDescription() {
        XCTAssertFalse(WallpaperSourceType.unsplash.description.isEmpty)
        XCTAssertFalse(WallpaperSourceType.bing.description.isEmpty)
        XCTAssertFalse(WallpaperSourceType.wallhaven.description.isEmpty)
        XCTAssertFalse(WallpaperSourceType.reddit.description.isEmpty)
        XCTAssertFalse(WallpaperSourceType.local.description.isEmpty)
    }

    func testWallpaperSourceRawValue() {
        XCTAssertEqual(WallpaperSourceType.unsplash.rawValue, "unsplash")
        XCTAssertEqual(WallpaperSourceType.bing.rawValue, "bing")
        XCTAssertEqual(WallpaperSourceType.wallhaven.rawValue, "wallhaven")
        XCTAssertEqual(WallpaperSourceType.reddit.rawValue, "reddit")
        XCTAssertEqual(WallpaperSourceType.local.rawValue, "local")
    }

    func testWallpaperSourceCodable() throws {
        let source = WallpaperSourceType.unsplash
        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(WallpaperSourceType.self, from: data)
        XCTAssertEqual(decoded, source)
    }
}
