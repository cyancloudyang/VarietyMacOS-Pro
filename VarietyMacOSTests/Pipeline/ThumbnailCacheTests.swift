import Testing
import AppKit
@testable import VarietyMacOS

@Suite struct ThumbnailCacheTests {
    @Test func setAndGet_roundtrip() async throws {
        let cache = ThumbnailCache()
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()
        
        let key = "test_key"
        try await cache.set(key: key, image: image)
        
        let cached = cache.get(key: key)
        #expect(cached != nil)
    }
    
    @Test func diskPersistence() async throws {
        let cache = ThumbnailCache()
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()
        
        let key = "persistence_test"
        try await cache.set(key: key, image: image)
        
        cache.clearMemory()
        
        let fromDisk = cache.get(key: key)
        #expect(fromDisk != nil)
    }
    
    @Test func clear_removesAll() async throws {
        let cache = ThumbnailCache()
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.green.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()
        
        let key = "clear_test"
        try await cache.set(key: key, image: image)
        
        cache.clear()
        
        let afterClear = cache.get(key: key)
        #expect(afterClear == nil)
    }
    
    @Test func clearMemory_preservesDisk() async throws {
        let cache = ThumbnailCache()
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.yellow.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        image.unlockFocus()
        
        let key = "memory_clear_test"
        try await cache.set(key: key, image: image)
        
        cache.clearMemory()
        
        let fromDisk = cache.get(key: key)
        #expect(fromDisk != nil)
    }
}
