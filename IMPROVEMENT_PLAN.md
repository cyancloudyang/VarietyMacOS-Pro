# Variety macOS 改进行略

基于对 Variety Linux 源码的分析，以下是建议的改进项目，按优先级排序。

## P0 - 核心功能完善

### 1. 安全模式 (Safe Mode)

**问题**: 当前没有 NSFW 内容过滤机制

**Variety Linux 实现**:
```python
SAFE_MODE_BLACKLIST = {
    "woman", "women", "model", "models", "boob", "boobs",
    "lingerie", "bikini", "sexy", "bra", "panties",
    "face", "faces", "legs", "feet", "pussy", "ass", "asses",
    "topless", "long hair", "lesbians", "cleavage", "brunette",
    "brunettes", "redhead", "redheads", "blonde", "blondes",
    "high heels", "miniskirt", "stockings", "anime girls",
    "in bed", "kneeling", "girl", "girls", "nude", "naked",
    "people", "fuck", "sex",
}
```

**macOS 实现建议**:

```swift
// Utilities/SafeModeFilter.swift
import Foundation

/// Safe mode filter for NSFW content
/// Reference: Variety Linux's SAFE_MODE_BLACKLIST
struct SafeModeFilter {
    /// Blacklist of keywords that indicate potentially unsafe content
    /// Based on Wallhaven and Flickr tags that cover most not-fully-safe images
    static let blacklistedKeywords: Set<String> = [
        // People-related
        "woman", "women", "model", "models", "girl", "girls",
        "brunette", "brunettes", "blonde", "blondes", "redhead", "redheads",
        
        // Body parts
        "boob", "boobs", "tit", "tits", "cleavage",
        "legs", "feet", "ass", "asses", "pussy",
        
        // Clothing
        "lingerie", "bikini", "bra", "bras", "panties",
        "topless", "nude", "naked",
        
        // Actions/Positions
        "kneeling", "in bed", "high heels", "miniskirt", "stockings",
        
        // Explicit content
        "sexy", "lesbians", "fuck", "sex", "nude", "naked",
        
        // Anime
        "anime girls",
    ]
    
    /// Check if content is safe based on keywords
    /// - Parameters:
    ///   - keywords: List of keywords to check
    ///   - sfwRating: SFW rating from source (0-100)
    /// - Returns: Tuple of (isSafe, matchedKeywords)
    static func checkSafety(keywords: [String], sfwRating: Int? = nil) -> (Bool, [String]) {
        // If sfwRating is provided and < 100, mark as unsafe
        if let rating = sfwRating, rating < 100 {
            return (false, ["sfwRating: \(rating)"])
        }
        
        let keywordSet = Set(keywords.map { $0.lowercased() })
        let matched = keywordSet.intersection(blacklistedKeywords)
        
        return (matched.isEmpty, Array(matched))
    }
    
    /// Check if content is safe based on purity string (Wallhaven specific)
    static func checkPurity(_ purity: String) -> Bool {
        switch purity.lowercased() {
        case "sfw": return true
        case "sketchy": return false  // Configurable
        case "nsfw": return false
        default: return true
        }
    }
}
```

**使用方式**:
```swift
// 在 WallhavenSource 中使用
let (isSafe, matched) = SafeModeFilter.checkSafety(
    keywords: wallpaperInfo.tags.map { $0.name },
    sfwRating: sfwRating
)

if !isSafe && Preferences.shared.safeModeEnabled {
    Logger.warning("Skipping image with unsafe keywords: \(matched)")
    return nil
}
```

---

### 2. 下载配额管理 (Download Quota)

**问题**: 没有下载文件夹大小限制，可能导致磁盘空间耗尽

**Variety Linux 实现**:
```python
self.quota_enabled = True
self.quota_size = 1000  # MB
```

**macOS 实现建议**:

```swift
// Download/DownloadQuotaManager.swift
import Foundation

/// Manages download quota to prevent disk space exhaustion
@available(macOS 13.0, *)
final class DownloadQuotaManager {
    static let shared = DownloadQuotaManager()
    
    private let fileManager = FileManager.default
    private let quotaEnabled: Bool = true
    private let quotaSizeMB: Int = 1000  // Default 1GB
    
    /// Check if download would exceed quota
    func canDownload(newFileSize: Int) -> Bool {
        guard quotaEnabled else { return true }
        
        let currentSize = getCurrentDownloadSize()
        let newSizeMB = (currentSize + newFileSize) / (1024 * 1024)
        
        return newSizeMB < quotaSizeMB
    }
    
    /// Get current download folder size
    func getCurrentDownloadSize() -> Int {
        let downloadFolder = getDownloadFolder()
        return calculateFolderSize(at: downloadFolder)
    }
    
    /// Clean up oldest downloads to fit quota
    func cleanupToQuota() {
        guard quotaEnabled else { return }
        
        let folder = getDownloadFolder()
        var files = getFilesWithDates(at: folder)
        
        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }
        
        var currentSize = calculateFolderSize(at: folder)
        let maxSize = quotaSizeMB * 1024 * 1024  // Convert to bytes
        
        // Remove oldest files until under quota
        for file in files {
            if currentSize <= maxSize { break }
            
            do {
                try fileManager.removeItem(at: file.url)
                currentSize -= file.size
                Logger.info("Cleaned up old download: \(file.url.lastPathComponent)")
            } catch {
                Logger.error("Failed to cleanup: \(error)")
            }
        }
    }
    
    // MARK: - Private
    
    private func getDownloadFolder() -> URL {
        FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Variety")
    }
    
    private func calculateFolderSize(at url: URL) -> Int {
        var totalSize = 0
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let file as URL in enumerator {
                totalSize += file.fileSize
            }
        }
        return totalSize
    }
    
    private func getFilesWithDates(at url: URL) -> [(url: URL, date: Date, size: Int)] {
        var files: [(URL, Date, Int)] = []
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) {
            for case let file as URL in enumerator {
                if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
                   let date = attrs[.modificationDate] as? Date,
                   let size = attrs[.size] as? Int {
                    files.append((file, date, size))
                }
            }
        }
        return files
    }
}
```

---

### 3. 队列缓存机制 (Queue Caching)

**问题**: 当前每次请求都调用 API，效率低且容易触发限流

**Variety Linux 实现**:
```python
def fill_queue(self):
    # 预填充队列，减少 API 调用
    items = self.fetch_from_api()
    for item in items:
        self.queue.append(item)
```

**macOS 实现建议**:

```swift
// Sources/Base/WallpaperQueueManager.swift
import Foundation

/// Manages wallpaper queue for efficient API usage
/// Reference: Variety Linux's fill_queue mechanism
@available(macOS 13.0, *)
final class WallpaperQueueManager<Source: WallpaperSource> {
    private let source: Source
    private var queue: [Wallpaper] = []
    private let maxQueueSize = 20
    private let minQueueSize = 5
    
    // Throttling
    private var lastFillTime: Date?
    private var lastDownloadTime: Date?
    private let maxDownloadsPerHour: Int = 10
    private let maxQueueFillsPerHour: Int = 6
    
    init(source: Source) {
        self.source = source
    }
    
    /// Get next wallpaper, filling queue if needed
    func nextWallpaper() async throws -> Wallpaper {
        // Fill queue if low
        if queue.count < minQueueSize {
            try await fillQueue()
        }
        
        // Pop from queue
        guard let wallpaper = queue.popLast() else {
            throw WallpaperError.noImageAvailable
        }
        
        lastDownloadTime = Date()
        return wallpaper
    }
    
    /// Fill queue with new wallpapers
    private func fillQueue() async throws {
        guard canFillQueue() else {
            Logger.info("Cannot fill queue - rate limited")
            return
        }
        
        let newWallpapers = try await source.fetchWallpapers(count: maxQueueSize)
        queue.append(contentsOf: newWallpapers)
        lastFillTime = Date()
        
        Logger.info("Filled queue with \(newWallpapers.count) wallpapers")
    }
    
    private func canFillQueue() -> Bool {
        guard let lastFill = lastFillTime else { return true }
        let elapsed = Date().timeIntervalSince(lastFill)
        return elapsed > 3600 / Double(maxQueueFillsPerHour)
    }
}
```

---

## P1 - 功能增强

### 4. 收藏夹管理 (Favorites Management)

```swift
// Data/FavoritesManager.swift
import Foundation

/// Manages favorite wallpapers and operations
@available(macOS 13.0, *)
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoritesFolder: URL?
    @Published var operations: [FavoriteOperation] = []
    
    /// Operations to perform when favoriting based on source
    struct FavoriteOperation {
        let sourcePattern: String  // e.g., "Downloaded", "Fetched", "Others"
        let action: FavoriteAction   // .copy, .move, .link
    }
    
    enum FavoriteAction {
        case copy
        case move
        case link
    }
    
    /// Add wallpaper to favorites
    func addToFavorites(_ wallpaper: Wallpaper) async throws {
        guard let favoritesFolder = favoritesFolder else {
            throw FavoritesError.noFolderConfigured
        }
        
        let sourceName = getSourceName(for: wallpaper)
        let operation = getOperation(for: sourceName)
        
        switch operation.action {
        case .copy:
            try await copyToFavorites(wallpaper, to: favoritesFolder)
        case .move:
            try await moveToFavorites(wallpaper, to: favoritesFolder)
        case .link:
            try await createLink(wallpaper, to: favoritesFolder)
        }
    }
    
    // MARK: - Private
    
    private func getSourceName(for wallpaper: Wallpaper) -> String {
        switch wallpaper.source {
        case .local: return "Local"
        case .bing: return "Bing"
        case .unsplash: return "Unsplash"
        case .wallhaven: return "Wallhaven"
        case .reddit: return "Reddit"
        case .artstation: return "ArtStation"
        }
    }
    
    private func getOperation(for sourceName: String) -> FavoriteOperation {
        // Find matching operation or default
        return operations.first { op in
            sourceName.contains(op.sourcePattern)
        } ?? FavoriteOperation(sourcePattern: "Others", action: .copy)
    }
}
```

---

### 5. 桌面引用和时钟 (Quotes and Clock Overlay)

```swift
// Overlays/DesktopOverlay.swift
import SwiftUI
import CoreImage
import CoreText

/// Desktop overlay for quotes and clock
/// Reference: Variety Linux's QuoteWriter.py
@available(macOS 13.0, *)
final class DesktopOverlay {
    @Published var isEnabled: Bool = false
    @Published var showClock: Bool = false
    @Published var showQuotes: Bool = false
    
    // Clock settings
    @Published var clockFont: String = "Serif 70"
    @Published var clockPosition: OverlayPosition = .bottomRight
    
    // Quote settings
    @Published var quoteFont: String = "Serif 30"
    @Published var quotePosition: OverlayPosition = .bottomLeft
    @Published var quoteTags: String = ""
    @Published var quoteAuthors: String = ""
    
    enum OverlayPosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    /// Apply overlay to image
    func applyOverlay(to image: NSImage) async -> NSImage {
        guard isEnabled else { return image }
        
        let result = image.copy() as! NSImage
        result.lockFocus()
        
        if showClock {
            drawClock(in: result)
        }
        
        if showQuotes {
            await drawQuote(in: result)
        }
        
        result.unlockFocus()
        return result
    }
    
    private func drawClock(in image: NSImage) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: Date())
        
        formatter.dateFormat = "EEEE, MMMM dd"
        let dateString = formatter.string(from: Date())
        
        let clockFont = NSFont(name: "Serif", size: 70) ?? .systemFont(ofSize: 70)
        let dateFont = NSFont(name: "Serif", size: 30) ?? .systemFont(ofSize: 30)
        
        let timeAttrs: [NSAttributedString.Key: Any] = [
            .font: clockFont,
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black,
            .strokeWidth: -3  // Outline
        ]
        
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black,
            .strokeWidth: -3
        ]
        
        // Draw at configured position
        let rect = CGRect(x: 0, y: 0, width: image.size.width, y: image.size.height)
        let timeRect = timeString.boundingRect(with: image.size, options: .usesLineFragmentOrigin, attributes: timeAttrs)
        
        timeString.draw(in: rect, withAttributes: timeAttrs)
    }
    
    private func drawQuote(in image: NSImage) async {
        // Fetch and draw quote
    }
}
```

---

## P2 - 扩展功能

### 6. 更多壁纸源

参考 Variety Linux 的实现，可以添加：

```swift
// Sources/NationalGeographic/NatGeoSource.swift
// Sources/Flickr/FlickrSource.swift
// Sources/500px/FiveHundredPXSource.swift
```

### 7. 统计和报告

```swift
// Data/WallpaperStatistics.swift
struct WallpaperStatistics {
    var totalDownloads: Int = 0
    var downloadsBySource: [WallpaperSourceType: Int] = [:]
    var totalSizeBytes: Int64 = 0
    var favoriteCount: Int = 0
    var lastDownloadDate: Date?
    
    func report() -> String {
        return """
        Wallpaper Statistics:
        - Total downloads: \(totalDownloads)
        - Downloads by source: \(downloadsBySource)
        - Storage used: \(ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file))
        - Favorites: \(favoriteCount)
        """
    }
}
```

---

## 实现优先级

1. **立即实现 (本周)**
   - [x] 修复 ArtStation 启用状态同步
   - [x] 修复 Wallhaven 限流问题
   - [ ] 实现安全模式

2. **短期 (本月)**
   - [ ] 实现下载配额管理
   - [ ] 实现队列缓存机制
   - [ ] 实现收藏夹操作

3. **中期 (下季度)**
   - [ ] 实现桌面引用功能
   - [ ] 实现桌面时钟功能
   - [ ] 添加更多壁纸源

4. **长期 (未来)**
   - [ ] 统计和报告
   - [ ] 同步功能
   - [ ] 插件系统
