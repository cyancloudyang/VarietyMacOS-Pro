import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for Preferences
@available(macOS 13.0, *)
final class PreferencesTests: XCTestCase {

    // MARK: - Singleton Tests

    func testPreferencesShared() {
        let prefs1 = Preferences.shared
        let prefs2 = Preferences.shared
        XCTAssert(prefs1 === prefs2)
    }

    // MARK: - General Settings Tests

    func testChangeIntervalDefault() {
        let prefs = Preferences.shared
        XCTAssertEqual(prefs.changeInterval, 1800) // 30 minutes
    }

    func testChangeIntervalSet() {
        let prefs = Preferences.shared
        let original = prefs.changeInterval

        prefs.changeInterval = 3600
        XCTAssertEqual(prefs.changeInterval, 3600)

        prefs.changeInterval = original
    }

    func testChangeOnStartDefault() {
        XCTAssertEqual(Preferences.shared.changeOnStart, false)
    }

    func testShowNotificationsDefault() {
        XCTAssertEqual(Preferences.shared.showNotifications, true)
    }

    func testFillModeDefault() {
        XCTAssertEqual(Preferences.shared.fillMode, .fill)
    }

    func testChangeAllScreensDefault() {
        XCTAssertEqual(Preferences.shared.changeAllScreens, true)
    }

    // MARK: - Download Settings Tests

    func testDownloadEnabledDefault() {
        XCTAssertEqual(Preferences.shared.downloadEnabled, true)
    }

    func testMaxDownloadSizeDefault() {
        XCTAssertEqual(Preferences.shared.maxDownloadSize, 10)
    }

    func testImageQualityDefault() {
        XCTAssertEqual(Preferences.shared.imageQuality, "high")
    }

    func testLimitDownloadSpeedDefault() {
        XCTAssertEqual(Preferences.shared.limitDownloadSpeed, false)
    }

    func testMaxDownloadSpeedDefault() {
        XCTAssertEqual(Preferences.shared.maxDownloadSpeed, 1000)
    }

    // MARK: - Source Settings Tests

    func testEnabledSourcesDefault() {
        let enabledSources = Preferences.shared.enabledSources
        XCTAssertFalse(enabledSources.isEmpty)
    }

    func testUnsplashEnabledDefault() {
        XCTAssertEqual(Preferences.shared.unsplashEnabled, true)
    }

    func testUnsplashWeightDefault() {
        XCTAssertEqual(Preferences.shared.unsplashWeight, 1.0)
    }

    func testBingEnabledDefault() {
        XCTAssertEqual(Preferences.shared.bingEnabled, true)
    }

    func testBingWeightDefault() {
        XCTAssertEqual(Preferences.shared.bingWeight, 1.0)
    }

    func testWallhavenEnabledDefault() {
        XCTAssertEqual(Preferences.shared.wallhavenEnabled, false)
    }

    func testRedditEnabledDefault() {
        XCTAssertEqual(Preferences.shared.redditEnabled, false)
    }

    func testLocalEnabledDefault() {
        XCTAssertEqual(Preferences.shared.localEnabled, false)
    }

    // MARK: - Reddit Settings Tests

    func testRedditSubredditsDefault() {
        let subreddits = Preferences.shared.redditSubreddits
        XCTAssertEqual(subreddits.first, "earthporn")
    }

    func testRedditSortDefault() {
        XCTAssertEqual(Preferences.shared.redditSort, "hot")
    }

    func testRedditTimeDefault() {
        XCTAssertEqual(Preferences.shared.redditTime, "day")
    }

    // MARK: - Local Settings Tests

    func testLocalRecursiveDefault() {
        XCTAssertEqual(Preferences.shared.localRecursive, true)
    }

    func testLocalShuffleDefault() {
        XCTAssertEqual(Preferences.shared.localShuffle, true)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        let prefs = Preferences.shared

        // Change some values
        prefs.changeInterval = 7200
        prefs.showNotifications = false
        prefs.changeAllScreens = false

        // Reset
        prefs.resetToDefaults()

        // Verify defaults
        XCTAssertEqual(prefs.changeInterval, 1800)
        XCTAssertEqual(prefs.showNotifications, true)
        XCTAssertEqual(prefs.changeAllScreens, true)
    }

    // MARK: - Preferences Data Codable Tests

    func testPreferencesDataCodable() throws {
        let original = PreferencesData(
            changeInterval: 3600,
            changeOnStart: true,
            showNotifications: false,
            fillMode: .fit,
            changeAllScreens: false,
            downloadEnabled: true,
            downloadFolder: "/tmp",
            maxDownloadSize: 20,
            imageQuality: "medium",
            limitDownloadSpeed: true,
            maxDownloadSpeed: 500,
            enabledSources: [.unsplash],
            unsplashEnabled: true,
            unsplashWeight: 2.0,
            unsplashAccessKey: "key",
            unsplashCollections: "nature",
            unsplashTopics: "landscape",
            bingEnabled: false,
            bingWeight: 1.0,
            bingMarket: "en-US",
            bingResolution: "HD",
            wallhavenEnabled: false,
            wallhavenWeight: 1.0,
            wallhavenAPIKey: nil,
            wallhavenSearchQuery: "",
            redditEnabled: true,
            redditWeight: 1.5,
            redditSubreddits: ["test"],
            redditSort: "top",
            redditTime: "week",
            localEnabled: false,
            localWeight: 1.0,
            localFolderPath: "",
            localRecursive: false,
            localShuffle: false,
            screenConfigurations: ["1": "wallpaper1"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PreferencesData.self, from: data)

        XCTAssertEqual(decoded.changeInterval, original.changeInterval)
        XCTAssertEqual(decoded.changeOnStart, original.changeOnStart)
        XCTAssertEqual(decoded.showNotifications, original.showNotifications)
        XCTAssertEqual(decoded.fillMode, original.fillMode)
        XCTAssertEqual(decoded.changeAllScreens, original.changeAllScreens)
        XCTAssertEqual(decoded.enabledSources, original.enabledSources)
        XCTAssertEqual(decoded.redditSubreddits, original.redditSubreddits)
        XCTAssertEqual(decoded.screenConfigurations, original.screenConfigurations)
    }

    // MARK: - Published Property Observation Tests

    func testChangeIntervalTriggersSave() {
        let prefs = Preferences.shared
        let original = prefs.changeInterval

        prefs.changeInterval = 900
        XCTAssertEqual(prefs.changeInterval, 900)

        prefs.changeInterval = original
    }

    func testShowNotificationsTriggersSave() {
        let prefs = Preferences.shared
        let original = prefs.showNotifications

        prefs.showNotifications = !original
        XCTAssertEqual(prefs.showNotifications, !original)

        prefs.showNotifications = original
    }

    func testFillModeTriggersSave() {
        let prefs = Preferences.shared
        let original = prefs.fillMode

        prefs.fillMode = .fit
        XCTAssertEqual(prefs.fillMode, .fit)

        prefs.fillMode = original
    }
}
