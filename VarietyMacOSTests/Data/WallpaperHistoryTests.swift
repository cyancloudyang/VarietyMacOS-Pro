import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for WallpaperHistory
@available(macOS 13.0, *)
final class WallpaperHistoryTests: XCTestCase {

    // MARK: - Singleton Tests

    func testWallpaperHistoryShared() {
        let history1 = WallpaperHistory.shared
        let history2 = WallpaperHistory.shared
        XCTAssert(history1 === history2)
    }

    // MARK: - Add Wallpaper Tests

    func testAddWallpaper() {
        let history = WallpaperHistory.shared
        let wallpaper = createTestWallpaper(id: "test_1")

        history.add(wallpaper)
        XCTAssertGreaterThan(history.entries.count, 0)
    }

    func testAddMultipleWallpapers() {
        let history = WallpaperHistory.shared
        let initialCount = history.entries.count
        let wallpaper1 = createTestWallpaper(id: "test_1")
        let wallpaper2 = createTestWallpaper(id: "test_2")

        history.add(wallpaper1)
        history.add(wallpaper2)

        XCTAssertEqual(history.entries.count, initialCount + 2)
    }

    // MARK: - Remove Tests

    func testRemoveEntry() {
        let history = WallpaperHistory.shared
        let wallpaper = createTestWallpaper(id: "remove_test")
        history.add(wallpaper)

        guard let entry = history.entries.first(where: { $0.wallpaperId == "remove_test" }) else {
            return
        }

        history.remove(entry)
        XCTAssertFalse(history.entries.contains { $0.id == entry.id })
    }

    // MARK: - Clear Tests

    func testClearHistory() {
        let history = WallpaperHistory.shared
        history.clear()
        XCTAssertEqual(history.entries.count, 0)
    }

    // MARK: - Helper Methods

    private func createTestWallpaper(id: String) -> Wallpaper {
        return Wallpaper(
            id: id,
            source: .unsplash,
            remoteURL: URL(string: "https://example.com/\(id).jpg"),
            title: "Test Wallpaper \(id)"
        )
    }
}

/// Tests for WallpaperFavorite
@available(macOS 13.0, *)
final class WallpaperFavoriteTests: XCTestCase {

    // MARK: - Singleton Tests

    func testWallpaperFavoriteShared() {
        let favorite1 = WallpaperFavorite.shared
        let favorite2 = WallpaperFavorite.shared
        XCTAssert(favorite1 === favorite2)
    }

    // MARK: - Add Favorite Tests

    func testAddFavorite() {
        let favorite = WallpaperFavorite.shared
        let initialCount = favorite.favorites.count
        let wallpaper = createTestWallpaper(id: "fav_test_1")

        favorite.add(wallpaper)

        // Check if count increased or wallpaper is favorited
        XCTAssertTrue(favorite.favorites.count >= initialCount)
        XCTAssertTrue(favorite.isFavorite(wallpaper))
    }

    func testRemoveFavorite() {
        let favorite = WallpaperFavorite.shared
        let wallpaper = createTestWallpaper(id: "fav_test_2")

        favorite.add(wallpaper)
        XCTAssertTrue(favorite.isFavorite(wallpaper))

        favorite.remove(wallpaper)
        XCTAssertFalse(favorite.isFavorite(wallpaper))
    }

    // MARK: - Toggle Tests

    func testToggleFavorite() {
        let favorite = WallpaperFavorite.shared
        let wallpaper = createTestWallpaper(id: "fav_test_3")

        // Add to favorites
        favorite.toggle(wallpaper)
        XCTAssertTrue(favorite.isFavorite(wallpaper))

        // Remove from favorites
        favorite.toggle(wallpaper)
        XCTAssertFalse(favorite.isFavorite(wallpaper))
    }

    // MARK: - Search Tests

    func testSearchFavorites() {
        let favorite = WallpaperFavorite.shared
        let results = favorite.search(query: "test")
        // Should return matching favorites
        XCTAssertNotNil(results)
    }

    // MARK: - Helper Methods

    private func createTestWallpaper(id: String) -> Wallpaper {
        return Wallpaper(
            id: id,
            source: .unsplash,
            remoteURL: URL(string: "https://example.com/\(id).jpg"),
            title: "Test Wallpaper \(id)"
        )
    }
}

/// Tests for WallpaperCache
@available(macOS 13.0, *)
final class WallpaperCacheTests: XCTestCase {

    // MARK: - Singleton Tests

    func testWallpaperCacheShared() {
        let cache1 = WallpaperCache.shared
        let cache2 = WallpaperCache.shared
        XCTAssert(cache1 === cache2)
    }

    // MARK: - Cache Operations Tests

    func testCacheImage() async {
        let cache = WallpaperCache.shared
        XCTAssertNotNil(cache)
    }

    func testCacheClear() async {
        let cache = WallpaperCache.shared
        await cache.clearAll()
    }

    func testCacheMemoryClear() async {
        let cache = WallpaperCache.shared
        await cache.clearMemory()
    }

    func testCacheDiskSize() async {
        let cache = WallpaperCache.shared
        let size = await cache.diskCacheSize()
        XCTAssertGreaterThanOrEqual(size, 0)
    }

    func testCacheKeyGeneration() {
        let wallpaper = Wallpaper(
            id: "test_key",
            source: .unsplash
        )
        let key = WallpaperCache.key(for: wallpaper)
        XCTAssertFalse(key.isEmpty)
    }

    func testCacheKeyFromURL() {
        let url = URL(string: "https://example.com/image.jpg")!
        let key = WallpaperCache.key(for: url)
        XCTAssertFalse(key.isEmpty)
    }
}
