import Foundation

/// Configuration for individual wallpaper sources
@available(macOS 13.0, *)
struct SourceConfig: Codable, Identifiable {
    let id: String
    var sourceType: WallpaperSourceType
    var isEnabled: Bool
    var weight: Double
    var settings: [String: String]
    
    init(
        sourceType: WallpaperSourceType,
        isEnabled: Bool = true,
        weight: Double = 1.0,
        settings: [String: String] = [:]
    ) {
        self.id = sourceType.rawValue
        self.sourceType = sourceType
        self.isEnabled = isEnabled
        self.weight = weight
        self.settings = settings
    }
}

// MARK: - Source Configuration Factory

@available(macOS 13.0, *)
enum SourceConfigFactory {
    /// Create default configuration for a source type
    static func defaultConfig(for type: WallpaperSourceType) -> SourceConfig {
        switch type {
        case .unsplash:
            return SourceConfig(
                sourceType: .unsplash,
                isEnabled: true,
                weight: 1.0,
                settings: [
                    "accessKey": "",
                    "collections": "",
                    "topics": "",
                    "orientation": "landscape"
                ]
            )
            
        case .bing:
            return SourceConfig(
                sourceType: .bing,
                isEnabled: true,
                weight: 1.0,
                settings: [
                    "market": "en-US",
                    "resolution": "UHD"
                ]
            )
            
        case .wallhaven:
            return SourceConfig(
                sourceType: .wallhaven,
                isEnabled: false,
                weight: 1.0,
                settings: [
                    "apiKey": "",
                    "searchQuery": "",
                    "categories": "111", // General, Anime, People
                    "purity": "100", // SFW only
                    "sorting": "random",
                    "atleast": "1920x1080"
                ]
            )
            
        case .artstation:
                    return SourceConfig(
                        sourceType: .artstation,
                        isEnabled: false,
                        weight: 1.0
                    )
                    
case .reddit:
            return SourceConfig(
                sourceType: .reddit,
                isEnabled: false,
                weight: 1.0,
                settings: [
                    "subreddits": "earthporn,CityPorn",
                    "sort": "hot",
                    "time": "day",
                    "minScore": "10"
                ]
            )
            
        case .local:
            return SourceConfig(
                sourceType: .local,
                isEnabled: false,
                weight: 1.0,
                settings: [
                    "folderPath": "",
                    "recursive": "true",
                    "shuffle": "true",
                    "supportedFormats": "jpg,jpeg,png,gif,bmp,tiff,webp,heic"
                ]
            )
        }
    }
    
    /// Create configurations for all sources
    static func allDefaultConfigs() -> [SourceConfig] {
        WallpaperSourceType.allCases.map { defaultConfig(for: $0) }
    }
}

// MARK: - Source Settings Helpers

@available(macOS 13.0, *)
extension SourceConfig {
    /// Get string setting
    func string(_ key: String, defaultValue: String = "") -> String {
        settings[key] ?? defaultValue
    }
    
    /// Get bool setting
    func bool(_ key: String, defaultValue: Bool = false) -> Bool {
        guard let value = settings[key] else { return defaultValue }
        return value.lowercased() == "true" || value == "1"
    }
    
    /// Get int setting
    func int(_ key: String, defaultValue: Int = 0) -> Int {
        guard let value = settings[key] else { return defaultValue }
        return Int(value) ?? defaultValue
    }
    
    /// Get double setting
    func double(_ key: String, defaultValue: Double = 0.0) -> Double {
        guard let value = settings[key] else { return defaultValue }
        return Double(value) ?? defaultValue
    }
    
    /// Get string array setting
    func stringArray(_ key: String, separator: Character = ",") -> [String] {
        guard let value = settings[key], !value.isEmpty else { return [] }
        return value.split(separator: separator).map(String.init)
    }
    
    /// Set string setting
    mutating func set(_ key: String, value: String) {
        settings[key] = value
    }
    
    /// Set bool setting
    mutating func set(_ key: String, value: Bool) {
        settings[key] = value ? "true" : "false"
    }
    
    /// Set int setting
    mutating func set(_ key: String, value: Int) {
        settings[key] = String(value)
    }
    
    /// Set double setting
    mutating func set(_ key: String, value: Double) {
        settings[key] = String(value)
    }
    
    /// Set string array setting
    mutating func set(_ key: String, values: [String], separator: String = ",") {
        settings[key] = values.joined(separator: separator)
    }
}

// MARK: - Source Configuration Manager

@available(macOS 13.0, *)
final class SourceConfigManager: ObservableObject {
    static let shared = SourceConfigManager()
    
    @Published var configs: [SourceConfig] = []
    
    private let persistence = Persistence.shared
    private let configsKey = "source_configs"
    
    private init() {
        loadConfigs()
    }
    
    /// Load configurations from persistence
    func loadConfigs() {
        if let data = persistence.data(forKey: configsKey),
           let decoded = try? JSONDecoder().decode([SourceConfig].self, from: data) {
            configs = decoded
        } else {
            configs = SourceConfigFactory.allDefaultConfigs()
            saveConfigs()
        }
    }
    
    /// Save configurations to persistence
    func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            persistence.set(data, forKey: configsKey)
        }
    }
    
    /// Get configuration for a source type
    func config(for type: WallpaperSourceType) -> SourceConfig? {
        configs.first { $0.sourceType == type }
    }
    
    /// Update configuration
    func updateConfig(_ config: SourceConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            saveConfigs()
        }
    }
    
    /// Reset to defaults
    func resetToDefaults() {
        configs = SourceConfigFactory.allDefaultConfigs()
        saveConfigs()
    }
    
    /// Get enabled sources
    func enabledSources() -> [SourceConfig] {
        configs.filter { $0.isEnabled }
    }
    
    /// Select a random source based on weights
    func randomSource() -> WallpaperSourceType? {
        let enabled = enabledSources()
        guard !enabled.isEmpty else { return nil }
        
        let totalWeight = enabled.reduce(0.0) { $0 + $1.weight }
        let randomValue = Double.random(in: 0..<totalWeight)
        
        var cumulativeWeight: Double = 0
        for config in enabled {
            cumulativeWeight += config.weight
            if randomValue < cumulativeWeight {
                return config.sourceType
            }
        }
        
        return enabled.last?.sourceType
    }
}
