import Foundation
import Combine
import SwiftData

/// App-wide preferences stored as a single SwiftData record
@Model
final class AppPreferences {
    // MARK: - General Settings

    var changeInterval: TimeInterval = 1800
    var changeOnStart: Bool = false
    var showNotifications: Bool = true
    var fillMode: DisplayMode = DisplayMode.fill
    var changeAllScreens: Bool = true

    // MARK: - Download Settings

    var downloadEnabled: Bool = true
    var downloadFolder: String = ""
    var maxDownloadSize: Double = 10
    var imageQuality: String = "high"
    var limitDownloadSpeed: Bool = false
    var maxDownloadSpeed: Double = 1000

    // MARK: - Source Settings

    var enabledSources: [WallpaperSourceType] = [WallpaperSourceType.unsplash, WallpaperSourceType.bing]

    var unsplashEnabled: Bool = true
    var unsplashWeight: Double = 1.0
    var unsplashAccessKey: String? = nil
    var unsplashCollections: String? = nil
    var unsplashTopics: String? = nil

    var bingEnabled: Bool = true
    var bingWeight: Double = 1.0
    var bingMarket: String? = "en-US"
    var bingResolution: String? = "UHD"

    var wallhavenEnabled: Bool = false
    var wallhavenWeight: Double = 1.0
    var wallhavenAPIKey: String? = nil
    var wallhavenSearchQuery: String = ""
    var wallhavenCategories: String = "111"
    var wallhavenPurity: String = "100"
    var wallhavenSorting: String = "random"
    var wallhavenResolution: String = ""
    var wallhavenRatio: String = ""

    var redditEnabled: Bool = false
    var redditWeight: Double = 1.0
    var redditSubreddits: [String] = ["earthporn"]
    var redditSort: String? = "hot"
    var redditTime: String? = "day"

    var artstationEnabled: Bool = false
    var artstationWeight: Double = 1.0

    var localEnabled: Bool = false
    var localWeight: Double = 1.0
    var localFolderPath: String = ""
    var localRecursive: Bool = true
    var localShuffle: Bool = true

    // MARK: - Screen Settings

    var screenConfigurations: [String: String] = [:]

    @Relationship(deleteRule: .nullify)
    var lastWallpaper: Wallpaper? = nil

    init() {}

    // MARK: - Reset

    func resetToDefaults() {
        changeInterval = 1800
        changeOnStart = false
        showNotifications = true
        fillMode = .fill
        changeAllScreens = true
        downloadEnabled = true
        downloadFolder = ""
        maxDownloadSize = 10
        imageQuality = "high"
        limitDownloadSpeed = false
        maxDownloadSpeed = 1000
        enabledSources = [WallpaperSourceType.unsplash, WallpaperSourceType.bing]
        unsplashEnabled = true
        bingEnabled = true
        wallhavenEnabled = false
        redditEnabled = false
        artstationEnabled = false
        localEnabled = false
    }
}

// MARK: - Preferences Manager

final class Preferences: ObservableObject {
    @Published var appPreferences: AppPreferences

    private var modelContext: ModelContext?

    static let shared = Preferences()

    private init() {
        appPreferences = AppPreferences()
    }

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadOrCreatePreferences()
    }

    private func loadOrCreatePreferences() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AppPreferences>()
        if let existing = try? context.fetch(descriptor).first {
            appPreferences = existing
        } else {
            let prefs = AppPreferences()
            context.insert(prefs)
            try? context.save()
            appPreferences = prefs
        }
    }

    // MARK: - Forwarding Properties
    // These computed properties forward to appPreferences so existing
    // call sites (Preferences.shared.xxx) continue to work seamlessly.

    // General
    var changeInterval: TimeInterval {
        get { appPreferences.changeInterval }
        set { appPreferences.changeInterval = newValue }
    }
    var changeOnStart: Bool {
        get { appPreferences.changeOnStart }
        set { appPreferences.changeOnStart = newValue }
    }
    var showNotifications: Bool {
        get { appPreferences.showNotifications }
        set { appPreferences.showNotifications = newValue }
    }
    var fillMode: DisplayMode {
        get { appPreferences.fillMode }
        set { appPreferences.fillMode = newValue }
    }
    var changeAllScreens: Bool {
        get { appPreferences.changeAllScreens }
        set { appPreferences.changeAllScreens = newValue }
    }

    // Download
    var downloadEnabled: Bool {
        get { appPreferences.downloadEnabled }
        set { appPreferences.downloadEnabled = newValue }
    }
    var downloadFolder: String {
        get { appPreferences.downloadFolder }
        set { appPreferences.downloadFolder = newValue }
    }
    var maxDownloadSize: Double {
        get { appPreferences.maxDownloadSize }
        set { appPreferences.maxDownloadSize = newValue }
    }
    var imageQuality: String {
        get { appPreferences.imageQuality }
        set { appPreferences.imageQuality = newValue }
    }
    var limitDownloadSpeed: Bool {
        get { appPreferences.limitDownloadSpeed }
        set { appPreferences.limitDownloadSpeed = newValue }
    }
    var maxDownloadSpeed: Double {
        get { appPreferences.maxDownloadSpeed }
        set { appPreferences.maxDownloadSpeed = newValue }
    }

    // Sources
    var enabledSources: [WallpaperSourceType] {
        get { appPreferences.enabledSources }
        set { appPreferences.enabledSources = newValue }
    }

    var unsplashEnabled: Bool {
        get { appPreferences.unsplashEnabled }
        set { appPreferences.unsplashEnabled = newValue }
    }
    var unsplashWeight: Double {
        get { appPreferences.unsplashWeight }
        set { appPreferences.unsplashWeight = newValue }
    }
    var unsplashAccessKey: String? {
        get { appPreferences.unsplashAccessKey }
        set { appPreferences.unsplashAccessKey = newValue }
    }
    var unsplashCollections: String? {
        get { appPreferences.unsplashCollections }
        set { appPreferences.unsplashCollections = newValue }
    }
    var unsplashTopics: String? {
        get { appPreferences.unsplashTopics }
        set { appPreferences.unsplashTopics = newValue }
    }

    var bingEnabled: Bool {
        get { appPreferences.bingEnabled }
        set { appPreferences.bingEnabled = newValue }
    }
    var bingWeight: Double {
        get { appPreferences.bingWeight }
        set { appPreferences.bingWeight = newValue }
    }
    var bingMarket: String? {
        get { appPreferences.bingMarket }
        set { appPreferences.bingMarket = newValue }
    }
    var bingResolution: String? {
        get { appPreferences.bingResolution }
        set { appPreferences.bingResolution = newValue }
    }

    var wallhavenEnabled: Bool {
        get { appPreferences.wallhavenEnabled }
        set { appPreferences.wallhavenEnabled = newValue }
    }
    var wallhavenWeight: Double {
        get { appPreferences.wallhavenWeight }
        set { appPreferences.wallhavenWeight = newValue }
    }
    var wallhavenAPIKey: String? {
        get { appPreferences.wallhavenAPIKey }
        set { appPreferences.wallhavenAPIKey = newValue }
    }
    var wallhavenSearchQuery: String {
        get { appPreferences.wallhavenSearchQuery }
        set { appPreferences.wallhavenSearchQuery = newValue }
    }
    var wallhavenCategories: String {
        get { appPreferences.wallhavenCategories }
        set { appPreferences.wallhavenCategories = newValue }
    }
    var wallhavenPurity: String {
        get { appPreferences.wallhavenPurity }
        set { appPreferences.wallhavenPurity = newValue }
    }
    var wallhavenSorting: String {
        get { appPreferences.wallhavenSorting }
        set { appPreferences.wallhavenSorting = newValue }
    }
    var wallhavenResolution: String {
        get { appPreferences.wallhavenResolution }
        set { appPreferences.wallhavenResolution = newValue }
    }
    var wallhavenRatio: String {
        get { appPreferences.wallhavenRatio }
        set { appPreferences.wallhavenRatio = newValue }
    }

    var redditEnabled: Bool {
        get { appPreferences.redditEnabled }
        set { appPreferences.redditEnabled = newValue }
    }
    var redditWeight: Double {
        get { appPreferences.redditWeight }
        set { appPreferences.redditWeight = newValue }
    }
    var redditSubreddits: [String] {
        get { appPreferences.redditSubreddits }
        set { appPreferences.redditSubreddits = newValue }
    }
    var redditSort: String? {
        get { appPreferences.redditSort }
        set { appPreferences.redditSort = newValue }
    }
    var redditTime: String? {
        get { appPreferences.redditTime }
        set { appPreferences.redditTime = newValue }
    }

    var artstationEnabled: Bool {
        get { appPreferences.artstationEnabled }
        set { appPreferences.artstationEnabled = newValue }
    }
    var artstationWeight: Double {
        get { appPreferences.artstationWeight }
        set { appPreferences.artstationWeight = newValue }
    }

    var localEnabled: Bool {
        get { appPreferences.localEnabled }
        set { appPreferences.localEnabled = newValue }
    }
    var localWeight: Double {
        get { appPreferences.localWeight }
        set { appPreferences.localWeight = newValue }
    }
    var localFolderPath: String {
        get { appPreferences.localFolderPath }
        set { appPreferences.localFolderPath = newValue }
    }
    var localRecursive: Bool {
        get { appPreferences.localRecursive }
        set { appPreferences.localRecursive = newValue }
    }
    var localShuffle: Bool {
        get { appPreferences.localShuffle }
        set { appPreferences.localShuffle = newValue }
    }

    // Screen
    var screenConfigurations: [String: String] {
        get { appPreferences.screenConfigurations }
        set { appPreferences.screenConfigurations = newValue }
    }

    // MARK: - Last Wallpaper
    var lastWallpaper: Wallpaper? {
        get { appPreferences.lastWallpaper }
        set { appPreferences.lastWallpaper = newValue }
    }
}
