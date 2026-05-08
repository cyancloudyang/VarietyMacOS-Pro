import Testing
@testable import VarietyMacOS

@available(macOS 13.0, *)
struct MockWallpaperSourceTests {

    @Test func testMockSourceReturnsConfiguredWallpapers() async throws {
        let wallpaper = Wallpaper(
            id: "test-1",
            source: .local,
            title: "Test Wallpaper",
            resolution: CGSize(width: 1920, height: 1080)
        )
        
        var source = MockWallpaperSource(
            sourceID: "TestSource",
            displayName: "Test Source",
            mockWallpapers: [wallpaper]
        )
        
        let result = try await source.fetchWallpaper()
        
        #expect(result.id == "test-1")
        #expect(result.title == "Test Wallpaper")
        #expect(source.sourceID == "TestSource")
        #expect(source.displayName == "Test Source")
    }
    
    @Test func testMockSourceFetchMultipleWallpapers() async throws {
        let wallpapers = (0..<5).map { index in
            Wallpaper(id: "test-\(index)", source: .local)
        }
        
        let source = MockWallpaperSource(mockWallpapers: wallpapers)
        let result = try await source.fetchWallpapers(count: 3)
        
        #expect(result.count == 3)
    }
    
    @Test func testMockSourceCyclesThroughWallpapers() async throws {
        let wallpapers = [
            Wallpaper(id: "wallpaper-1", source: .unsplash),
            Wallpaper(id: "wallpaper-2", source: .bing)
        ]
        
        let source = MockWallpaperSource(mockWallpapers: wallpapers)
        
        let result = try await source.fetchWallpapers(count: 5)
        
        #expect(result.count == 5)
        #expect(result[0].id == "wallpaper-1")
        #expect(result[1].id == "wallpaper-2")
        #expect(result[2].id == "wallpaper-1")
        #expect(result[3].id == "wallpaper-2")
        #expect(result[4].id == "wallpaper-1")
    }
    
    @Test func testMockSourceThrowsErrorWhenConfigured() async throws {
        var source = MockWallpaperSource.builder()
        source.fetchError = MockError.networkError
        
        await #expect(throws: MockError.networkError) {
            _ = try await source.fetchWallpaper()
        }
    }
    
    @Test func testMockSourceAvailability() async throws {
        var source = MockWallpaperSource()
        
        #expect(source.isAvailable() == true)
        
        source.isAvailableValue = false
        #expect(source.isAvailable() == false)
    }
    
    @Test func testMockSourceConfiguration() async throws {
        let config = SourceConfiguration(
            sourceType: .unsplash,
            isEnabled: true,
            weight: 2.0,
            customSettings: ["key": "value"]
        )
        
        let source = MockWallpaperSource(mockConfiguration: config)
        
        let result = source.configuration()
        #expect(result.sourceType == .unsplash)
        #expect(result.weight == 2.0)
        #expect(result.customSettings["key"] == "value")
    }
    
    @Test func testMockSourceBuilder() async throws {
        let source = MockWallpaperSource.builder(
            id: "builder-test",
            source: .reddit,
            title: "Builder Title",
            hasRemoteURL: true,
            hasLocalURL: false,
            hasThumbnailURL: true,
            resolution: CGSize(width: 3840, height: 2160)
        )
        
        let wallpaper = try await source.fetchWallpaper()
        
        #expect(wallpaper.id == "builder-test")
        #expect(wallpaper.source == .reddit)
        #expect(wallpaper.title == "Builder Title")
        #expect(wallpaper.remoteURL != nil)
        #expect(wallpaper.localURL == nil)
        #expect(wallpaper.thumbnailURL != nil)
        #expect(wallpaper.resolution.width == 3840)
        #expect(wallpaper.resolution.height == 2160)
    }
    
    @Test func testMockSourceEmptyWallpapers() async throws {
        let source = MockWallpaperSource(mockWallpapers: [])
        
        await #expect(throws: MockError.noWallpapersAvailable) {
            _ = try await source.fetchWallpaper()
        }
        
        await #expect(throws: MockError.noWallpapersAvailable) {
            _ = try await source.fetchWallpapers(count: 1)
        }
    }
    
    @Test func testMockSourceZeroCount() async throws {
        let source = MockWallpaperSource(
            mockWallpapers: [Wallpaper(id: "test", source: .local)]
        )
        
        let result = try await source.fetchWallpapers(count: 0)
        
        #expect(result.isEmpty)
    }
}
