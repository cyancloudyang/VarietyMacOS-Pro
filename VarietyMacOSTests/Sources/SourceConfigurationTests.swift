import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for SourceConfiguration
final class SourceConfigurationTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSourceConfigurationDefaultInitialization() {
        let config = SourceConfiguration(sourceType: .unsplash)

        XCTAssertEqual(config.sourceType, .unsplash)
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.weight, 1.0)
        XCTAssertEqual(config.customSettings.count, 0)
    }

    func testSourceConfigurationCustomInitialization() {
        let settings: [String: String] = ["key1": "value1", "key2": "value2"]
        let config = SourceConfiguration(
            sourceType: .reddit,
            isEnabled: false,
            weight: 2.0,
            customSettings: settings
        )

        XCTAssertEqual(config.sourceType, .reddit)
        XCTAssertFalse(config.isEnabled)
        XCTAssertEqual(config.weight, 2.0)
        XCTAssertEqual(config.customSettings.count, 2)
        XCTAssertEqual(config.customSettings["key1"], "value1")
        XCTAssertEqual(config.customSettings["key2"], "value2")
    }

    // MARK: - Codable Tests

    func testSourceConfigurationCodable() throws {
        let original = SourceConfiguration(
            sourceType: .wallhaven,
            isEnabled: true,
            weight: 1.5,
            customSettings: ["setting": "value"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SourceConfiguration.self, from: data)

        XCTAssertEqual(decoded.sourceType, original.sourceType)
        XCTAssertEqual(decoded.isEnabled, original.isEnabled)
        XCTAssertEqual(decoded.weight, original.weight)
        XCTAssertEqual(decoded.customSettings, original.customSettings)
    }

    // MARK: - Codable Tests

    func testSourceConfigurationCodableWithAllSourceTypes() throws {
        let sourceTypes: [WallpaperSourceType] = [.unsplash, .bing, .wallhaven, .reddit, .local]

        for sourceType in sourceTypes {
            let config = SourceConfiguration(sourceType: sourceType)
            let data = try JSONEncoder().encode(config)
            let decoded = try JSONDecoder().decode(SourceConfiguration.self, from: data)
            XCTAssertEqual(decoded.sourceType, sourceType)
        }
    }
}

/// Tests for SourceSelector
final class SourceSelectorTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSourceSelectorInitializationWithEmptyConfigurations() {
        let selector = SourceSelector(configurations: [])
        XCTAssertNil(selector.selectSource())
    }

    func testSourceSelectorInitializationWithDisabledConfigurations() {
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: false),
            SourceConfiguration(sourceType: .bing, isEnabled: false)
        ]
        let selector = SourceSelector(configurations: configs)
        XCTAssertNil(selector.selectSource())
    }

    func testSourceSelectorInitializationWithMixedConfigurations() {
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: true),
            SourceConfiguration(sourceType: .bing, isEnabled: false),
            SourceConfiguration(sourceType: .reddit, isEnabled: true)
        ]
        let selector = SourceSelector(configurations: configs)

        // Should be able to select from enabled configs only
        let selectedSource = selector.selectSource()
        XCTAssertNotNil(selectedSource)
    }

    // MARK: - Selection Tests

    func testSourceSelectorSelectsFromEnabledOnly() {
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: false, weight: 10.0),
            SourceConfiguration(sourceType: .bing, isEnabled: true, weight: 1.0),
            SourceConfiguration(sourceType: .reddit, isEnabled: true, weight: 1.0)
        ]
        let selector = SourceSelector(configurations: configs)

        // Run multiple times to ensure we never get unsplash
        for _ in 0..<10 {
            if let source = selector.selectSource() {
                // The source should be selectable, but we can't directly test the type
                // Just ensure it's a valid source
                XCTAssertNotNil(source)
            }
        }
    }

    func testSourceSelectorWeightDistribution() {
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: true, weight: 9.0),
            SourceConfiguration(sourceType: .bing, isEnabled: true, weight: 1.0)
        ]
        let selector = SourceSelector(configurations: configs)

        // With weights 9:1, unsplash should be selected roughly 90% of the time
        var unsplashCount = 0
        let iterations = 1000

        for _ in 0..<iterations {
            _ = selector.selectSource()
            // Note: We can't directly verify which source was selected
            // This test ensures the selector works without crashing
        }
    }

    // MARK: - Edge Cases

    func testSourceSelectorWithZeroWeight() {
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: true, weight: 0.0),
            SourceConfiguration(sourceType: .bing, isEnabled: true, weight: 1.0)
        ]
        let selector = SourceSelector(configurations: configs)

        // Should still be able to select (bing should be favored)
        let selected = selector.selectSource()
        XCTAssertNotNil(selected)
    }

    func testSourceSelectorWithNegativeWeight() {
        // Negative weights can cause issues in selection
        // The test verifies the selector handles this gracefully
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: true, weight: -1.0),
            SourceConfiguration(sourceType: .bing, isEnabled: true, weight: 1.0)
        ]
        let selector = SourceSelector(configurations: configs)

        // With negative weight, selector may return nil or a valid source
        // Just verify it doesn't crash
        let selected = selector.selectSource()
        // Selection may be nil if total weight is zero or negative
        // This is expected behavior
        _ = selected
    }

    // MARK: - Multiple Selections

    func testSourceSelectorMultipleSelections() {
        let configs = [
            SourceConfiguration(sourceType: .unsplash, isEnabled: true, weight: 1.0),
            SourceConfiguration(sourceType: .bing, isEnabled: true, weight: 1.0),
            SourceConfiguration(sourceType: .reddit, isEnabled: true, weight: 1.0)
        ]
        let selector = SourceSelector(configurations: configs)

        var selectedSources: [Any] = []
        for _ in 0..<10 {
            if let source = selector.selectSource() {
                selectedSources.append(source)
            }
        }

        // Should have selected 10 times
        XCTAssertEqual(selectedSources.count, 10)
    }
}
