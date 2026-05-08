import Foundation
import Combine

/// App-wide preferences manager
@available(macOS 13.0, *)
final class Preferences: ObservableObject {
    static let shared = Preferences()
    
    private let persistence = Persistence.shared
    
    // MARK: - General Settings
    
    @Published var changeInterval: TimeInterval = 1800 {
        didSet { savePreferences() }
    }
    
    @Published var changeOnStart: Bool = false {
        didSet { savePreferences() }
    }
    
    @Published var showNotifications: Bool = true {
        didSet { savePreferences() }
    }
    
    @Published var fillMode: DisplayMode = .fill {
        didSet { savePreferences() }
    }
    
    @Published var changeAllScreens: Bool = true {
        didSet { savePreferences() }
    }
    
    // MARK: - Download Settings
    
    @Published var downloadEnabled: Bool = true {
        didSet { savePreferences() }
    }
    
    @Published var downloadFolder: String = "" {
        didSet { savePreferences() }
    }
    
    @Published var maxDownloadSize: Double = 10 {
        didSet { savePreferences() }
    }
    
    @Published var imageQuality: String = "high" {
        didSet { savePreferences() }
    }
    
    @Published var limitDownloadSpeed: Bool = false {
        didSet { savePreferences() }
    }
    
    @Published var maxDownloadSpeed: Double = 1000 {
        didSet { savePreferences() }
    }
    
    // MARK: - Source Settings
    
    @Published var enabledSources: [WallpaperSourceType] = [.unsplash, .bing] {
        didSet { savePreferences() }
    }
    
    @Published var unsplashEnabled: Bool = true {
        didSet { savePreferences() }
    }
    
    @Published var unsplashWeight: Double = 1.0 {
        didSet { savePreferences() }
    }
    
    @Published var unsplashAccessKey: String? = nil {
        didSet { savePreferences() }
    }
    
    @Published var unsplashCollections: String? = nil {
        didSet { savePreferences() }
    }
    
    @Published var unsplashTopics: String? = nil {
        didSet { savePreferences() }
    }
    
    @Published var bingEnabled: Bool = true {
        didSet { savePreferences() }
    }
    
    @Published var bingWeight: Double = 1.0 {
        didSet { savePreferences() }
    }
    
    @Published var bingMarket: String? = "en-US" {
        didSet { savePreferences() }
    }
    
    @Published var bingResolution: String? = "UHD" {
        didSet { savePreferences() }
    }
    
    @Published var wallhavenEnabled: Bool = false {
        didSet { savePreferences() }
    }
    
    @Published var wallhavenWeight: Double = 1.0 {
        didSet { savePreferences() }
    }
    
    @Published var wallhavenAPIKey: String? = nil {
        didSet { savePreferences() }
    }
    
    @Published var wallhavenSearchQuery: String = "" {
        didSet { savePreferences() }
    }
    
    @Published var redditEnabled: Bool = false {
        didSet { savePreferences() }
    }
    
    @Published var redditWeight: Double = 1.0 {
        didSet { savePreferences() }
    }
    
    @Published var redditSubreddits: [String] = ["earthporn"] {
        didSet { savePreferences() }
    }
    
    @Published var redditSort: String? = "hot" {
        didSet { savePreferences() }
    }
    
@Published var redditTime: String? = "day" {
        didSet { savePreferences() }
    }

    @Published var artstationEnabled: Bool = false {
        didSet { savePreferences() }
    }

    @Published var artstationWeight: Double = 1.0 {
        didSet { savePreferences() }
    }

    @Published var localEnabled: Bool = false {
        didSet { savePreferences() }
    }
    
    @Published var localWeight: Double = 1.0 {
        didSet { savePreferences() }
    }
    
    @Published var localFolderPath: String = "" {
        didSet { savePreferences() }
    }
    
    @Published var localRecursive: Bool = true {
        didSet { savePreferences() }
    }
    
    @Published var localShuffle: Bool = true {
        didSet { savePreferences() }
    }
    
    // MARK: - Screen Settings
    
    @Published var screenConfigurations: [String: String] = [:] {
        didSet { savePreferences() }
    }
    
    // MARK: - Last State
    
    @Published var lastWallpaper: Wallpaper? = nil {
        didSet { savePreferences() }
    }
    
    // MARK: - Initialization
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Persistence
    
    private func savePreferences() {
        let prefs = PreferencesData(
            changeInterval: changeInterval,
            changeOnStart: changeOnStart,
            showNotifications: showNotifications,
            fillMode: fillMode,
            changeAllScreens: changeAllScreens,
            downloadEnabled: downloadEnabled,
            downloadFolder: downloadFolder,
            maxDownloadSize: maxDownloadSize,
            imageQuality: imageQuality,
            limitDownloadSpeed: limitDownloadSpeed,
            maxDownloadSpeed: maxDownloadSpeed,
            enabledSources: enabledSources,
            unsplashEnabled: unsplashEnabled,
            unsplashWeight: unsplashWeight,
            unsplashAccessKey: unsplashAccessKey,
            unsplashCollections: unsplashCollections,
            unsplashTopics: unsplashTopics,
            bingEnabled: bingEnabled,
            bingWeight: bingWeight,
            bingMarket: bingMarket,
            bingResolution: bingResolution,
            wallhavenEnabled: wallhavenEnabled,
            wallhavenWeight: wallhavenWeight,
            wallhavenAPIKey: wallhavenAPIKey,
            wallhavenSearchQuery: wallhavenSearchQuery,
            redditEnabled: redditEnabled,
            redditWeight: redditWeight,
            redditSubreddits: redditSubreddits,
            redditSort: redditSort,
redditTime: redditTime,
        artstationEnabled: artstationEnabled,
        artstationWeight: artstationWeight,
        localEnabled: localEnabled,
        localWeight: localWeight,
        localFolderPath: localFolderPath,
        localRecursive: localRecursive,
        localShuffle: localShuffle,
        screenConfigurations: screenConfigurations
        )
        
        _ = persistence.save(prefs, forKey: "app_preferences")
    }
    
    private func loadPreferences() {
        guard let data: PreferencesData = persistence.load(PreferencesData.self, forKey: "app_preferences") else { return }
        
        changeInterval = data.changeInterval
        changeOnStart = data.changeOnStart
        showNotifications = data.showNotifications
        fillMode = data.fillMode
        changeAllScreens = data.changeAllScreens
        downloadEnabled = data.downloadEnabled
        downloadFolder = data.downloadFolder
        maxDownloadSize = data.maxDownloadSize
        imageQuality = data.imageQuality
        limitDownloadSpeed = data.limitDownloadSpeed
        maxDownloadSpeed = data.maxDownloadSpeed
        enabledSources = data.enabledSources
        unsplashEnabled = data.unsplashEnabled
        unsplashWeight = data.unsplashWeight
        unsplashAccessKey = data.unsplashAccessKey
        unsplashCollections = data.unsplashCollections
        unsplashTopics = data.unsplashTopics
        bingEnabled = data.bingEnabled
        bingWeight = data.bingWeight
        bingMarket = data.bingMarket
        bingResolution = data.bingResolution
        wallhavenEnabled = data.wallhavenEnabled
        wallhavenWeight = data.wallhavenWeight
        wallhavenAPIKey = data.wallhavenAPIKey
        wallhavenSearchQuery = data.wallhavenSearchQuery
        redditEnabled = data.redditEnabled
        redditWeight = data.redditWeight
        redditSubreddits = data.redditSubreddits
        redditSort = data.redditSort
        redditTime = data.redditTime
        artstationEnabled = data.artstationEnabled
        artstationWeight = data.artstationWeight
        localEnabled = data.localEnabled
        localWeight = data.localWeight
        localFolderPath = data.localFolderPath
        localRecursive = data.localRecursive
        localShuffle = data.localShuffle
        screenConfigurations = data.screenConfigurations
    }
    
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
        enabledSources = [.unsplash, .bing]
        unsplashEnabled = true
        bingEnabled = true
        wallhavenEnabled = false
        redditEnabled = false
        artstationEnabled = false
        localEnabled = false
        savePreferences()
    }
}

// MARK: - Preferences Data

struct PreferencesData: Codable {
    var changeInterval: TimeInterval
    var changeOnStart: Bool
    var showNotifications: Bool
    var fillMode: DisplayMode
    var changeAllScreens: Bool
    
    var downloadEnabled: Bool
    var downloadFolder: String
    var maxDownloadSize: Double
    var imageQuality: String
    var limitDownloadSpeed: Bool
    var maxDownloadSpeed: Double
    
    var enabledSources: [WallpaperSourceType]
    
    var unsplashEnabled: Bool
    var unsplashWeight: Double
    var unsplashAccessKey: String?
    var unsplashCollections: String?
    var unsplashTopics: String?
    
    var bingEnabled: Bool
    var bingWeight: Double
    var bingMarket: String?
    var bingResolution: String?
    
    var wallhavenEnabled: Bool
    var wallhavenWeight: Double
    var wallhavenAPIKey: String?
    var wallhavenSearchQuery: String
    
var redditEnabled: Bool
    var redditWeight: Double
    var redditSubreddits: [String]
    var redditSort: String?
    var redditTime: String?

    var artstationEnabled: Bool
    var artstationWeight: Double

    var localEnabled: Bool
    var localWeight: Double
    var localFolderPath: String
    var localRecursive: Bool
    var localShuffle: Bool
    
    var screenConfigurations: [String: String]
}
