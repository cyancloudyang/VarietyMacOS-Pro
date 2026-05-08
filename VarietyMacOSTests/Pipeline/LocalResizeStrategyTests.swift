import Foundation
import Testing
import AppKit
@testable import VarietyMacOS

struct LocalResizeStrategyTests {
    
    @Test("Preserve aspect ratio: 1920x1080 should fit within 400x225")
    func testPreserveAspectRatio_1920x1080_to_400x225() async throws {
        let strategy = LocalResizeStrategy(targetSize: CGSize(width: 400, height: 225))
        
        let originalSize = NSSize(width: 1920, height: 1080)
        let originalImage = NSImage(size: originalSize, flipped: false) { _ in
            NSColor.blue.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: originalSize)).fill()
            return true
        }
        
        let resized = originalImage.resized(to: CGSize(width: 400, height: 225))
        
        #expect(resized.size.width <= 400)
        #expect(resized.size.height <= 225)
        
        let aspectRatio = resized.size.width / resized.size.height
        #expect(abs(aspectRatio - (1920.0 / 1080.0)) < 0.01)
    }
    
    @Test("Large image downsampling creates thumbnail within bounds")
    func testLargeImageDownsampling() async throws {
        let strategy = LocalResizeStrategy(targetSize: CGSize(width: 400, height: 225))
        
        let originalSize = NSSize(width: 4000, height: 3000)
        let originalImage = NSImage(size: originalSize, flipped: false) { _ in
            NSColor.red.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: originalSize)).fill()
            return true
        }
        
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalResizeStrategyTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let imageURL = tempDir.appendingPathComponent("test_image.jpg")
        if let tiffData = originalImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
            try jpegData.write(to: imageURL)
        }
        
        let result = try await strategy.generateThumbnail(from: imageURL)
        
        #expect(result.image.size.width <= 400)
        #expect(result.image.size.height <= 225)
        
        guard case .local(_) = result.source else {
            Issue.record("Expected local source")
            return
        }
    }
    
    @Test("Corrupt image throws error")
    func testCorruptImageThrowsError() async throws {
        let strategy = LocalResizeStrategy()
        
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalResizeStrategyTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let corruptURL = tempDir.appendingPathComponent("corrupt.jpg")
        try "not an image".write(to: corruptURL, atomically: true, encoding: .utf8)
        
        await #expect(throws: ThumbnailError.self) {
            _ = try await strategy.generateThumbnail(from: corruptURL)
        }
    }
    
    @Test("Non-existent file throws error")
    func testNonExistentFileThrowsError() async throws {
        let strategy = LocalResizeStrategy()
        let nonExistentURL = URL(fileURLWithPath: "/tmp/does_not_exist_\(UUID().uuidString).jpg")
        
        await #expect(throws: ThumbnailError.self) {
            _ = try await strategy.generateThumbnail(from: nonExistentURL)
        }
    }
    
    @Test("Default target size is 400x225")
    func testDefaultTargetSize() async throws {
        let strategy = LocalResizeStrategy()
        
        let originalSize = NSSize(width: 800, height: 600)
        let originalImage = NSImage(size: originalSize, flipped: false) { _ in
            NSColor.green.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: originalSize)).fill()
            return true
        }
        
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalResizeStrategyTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let imageURL = tempDir.appendingPathComponent("test_image.jpg")
        if let tiffData = originalImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) {
            try jpegData.write(to: imageURL)
        }
        
        let result = try await strategy.generateThumbnail(from: imageURL)
        
        #expect(result.image.size.width <= 400)
        #expect(result.image.size.height <= 225)
    }
}
