import Foundation

/// Handles data persistence using UserDefaults and file storage
@available(macOS 13.0, *)
final class Persistence {
    static let shared = Persistence()
    
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    /// Base directory for file storage
    private var appSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Variety")
    }
    
    private init() {
        createDirectories()
    }
    
    // MARK: - UserDefaults Methods
    
    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    
    func value(forKey key: String) -> Any? {
        defaults.object(forKey: key)
    }
    
    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }
    
    func integer(forKey key: String) -> Int {
        defaults.integer(forKey: key)
    }
    
    func double(forKey key: String) -> Double {
        defaults.double(forKey: key)
    }
    
    func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }
    
    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }
    
    func array(forKey key: String) -> [Any]? {
        defaults.array(forKey: key)
    }
    
    func dictionary(forKey key: String) -> [String: Any]? {
        defaults.dictionary(forKey: key)
    }
    
    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
    
    func exists(key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }
    
    // MARK: - Codable Methods
    
    func save<T: Codable>(_ object: T, forKey key: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(object)
            defaults.set(data, forKey: key)
            return true
        } catch {
            Logger.error("Failed to save: \(error)")
            return false
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            Logger.error("Failed to load: \(error)")
            return nil
        }
    }
    
    // MARK: - File Storage Methods
    
    func saveData(_ data: Data, to filename: String) throws {
        let url = appSupportDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
    }
    
    func loadData(from filename: String) -> Data? {
        let url = appSupportDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }
    
    func deleteFile(_ filename: String) throws {
        let url = appSupportDirectory.appendingPathComponent(filename)
        try fileManager.removeItem(at: url)
    }
    
    func fileExists(_ filename: String) -> Bool {
        let url = appSupportDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }
    
    func fileURL(for filename: String) -> URL {
        appSupportDirectory.appendingPathComponent(filename)
    }
    
    // MARK: - Directory Management
    
    private func createDirectories() {
        try? fileManager.createDirectory(
            at: appSupportDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func storageSize() -> UInt64 {
        var size: UInt64 = 0
        if let enumerator = fileManager.enumerator(at: appSupportDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? UInt64 {
                    size += fileSize
                }
            }
        }
        return size
    }
    
    func clearAll() {
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.hasPrefix("variety_") {
                defaults.removeObject(forKey: key)
            }
        }
        try? fileManager.removeItem(at: appSupportDirectory)
        createDirectories()
    }
    
    func clearCache() {
        let cacheDir = appSupportDirectory.appendingPathComponent("Cache")
        try? fileManager.removeItem(at: cacheDir)
    }
}

// MARK: - Persistence Keys

extension Persistence {
    enum Keys {
        static let preferences = "variety_preferences"
        static let history = "variety_history"
        static let favorites = "variety_favorites"
        static let cache = "variety_cache"
    }
}
