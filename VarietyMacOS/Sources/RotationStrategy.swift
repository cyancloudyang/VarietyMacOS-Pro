import Foundation

/// Rotation strategy for selecting the next wallpaper source
enum RotationStrategy: String, CaseIterable, Codable, Sendable {
    case roundRobin = "Round Robin"
    case weightedRandom = "Weighted Random"
    case smartRating = "Smart (Rating-Based)"
    case random = "Pure Random"
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .roundRobin:
            return "Cycle through enabled sources in order"
        case .weightedRandom:
            return "Select sources based on configured weights"
        case .smartRating:
            return "Favor sources with higher user ratings"
        case .random:
            return "Completely random selection"
        }
    }
}

/// Protocol for source selection strategies
@MainActor
protocol RotationStrategySelector {
    func selectSource(
        enabledSources: [WallpaperSourceType],
        recentHistory: [Wallpaper]
    ) -> WallpaperSource
}

// MARK: - Round Robin Selector

@MainActor
final class RoundRobinSelector: RotationStrategySelector {
    private static var lastIndex: Int = -1
    
    func selectSource(
        enabledSources: [WallpaperSourceType],
        recentHistory: [Wallpaper]
    ) -> WallpaperSource {
        guard !enabledSources.isEmpty else {
            return BingSource(fromPreferences: true)
        }
        
        RoundRobinSelector.lastIndex = (RoundRobinSelector.lastIndex + 1) % enabledSources.count
        let sourceType = enabledSources[RoundRobinSelector.lastIndex]
        
        return sourceType.createSourceFromPreferences()
    }
}

// MARK: - Weighted Random Selector

@MainActor
final class WeightedRandomSelector: RotationStrategySelector {
    func selectSource(
        enabledSources: [WallpaperSourceType],
        recentHistory: [Wallpaper]
    ) -> WallpaperSource {
        guard !enabledSources.isEmpty else {
            return BingSource(fromPreferences: true)
        }
        
        // Get weights from preferences
        let weights = enabledSources.map { sourceType -> (source: WallpaperSourceType, weight: Double) in
            let weight = getSourceWeight(for: sourceType)
            return (source: sourceType, weight: weight)
        }
        
        // Calculate total weight
        let totalWeight = weights.reduce(0.0) { $0 + $1.weight }
        
        guard totalWeight > 0 else {
            // All weights are zero, fall back to random
            let randomIndex = Int.random(in: 0..<enabledSources.count)
            return enabledSources[randomIndex].createSourceFromPreferences()
        }
        
        // Weighted random selection
        var randomValue = Double.random(in: 0..<totalWeight)
        for (source, weight) in weights {
            randomValue -= weight
            if randomValue < 0 {
                return source.createSourceFromPreferences()
            }
        }
        
        // Fallback to last source
        return enabledSources.last!.createSourceFromPreferences()
    }
    
    private func getSourceWeight(for sourceType: WallpaperSourceType) -> Double {
        switch sourceType {
        case .unsplash:
            return Preferences.shared.unsplashWeight
        case .bing:
            return Preferences.shared.bingWeight
        case .wallhaven:
            return Preferences.shared.wallhavenWeight
        case .reddit:
            return Preferences.shared.redditWeight
        case .artstation:
            return Preferences.shared.artstationWeight
        case .local:
            return Preferences.shared.localWeight
        }
    }
}

// MARK: - Smart Rating Selector

@MainActor
final class SmartRatingSelector: RotationStrategySelector {
    func selectSource(
        enabledSources: [WallpaperSourceType],
        recentHistory: [Wallpaper]
    ) -> WallpaperSource {
        guard !enabledSources.isEmpty else {
            return BingSource(fromPreferences: true)
        }
        
        // Calculate average rating for each source from recent history
        var sourceRatings: [WallpaperSourceType: (sum: Int, count: Int)] = [:]
        
        for wallpaper in recentHistory {
            if let rating = wallpaper.userRating {
                let current = sourceRatings[wallpaper.source] ?? (0, 0)
                sourceRatings[wallpaper.source] = (current.sum + rating, current.count + 1)
            }
        }
        
        // Calculate scores (average rating + exploration bonus)
        let scores = enabledSources.map { sourceType -> (source: WallpaperSourceType, score: Double) in
            let ratings = sourceRatings[sourceType] ?? (0, 0)
            let averageRating: Double
            if ratings.count > 0 {
                averageRating = Double(ratings.sum) / Double(ratings.count)
            } else {
                // No ratings yet, use default weight as proxy
                averageRating = getDefaultWeight(for: sourceType)
            }
            
            // Add 10% exploration bonus to encourage trying all sources
            let explorationBonus = 1.0 + (Double.random(in: 0.0..<0.1))
            return (source: sourceType, score: averageRating * explorationBonus)
        }
        
        // Select source with highest score
        let bestSource = scores.max { $0.score < $1.score } ?? (source: enabledSources.first!, score: 0)
        return bestSource.source.createSourceFromPreferences()
    }
    
    private func getDefaultWeight(for sourceType: WallpaperSourceType) -> Double {
        switch sourceType {
        case .unsplash:
            return Preferences.shared.unsplashWeight
        case .bing:
            return Preferences.shared.bingWeight
        case .wallhaven:
            return Preferences.shared.wallhavenWeight
        case .reddit:
            return Preferences.shared.redditWeight
        case .artstation:
            return Preferences.shared.artstationWeight
        case .local:
            return Preferences.shared.localWeight
        }
    }
}

// MARK: - Factory

@MainActor
enum RotationStrategyFactory {
    static func createSelector(for strategy: RotationStrategy) -> RotationStrategySelector {
        switch strategy {
        case .roundRobin:
            return RoundRobinSelector()
        case .weightedRandom:
            return WeightedRandomSelector()
        case .smartRating:
            return SmartRatingSelector()
        case .random:
            return RandomSelector()
        }
    }
}

// MARK: - Random Selector

@MainActor
final class RandomSelector: RotationStrategySelector {
    func selectSource(
        enabledSources: [WallpaperSourceType],
        recentHistory: [Wallpaper]
    ) -> WallpaperSource {
        guard !enabledSources.isEmpty else {
            return BingSource(fromPreferences: true)
        }
        let randomIndex = Int.random(in: 0..<enabledSources.count)
        return enabledSources[randomIndex].createSourceFromPreferences()
    }
}
