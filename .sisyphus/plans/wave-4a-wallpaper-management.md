# Wave 4A: Wallpaper Management Plan

**Project**: VarietyMacOS Pro (P1 Upgrade)  
**Wave Scope**: Enhanced wallpaper management features (Collections, Ratings, Tags, Search, Metadata Panel)  
**Dependencies**: Wave 1 (SwiftData) ✅, Wave 2 (Swift 6) ✅, Wave 3 (NavigationSplitView) ✅  
**Branch**: `feat/p1-wave4a-wallpaper-management`  
**Estimated Effort**: 2-3 agent sessions (8-12 hours)

---

## TL;DR

Wave 4A adds 4 core features to improve wallpaper organization and discovery:
1. **Rating & Tagging**: 5-star rating system + custom tags on every wallpaper (new model fields)
2. **Collections**: User-created albums to group related wallpapers (new @Model)
3. **Enhanced Info Panel**: Full metadata display with color palette, copy-on-click hex values
4. **Search**: Full-text search across favorites/history/collections with advanced filters

All features leverage SwiftData for persistence. UI integrates seamlessly with existing NavigationSplitView.

---

## Execution Waves (Sequential)

| Wave | Parallel Group | Tasks | Description |
|------|----------------|-------|-------------|
| **4A.1** | Serial | 1 | Add `userRating`, `userTags` to Wallpaper model + UI controls |
| **4A.2** | Serial | 1 | Collections model + CRUD sidebar integration |
| **4A.3** | Serial | 1 | Enhanced metadata panel with color swatches |
| **4A.4** | Serial | 1 | Search view with filter predicates |

**Total Tasks**: 4  
**Estimated Duration**: 1 day (with QA verification)

---

## Detailed TODOs

### 4A.1: Wallpaper Rating & Tagging System

**Goal**: Add user-controlled rating (1-5 stars) and custom tags to wallpapers

#### What To Do:

1. **Extend Wallpaper Model**
   - **File**: `VarietyMacOS/Data/Models/Wallpaper.swift`
   - Add properties:
     ```swift
     var userRating: Int?  // 1-5, nil = unrated
     var userTags: [String]?  // Custom tags array
     ```
   - Update initializer to include these fields

2. **Rating Stars UI Component**
   - **File**: `VarietyMacOS/App/RatingStarsView.swift` (NEW)
   - SwiftUI `View` with 5 interactive stars
   - Tap/click to set rating (1-5) or clear (0)
   - Golden fills for rated stars, outline for unrated
   - Supports animation on interaction

3. **Tag Editor UI Component**
   - **File**: `VarietyMacOS/App/TagEditorView.swift` (NEW)
   - Chip-based tag input (add/remove tags)
   - Press Enter or click "+" to add tag
   - Each tag shows X button to remove
   - Persist to SwiftData on change

4. **Integrate into Wallpaper Detail View**
   - **File**: `VarietyMacOS/App/DetailPlaceholderView.swift`
   - Add rating stars below wallpaper title
   - Add tag editor below rating
   - Bind to selected wallpaper's `userRating` and `userTags`

#### Acceptance Criteria:
- [ ] `userRating` stores 1-5 (or nil) and persists via SwiftData
- [ ] `userTags` arrays survive app restarts
- [ ] Star rating UI responds instantly and saves
- [ ] Tag editor allows adding/removing with immediate persistence
- [ ] No new SwiftData migration errors on launch

#### Agent-Executed QA Scenarios:

**QA-4A.1.1: Basic Rating**
```
Playwright Steps:
1. Launch app, select any wallpaper
2. Click 3rd star → observe fill state
3. Close app, reopen → rating persists
4. File > Reset to verify rating clears (if test mode)
```

**QA-4A.1.2: Tag Operations**
```
Playwright Steps:
1. Select wallpaper, click "Add Tag" button
2. Type "nature" + Enter → see tag chip appear
3. Click chip's X button → tag removed
4. Reopen app → tags persisted correctly
```

**QA-4A.1.3: Data Integrity**
```
Bash (SwiftData inspection):
# Open SQLite inspector on default.db
sqlite3 ~/Library/Application\ Support/com.cyancloud.VarietyMacOS-Pro/default.sqlite
SELECT id, userRating, userTags FROM Wallpaper LIMIT 5;
# Verify JSON-encoded tags array and integer ratings
```

---

### 4A.2: Wallpaper Collections (Albums)

**Goal**: Create user-defined collections to organize wallpapers into albums

#### What To Do:

1. **Create Collection Model**
   - **File**: `VarietyMacOS/Data/Models/WallpaperCollection.swift` (NEW)
   - Define:
     ```swift
     @Model class WallpaperCollection {
         var id: String
         var name: String
         var createdAt: Date
         var description: String?
         var wallpapers: [Wallpaper]  // @Relationship
         
         init(id: String = UUID().uuidString, name: String, description: String? = nil) {
             self.id = id
             self.name = name
             self.description = description
             self.createdAt = Date()
             self.wallpapers = []
         }
     }
     ```

2. **Collections CRUD Manager**
   - **File**: `VarietyMacOS/Core/CollectionManager.swift` (NEW)
   - `@MainActor final class`
   - Methods:
     - `create(name: String, description: String?) -> WallpaperCollection`
     - `update(_ collection: WallpaperCollection, name: String?, description: String?)`
     - `delete(_ collection: WallpaperCollection)`
     - `addWallpaper(_ wallpaper: Wallpaper, to collection: WallpaperCollection)`
     - `removeWallpaper(_ wallpaper: Wallpaper, from collection: WallpaperCollection)`
     - `collectionsForWallpaper(_ wallpaper: Wallpaper) -> [WallpaperCollection]`

3. **Collections Sidebar Section**
   - **File**: `VarietyMacOS/App/SidebarView.swift` (EDIT)
   - Add "Collections" navigation group under Favorites/History
   - Show collection count: "My Favorites (12)"
   - Add "+" button for creating new collection
   - Selecting collection navigates to new "CollectionView"

4. **Collection Detail View**
   - **File**: `VarietyMacOS/App/CollectionView.swift` (NEW)
   - Display all wallpapers in collection
   - Grid layout with thumbnails
   - Context menu: "Remove from Collection"
   - Header shows collection name, wallpaper count, edit button

5. **Context Menu Integration**
   - **File**: Any wallpaper grid view (e.g., `FavoritesContentView.swift`)
   - Add "Add to Collection..." context menu item
   - Opens popover with list of collections + "New Collection"

#### Acceptance Criteria:
- [ ] Create/delete collections persist
- [ ] Collections maintain wallpaper relationships after restart
- [ ] Sidebar displays collection list with counts
- [ ] Adding/removing wallpapers from collections reflects immediately
- [ ] Deleting collection does NOT delete wallpapers (deprotects only)

#### Agent-Executed QA Scenarios:

**QA-4A.2.1: Create Collection Flow**
```
Playwright Steps:
1. Sidebar > Collections > click "+"
2. Enter name "Landscapes", description "Beautiful nature shots"
3. Confirm → collection appears in sidebar
4. Close app → collection survives
```

**QA-4A.2.2: Add Wallpapers to Collection**
```
Playwright Steps:
1. Go to Favorites grid
2. Right-click wallpaper > Add to Collection > "Landscapes"
3. Navigate to Collections > "Landscapes" → wallpaper appears
4. Select wallpaper in collection, click trash → removed from collection but wallpaper still exists in app
```

**QA-4A.2.3: Collection Delete Safety**
```
Playwright Steps:
1. Create test collection, add 3 wallpapers
2. Delete collection
3. Verify 3 wallpapers still accessible in Favorites/History
4. (Do not lose wallpapers - only collection grouping)
```

**QA-4A.2.4: SwiftData Relationships**
```
Bash commands:
sqlite3 ~/Library/Application\ Support/com.cyancloud.VarietyMacOS-Pro/default.sqlite
SELECT COUNT(*) FROM WallpaperCollection;
SELECT w.id, w.title FROM Wallpaper w, WallpaperCollection_wallpapers wp WHERE wp.wallpaper_id = w.id LIMIT 5;
# Verify collection-wallpaper join table has data
```

---

### 4A.3: Enhanced Wallpaper Info Panel

**Goal**: Full metadata display in detail column with color palette and interactive tags

#### What To Do:

1. **Enhance DetailPlaceholderView**
   - **File**: `VarietyMacOS/App/DetailPlaceholderView.swift` (major rewrite)
   - Structure (ordered sections):
     1. Title + Author + Source badge + Rating stars
     2. Metadata table:
        - Resolution: \(width) × \(height)
        - Aspect Ratio: 16:9 (or exact ratio)
        - File Size: "2.3 MB"
        - File Type: PNG/JPEG/etc
        - Download Date: "2025-05-10"
        - Source: "Unsplash / r/wallpapers"
     3. Source attribution:
        - Author name (if available) with link
        - Source URL button (opens browser)
     4. Color Palette section:
        - Up to 6 color swatches
        - Each swatch: preview circle + hex value
        - Click swatch → copy hex to clipboard, show "Copied!" notification
     5. Tags section:
        - Source tags (if any) as chips
        - User tags as chips
        - Click tag → filter view by that tag
     6. User stats:
        - Views: "12.4K views"
        - Upvotes: "856 likes"
        - Favorites count
     7. Actions:
        - Set as Desktop button
        - Save to Disk button
        - Favorite button
        - Add to Collection dropdown

2. **ColorSwatchView Component**
   - **File**: `VarietyMacOS/App/ColorSwatchView.swift` (NEW)
   - `View` with:
     - Circular/swatch shape filled with hex color
     - Hex code text overlay
     - OnClick handler for copy + toast

3. **Hex Copy Notification**
   - **File**: `VarietyMacOS/App/ToastNotificationView.swift` (NEW)
   - Floating toast with "Copied #FF5733 to clipboard!"
   - Auto-dismiss after 2s
   - Dismissible on click

4. **Tag Chip with Filter**
   - **File**: `VarietyMacOS/App/TagChipView.swift` (NEW)
   - pill-shaped chip with background color based on tag hash
   - Click event emits tag string
   - Parent view handles filter state

#### Acceptance Criteria:
- [ ] All metadata fields display correctly for every wallpaper
- [ ] Color swatches render with correct hex values
- [ ] Clicking swatch copies hex and shows toast
- [ ] Tags are clickable for filtering
- [ ] Attribution links open in browser
- [ ] No layout break when fields are nil (fallback to "Unknown")

#### Agent-Executed QA Scenarios:

**QA-4A.3.1: Metadata Accuracy**
```
Playwright Steps:
1. Select a known wallpaper (downloaded from Wallhaven)
2. Verify resolution matches actual image (right-click > Get Info to compare)
3. Verify file size
4. Test with local file (no resolution metadata) → falls back to "Unknown"
```

**QA-4A.3.2: Color Palette Copy**
```
Playwright Steps:
1. Check wallpaper with colors array
2. Click first color swatch
3. Paste from clipboard in TextEdit
4. Verify hex matches swatch color
5. Multiple clicks → multiple copies succeed
```

**QA-4A.3.3: Attribution Links**
```
Playwright Steps:
1. Wallpaper with sourceURL → click "View Source"
2. Browser opens correct URL
3. Test wallpaper without sourceURL → button disabled or hidden
```

**QA-4A.3.4: Tag Filter Interaction**
```
Playwright Steps:
1. Select wallpaper with tags
2. Click "nature" tag
3. Navigate to search/favorites view
4. Verify only tagged wallpapers visible (filter active)
5. Clear filter → all wallpapers return
```

---

### 4A.4: Wallpaper Search System

**Goal**: Full-text search with advanced filters

#### What To Do:

1. **SearchView Main Interface**
   - **File**: `VarietyMacOS/App/SearchView.swift` (NEW)
   - Top search field with search icon
   - Results grid below
   - Filter section above results (collapsible):
     - Source filter: multi-select chips (Bing, Unsplash, etc.)
     - Tag filter: selected user tags
     - Rating filter: slider 0-5 stars
     - Date range: from/to date pickers
     - Collections: select one or "all"

2. **Search Service**
   - **File**: `VarietyMacOS/Core/WallpaperSearchService.swift` (NEW)
   - `@MainActor final class`
   - Method:
     ```swift
     func search(
         query: String,
         sources: Set<WallpaperSourceType>,
         tags: [String],
         minRating: Int?,
         from: Date?,
         to: Date?,
         collections: Set<WallpaperCollection>
     ) async throws -> [Wallpaper]
     ```
   - Uses SwiftData `#Predicate`:
     ```swift
     let predicate = #Predicate<Wallpaper> { wallpaper in
         (query.isEmpty || 
          wallpaper.title?.contains(query) == true ||
          wallpaper.tags?.contains(query) == true) &&
         (sources.isEmpty || sources.contains(wallpaper.source)) &&
         ... // other filters
     }
     ```

3. **Date Utilities**
   - **File**: `VarietyMacOS/Utilities/DateRangePicker.swift` (NEW or EDIT)
   - SwiftUI date picker component
   - Presets: Today, Yesterday, This Week, This Month, Any time

4. **Component Wiring**
   - **File**: `VarietyMacOS/App/AppNavigationView.swift` (EDIT)
   - Add "Search" section to sidebar
   - Set selectedSection to display SearchView

#### Acceptance Criteria:
- [ ] Empty query returns all results
- [ ] Typing filters results in real-time
- [ ] Can combine source + tag + rating filters
- [ ] Date ranges filter correctly
- [ ] Collections filter shows only wallpapers in those collections
- [ ] No crash on complex queries (empty database, 0 results)

#### Agent-Executed QA Scenarios:

**QA-4A.4.1: Basic Keyword Search**
```
Playwright Steps:
1. Navigate to Search tab
2. Type "nature" in search field
3. Verify results show wallpapers with:
   - "nature" in title
   - "nature" in tags
4. Clear search → all wallpapers return
```

**QA-4A.4.2: Source Filter**
```
Playwright Steps:
1. Search "nature" results showing
2. Check only "Bing" in source filter
3. Verify only Bing wallpapers remain
4. Uncheck Bing → Unsplash appears
5. No sources selected → all appear
```

**QA-4A.4.3: Rating Filter**
```
Playwright Steps:
1. Rate a wallpaper 5 stars
2. Search "nature" with minRating = 4
3. Verify rated wallpaper appears
4. Set minRating = 5, rated wallpaper disappears (only 4-star)
```

**QA-4A.4.4: Date Range**
```
Playwright Steps:
1. Download wallpaper today
2. Set date range = "Last 7 days"
3. Selected wallpaper shows
4. Set "Last 24 hours" → may not show (if >24h ago)
5. Set "Any time" → all wallpapers
```

**QA-4A.4.5: Collection Filter**
```
Playwright Steps:
1. Add wallpapers to "Landscapes" collection
2. Search "mountain" with Collection = "Landscapes"
3. Only wallpapers in collection appear
4. No results if collection is empty
```

**QA-4A.4.6: Edge Cases**
```
Playwright Steps:
1. Database has 0 wallpapers
   - Search result: empty grid, "No results found" message
2. Search non-existent term
   - Empty grid, "No matches for 'xyz'" message
3. Use emoji in search
   - No crash, returns 0 results
```

**QA-4A.4.7: SwiftData Predicate Coverage**
```
Bash validation:
# Check number of wallpapers matching query
sqlite3 ~/Library/Application\ Support/com.cyancloud.VarietyMacOS-Pro/default.sqlite
SELECT COUNT(*) FROM Wallpaper WHERE title LIKE '%nature%' OR tags LIKE '%nature%';
# Compare to UI result count for validation
```

---

## Dependency Graph

```
Wave 1 (SwiftData) ─── Wave 2 (Swift 6) ─── Wave 3 (NavSplit) ─── Wave 4A
   ✅                         ✅                    ✅                 │
                                                                    ├── 4A.1: Rating/Tagging
                                                                    │     └── Model: Wallpaper extension
                                                                    │
                                                                    ├── 4A.2: Collections
                                                                    │     ├── Model: WallpaperCollection (NEW)
                                                                    │     └── Requires: 4A.1 (uses tags from Wallpaper)
                                                                    │
                                                                    ├── 4A.3: Enhanced Info Panel
                                                                    │     └── Uses: rating from 4A.1, colors from Wallpaper.tags
                                                                    │
                                                                    └── 4A.4: Search
                                                                          └── Requires: 4A.1 (tags) + 4A.2 (collections filter)
```

---

## Files Changed (Wave 4A)

| File | Action | Description |
|------|--------|-------------|
| `VarietyMacOS/Data/Models/Wallpaper.swift` | EDIT | Add `userRating` and `userTags` fields |
| `VarietyMacOS/App/RatingStarsView.swift` | NEW | 5-star interactive rating component |
| `VarietyMacOS/App/TagEditorView.swift` | NEW | Chip-based tag input |
| `VarietyMacOS/App/DetailPlaceholderView.swift` | EDIT | Enhanced metadata panel design |
| `VarietyMacOS/Data/Models/WallpaperCollection.swift` | NEW | Collection @Model class |
| `VarietyMacOS/Core/CollectionManager.swift` | NEW | CRUD operations for collections |
| `VarietyMacOS/App/SidebarView.swift` | EDIT | Add Collections section |
| `VarietyMacOS/App/CollectionView.swift` | NEW | Collection detail view |
| `VarietyMacOS/App/ColorSwatchView.swift` | NEW | Hex color swatch UI |
| `VarietyMacOS/App/ToastNotificationView.swift` | NEW | Copy confirmation toast |
| `VarietyMacOS/App/TagChipView.swift` | NEW | Clickable tag chip |
| `VarietyMacOS/App/SearchView.swift` | NEW | Full search interface |
| `VarietyMacOS/Core/WallpaperSearchService.swift` | NEW | SwiftData predicate search |
| `VarietyMacOS/App/AppNavigationView.swift` | EDIT | Wire up Search section |

**Total**: 13 files (5 NEW, 8 EDIT, 0 DELETE)

---

## Verification Strategy

### Pre-Implementation Checks:
- [ ] Build succeeds with all prior waves complete
- [ ] SwiftData schema has no conflicts
- [ ] Branch created: `feat/p1-wave4a-wallpaper-management`

### Post-Task Verification:

**After 4A.1 (Rating/Tagging):**
- [ ] `xcodebuild clean build` passes with no errors
- [ ] Wallpaper.swift compiles with new fields
- [ ] App launches without migration crash

**After 4A.2 (Collections):**
- [ ] WallpaperCollection API test compiles
- [ ] Collections section renders in sidebar
- [ ] CRUD operations complete without errors

**After 4A.3 (Info Panel):**
- [ ] Detail view layout correct for all wallpaper types
- [ ] Color swatches copy to clipboard
- [ ] Tags clickable for filter

**After 4A.4 (Search):**
- [ ] Search service returns correct results
- [ ] All filter combinations work
- [ ] Empty states render properly

### Final Wave Acceptance:
- [ ] All 4A tasks completed
- [ ] LSP diagnostics clean on all changed files
- [ ] Playwright QA passes 6 scenarios (4A.1 to 4A.4)
- [ ] No SwiftData corruption or migration errors
- [ ] User tested: "I can rate a wallpaper, create a collection, search by tags, and see full metadata"

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| SwiftData migration fails on new fields | HIGH | Optional fields with defaults; test on dev database first |
| Collections relationship circular reference | MEDIUM | Use `.nullify` delete rule for wallpapers, test manually |
| Search predicate complexity causes NPE | MEDIUM | Handle nil with `?: true` in predicates; unit test each filter |
| Color parsing from source tags | LOW | Graceful fallback to "Unknown" or empty palette |

---

## Agent QA Checklist Summary

All tests are Playwright-automated except where noted:

1. **4A.1.1**: Basic Rating (Playwright)
2. **4A.1.2**: Tag Operations (Playwright)
3. **4A.1.3**: Data Integrity (Bash/SQLite)
4. **4A.2.1**: Create Collection Flow (Playwright)
5. **4A.2.2**: Add Wallpapers to Collection (Playwright)
6. **4A.2.3**: Collection Delete Safety (Playwright)
7. **4A.2.4**: Collections Relationship (Bash/SQLite)
8. **4A.3.1**: Metadata Accuracy (Playwright)
9. **4A.3.2**: Color Palette Copy (Playwright)
10. **4A.3.3**: Attribution Links (Playwright)
11. **4A.3.4**: Tag Filter (Playwright)
12. **4A.4.1**: Basic Keyword Search (Playwright)
13. **4A.4.2**: Source Filter (Playwright)
14. **4A.4.3**: Rating Filter (Playwright)
15. **4A.4.4**: Date Range (Playwright)
16. **4A.4.5**: Collection Filter (Playwright)
17. **4A.4.6**: Edge Cases (Playwright)
18. **4A.4.7**: Predicate Coverage (Bash/SQLite)

Total QA scenarios: **18** (16 Playwright + 3 Bash - overlap allowed)

---

## Next Steps After Wave 4A

Once Wave 4A passes all QA:
1. Commit to `feat/p1-wave4a-wallpaper-management`
2. Implement Wave 4B (Auto-Change Enhancements) on new branch
3. Merge both into main after full Wave 4 QA

---

**Plan Author**: sisyphus-junior  
**Date**: 2025-05-11  
**Status**: Ready for /start-work execution