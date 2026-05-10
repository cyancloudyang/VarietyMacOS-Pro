import Foundation
import SwiftData

@MainActor
enum DataContainer {
    static let schema = Schema([
        Wallpaper.self,
        HistoryEntry.self,
        FavoriteEntry.self,
        AppPreferences.self,
        SourceConfig.self,
    ])

    static let modelContainer: ModelContainer = {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    static func ensureDefaults(in context: ModelContext) {
        let descriptor = FetchDescriptor<AppPreferences>()
        if (try? context.fetchCount(descriptor)) == 0 {
            let prefs = AppPreferences()
            context.insert(prefs)
        }

        let sourceDescriptor = FetchDescriptor<SourceConfig>()
        if (try? context.fetchCount(sourceDescriptor)) == 0 {
            let configs = SourceConfigFactory.allDefaultConfigs()
            for config in configs {
                context.insert(config)
            }
        }

        try? context.save()
    }
}
