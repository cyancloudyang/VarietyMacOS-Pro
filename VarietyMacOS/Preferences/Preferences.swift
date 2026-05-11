import Foundation
import SwiftData

/// A schedule rule for time-based wallpaper change intervals
@Model
final class ScheduleRule {
    var id: String
    var name: String
    var startTime: Double  // Seconds from midnight (e.g., 9*3600 = 9 AM)
    var endTime: Double
    var daysOfWeekData: Data?  // Encoded Set<Int> for SwiftData compatibility
    var interval: TimeInterval
    var isEnabled: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        startTime: Double,
        endTime: Double,
        daysOfWeek: Set<Int>,
        interval: TimeInterval,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.daysOfWeekData = try? JSONEncoder().encode(daysOfWeek)
        self.interval = interval
        self.isEnabled = isEnabled
    }
    
    /// Computed property for days of week (1=Sunday, 7=Saturday)
    var daysOfWeek: Set<Int> {
        get {
            guard let data = daysOfWeekData else { return [] }
            return (try? JSONDecoder().decode(Set<Int>.self, from: data)) ?? []
        }
        set {
            daysOfWeekData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Check if this rule is currently active based on time and day
    var isActive: Bool {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .minute, .weekday], from: now)
        guard let hour = components.hour, let minute = components.minute, let weekday = components.weekday else {
            return false
        }
        
        let currentTime = Double(hour) * 3600 + Double(minute) * 60
        let currentDay = weekday
        
        // Check if current day is in the rule's days
        guard daysOfWeek.contains(currentDay) else { return false }
        
        // Check if current time is within the rule's time range
        if startTime < endTime {
            return currentTime >= startTime && currentTime <= endTime
        } else {
            // Overnight rule (e.g., 10 PM to 6 AM)
            return currentTime >= startTime || currentTime <= endTime
        }
    }
    
    /// Formatted time string for display
    var formattedTimeRange: String {
        let startHour = Int(startTime) / 3600
        let startMinute = Int(startTime) % 3600 / 60
        let endHour = Int(endTime) / 3600
        let endMinute = Int(endTime) % 3600 / 60
        
        let startStr = String(format: "%02d:%02d", startHour, startMinute)
        let endStr = String(format: "%02d:%02d", endHour, endMinute)
        return "\(startStr) - \(endStr)"
    }
}

// MARK: - Default Schedule Rules

extension ScheduleRule {
    /// Create default schedule rules for first-time users
    static func createDefaultRules() -> [ScheduleRule] {
        [
            // Work Hours: Mon-Fri, 9 AM - 5 PM, 1 hour interval
            ScheduleRule(
                name: "Work Hours",
                startTime: 9 * 3600,
                endTime: 17 * 3600,
                daysOfWeek: [2, 3, 4, 5, 6], // Mon-Fri
                interval: 3600,
                isEnabled: true
            ),
            // Evening: Mon-Fri, 5 PM - 11 PM, 30 minute interval
            ScheduleRule(
                name: "Evening",
                startTime: 17 * 3600,
                endTime: 23 * 3600,
                daysOfWeek: [2, 3, 4, 5, 6], // Mon-Fri
                interval: 1800,
                isEnabled: true
            ),
            // Night: Daily, 11 PM - 7 AM, pause (24 hour interval)
            ScheduleRule(
                name: "Night (Pause)",
                startTime: 23 * 3600,
                endTime: 7 * 3600,
                daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Daily
                interval: 86400,
                isEnabled: false
            ),
            // Weekend: Sat-Sun, all day, 2 hour interval
            ScheduleRule(
                name: "Weekend",
                startTime: 0,
                endTime: 24 * 3600 - 1,
                daysOfWeek: [1, 7], // Sun, Sat
                interval: 7200,
                isEnabled: true
            )
        ]
    }
}
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
    
    // MARK: - Smart Scheduling
    
    var smartSchedulingEnabled: Bool = false
    
    @Relationship(deleteRule: .cascade)
    var scheduleRules: [ScheduleRule] = []
    
    init() {
        // SwiftData required init for @Model with default values
    }
    
    /// Get the currently active schedule rule
    func getCurrentScheduleRule() -> ScheduleRule? {
        guard smartSchedulingEnabled else { return nil }
        return scheduleRules.first { $0.isActive && $0.isEnabled }
    }
    
    /// Get the effective interval based on active schedule rule
    func getCurrentInterval() -> TimeInterval {
        if let rule = getCurrentScheduleRule() {
            return rule.interval
        }
        return changeInterval
    }
    
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

@MainActor
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

    /// Get the currently active schedule rule
    func getCurrentScheduleRule() -> ScheduleRule? {
        appPreferences.getCurrentScheduleRule()
    }

    /// Get the effective interval based on active schedule rule
    func getCurrentInterval() -> TimeInterval {
        appPreferences.getCurrentInterval()
    }

    // MARK: - Snapshot for Actor Isolation

    /// A Sendable snapshot of current preferences values.
    /// Actors (DownloadManager, ThrottlingManager) capture this at init
    /// to avoid cross-actor access to Preferences.shared.
    struct Snapshot: Sendable {
        let downloadFolder: String
        let limitDownloadSpeed: Bool
        let maxDownloadSpeed: Double
        let redditSubreddits: [String]
        let redditSort: String?
        let redditTime: String?
        let wallhavenAPIKey: String?
        let wallhavenSearchQuery: String
        let wallhavenEnabled: Bool
        let wallhavenWeight: Double
        let changeInterval: TimeInterval
        let showNotifications: Bool
        let changeAllScreens: Bool
        let fillMode: DisplayMode
        let enabledSources: [WallpaperSourceType]
        let unsplashEnabled: Bool
        let unsplashWeight: Double
        let unsplashAccessKey: String?
        let unsplashCollections: String?
        let unsplashTopics: String?
        let bingEnabled: Bool
        let bingWeight: Double
        let bingMarket: String?
        let bingResolution: String?
        let redditEnabled: Bool
        let redditWeight: Double
        let artstationEnabled: Bool
        let artstationWeight: Double
        let localEnabled: Bool
        let localWeight: Double
        let localFolderPath: String
        let localRecursive: Bool
        let localShuffle: Bool
    }

    /// Create a Sendable snapshot of all current preference values.
    /// Call this from @MainActor context, then pass the snapshot into actors.
    func snapshot() -> Snapshot {
        Snapshot(
            downloadFolder: appPreferences.downloadFolder,
            limitDownloadSpeed: appPreferences.limitDownloadSpeed,
            maxDownloadSpeed: appPreferences.maxDownloadSpeed,
            redditSubreddits: appPreferences.redditSubreddits,
            redditSort: appPreferences.redditSort,
            redditTime: appPreferences.redditTime,
            wallhavenAPIKey: appPreferences.wallhavenAPIKey,
            wallhavenSearchQuery: appPreferences.wallhavenSearchQuery,
            wallhavenEnabled: appPreferences.wallhavenEnabled,
            wallhavenWeight: appPreferences.wallhavenWeight,
            changeInterval: appPreferences.changeInterval,
            showNotifications: appPreferences.showNotifications,
            changeAllScreens: appPreferences.changeAllScreens,
            fillMode: appPreferences.fillMode,
            enabledSources: appPreferences.enabledSources,
            unsplashEnabled: appPreferences.unsplashEnabled,
            unsplashWeight: appPreferences.unsplashWeight,
            unsplashAccessKey: appPreferences.unsplashAccessKey,
            unsplashCollections: appPreferences.unsplashCollections,
            unsplashTopics: appPreferences.unsplashTopics,
            bingEnabled: appPreferences.bingEnabled,
            bingWeight: appPreferences.bingWeight,
            bingMarket: appPreferences.bingMarket,
            bingResolution: appPreferences.bingResolution,
            redditEnabled: appPreferences.redditEnabled,
            redditWeight: appPreferences.redditWeight,
            artstationEnabled: appPreferences.artstationEnabled,
            artstationWeight: appPreferences.artstationWeight,
            localEnabled: appPreferences.localEnabled,
            localWeight: appPreferences.localWeight,
            localFolderPath: appPreferences.localFolderPath,
            localRecursive: appPreferences.localRecursive,
            localShuffle: appPreferences.localShuffle
        )
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
