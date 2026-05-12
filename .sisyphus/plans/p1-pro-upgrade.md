# P1 Upgrade Plan: VarietyMacOS Pro

## Overview

**Project**: VarietyMacOS Pro (forked from VarietyMacOS P0-complete codebase)  
**Repo**: https://github.com/cyancloudyang/VarietyMacOS-Pro  
**Target**: macOS 14+ (Sonoma), Swift 6, SwiftData, NavigationSplitView  
**Strategy**: Fresh start — no UserDefaults data migration  
**QA**: Agent QA only (no automated tests)  
**Versioning**: Pro starts at v1.0  

---

## Execution Waves

### Wave 1: Build Config + SwiftData Foundation (Branch: `feat/p1-wave1-swiftdata`)

**Goal**: Upgrade build settings, migrate core data models to SwiftData, wire up ModelContainer. App must compile and run with SwiftData replacing UserDefaults+Persistence.

#### Step 1.1: Build Configuration Upgrade
- **File**: `VarietyMacOS.xcodeproj/project.pbxproj`
- Changes:
  - `SWIFT_VERSION = 5.0` → `SWIFT_VERSION = 6.0` (all targets)
  - `MACOSX_DEPLOYMENT_TARGET = 13.0` → `MACOSX_DEPLOYMENT_TARGET = 14.0` (all targets)
  - Add `SWIFT_STRICT_CONCURRENCY = complete` to all build configurations
  - `PRODUCT_BUNDLE_IDENTIFIER` → update from `com.yourname.variety-macos` to `com.cyancloud.VarietyMacOS-Pro`
- Remove all `@available(macOS 13.0, *)` annotations (now minimum is 14.0)
- **Verification**: `xcodebuild clean build` passes with warnings only (errors from Swift 6 concurrency will be fixed in Wave 2)

#### Step 1.2: Create SwiftData Model — Wallpaper
- **File**: `VarietyMacOS/Data/Models/Wallpaper.swift`
- Transform from `final class Wallpaper: Identifiable, Codable, ObservableObject` to `@Model class Wallpaper`
- Key changes:
  ```swift
  @Model class Wallpaper {
      var id: String
      var source: WallpaperSourceType  // rawValue String via Codable enum
      var title: String?
      var description: String?
      var author: String?
      var authorURL: URL?
      var sourceURL: URL?
      var resolutionWidth: Double      // CGSize decomposed
      var resolutionHeight: Double     // CGSize decomposed
      var fileSize: Int?
      var createdAt: Date?
      var upvotes: Int?
      var subreddit: String?
      var tags: [String]?
      var colors: [String]?
      var views: Int?
      var favorites: Int?
      var fileType: String?
      var remoteURL: URL?
      var localURL: URL?
      var thumbnailURL: URL?
      @Transient var cachedImage: NSImage?  // NOT persisted
      var downloadDate: Date?
      
      // Computed: reconstitute CGSize
      var resolution: CGSize {
          CGSize(width: resolutionWidth, height: resolutionHeight)
      }
      
      // Keep all computed properties (displayTitle, resolutionString, etc.)
  }
  ```
- **Delete**: Custom `CodingKeys`, `init(from:)`, `encode(to:)` — SwiftData handles persistence
- **Delete**: `Hashable`/`Equatable` manual conformance — SwiftData provides identity via `PersistentIdentifier`
- **CGSize strategy**: Decompose into `resolutionWidth: Double` + `resolutionHeight: Double`. Computed property `resolution: CGSize` reconstructs it. This avoids ValueTransformer complexity.
- **WallpaperSourceType**: Already `String, Codable` enum — SwiftData stores rawValue automatically
- **Relationships**: Add `@Relationship(deleteRule: .cascade, inverse: \HistoryEntry.wallpaper)` for history entries, `@Relationship(deleteRule: .cascade, inverse: \FavoriteEntry.wallpaper)` for favorites

#### Step 1.3: Create SwiftData Model — HistoryEntry
- **File**: `VarietyMacOS/Data/Models/WallpaperHistory.swift`
- Transform `struct HistoryEntry: Identifiable, Codable` → `@Model class HistoryEntry`
- Key changes:
  ```swift
  @Model class HistoryEntry {
      var id: String
      var wallpaperId: String
      var wallpaper: Wallpaper?     // @Relationship — now properly persisted
      var timestamp: Date
      var source: WallpaperSourceType
  }
  ```
- **Delete**: Custom `CodingKeys`, `init(from:)`, `encode(to:)`
- Wallpaper reference is now a **real SwiftData Relationship** — no longer nil on decode

#### Step 1.4: Create SwiftData Model — FavoriteEntry
- **File**: `VarietyMacOS/Data/Models/WallpaperFavorite.swift`
- Transform `struct FavoriteEntry: Identifiable, Codable` → `@Model class FavoriteEntry`
- Key changes:
  ```swift
  @Model class FavoriteEntry {
      var id: String
      var wallpaperId: String
      var wallpaper: Wallpaper?     // @Relationship
      var dateAdded: Date
      var tags: [String]
      var notes: String?
  }
  ```
- **Delete**: Custom `CodingKeys`, `init(from:)`, `encode(to:)`

#### Step 1.5: Create SwiftData Model — AppPreferences
- **File**: `VarietyMacOS/Preferences/Preferences.swift` (rewrite)
- Transform `final class Preferences: ObservableObject` → `@Model class AppPreferences`
- Strategy: Make it a **single-record @Model** (singleton pattern in SwiftData)
  ```swift
  @Model class AppPreferences {
      // General
      var changeInterval: TimeInterval = 1800
      var changeOnStart: Bool = false
      var showNotifications: Bool = true
      var fillMode: DisplayMode = .fill  // rawValue String
      var changeAllScreens: Bool = true
      
      // Download
      var downloadEnabled: Bool = true
      var downloadFolder: String = ""
      var maxDownloadSize: Double = 10
      var imageQuality: String = "high"
      var limitDownloadSpeed: Bool = false
      var maxDownloadSpeed: Double = 1000
      
      // Source settings (all 50+ fields as direct @Model properties)
      // ... (each @Published var → var, with didSet removed)
      
      // Screen
      var screenConfigurations: [String: String] = [:]
  }
  ```
- **Delete**: `PreferencesData` struct, `savePreferences()`, `loadPreferences()`, all `didSet` save calls
- **Delete**: `Persistence` class usage — SwiftData auto-saves on model changes
- **Why @Model over @AppStorage**: 50+ fields with complex types (DisplayMode enum, [WallpaperSourceType]) — @AppStorage can't handle these. Single-record @Model gives us type safety + auto-persistence.

#### Step 1.6: Create SwiftData Model — SourceConfig
- **File**: `VarietyMacOS/Preferences/SourceConfig.swift`
- Transform `struct SourceConfig: Codable, Identifiable` → `@Model class SourceConfig`
- `settings: [String: String]` works in SwiftData (primitive dictionary)
- SourceConfigManager singleton → query via `@Query` or `ModelContext.fetch()`

#### Step 1.7: Configure ModelContainer
- **New file**: `VarietyMacOS/Data/DataContainer.swift`
  ```swift
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
      
      /// Ensure single AppPreferences record exists
      static func ensureDefaults(in context: ModelContext) {
          let descriptor = FetchDescriptor<AppPreferences>()
          if (try? context.fetchCount(descriptor)) == 0 {
              let prefs = AppPreferences()
              context.insert(prefs)
          }
      }
  }
  ```

#### Step 1.8: Wire ModelContainer into App
- **File**: `VarietyMacOS/VarietyMacOSApp.swift`
- Add `.modelContainer(DataContainer.modelContainer)` to WindowGroup and Settings
- Remove `@EnvironmentObject` passing for managers that become SwiftData queries

#### Step 1.9: Delete Persistence.swift
- **File**: `VarietyMacOS/Data/Persistence.swift` — **DELETE ENTIRELY**
- Remove all references to `Persistence.shared` from:
  - `WallpaperHistory.swift` (load/save methods)
  - `WallpaperFavorite.swift` (load/save methods)
  - `Preferences.swift` (persistence field)
  - `SourceConfig.swift` (SourceConfigManager)
- Replace with `ModelContext` operations:
  ```swift
  // Old:
  private let persistence = Persistence.shared
  persistence.set(data, forKey: historyKey)
  
  // New:
  @Environment(\.modelContext) private var modelContext
  // SwiftData auto-saves on insert/delete/update
  ```

#### Step 1.10: Migrate WallpaperHistory to SwiftData queries
- **File**: `VarietyMacOS/Data/Models/WallpaperHistory.swift`
- Remove singleton pattern, remove manual load/save
- Replace `@Published var entries: [HistoryEntry]` with `@Query` in views
- Keep business logic (add, remove, statistics) but use `ModelContext`:
  ```swift
  @MainActor
  final class WallpaperHistory: ObservableObject {
      private var modelContext: ModelContext
      
      init(modelContext: ModelContext) {
          self.modelContext = modelContext
      }
      
      func add(_ wallpaper: Wallpaper) {
          let entry = HistoryEntry(wallpaperId: wallpaper.id, wallpaper: wallpaper, timestamp: Date(), source: wallpaper.source)
          modelContext.insert(entry)
          // Trim to maxEntries
          trimIfNeeded()
      }
      
      func remove(_ entry: HistoryEntry) {
          modelContext.delete(entry)
      }
  }
  ```

#### Step 1.11: Migrate WallpaperFavorite to SwiftData queries
- Same pattern as WallpaperHistory — remove singleton, inject ModelContext

#### Step 1.12: Migrate Preferences access pattern
- All `Preferences.shared.someProperty` access → fetch the single `AppPreferences` record from ModelContext
- Create convenience accessor:
  ```swift
  @MainActor
  extension ModelContext {
      var preferences: AppPreferences {
          let descriptor = FetchDescriptor<AppPreferences>(predicate: nil)
          let results = (try? fetch(descriptor)) ?? []
          if let existing = results.first { return existing }
          let new = AppPreferences()
          insert(new)
          return new
      }
  }
  ```

**Wave 1 Verification**:
- [ ] `xcodebuild clean build` compiles (warnings OK for concurrency — fixed in Wave 2)
- [ ] App launches without crash
- [ ] SwiftData stores data in default SQLite location
- [ ] No UserDefaults persistence calls remain (grep for `Persistence.shared` and `UserDefaults.standard`)
- [ ] `Persistence.swift` file deleted

---

### Wave 2: Swift 6 Concurrency Migration (Branch: `feat/p1-wave2-swift6`)

**Goal**: All Swift 6 strict concurrency errors resolved. Zero compiler errors with `SWIFT_STRICT_CONCURRENCY = complete`.

#### Step 2.1: Annotate Main-Actor-Isolated Types
All UI-bound singletons must be `@MainActor`:
- `WallpaperManager` → already `@MainActor` on methods, needs class-level annotation:
  ```swift
  @MainActor
  final class WallpaperManager: ObservableObject { ... }
  ```
- `WallpaperHistory` → add `@MainActor`
- `WallpaperFavorite` → add `@MainActor`
- `AppPreferences` → `@Model` is already MainActor-isolated in SwiftData
- `WallpaperTimer` → add `@MainActor`
- `SourceConfigManager` → add `@MainActor`
- `ImageCacheManager` → add `@MainActor`

#### Step 2.2: Sendable Conformance for Value Types
- `WallpaperSourceType` → already `String, Codable` enum — add `Sendable`
- `DisplayMode` → already `String, Codable` enum — add `Sendable`
- `WallpaperError` → add `Sendable` (enum with associated values need all payloads Sendable)
- `HistoryStatistics` → add `Sendable` (struct with value types only)
- `FavoriteStatistics` → add `Sendable`
- `SourceConfiguration` → add `Sendable`
- `SourceConfig` → as @Model, isolation handled by SwiftData
- `ThumbnailResult`, `ThumbnailSource`, `ThumbnailError` (Pipeline types) → add `Sendable`

#### Step 2.3: WallpaperSource Protocol — Sendable Conformance
- **File**: `VarietyMacOS/Sources/WallpaperSource.swift`
  ```swift
  protocol WallpaperSource: Sendable {
      var sourceID: String { get }
      var displayName: String { get }
      func fetchWallpaper() async throws -> Wallpaper
      func fetchWallpapers(count: Int) async throws -> [Wallpaper]
      func isAvailable() -> Bool
      func configuration() -> SourceConfiguration
  }
  ```
- All concrete source implementations (UnsplashSource, BingSource, etc.) must conform to `Sendable`
- Review each source for mutable state → move to actor or make immutable

#### Step 2.4: NSImage Sendable Safety
- `NSImage` is NOT Sendable. Strategies:
  - `@Transient var cachedImage: NSImage?` in Wallpaper → accessed only from `@MainActor` context
  - `ImageCacheManager` → `@MainActor` class, all image operations on main actor
  - `ThumbnailPipeline` (already actor) → return `Data` instead of `NSImage` across boundaries, decode on main actor
  - Or use `@preconcurrency import AppKit` at module level if isolation boundaries are clean
  - **Preferred**: Keep NSImage on `@MainActor` side, use `nonisolated` computed properties that don't touch NSImage

#### Step 2.5: ImageCacheManager Redesign
- Currently: `final class` with sync/async mixing
- Migrate to: `@MainActor final class` (NOT actor — needs NSImage which isn't Sendable)
- All public methods already async-safe or can be made async:
  ```swift
  @MainActor
  final class ImageCacheManager: Sendable {
      static let shared = ImageCacheManager()
      private let memoryCache = NSCache<NSString, NSImage>()
      // ...
      func getImage(for key: String, from url: URL) async throws -> NSImage { ... }
      func getImage(from fileURL: URL) throws -> NSImage { ... }
  }
  ```
- Remove `Task {}` wrapping in internal methods — direct async calls

#### Step 2.6: WallpaperManager Concurrency Fixes
- `DispatchSource.makeMemoryPressureSource` → must run on specific queue, ensure callback dispatched to MainActor
- Combine cancellables → ensure `@MainActor` isolation
- Timer callback closure → explicitly `@Sendable`

#### Step 2.7: WallpaperTimer Concurrency
- `Timer.scheduledTimer` callbacks → `@Sendable` closures
- Combine publisher `sink` → `@MainActor` isolated
- `onTimerFired` closure → `@Sendable @MainActor () -> Void`

#### Step 2.8: Fix remaining concurrency warnings
- Run `xcodebuild` with strict concurrency and fix ALL errors
- Common patterns:
  - `@StateObject`/`@ObservedObject` → already on main actor in SwiftUI views
  - `@EnvironmentObject` → already main actor
  - Singleton access from background → dispatch to MainActor
  - `Task {}` blocks → ensure proper isolation

**Wave 2 Verification**:
- [ ] `xcodebuild clean build` with ZERO concurrency errors
- [ ] `SWIFT_STRICT_CONCURRENCY = complete` in all build configs
- [ ] No `Sendable` warnings
- [ ] App runs correctly — wallpaper fetch/apply works

---

### Wave 3: NavigationSplitView UI Restructure (Branch: `feat/p1-wave3-navsplit`)

**Goal**: Replace single-window card layout + sheet navigation with NavigationSplitView (sidebar/content/detail).

#### Step 3.1: App Entry Point Restructure
- **File**: `VarietyMacOS/VarietyMacOSApp.swift`
- WindowGroup becomes NavigationSplitView host:
  ```swift
  @main
  struct VarietyMacOSApp: App {
      @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
      
      var body: some Scene {
          WindowGroup {
              AppNavigationView()
                  .environmentObject(WallpaperManager.shared)
                  .modelContainer(DataContainer.modelContainer)
          }
          .windowStyle(.titleBar)
          .defaultSize(width: 900, height: 600)
          
          Settings {
              SettingsView()
          }
      }
  }
  ```

#### Step 3.2: Create AppNavigationView (NavigationSplitView)
- **New file**: `VarietyMacOS/App/AppNavigationView.swift`
  ```swift
  struct AppNavigationView: View {
      @State private var selectedSection: AppSection? = .current
      
      enum AppSection: String, CaseIterable {
          case current = "Current"
          case favorites = "Favorites"
          case history = "History"
          case sources = "Sources"
      }
      
      var body: some View {
          NavigationSplitView {
              // SIDEBAR
              SidebarView(selectedSection: $selectedSection)
          } content: {
              // CONTENT
              switch selectedSection {
              case .current: CurrentWallpaperView()
              case .favorites: FavoritesContentView()
              case .history: HistoryContentView()
              case .sources: SourcesContentView()
              case .none: Text("Select a section")
              }
          } detail: {
              // DETAIL (optional — wallpaper info/metadata)
              DetailPlaceholderView()
          }
      }
  }
  ```

#### Step 3.3: Create SidebarView
- **New file**: `VarietyMacOS/App/SidebarView.swift`
- Sections: Current Wallpaper, Favorites, History, Sources
- Each item: icon + label
- Use `NavigationLink` or `List(selection:)`

#### Step 3.4: Create CurrentWallpaperView (from currentWallpaperCard)
- Extract `currentWallpaperCard` from ContentView into standalone view
- Add `@Query` for current wallpaper state
- Add timer controls, quick actions

#### Step 3.5: Create FavoritesContentView
- **From**: WallpaperFavorite.shared access
- **To**: `@Query var favorites: [FavoriteEntry]` — SwiftData query
- Grid or list layout for favorites

#### Step 3.6: Create HistoryContentView
- **From**: HistorySheetView (sheet presentation)
- **To**: Full content column view with `@Query var entries: [HistoryEntry]`
- Sort by timestamp descending
- Group by date (Today, Yesterday, This Week, Older)

#### Step 3.7: Create SourcesContentView
- Source status overview, enable/disable toggles
- Links to source configuration

#### Step 3.8: Create DetailPlaceholderView
- Shows selected wallpaper metadata when one is selected
- Color swatches, tags, resolution, source info
- Favorite button, download button

#### Step 3.9: Migrate ContentView → remove old card layout
- Old `ContentView` with card-based layout → **DELETE** (replaced by AppNavigationView)
- Keep `FlowLayout`, `ThumbnailImageView`, `hexColor` helper — move to Utilities
- Keep `TestSourceCard` debug tool → move to Debug folder or behind feature flag

#### Step 3.10: Settings stays as Settings scene
- No change — Settings already works as separate window with TabView
- Update bundle ID references from "Variety" to "VarietyMacOS Pro"

#### Step 3.11: MenuBarView updates
- MenuBarView can stay as-is (popover view) or integrate with NavigationSplitView
- Sheet presentations for History → navigate to History section instead
- Keep as separate lightweight view for menu bar context

**Wave 3 Verification**:
- [ ] NavigationSplitView renders with sidebar, content, detail columns
- [ ] All sections navigable
- [ ] History section shows SwiftData-queried entries
- [ ] Favorites section shows SwiftData-queried entries
- [ ] Settings opens as separate window
- [ ] No sheet presentations for history (was HistorySheetView)
- [ ] App window default size 900x600 (sidebar + content + detail)

---

### Wave 4: Core Feature Enhancements (Branch: `feat/p1-wave4-enhancements`)

**Goal**: Enhance wallpaper management, auto-change, and UI/UX.

#### 4A: Wallpaper Management Enhancement

##### Step 4A.1: Wallpaper Rating/Tagging
- Add `userRating: Int?` (1-5) and `userTags: [String]?` to Wallpaper @Model
- UI: Rating stars in detail column, tag editor
- Filter by user tags in sidebar

##### Step 4A.2: Wallpaper Collections/Albums
- New `@Model class WallpaperCollection`:
  ```swift
  @Model class WallpaperCollection {
      var id: String
      var name: String
      var createdAt: Date
      var wallpapers: [Wallpaper]  // @Relationship
  }
  ```
- UI: Create/manage collections in sidebar
- Add wallpaper to collection via context menu

##### Step 4A.3: Enhanced Wallpaper Info Panel
- Full metadata display in detail column:
  - EXIF-like data (resolution, file type, file size)
  - Source attribution with link
  - Color palette with copy-on-click hex values
  - Tags with click-to-filter
  - View/favorite counts from source

##### Step 4A.4: Wallpaper Search
- Search across all wallpapers (favorites, history, collections)
- Filter by source, tags, date range, rating
- Use SwiftData `#Predicate` for queries

#### 4B: Auto-Change Enhancement

##### Step 4B.1: Smart Scheduling
- Time-based rules: different intervals at different times of day
  - Work hours: 1 hour
  - Evening: 30 minutes
  - Night: pause
- Day-of-week rules
- UI: Schedule editor in Settings → General

##### Step 4B.2: Source Priority & Rotation Strategy
- Replace simple "Bing first, then random" with configurable strategies:
  - Round-robin: cycle through enabled sources
  - Weighted random: respect source weights
  - Smart: favor sources with higher user ratings
- UI: Strategy picker in Settings → Sources

##### Step 4B.3: Avoid Duplicates
- Track recently applied wallpaper IDs
- Configure "don't repeat for X hours/days"
- Use SwiftData query to check recent history

##### Step 4B.4: Conditional Auto-Change
- Pause when on battery (laptop)
- Pause when specific app is fullscreen (gaming, presentations)
- Resume when conditions change
- Use `ProcessInfo.processInfo.isLowPowerModeEnabled` and NSWorkspace notifications

#### 4C: UI/UX Enhancement

##### Step 4C.1: Modern macOS Design Language
- Consistent use of SwiftUI materials (.ultraThinMaterial, .thickMaterial)
- Vibrancy effects for sidebar
- Proper toolbar with search field
- Unified title bar + toolbar style

##### Step 4C.2: Animations & Transitions
- Crossfade wallpaper transitions
- Smooth list animations for history/favorites
- Hover effects on wallpaper thumbnails
- Progress indicators for downloads

##### Step 4C.3: Keyboard Shortcuts
- `⌘N` — Next wallpaper
- `⌘P` — Previous wallpaper
- `⌘F` — Favorite current wallpaper
- `⌘S` — Skip to next source
- `⌘,` — Open Settings
- Register via `.keyboardShortcut()` modifiers

##### Step 4C.4: Drag & Drop
- Drag wallpaper image to save to desktop
- Drop image files to add to local collection
- Reorder sources via drag in settings

##### Step 4C.5: Context Menus
- Right-click wallpaper: Set as Desktop, Save As..., Favorite, Share, View Source
- Right-click history entry: Re-apply, Delete, Favorite, Copy Info
- Use `.contextMenu()` modifier

##### Step 4C.6: Onboarding Experience
- First-launch setup wizard:
  1. Welcome screen
  2. Choose sources (with preview images from each)
  3. Set change interval
  4. Done
- Store onboarding completion in AppPreferences

**Wave 4 Verification**:
- [ ] Collections CRUD works
- [ ] Search returns results across all data
- [ ] Smart scheduling respects time-of-day rules
- [ ] Duplicate avoidance works (no repeat within configured window)
- [ ] Keyboard shortcuts functional
- [ ] Context menus show relevant options
- [ ] First-launch wizard completes and stores preference
- [ ] All UI uses modern macOS design patterns

---

## Dependency Graph

```
Wave 1 (SwiftData) ─── Wave 2 (Swift 6) ─── Wave 3 (NavSplit) ─── Wave 4 (Enhancements)
   │                      │                      │                     │
   │                      │                      │                     ├─ 4A: Wallpaper Mgmt
   │                      │                      │                     ├─ 4B: Auto-Change
   │                      │                      │                     └─ 4C: UI/UX
   │                      │                      │
   └─ Must compile ──────┘                      └─ Must build clean ──┘
   (warnings OK)                                    (zero errors)
```

**Strictly sequential**: Each wave depends on the previous wave being complete and verified.

---

## Files Changed Per Wave

### Wave 1 (12 steps)
| File | Action |
|------|--------|
| `VarietyMacOS.xcodeproj/project.pbxproj` | EDIT: Swift 6, macOS 14, bundle ID, strict concurrency |
| `Data/Models/Wallpaper.swift` | REWRITE: @Model, remove Codable, decompose CGSize |
| `Data/Models/WallpaperHistory.swift` | REWRITE: HistoryEntry @Model, WallpaperHistory uses ModelContext |
| `Data/Models/WallpaperFavorite.swift` | REWRITE: FavoriteEntry @Model, WallpaperFavorite uses ModelContext |
| `Preferences/Preferences.swift` | REWRITE: AppPreferences @Model, delete PreferencesData |
| `Preferences/SourceConfig.swift` | REWRITE: SourceConfig @Model, SourceConfigManager uses ModelContext |
| `Data/DataContainer.swift` | NEW: ModelContainer configuration |
| `VarietyMacOSApp.swift` | EDIT: Add .modelContainer(), remove old env passing |
| `Data/Persistence.swift` | DELETE |
| `Core/WallpaperManager.swift` | EDIT: Remove Persistence.shared, use ModelContext |
| `Data/ImageCacheManager.swift` | EDIT: Remove Persistence.shared references |
| All files with `@available(macOS 13.0, *)` | EDIT: Remove availability annotations |

### Wave 2 (8 steps)
| File | Action |
|------|--------|
| `Core/WallpaperManager.swift` | EDIT: @MainActor class-level, Sendable closures |
| `Data/ImageCacheManager.swift` | EDIT: @MainActor, remove sync/async mixing |
| `Core/WallpaperTimer.swift` | EDIT: @MainActor, @Sendable closures |
| `Sources/WallpaperSource.swift` | EDIT: Protocol: Sendable conformance |
| `Sources/*/Source implementations` | EDIT: Sendable conformance |
| `Data/Models/*.swift` | EDIT: Sendable conformance on enums/structs |
| `Pipeline/ThumbnailTypes.swift` | EDIT: Sendable conformance |
| `Core/DisplayMode.swift` | EDIT: Sendable conformance |

### Wave 3 (11 steps)
| File | Action |
|------|--------|
| `VarietyMacOSApp.swift` | EDIT: WindowGroup hosts AppNavigationView |
| `App/AppNavigationView.swift` | NEW: NavigationSplitView |
| `App/SidebarView.swift` | NEW: Sidebar section list |
| `App/CurrentWallpaperView.swift` | NEW: From currentWallpaperCard |
| `App/FavoritesContentView.swift` | NEW: Favorites with @Query |
| `App/HistoryContentView.swift` | NEW: History with @Query (replaces HistorySheetView) |
| `App/SourcesContentView.swift` | NEW: Sources overview |
| `App/DetailPlaceholderView.swift` | NEW: Detail column |
| `App/MenuBarView.swift` | EDIT: Navigate instead of sheet for history |
| `VarietyMacOSApp.swift` (old ContentView) | REFACTOR: Extract helpers, delete card layout |
| Various view files | EDIT: @Query instead of @ObservedObject singleton |

### Wave 4 (15+ steps)
| File | Action |
|------|--------|
| `Data/Models/Wallpaper.swift` | EDIT: Add userRating, userTags |
| `Data/Models/WallpaperCollection.swift` | NEW: Collection model |
| `App/WallpaperDetailView.swift` | NEW/ENHANCE: Full metadata panel |
| `App/WallpaperSearchView.swift` | NEW: Search interface |
| `Core/WallpaperManager.swift` | EDIT: Smart scheduling, rotation, dedup |
| `Core/WallpaperTimer.swift` | EDIT: Time-based rules |
| `Core/AutoChangeStrategy.swift` | NEW: Strategy pattern for source selection |
| `Core/DuplicateAvoidance.swift` | NEW: Track recent, prevent repeats |
| `Core/ConditionalPauser.swift` | NEW: Battery/app fullscreen detection |
| `App/SettingsView.swift` | EDIT: Schedule editor, strategy picker |
| `App/KeyboardShortcuts.swift` | NEW: Global keyboard shortcuts |
| `App/OnboardingView.swift` | NEW: First-launch wizard |
| Multiple UI files | EDIT: Materials, animations, context menus, drag & drop |

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Swift 6 strict concurrency breaks compile | HIGH | Wave 1 allows warnings; Wave 2 dedicated to fixing |
| SwiftData @Model + NSImage complexity | MEDIUM | @Transient + @MainActor isolation |
| CGSize in SwiftData | LOW | Decompose to Double pairs — proven pattern |
| NavigationSplitView layout regressions | MEDIUM | Incremental migration, keep old views until new ones verified |
| ModelContainer singleton lifecycle | LOW | @MainActor enum with static let — standard pattern |
| Preferences 50+ fields migration | MEDIUM | Direct @Model migration — tedious but straightforward |

---

## Visual Analysis Addendum (2026-05-12)

**Analysis Method**: AI-powered image recognition via Mistral Medium 3.5  
**Input**: VarietyMacOS Pro main window screenshot

### Identified UI Issues

| Issue | Severity | Location | Recommendation |
|-------|----------|----------|----------------|
| Button text truncation "Next Wallp..." | Medium | Quick Actions section | Use `.frame(minWidth: ...)` or automatic layout |
| Empty state lacks guidance | Low | Current Wallpaper view | Add sample wallpaper grid or "Add first wallpaper" CTA |
| Placeholder icon too large | Low | Empty state | Reduce icon size, add instructional text |

### Recommended Actions

1. **Fix button truncation** (Priority: High)
   - File: `VarietyMacOS/App/CurrentWallpaperView.swift`
   - Change: Add `.frame(minWidth: 100)` to "Next Wallpaper" button
   - Alternative: Use "Next" + icon instead of full text

2. **Enhance empty state** (Priority: Medium)
   - File: `VarietyMacOS/App/CurrentWallpaperView.swift`
   - Add: "Browse featured wallpapers" button
   - Add: Grid of 3-6 sample wallpapers from enabled sources

3. **Improve visual hierarchy** (Priority: Low)
   - Reduce placeholder icon size by 30%
   - Add subtle animation to "Ready" status indicator
   - Consider showing last applied wallpaper as background preview

---

## Timeline Estimate

| Wave | Steps | Est. Agent Sessions |
|------|-------|---------------------|
| Wave 1: SwiftData | 12 | 4-6 deep sessions |
| Wave 2: Swift 6 | 8 | 2-3 deep sessions |
| Wave 3: NavigationSplitView | 11 | 3-4 visual-engineering sessions |
| Wave 4: Enhancements | 15+ | 6-8 mixed sessions |
| **Total** | **46+** | **15-21 sessions** |

Each "deep session" = one `task(category="deep")` delegation handling 2-4 related steps.
