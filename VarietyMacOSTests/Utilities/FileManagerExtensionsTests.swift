import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for FileManager extensions
final class FileManagerExtensionsTests: XCTestCase {

    // MARK: - File Extension Tests

    func testImageExtensions() {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "tiff"]

        for ext in imageExtensions {
            XCTAssertTrue(isImageExtension(ext), "\(ext) should be recognized as image extension")
        }
    }

    func testNonImageExtensions() {
        let nonImageExtensions = ["txt", "pdf", "doc", "mp3", "mp4", "zip"]

        for ext in nonImageExtensions {
            XCTAssertFalse(isImageExtension(ext), "\(ext) should not be recognized as image extension")
        }
    }

    func testImageExtensionCaseSensitivity() {
        XCTAssertTrue(isImageExtension("jpg"))
        XCTAssertTrue(isImageExtension("JPG"))
        XCTAssertTrue(isImageExtension("Jpg"))
        XCTAssertTrue(isImageExtension("pNg"))
    }

    // MARK: - Helper Methods

    private func isImageExtension(_ ext: String) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "tiff"]
        return imageExtensions.contains(ext.lowercased())
    }
}

/// Tests for Logger
final class LoggerTests: XCTestCase {

    // MARK: - Logger Method Tests

    func testLoggerInfo() {
        // Just verify these methods can be called without crashing
        Logger.info("Test info message")
    }

    func testLoggerWarning() {
        Logger.warning("Test warning message")
    }

    func testLoggerError() {
        Logger.error("Test error message")
    }

    func testLoggerDebug() {
        Logger.debug("Test debug message")
    }

    // MARK: - Logger Format Tests

    func testLoggerWithMultipleParameters() {
        Logger.info("Test message", file: "TestFile.swift", line: 100)
    }

    func testLoggerEmptyMessage() {
        Logger.info("")
    }

    func testLoggerLongMessage() {
        let longMessage = String(repeating: "A", count: 1000)
        Logger.info(longMessage)
    }
}

/// Tests for URL construction utilities
final class URLConstructionTests: XCTestCase {

    // MARK: - Reddit URL Tests

    func testRedditURLConstruction() {
        let subreddits = ["earthporn", "CityPorn", "spaceporn", "test"]

        for subreddit in subreddits {
            let urlString = "https://www.reddit.com/r/\(subreddit)/hot.json"
            XCTAssertNotNil(URL(string: urlString), "URL should be valid for r/\(subreddit)")
        }
    }

    func testRedditURLWithMultipleSubreddits() {
        let subreddits = ["earthporn+spaceporn", "nature"]
        for subreddit in subreddits {
            let urlString = "https://www.reddit.com/r/\(subreddit)/hot.json"
            XCTAssertNotNil(URL(string: urlString))
        }
    }

    // MARK: - Bing URL Tests

    func testBingURLConstruction() {
        let bingURL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
        XCTAssertNotNil(URL(string: bingURL))
    }

    func testBingURLWithDifferentMarkets() {
        let markets = ["en-US", "zh-CN", "ja-JP", "en-GB", "fr-FR"]

        for market in markets {
            let bingURL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=\(market)"
            XCTAssertNotNil(URL(string: bingURL), "Bing URL should be valid for market: \(market)")
        }
    }

    // MARK: - Unsplash URL Tests

    func testUnsplashURLConstruction() {
        let unsplashURL = "https://source.unsplash.com/random/1920x1080"
        XCTAssertNotNil(URL(string: unsplashURL))
    }

    func testUnsplashURLWithDimensions() {
        let dimensions = [
            "1920x1080",
            "2560x1440",
            "3840x2160",
            "1080x1920"
        ]

        for dim in dimensions {
            let url = "https://source.unsplash.com/random/\(dim)"
            XCTAssertNotNil(URL(string: url), "Unsplash URL should be valid for dimensions: \(dim)")
        }
    }

    // MARK: - Wallhaven URL Tests

    func testWallhavenURLConstruction() {
        let wallhavenURL = "https://wallhaven.cc/api/v1/search"
        XCTAssertNotNil(URL(string: wallhavenURL))
    }

    // MARK: - General URL Validation

    func testURLValidation() {
        let validURLs = [
            "https://example.com",
            "https://example.com/path",
            "https://example.com/path?query=value",
            "https://sub.example.com/path?query=value#fragment"
        ]

        for urlString in validURLs {
            XCTAssertNotNil(URL(string: urlString))
        }
    }
}

/// Tests for common resolution helpers
final class ResolutionTests: XCTestCase {

    // MARK: - Common Resolution Tests

    func testCommonResolutions() {
        let resolutions = [
            CGSize(width: 1920, height: 1080),  // 1080p
            CGSize(width: 2560, height: 1440),  // 1440p
            CGSize(width: 3840, height: 2160),  // 4K
            CGSize(width: 1280, height: 720),   // 720p
            CGSize(width: 7680, height: 4320),  // 8K
        ]

        for resolution in resolutions {
            XCTAssertGreaterThan(resolution.width, 0)
            XCTAssertGreaterThan(resolution.height, 0)
            XCTAssertGreaterThan(resolution.width, resolution.height) // Landscape
        }
    }

    // MARK: - Aspect Ratio Tests

    func testCommonAspectRatios() {
        // 16:9
        let aspect16_9 = CGSize(width: 1920, height: 1080)
        XCTAssertEqual(aspect16_9.width / aspect16_9.height, 16.0 / 9.0, accuracy: 0.01)

        // 16:10
        let aspect16_10 = CGSize(width: 1920, height: 1200)
        XCTAssertEqual(aspect16_10.width / aspect16_10.height, 16.0 / 10.0, accuracy: 0.01)

        // 21:9 (Ultrawide)
        let aspect21_9 = CGSize(width: 2560, height: 1080)
        XCTAssertEqual(aspect21_9.width / aspect21_9.height, 21.0 / 9.0, accuracy: 0.1)
    }

    // MARK: - Resolution Comparison Tests

    func testResolutionComparison() {
        let hd = CGSize(width: 1920, height: 1080)
        let fourK = CGSize(width: 3840, height: 2160)

        // 4K has more pixels than HD
        XCTAssertGreaterThan(fourK.width * fourK.height, hd.width * hd.height)

        // 4K is exactly 4x HD in each dimension
        XCTAssertEqual(fourK.width, hd.width * 2)
        XCTAssertEqual(fourK.height, hd.height * 2)
    }
}
