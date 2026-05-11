import Foundation
import Combine

/// Timer manager for automatic wallpaper changes
@MainActor
final class WallpaperTimer: ObservableObject {
    static let shared = WallpaperTimer()
    
    @Published var isRunning: Bool = false
    @Published var timeUntilNextChange: TimeInterval = 0
    @Published var nextChangeDate: Date?
    
    private nonisolated(unsafe) var timer: Timer?
    private nonisolated(unsafe) var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    /// Callback to execute when timer fires
    var onTimerFired: (() -> Void)?
    
    /// Timer interval in seconds (dynamic from schedule rules)
    private var interval: TimeInterval {
        Preferences.shared.getCurrentInterval()
    }
    
    private init() {
        setupPreferenceObservers()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    // MARK: - Timer Control
    
    /// Start the wallpaper change timer
    func start(interval: TimeInterval? = nil) {
        stop()
        
        // Use provided interval or read from preferences (which may use schedule rules)
        let currentInterval = interval ?? Preferences.shared.getCurrentInterval()
        timer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fireTimer()
            }
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
        isRunning = true
        nextChangeDate = Date().addingTimeInterval(currentInterval)
        updateCountdown()
        
        Logger.info("Wallpaper timer started with interval: \(formatInterval(currentInterval))")
    }
    
    /// Stop the timer
    func stop() {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        isRunning = false
        nextChangeDate = nil
        timeUntilNextChange = 0
        
        Logger.info("Wallpaper timer stopped")
    }
    
    /// Pause the timer temporarily
    func pause() {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        isRunning = false
        
        Logger.info("Wallpaper timer paused")
    }
    
    /// Resume the timer
    func resume() {
        start()
    }
    
    /// Toggle timer state
    func toggle() {
        if isRunning {
            pause()
        } else {
            resume()
        }
    }
    
    /// Reset the timer (re-reads interval from preferences)
    func reset() {
        if isRunning {
            start()
        }
    }
    
    /// Skip to next wallpaper immediately and reset timer
    func skip() {
        fireTimer()
        if isRunning {
            start()
        }
    }
    
    // MARK: - Timer Events
    
    private func fireTimer() {
        Logger.info("Timer fired - changing wallpaper")
        onTimerFired?()
        nextChangeDate = Date().addingTimeInterval(interval)
    }
    
    private func updateCountdown() {
        guard let nextDate = nextChangeDate else {
            timeUntilNextChange = 0
            return
        }
        timeUntilNextChange = max(0, nextDate.timeIntervalSinceNow)
    }
    
    // MARK: - Preference Observers
    
    private func setupPreferenceObservers() {
        Preferences.shared.$appPreferences
            .dropFirst()
            .sink { [weak self] newPrefs in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let newInterval = newPrefs.getCurrentInterval()
                    if self.isRunning {
                        self.start(interval: newInterval)
                    }
                    // If not running, interval is automatically read from preferences on next start()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Utilities
    
    /// Format time interval for display
    func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// Format remaining time until next change
    var formattedTimeUntilNextChange: String {
        if !isRunning {
            return "Paused"
        }
        return formatInterval(timeUntilNextChange)
    }
    
    /// Get progress percentage (0.0 to 1.0)
    var progress: Double {
        guard isRunning, interval > 0 else { return 0 }
        return 1.0 - (timeUntilNextChange / interval)
    }
}

// MARK: - Notification Extensions

extension WallpaperTimer {
    /// Notification posted when timer fires
    static let timerFired = Notification.Name("WallpaperTimerFired")
    
    /// Notification posted when timer state changes
    static let timerStateChanged = Notification.Name("WallpaperTimerStateChanged")
}
