import Foundation

/// Aggregates all pause conditions for wallpaper auto-change
@MainActor
final class ConditionalPauseManager {
    static let shared = ConditionalPauseManager()
    
    private let powerMonitor = PowerMonitor.shared
    private let appMonitor = AppMonitor.shared
    
    private init() {}
    
    /// Start all monitors
    func startMonitoring() {
        powerMonitor.startMonitoring()
        appMonitor.startMonitoring()
    }
    
    /// Check if wallpaper changes should be paused
    func shouldPause() -> Bool {
        // Check battery condition
        if powerMonitor.shouldPauseOnBattery() {
            return true
        }
        
        // Check app condition
        if appMonitor.shouldPauseForApp() {
            return true
        }
        
        return false
    }
    
    /// Get list of active pause conditions
    func getActiveConditions() -> [String] {
        var conditions: [String] = []
        
        if powerMonitor.shouldPauseOnBattery() {
            conditions.append("On battery (\(powerMonitor.batteryLevel)%)")
        }
        
        if appMonitor.isPresentationMode {
            conditions.append("Presentation mode")
        }
        
        if appMonitor.isGaming {
            conditions.append("Gaming/Video mode")
        }
        
        return conditions
    }
}
