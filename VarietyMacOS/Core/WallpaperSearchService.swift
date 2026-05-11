import Foundation
import SwiftData

@MainActor
final class WallpaperSearchService {
    static let shared = WallpaperSearchService()

    func search(
        query: String,
        context: ModelContext
    ) throws -> [Wallpaper] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else {
            return try fetchAll(context: context)
        }

        // Use #Predicate with localizedStandardContains (case + diacritic insensitive)
        // #Predicate does not support localizedCaseInsensitiveContains or NSPredicate
        let predicate = #Predicate<Wallpaper> { wallpaper in
            (wallpaper.title != nil && wallpaper.title!.localizedStandardContains(trimmedQuery))
            || (wallpaper.author != nil && wallpaper.author!.localizedStandardContains(trimmedQuery))
            || (wallpaper.wallpaperDescription != nil && wallpaper.wallpaperDescription!.localizedStandardContains(trimmedQuery))
        }

        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    private func fetchAll(context: ModelContext) throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
