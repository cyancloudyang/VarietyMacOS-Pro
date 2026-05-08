import Foundation
import AppKit
import Combine
import UserNotifications

/// Main manager for wallpaper operations
@available(macOS 13.0, *)
final class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()

    // MARK: - Published Properties

    @Published var currentWallpaper: Wallpaper?
    @Published var isLoading = false
    @Published var currentSource: WallpaperSourceType = .unsplash
    @Published var error: WallpaperError?
    @Published var downloadProgress: Double = 0.0  // New: download progress

    // Debug property for UI
    var debugHistoryCount: Int {
        wallpaperHistory.count
    }

    // MARK: - Private Properties

    private var wallpaperHistory: [Wallpaper] = []
    private var historyIndex = -1
    private var cancellables = Set<AnyCancellable>()
    private let downloadManager = DownloadManager.shared
    private let imageCache = ImageCacheManager.shared
    
// MARK: - Initialization

private init() {
    loadLastWallpaper()
    setupTimer()
    setupMemoryWarningObserver()
}
    
// MARK: - Timer Setup

    private static var isTimerSetup = false

    private func setupTimer() {
        // Only set up the callback once
        guard !WallpaperManager.isTimerSetup else { return }
        WallpaperManager.isTimerSetup = true

        WallpaperTimer.shared.onTimerFired = { [weak self] in
            Task { @MainActor in
                await self?.nextWallpaper()
            }
        }

        // Start timer if enabled
        if Preferences.shared.changeInterval > 0 {
            WallpaperTimer.shared.start(interval: Preferences.shared.changeInterval)
        }
    }

    private func setupMemoryWarningObserver() {
        // Intentionally empty - macOS handles memory automatically
        // Memory is freed via clearCachedImage() calls after applyWallpaper
    }

    // MARK: - Wallpaper Operations
    
    /// Load the next wallpaper
    @MainActor
    func nextWallpaper() async {
        print("🔄 nextWallpaper() called, isLoading=\(isLoading)")
        
        if isLoading {
            print("⚠️ Already loading, skipping")
            return
        }
        print("🔄 Next wallpaper requested")
        
        // Check history first
        if historyIndex < wallpaperHistory.count - 1 {
            historyIndex += 1
            print("📜 Using history[\(historyIndex)]")
            await applyWallpaper(wallpaperHistory[historyIndex])
            return
        }

        // Fetch new wallpaper
        print("🆕 Fetching new wallpaper")
        await fetchNewWallpaper()
    }
    
/// Go to previous wallpaper
    @MainActor
    func previousWallpaper() async {
        guard historyIndex > 0 else {
            Logger.warning("No previous wallpaper available")
            return
        }

        historyIndex -= 1
        await applyWallpaper(wallpaperHistory[historyIndex])
    }
    
/// Fetch a new wallpaper from enabled sources with retry mechanism
    @MainActor
    private func fetchNewWallpaper() async {
        guard !isLoading else {
            print("⚠️ Already loading, skipping")
            return
        }

        isLoading = true
        error = nil
        print("🔴 isLoading set to true")

        defer {
            isLoading = false
            print("🟢 isLoading set to false (defer)")
        }

        // Try up to 5 times with different sources (increased from 3)
        let maxRetries = 5
        var lastError: Error? = nil
        var attemptedSources: Set<String> = []

        for attempt in 1...maxRetries {
            let source = getNextSource()
            let sourceKey = source.sourceID
            
            // Skip if this source was already tried in this cycle
            if attemptedSources.contains(sourceKey) {
                if attempt < maxRetries {
                    continue
                }
                break
            }
            attemptedSources.insert(sourceKey)
            
            print("📥 Attempt \(attempt)/\(maxRetries): Fetching from \(source.displayName)...")

            do {
                let wallpaper = try await source.fetchWallpaper()
                print("✓ Fetched: \(wallpaper.title ?? "Untitled")")
                
                // Validate wallpaper has valid URL
                guard wallpaper.remoteURL != nil || wallpaper.localURL != nil else {
                    throw NSError(domain: "WallpaperManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid wallpaper - no URL"])
                }
                
                wallpaperHistory.append(wallpaper)
                historyIndex = wallpaperHistory.count - 1
                print("🖼️ Applying to desktop...")
                await applyWallpaper(wallpaper)
                print("✓ Done")
                return // Success! Exit the function
            } catch {
                lastError = error
                print("✗ Attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Add small delay before retry to avoid rate limiting
                if attempt < maxRetries {
                    print("🔄 Retrying with different source...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                }
            }
        }

        // All attempts failed
        print("✗ All \(maxRetries) attempts failed")
        let errorMessage = lastError?.localizedDescription ?? "Unknown error"
        self.error = WallpaperError.fetchFailed(lastError ?? NSError(domain: "WallpaperManager", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        
        // Show notification to user
        showNotification(title: "Failed to Fetch Wallpaper", body: "Could not fetch wallpaper after \(maxRetries) attempts. Please check your network connection.")
    }
    
    /// Apply wallpaper to screen(s) - Public version
    @MainActor
    func applyWallpaper(_ wallpaper: Wallpaper) async {
        print("🖼️ applyWallpaper() started for: \(wallpaper.title ?? "Unknown")")
        
        do {
            let image = try await loadImage(for: wallpaper)
            print("🖼️ Image loaded, size: \(image.size)")

            await MainActor.run {
                print("🖼️ Setting wallpaper on desktop...")
                setWallpaper(image: image)
                currentWallpaper = wallpaper

// Save to history
            WallpaperHistory.shared.add(wallpaper)
            
            // Clear cached image to free memory
            wallpaper.clearCachedImage()

            // Show notification if enabled
            if Preferences.shared.showNotifications {
                showNotification(for: wallpaper)
            }
            }
            print("✓ applyWallpaper() completed")
        } catch {
            print("✗ applyWallpaper() error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = WallpaperError.applyFailed(error)
            }
        }
    }
    
    /// Apply wallpaper to screen(s) - Private version for internal use
    private func applyWallpaper(_ wallpaper: Wallpaper) {
        Task {
            await applyWallpaper(wallpaper)
        }
    }
    
    /// Load image from wallpaper with caching
    private func loadImage(for wallpaper: Wallpaper) async throws -> NSImage {
        print("📷 loadImage() for: \(wallpaper.title ?? "Unknown")")

        // Check in-memory cache first
        if let cachedImage = wallpaper.cachedImage {
            print("📷 Image found in memory cache")
            return cachedImage
        }

        // Use ImageCacheManager for optimized loading
        do {
            // Remote image with caching
            if let url = wallpaper.remoteURL {
                let image = try await imageCache.getImage(for: wallpaper.cacheKey, from: url)
                wallpaper.cachedImage = image
                print("📷 Image loaded from cache: \(image.size)")
                return image
            }

            // Local image
            if let imageURL = wallpaper.localURL, FileManager.default.fileExists(atPath: imageURL.path) {
                print("📷 Loading from local: \(imageURL.path)")
                let image = try imageCache.getImage(from: imageURL)
                wallpaper.cachedImage = image
                return image
            }

            print("📷 No image source available")
            throw WallpaperError.noImageAvailable
        } catch {
            print("📷 Error loading image: \(error)")
            throw WallpaperError.invalidImage
        }
    }
    
/// Set the actual desktop wallpaper
private func setWallpaper(image: NSImage) {
    let screens = Preferences.shared.changeAllScreens ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
    let displayMode = Preferences.shared.fillMode

    for screen in screens {
        let success = displayMode.apply(to: image, on: screen)
        if success {
            print("✓ Wallpaper applied to screen")
        } else {
            print("✗ Failed to apply wallpaper to screen")
        }
    }
}
    
    // MARK: - Source Management
    
    /// Get the next source to use based on preferences
    private func getNextSource() -> WallpaperSource {
        let enabledSources = Preferences.shared.enabledSources
        guard !enabledSources.isEmpty else {
            // Fallback to Bing if no sources enabled
            return BingSource()
        }

        // Simple rotation for now - prefer Bing since it's more reliable
        let sourceType = enabledSources.randomElement() ?? .bing
        return sourceType.createSource()
    }
    
    // MARK: - Timer Control
    
    /// Toggle the wallpaper timer
    func toggleTimer() {
        WallpaperTimer.shared.toggle()
    }
    
    /// Start timer with current interval
    func startTimer() {
        WallpaperTimer.shared.start(interval: Preferences.shared.changeInterval)
    }
    
    /// Stop the timer
    func stopTimer() {
        WallpaperTimer.shared.stop()
    }
    
    // MARK: - Favorites
    
    /// Add current wallpaper to favorites
    func addToFavorites() {
        guard let wallpaper = currentWallpaper else { return }
        WallpaperFavorite.shared.add(wallpaper)
    }
    
    /// Remove from favorites
    func removeFromFavorites(_ wallpaper: Wallpaper) {
        WallpaperFavorite.shared.remove(wallpaper)
    }
    
    // MARK: - Persistence
    
    private func loadLastWallpaper() {
        // Load last used wallpaper info if available
        if let lastWallpaper = Preferences.shared.lastWallpaper {
            currentWallpaper = lastWallpaper
        }
    }
    
private func showNotification(for wallpaper: Wallpaper) {
        let notification = UNMutableNotificationContent()
        notification.title = "Wallpaper Changed"
        notification.body = wallpaper.title ?? "New wallpaper from \(wallpaper.source.displayName)"
        notification.sound = .none

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showNotification(title: String, body: String) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        notification.body = body
        notification.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Errors

enum WallpaperError: LocalizedError {
    case fetchFailed(Error)
    case applyFailed(Error)
    case invalidImage
    case noImageAvailable
    case sourceNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch wallpaper: \(error.localizedDescription)"
        case .applyFailed(let error):
            return "Failed to apply wallpaper: \(error.localizedDescription)"
        case .invalidImage:
            return "Invalid image data"
        case .noImageAvailable:
            return "No image available"
        case .sourceNotAvailable:
            return "Wallpaper source not available"
        }
    }
}
