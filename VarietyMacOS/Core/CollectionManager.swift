import Foundation
import SwiftData

@MainActor
final class CollectionManager: ObservableObject {
    static let shared = CollectionManager()
    
    @Published var collections: [WallpaperCollection] = []
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
        fetchCollections()
    }
    
    func fetchCollections() {
        guard let context = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<WallpaperCollection>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        collections = (try? context.fetch(fetchDescriptor)) ?? []
    }
    
    func create(name: String, description: String? = nil) -> WallpaperCollection {
        let collection = WallpaperCollection(name: name, collectionDescription: description)
        modelContext?.insert(collection)
        try? modelContext?.save()
        fetchCollections()
        return collection
    }
    
    func delete(_ collection: WallpaperCollection) {
        modelContext?.delete(collection)
        try? modelContext?.save()
        fetchCollections()
    }
    
    func addWallpaper(_ wallpaper: Wallpaper, to collection: WallpaperCollection) {
        guard !collection.wallpapers.contains(where: { $0.id == wallpaper.id }) else { return }
        collection.wallpapers.append(wallpaper)
        try? modelContext?.save()
        fetchCollections()
    }
    
    func removeWallpaper(_ wallpaper: Wallpaper, from collection: WallpaperCollection) {
        collection.wallpapers.removeAll { $0.id == wallpaper.id }
        try? modelContext?.save()
        fetchCollections()
    }
}