import Foundation
import os.log

/// Simple logging utility for the app
enum Logger: Sendable {
    private static let osLog = OSLog(subsystem: "com.variety.app", category: "General")
    
    /// Log level
    enum Level: String, CaseIterable, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        
        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            }
        }
    }
    
    /// Minimum log level (can be configured)
    nonisolated(unsafe) static var minimumLevel: Level = .debug

    /// Enable console logging
    nonisolated(unsafe) static var enableConsoleLogging: Bool = true

    /// Enable file logging
    nonisolated(unsafe) static var enableFileLogging: Bool = false
    
    /// Log file URL
    static var logFileURL: URL? {
        let docs = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent("Variety/Logs/app.log")
    }
    
    // MARK: - Log Methods
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    static func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log(error.localizedDescription, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private static func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        // Check minimum level
        guard shouldLog(level: level) else { return }
        
        let timestamp = formattedTimestamp()
        let filename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(filename):\(line)] \(message)"
        
        // OS Log
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // Console
        if enableConsoleLogging {
            print(logMessage)
        }
        
        // File
        if enableFileLogging {
            writeToFile(logMessage)
        }
    }
    
    private static func shouldLog(level: Level) -> Bool {
        let levels = Level.allCases
        guard let minIndex = levels.firstIndex(of: minimumLevel),
              let currentIndex = levels.firstIndex(of: level) else {
            return true
        }
        return currentIndex >= minIndex
    }
    
    private static func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    private static func writeToFile(_ message: String) {
        guard let url = logFileURL else { return }
        
        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Append to file
        let logLine = message + "\n"
        if let data = logLine.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let fileHandle = try? FileHandle(forWritingTo: url) {
                    _ = fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: url)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clear log file
    static func clearLogFile() {
        guard let url = logFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Get log file contents
    static func logFileContents() -> String? {
        guard let url = logFileURL else { return nil }
        return try? String(contentsOf: url)
    }
    
    /// Get log file size
    static func logFileSize() -> UInt64 {
        guard let url = logFileURL else { return 0 }
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? UInt64 else {
            return 0
        }
        return size
    }
}

// MARK: - Debug Helpers

extension Logger {
    /// Log object description for debugging
    static func dump<T>(_ value: T, name: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let description = String(describing: value)
        let prefix = name.map { "\($0): " } ?? ""
        debug("\(prefix)\(description)", file: file, function: function, line: line)
    }
    
    /// Log method entry
    static func enter(file: String = #file, function: String = #function, line: Int = #line) {
        debug("Entering \(function)", file: file, function: function, line: line)
    }
    
    /// Log method exit
    static func exit(file: String = #file, function: String = #function, line: Int = #line) {
        debug("Exiting \(function)", file: file, function: function, line: line)
    }
}
