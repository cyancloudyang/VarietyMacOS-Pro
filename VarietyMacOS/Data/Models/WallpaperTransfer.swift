//
// WallpaperTransfer.swift
// VarietyMacOS
//
// Transferable wrapper for Wallpaper drag & drop
//

import Foundation
import SwiftData

/// Transferable wrapper for Wallpaper to support drag & drop
struct WallpaperTransfer: Codable, Transferable {
    let wallpaperId: String
    
    init(wallpaper: Wallpaper) {
        self.wallpaperId = wallpaper.id
    }
    
    /// Resolve to actual Wallpaper from database
    func resolve(in modelContext: ModelContext) -> Wallpaper? {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { $0.id == wallpaperId }
        )
        return try? modelContext.fetch(descriptor).first
    }
}
