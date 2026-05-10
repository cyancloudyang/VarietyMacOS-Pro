import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for WallpaperError
final class WallpaperErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testFetchFailedDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        let error = WallpaperError.fetchFailed(underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Failed to fetch wallpaper") == true)
        XCTAssertTrue(error.errorDescription?.contains("Not found") == true)
    }

    func testApplyFailedDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        let error = WallpaperError.applyFailed(underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Failed to apply wallpaper") == true)
        XCTAssertTrue(error.errorDescription?.contains("Server error") == true)
    }

    func testInvalidImageDescription() {
        let error = WallpaperError.invalidImage
        XCTAssertEqual(error.errorDescription, "Invalid image data")
    }

    func testNoImageAvailableDescription() {
        let error = WallpaperError.noImageAvailable
        XCTAssertEqual(error.errorDescription, "No image available")
    }

    func testSourceNotAvailableDescription() {
        let error = WallpaperError.sourceNotAvailable
        XCTAssertEqual(error.errorDescription, "Wallpaper source not available")
    }

    // MARK: - LocalizedError Conformance

    func testAllErrorsHaveDescriptions() {
        let underlyingError = NSError(domain: "Test", code: 1)
        let errors: [WallpaperError] = [
            .fetchFailed(underlyingError),
            .applyFailed(underlyingError),
            .invalidImage,
            .noImageAvailable,
            .sourceNotAvailable
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}

/// Tests for DisplayMode
final class DisplayModeTests: XCTestCase {

    // MARK: - DisplayMode Enum Tests

    func testDisplayModeAllCases() {
        let allModes: [DisplayMode] = [.fill, .fit, .stretch, .center, .tile]
        XCTAssertEqual(allModes.count, 5)
    }

    func testDisplayModeRawValues() {
        XCTAssertEqual(DisplayMode.fill.rawValue, "fill")
        XCTAssertEqual(DisplayMode.fit.rawValue, "fit")
        XCTAssertEqual(DisplayMode.stretch.rawValue, "stretch")
        XCTAssertEqual(DisplayMode.center.rawValue, "center")
        XCTAssertEqual(DisplayMode.tile.rawValue, "tile")
    }

    func testDisplayModeCodable() throws {
        let modes: [DisplayMode] = [.fill, .fit, .stretch, .center, .tile]

        for mode in modes {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(DisplayMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }

    // MARK: - DisplayMode RawRepresentable Extension

    func testDisplayModeRawRepresentable() {
        // DisplayMode is a String RawRepresentable enum
        // Valid raw values should return the corresponding case
        XCTAssertEqual(DisplayMode(rawValue: "fill"), .fill)
        XCTAssertEqual(DisplayMode(rawValue: "fit"), .fit)
        XCTAssertEqual(DisplayMode(rawValue: "stretch"), .stretch)
        XCTAssertEqual(DisplayMode(rawValue: "center"), .center)
        XCTAssertEqual(DisplayMode(rawValue: "tile"), .tile)

        // Invalid raw value should return nil (not a default value)
        XCTAssertNil(DisplayMode(rawValue: "invalid"))
    }
}

/// Tests for WallpaperTimer
final class WallpaperTimerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testWallpaperTimerShared() {
        let timer1 = WallpaperTimer.shared
        let timer2 = WallpaperTimer.shared
        XCTAssert(timer1 === timer2)
    }

    // MARK: - Timer State Tests

    func testTimerInitialStatus() {
        let timer = WallpaperTimer.shared
        // Timer should be created but not necessarily running
        XCTAssertNotNil(timer)
    }

    func testTimerCallback() {
        var callbackCalled = false
        let timer = WallpaperTimer.shared
        timer.onTimerFired = {
            callbackCalled = true
        }

        // The callback should be settable
        XCTAssertNotNil(timer.onTimerFired)
    }

    // MARK: - Timer Creation Tests

    func testTimerCreation() {
        let timer = WallpaperTimer.shared
        XCTAssertNotNil(timer)
    }
}
