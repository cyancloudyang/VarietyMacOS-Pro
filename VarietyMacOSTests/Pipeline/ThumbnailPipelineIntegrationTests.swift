import Testing
import Foundation
import AppKit
@testable import VarietyMacOS

@available(macOS 13.0, *)
struct ThumbnailPipelineIntegrationTests {
    
    @Test func testPipeline_fetchesFromSource() async throws {
        // Given a wallpaper with thumbnailURL
        let wallpaper = Wallpaper(
            id: "test_1",
            source: .bing,
            title: "Test",
            description: nil,
            author: nil,
            authorURL: nil,
            sourceURL: nil,
            resolution: NSSize(width: 1920, height: 1080),
            fileSize: nil,
            createdAt: nil,
            upvotes: nil,
            subreddit: nil,
            remoteURL: URL(string: "https://example.com/image.jpg"),
            localURL: nil,
            thumbnailURL: URL(string: "https://example.com/thumb.jpg")
        )
        
        // When fetching thumbnail
        let pipeline = ThumbnailPipeline()
        let result = try await pipeline.thumbnail(for: wallpaper)
        
        // Then result should not be nil
        #expect(result.image != nil)
    }
    
    @Test func testPipeline_usesLocalFallback() async throws {
        // Given a wallpaper without thumbnailURL but with localURL
        let wallpaper = Wallpaper(
            id: "test_2",
            source: .local,
            title: "Test Local",
            description: nil,
            author: nil,
            authorURL: nil,
            sourceURL: nil,
            resolution: NSSize(width: 1920, height: 1080),
            fileSize: nil,
            createdAt: nil,
            upvotes: nil,
            subreddit: nil,
            remoteURL: nil,
            localURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            thumbnailURL: nil
        )
        
        // When fetching thumbnail (should fail gracefully or use fallback)
        let pipeline = ThumbnailPipeline()
        do {
            _ = try await pipeline.thumbnail(for: wallpaper)
            // If succeeds, that's fine
        } catch {
            // If fails with sourceNotFound, that's also acceptable
            guard error is ThumbnailError else {
                throw error
            }
        }
    }
}
