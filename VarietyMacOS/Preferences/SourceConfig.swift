import Foundation
import SwiftData

/// Configuration for individual wallpaper sources
@Model
final class SourceConfig {
    var id: String
    var sourceType: WallpaperSourceType
    var isEnabled: Bool
    var weight: Double
    var settings: [String: String]

    init(
        id: String = "",
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

    // MARK: - Source Settings Helpers

    func string(_ key: String, defaultValue: String = "") -> String {
        settings[key] ?? defaultValue
    }

    func bool(_ key: String, defaultValue: Bool = false) -> Bool {
        guard let value = settings[key] else { return defaultValue }
        return value.lowercased() == "true" || value == "1"
    }

    func int(_ key: String, defaultValue: Int = 0) -> Int {
        guard let value = settings[key] else { return defaultValue }
        return Int(value) ?? defaultValue
    }

    func double(_ key: String, defaultValue: Double = 0.0) -> Double {
        guard let value = settings[key] else { return defaultValue }
        return Double(value) ?? defaultValue
    }

    func stringArray(_ key: String, separator: Character = ",") -> [String] {
        guard let value = settings[key], !value.isEmpty else { return [] }
        return value.split(separator: separator).map(String.init)
    }

    func set(_ key: String, value: String) {
        settings[key] = value
    }

    func set(_ key: String, value: Bool) {
        settings[key] = value ? "true" : "false"
    }

    func set(_ key: String, value: Int) {
        settings[key] = String(value)
    }

    func set(_ key: String, value: Double) {
        settings[key] = String(value)
    }

    func set(_ key: String, values: [String], separator: String = ",") {
        settings[key] = values.joined(separator: separator)
    }
}

// MARK: - Source Configuration Factory

enum SourceConfigFactory {
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
                    "categories": "111",
                    "purity": "100",
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

    static func allDefaultConfigs() -> [SourceConfig] {
        WallpaperSourceType.allCases.map { defaultConfig(for: $0) }
    }
}

// MARK: - Source Configuration Manager

@MainActor
final class SourceConfigManager: ObservableObject {
    @Published var configs: [SourceConfig] = []

    private var modelContext: ModelContext?

    static let shared = SourceConfigManager()

    private init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadConfigs()
    }

    func loadConfigs() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<SourceConfig>(
            sortBy: [SortDescriptor(\.id)]
        )
        if let result = try? context.fetch(descriptor), !result.isEmpty {
            configs = result
        } else {
            configs = SourceConfigFactory.allDefaultConfigs()
            for config in configs {
                context.insert(config)
            }
            try? context.save()
        }
    }

    func saveConfigs() {
        guard let context = modelContext else { return }
        try? context.save()
    }

    func config(for type: WallpaperSourceType) -> SourceConfig? {
        configs.first { $0.sourceType == type }
    }

    func updateConfig(_ config: SourceConfig) {
        guard let context = modelContext else { return }
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            try? context.save()
        }
    }

    func resetToDefaults() {
        guard let context = modelContext else { return }
        for config in configs {
            context.delete(config)
        }
        configs = SourceConfigFactory.allDefaultConfigs()
        for config in configs {
            context.insert(config)
        }
        try? context.save()
    }

    func enabledSources() -> [SourceConfig] {
        configs.filter { $0.isEnabled }
    }

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
