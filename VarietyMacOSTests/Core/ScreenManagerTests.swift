import Foundation
import XCTest
@testable import VarietyMacOS

/// Tests for ScreenManager
final class ScreenManagerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testScreenManagerShared() {
        let manager1 = ScreenManager.shared
        let manager2 = ScreenManager.shared
        XCTAssert(manager1 === manager2)
    }

    // MARK: - Screen Detection Tests

    func testAvailableScreens() {
        let manager = ScreenManager.shared
        XCTAssertGreaterThan(manager.availableScreens.count, 0)
    }

    func testSelectedScreen() {
        let manager = ScreenManager.shared
        if !manager.availableScreens.isEmpty {
            XCTAssertNotNil(manager.selectedScreen)
        }
    }

    func testRefreshScreens() {
        let manager = ScreenManager.shared
        manager.refreshScreens()
        XCTAssertGreaterThan(manager.availableScreens.count, 0)
    }

    // MARK: - Screen Properties Tests

    func testMainScreen() {
        let manager = ScreenManager.shared
        // Main screen may be nil in testing environment
        // Just verify the property is accessible
        XCTAssertNotNil(manager.mainScreen ?? nil)
    }

    func testScreenIDs() {
        let manager = ScreenManager.shared
        let screenIDs = manager.screenIDs
        XCTAssertEqual(screenIDs.count, manager.availableScreens.count)
    }

    // MARK: - Resolution Tests

    func testResolution() {
        let manager = ScreenManager.shared
        let screen = manager.availableScreens.first!

        let resolution = manager.resolution(for: screen)
        XCTAssertGreaterThan(resolution.width, 0)
        XCTAssertGreaterThan(resolution.height, 0)
    }

    func testScaleFactor() {
        let manager = ScreenManager.shared
        let screen = manager.availableScreens.first!

        let scaleFactor = manager.scaleFactor(for: screen)
        XCTAssertGreaterThan(scaleFactor, 0)
    }

    func testOptimalImageSize() {
        let manager = ScreenManager.shared
        let screen = manager.availableScreens.first!

        let optimalSize = manager.optimalImageSize(for: screen)
        XCTAssertGreaterThan(optimalSize.width, 0)
        XCTAssertGreaterThan(optimalSize.height, 0)
    }

    // MARK: - Screen Configuration Tests

    func testScreenConfigurationInit() {
        let screen = NSScreen.main!
        let config = ScreenConfiguration(
            screen: screen,
            resolution: CGSize(width: 1920, height: 1080),
            scaleFactor: 2.0
        )

        XCTAssertEqual(config.resolution, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(config.scaleFactor, 2.0)
    }

    // MARK: - NSScreen Extension Tests

    func testNSScreenId() {
        let screen = NSScreen.main!
        XCTAssertFalse(screen.id.isEmpty)
    }

    func testNSScreenDisplayName() {
        let screen = NSScreen.main!
        XCTAssertFalse(screen.displayName.isEmpty)
    }

    // MARK: - Screen Identification Tests

    func testScreenWithID() {
        let manager = ScreenManager.shared
        let screens = manager.availableScreens

        if let firstScreen = screens.first {
            if let screenNumber = firstScreen.deviceDescription[.init("NSScreenNumber")] as? NSNumber {
                let screenID = CGDirectDisplayID(screenNumber.uint32Value)
                let foundScreen = manager.screen(withID: screenID)
                XCTAssertNotNil(foundScreen)
            }
        }
    }

    // MARK: - Multi-Screen Tests

    func testMultipleScreens() {
        let manager = ScreenManager.shared
        let screens = manager.availableScreens

        // Verify all screens have valid properties
        for screen in screens {
            let resolution = manager.resolution(for: screen)
            XCTAssertGreaterThan(resolution.width, 0)
            XCTAssertGreaterThan(resolution.height, 0)

            let scaleFactor = manager.scaleFactor(for: screen)
            XCTAssertGreaterThan(scaleFactor, 0)
        }
    }
}
