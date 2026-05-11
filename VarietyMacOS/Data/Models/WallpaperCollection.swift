import Foundation
import SwiftData

/// User-created collection for grouping wallpapers
@Model
final class WallpaperCollection {
    var id: String
    var name: String
    var collectionDescription: String?
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .nullify)
    var wallpapers: [Wallpaper]

    init(
        id: String = UUID().uuidString,
        name: String,
        collectionDescription: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.collectionDescription = collectionDescription
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.wallpapers = []
    }
}