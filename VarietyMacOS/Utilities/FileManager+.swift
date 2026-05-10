import Foundation

// MARK: - FileManager Extensions

extension FileManager {
    /// Check if file exists and is readable
    func fileExistsAndIsReadable(at url: URL) -> Bool {
        fileExists(atPath: url.path) && isReadableFile(atPath: url.path)
    }
    
    /// Check if file exists and is writable
    func fileExistsAndIsWritable(at url: URL) -> Bool {
        fileExists(atPath: url.path) && isWritableFile(atPath: url.path)
    }
    
    /// Create directory if it doesn't exist
    @discardableResult
    func createDirectoryIfNeeded(at url: URL) -> Bool {
        if !fileExists(atPath: url.path) {
            do {
                try createDirectory(at: url, withIntermediateDirectories: true)
                return true
            } catch {
                Logger.error("Failed to create directory: \(error)")
                return false
            }
        }
        return true
    }
    
    /// Get file size
    func fileSize(at url: URL) -> UInt64? {
        guard let attributes = try? attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? UInt64 else {
            return nil
        }
        return size
    }
    
    /// Get directory size recursively
    func directorySize(at url: URL) -> UInt64 {
        var size: UInt64 = 0
        
        if let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = fileSize(at: fileURL) {
                    size += fileSize
                }
            }
        }
        
        return size
    }
    
    /// Format file size for display
    static func formatFileSize(_ size: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    /// Secure copy file
    func secureCopy(from source: URL, to destination: URL) throws {
        // Remove existing file if any
        if fileExists(atPath: destination.path) {
            try removeItem(at: destination)
        }
        
        // Copy with permissions
        try copyItem(at: source, to: destination)
        
        // Set appropriate permissions (readable/writable by user only)
        try setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
    }
    
    /// Move file with backup
    func moveWithBackup(from source: URL, to destination: URL) throws {
        let backupURL = destination.appendingPathExtension("backup")
        
        // Backup existing file
        if fileExists(atPath: destination.path) {
            if fileExists(atPath: backupURL.path) {
                try removeItem(at: backupURL)
            }
            try moveItem(at: destination, to: backupURL)
        }
        
        // Move new file
        try moveItem(at: source, to: destination)
        
        // Remove backup on success
        if fileExists(atPath: backupURL.path) {
            try removeItem(at: backupURL)
        }
    }
    
    /// Get temporary file URL
    func temporaryFile(named name: String? = nil) -> URL {
        let filename = name ?? UUID().uuidString
        return temporaryDirectory.appendingPathComponent(filename)
    }
    
    /// Clean up temporary files
    func cleanupTemporaryFiles(olderThan age: TimeInterval = 86400) {
        let cutoffDate = Date().addingTimeInterval(-age)
        
        if let enumerator = enumerator(at: temporaryDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let attributes = try attributesOfItem(atPath: fileURL.path)
                    if let modificationDate = attributes[.modificationDate] as? Date,
                       modificationDate < cutoffDate {
                        try removeItem(at: fileURL)
                    }
                } catch {
                    Logger.warning("Failed to cleanup temp file: \(error)")
                }
            }
        }
    }
    
    /// Get available disk space
    func availableDiskSpace() -> UInt64? {
        do {
            let attributes = try attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemFreeSize] as? UInt64
        } catch {
            Logger.error("Failed to get disk space: \(error)")
            return nil
        }
    }
    
    /// Check if there's enough disk space
    func hasEnoughDiskSpace(required: UInt64) -> Bool {
        guard let available = availableDiskSpace() else { return true }
        return available >= required
    }
}

// MARK: - URL Extensions

extension URL {
    /// File size
    var fileSize: UInt64? {
        FileManager.default.fileSize(at: self)
    }
    
    /// Is directory
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
    
    /// Is file
    var isFile: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
    }
    
    /// Exists
    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    /// Is readable
    var isReadable: Bool {
        FileManager.default.isReadableFile(atPath: path)
    }
    
    /// Is writable
    var isWritable: Bool {
        FileManager.default.isWritableFile(atPath: path)
    }
    
    /// Parent directory
    var parent: URL {
        deletingLastPathComponent()
    }
    
    /// Filename without extension
    var filenameWithoutExtension: String {
        deletingPathExtension().lastPathComponent
    }
    
    /// Extension (lowercase)
    var fileExtension: String {
        pathExtension.lowercased()
    }
    
    /// Add timestamp to filename
    func appendingTimestamp() -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let newName = "\(filenameWithoutExtension)_\(timestamp).\(pathExtension)"
        return parent.appendingPathComponent(newName)
    }
    
    /// Create intermediate directories
    func createIntermediateDirectories() throws {
        try FileManager.default.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )
    }
    
    /// Securely delete (overwrite then delete)
    func secureDelete() throws {
        guard exists else { return }
        
        // Overwrite with random data (basic implementation)
        if let fileSize = fileSize, fileSize > 0 {
            var data = Data(count: Int(fileSize))
            _ = data.withUnsafeMutableBytes { SecRandomCopyBytes(nil, $0.count, $0.baseAddress!) }
            try data.write(to: self, options: .atomic)
        }
        
        // Delete
        try FileManager.default.removeItem(at: self)
    }
}

// MARK: - Path Extensions

extension String {
    /// Expand tilde in path
    var expandingTilde: String {
        return NSString(string: self).expandingTildeInPath
    }
    
    /// Collapse home directory to tilde
    var collapsingTilde: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if hasPrefix(home) {
            return "~" + dropFirst(home.count)
        }
        return self
    }
    
    /// Sanitize filename
    var sanitizedFilename: String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Sandbox Security

enum SecurityScope {
    /// Start accessing security scoped resource
    static func access<T>(_ url: URL, block: () throws -> T) rethrows -> T {
        let shouldStopAccess = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try block()
    }
    
    /// Async version
    static func access<T>(_ url: URL, block: () async throws -> T) async rethrows -> T {
        let shouldStopAccess = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try await block()
    }
}
