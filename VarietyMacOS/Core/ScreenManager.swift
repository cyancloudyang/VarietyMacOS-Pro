import Foundation
import AppKit
import Combine
import UserNotifications

/// Manages screen detection and configuration
@available(macOS 13.0, *)
final class ScreenManager: ObservableObject {
    static let shared = ScreenManager()
    
    @Published var availableScreens: [NSScreen] = []
    @Published var selectedScreen: NSScreen?
    @Published var screenConfigurations: [ScreenConfiguration] = []
    private var cancellables = Set<AnyCancellable>()
    
    /// Notification name for screen configuration changes
    static let screenConfigurationDidChange = Notification.Name("ScreenConfigurationDidChange")
    
    private init() {
        refreshScreens()
        setupObservers()
    }
    
    // MARK: - Screen Management
    
    /// Refresh the list of available screens
    func refreshScreens() {
        availableScreens = NSScreen.screens
        
        // Update selected screen if it's no longer available
        if let selected = selectedScreen, !availableScreens.contains(selected) {
            selectedScreen = availableScreens.first
        }
        
        // Set default if no screen selected
        if selectedScreen == nil {
            selectedScreen = availableScreens.first
        }
        
        updateConfigurations()
    }
    
    /// Get the main screen
    var mainScreen: NSScreen? { NSScreen.main }
    
    /// Get all screen IDs
    var screenIDs: [CGDirectDisplayID] {
        availableScreens.compactMap { screen in
            guard let screenNumber = screen.deviceDescription[.init("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            return CGDirectDisplayID(screenNumber.uint32Value)
        }
    }
    
    /// Get screen by ID
    func screen(withID id: CGDirectDisplayID) -> NSScreen? {
        availableScreens.first { screen in
            guard let screenNumber = screen.deviceDescription[.init("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return CGDirectDisplayID(screenNumber.uint32Value) == id
        }
    }
    
    /// Get screen resolution
    func resolution(for screen: NSScreen) -> CGSize {
        screen.frame.size
    }
    
    /// Get screen scale factor
    func scaleFactor(for screen: NSScreen) -> CGFloat {
        screen.backingScaleFactor
    }
    
    /// Get the best image size for a screen
    func optimalImageSize(for screen: NSScreen) -> CGSize {
        let resolution = resolution(for: screen)
        let scale = scaleFactor(for: screen)
        return CGSize(
            width: resolution.width * scale,
            height: resolution.height * scale
        )
    }
    
    // MARK: - Configuration
    
    /// Update screen configurations
    private func updateConfigurations() {
        screenConfigurations = availableScreens.map { screen in
            ScreenConfiguration(
                screen: screen,
                resolution: resolution(for: screen),
                scaleFactor: scaleFactor(for: screen)
            )
        }
    }
    
    /// Save configuration for a screen
    func saveConfiguration(for screenID: CGDirectDisplayID, wallpaperID: String) {
        var configs = Preferences.shared.screenConfigurations
        configs["\(screenID)"] = wallpaperID
        Preferences.shared.screenConfigurations = configs
    }
    
    /// Get saved configuration for a screen
    func configuration(for screenID: CGDirectDisplayID) -> String? {
        Preferences.shared.screenConfigurations["\(screenID)"]
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Observe screen configuration changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.refreshScreens()
                NotificationCenter.default.post(name: Self.screenConfigurationDidChange, object: nil)
            }
            .store(in: &cancellables)
        
        // Observe workspace notifications
        NotificationCenter.default.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .sink { [weak self] _ in
                self?.refreshScreens()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Screen Configuration

/// Represents a screen configuration
@available(macOS 13.0, *)
struct ScreenConfiguration: Identifiable, Codable {
    let id: CGDirectDisplayID
    let resolution: CGSize
    let scaleFactor: CGFloat
    
    init(screen: NSScreen, resolution: CGSize, scaleFactor: CGFloat) {
        if let screenNumber = screen.deviceDescription[.init("NSScreenNumber")] as? NSNumber {
            self.id = CGDirectDisplayID(screenNumber.uint32Value)
        } else {
            self.id = 0
        }
        self.resolution = resolution
        self.scaleFactor = scaleFactor
    }
}

// MARK: - NSScreen Extensions

@available(macOS 13.0, *)
extension NSScreen: @retroactive Identifiable {
    public var id: String {
        guard let screenNumber = deviceDescription[.init("NSScreenNumber")] as? NSNumber else {
            return UUID().uuidString
        }
        return "\(screenNumber.uint32Value)"
    }
    
    var displayName: String {
        localizedName
    }
}
