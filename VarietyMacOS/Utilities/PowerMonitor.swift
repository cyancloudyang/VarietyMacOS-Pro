import Foundation
import IOKit.ps

/// Monitors power state (battery vs AC power)
@MainActor
final class PowerMonitor: ObservableObject {
    static let shared = PowerMonitor()
    
    @Published var isOnBattery: Bool = false
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    
    private init() {
        updatePowerState()
    }
    
    /// Start monitoring power state changes
    func startMonitoring() {
        // Start a timer to poll every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePowerState()
            }
        }
    }
    
    /// Update current power state
    func updatePowerState() {
        let powerSources = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard powerSources != nil else {
            isOnBattery = false
            batteryLevel = 100
            isCharging = false
            return
        }
        
        if let sources = IOPSCopyPowerSourcesList(powerSources)?.takeRetainedValue() as? [CFTypeRef],
           let source = sources.first,
           let description = IOPSGetPowerSourceDescription(powerSources, source)?.takeUnretainedValue() as? [String: Any] {
            
            // Check if on battery
            if let isChargingDesc = description[kIOPSIsChargingKey] as? Bool {
                isCharging = isChargingDesc
            }
            
            // Check current capacity
            if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                batteryLevel = capacity
            }
            
            // Check power source state
            if let state = description[kIOPSPowerSourceStateKey] as? String {
                isOnBattery = (state == "Battery Power")
            }
        }
        
        objectWillChange.send()
    }
    
    /// Check if currently on battery and should pause
    func shouldPauseOnBattery() -> Bool {
        isOnBattery && batteryLevel < 20  // Pause if on battery and below 20%
    }
}
