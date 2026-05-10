# Round 3: Recent History Thumbnails + Wallhaven Metadata Enrichment

## TL;DR

> **Quick Summary**: Connect the existing ThumbnailPipeline to the Recent History card (replacing static SF Symbol icons) and enrich Wallhaven wallpaper display with all available search-result metadata (views, favorites, colors, fileType). Add responsive info panels that show more detail when the window is larger.
> 
> **Deliverables**:
> - Enrich Wallpaper model with 5 new optional fields (tags, colors, views, favorites, fileType)
> - Fix WallhavenSource.createWallpaper() to map ALL search-result fields
> - Integrate ThumbnailPipeline into ContentView recentHistoryCard
> - Add ViewThatFits adaptive info panels to Current Wallpaper and History cards
> - Color swatches display for Wallhaven wallpapers
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 3 waves
> **Critical Path**: Task 1 → Task 3 → Task 5 → Tasks 6-8

---

## Context

### Original Request
User tested VarietyMacOS 3 times and found:
1. **Recent History card** shows only `photo` SF Symbol — no thumbnails. The ThumbnailPipeline (built in P0 plan T1-T6) exists but was never connected.
2. **Wallhaven metadata is wasted** — API returns rich data (views, favorites, colors, fileSize, fileType, ratio, source URL, createdAt) but `createWallpaper()` only extracts category, purity, and username.
3. **Info panel is minimal** — wants it responsive to window size: compact view for small windows, fuller details for larger windows.

### Interview Summary
**Key Discussions**:
- Wallhaven API strategy: **Search-only** (no extra detail API calls for tags/uploader). Use whatever fields are in search results.
- Model expansion: Add `tags: [String]?`, `colors: [String]?`, `views: Int?`, `favorites: Int?`, `fileType: String?` — all optional, Codable-safe.
- Responsive info: `ViewThatFits` to auto-select Compact vs Full layout based on available space.
- History thumbnails: Integrate existing `ThumbnailPipeline` (actors already built).
- Test strategy: Agent-executed QA only (build verification, Playwright UI snapshots, curl).

**Research Findings**:
- `ContentView.recentHistoryCard` (line 355): Always uses `Image(systemName: "photo")` — no thumbnail integration
- `WallhavenSource.createWallpaper()` (line 154-170): Maps only 3 of 15+ fields
- `WallhavenWallpaper` struct (line 180-201): Already parses ALL fields from JSON — they're just not passed to Wallpaper()
- `ThumbnailPipeline` needs instantiation (not `.shared` singleton). Task 4 creates an instance and calls `thumbnail(for:)` + `prewarmCache(for:)` via `.task` modifier.
- ThumbnailPipeline uses `NSImage` (not `Image`), needs async loading via `.task` modifier

### Metis Review
(Skipped — timeout. Self-review applied instead.)
**Gaps Self-Identified**:
- ThumbnailPipeline returns `NSImage` but SwiftUI views need `Image` — bridge needed
- HistoryEntry.wallpaper may be nil (decoded entries) — fallback needed
- colors as `[String]` hex codes — need color swatch rendering
- Wallpaper model needs `@Published` for new fields to trigger UI updates
- Existing history JSON (saved wallpapers) must still decode with new optional fields

---

## Work Objectives

### Core Objective
Fix Recent History thumbnails (integrate ThumbnailPipeline), enrich Wallhaven metadata display, and add responsive info panels.

### Concrete Deliverables
- `Data/Models/Wallpaper.swift` — Add 5 new optional fields (tags, colors, views, favorites, fileType)
- `Sources/Wallhaven/WallhavenSource.swift` — Map all search-result fields in createWallpaper()
- `VarietyMacOSApp.swift` — Integrate ThumbnailPipeline into recentHistoryCard + adaptive info
- `VarietyMacOSApp.swift` — Add ViewThatFits adaptive info to currentWallpaperCard

### Definition of Done
- [ ] Recent History shows actual wallpaper thumbnails (not SF Symbol)
- [ ] Thumbnails load asynchronously via ThumbnailPipeline with caching
- [ ] Wallhaven wallpapers show: views, favorites, colors (as swatches), file type
- [ ] Current Wallpaper card adapts info panel to window size (Compact vs Full)
- [ ] History entries show richer metadata when window is large
- [ ] Build succeeds with 0 errors
- [ ] Existing history JSON still decodes (backward compatibility)

### Must Have
- ThumbnailPipeline integration into recentHistoryCard
- Wallpaper model extended with 5 optional Codable fields
- WallhavenSource mapping ALL search-result fields
- ViewThatFits for adaptive info in currentWallpaperCard
- Color swatch display for Wallhaven wallpaper colors
- Backward-compatible Codable (new fields optional, existing JSON still loads)

### Must NOT Have (Guardrails)
- Do NOT make extra Wallhaven detail API calls (search-only strategy)
- Do NOT change ThumbnailPipeline interface (actors are already built)
- Do NOT modify WallpaperSource protocol
- Do NOT create new Swift files (modify existing files only)
- Do NOT touch other sources (Bing/Unsplash/Reddit/ArtStation/Local) — Wallhaven enrichment only
- Do NOT change the layout grid/stack structure of existing views
- Do NOT add new third-party dependencies
- Do NOT break existing Codable (new fields must be optional with defaults)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: YES (XCTest framework present, 8 test files)
- **Automated tests**: NO (Agent-executed QA only)
- **Framework**: N/A

### QA Policy
Every task includes agent-executed QA scenarios:
- **UI/Frontend**: Playwright — Navigate, interact, snapshot, assert DOM, screenshot
- **CLI/Build**: Bash — xcodebuild clean build, verify 0 errors
- **API/Backend**: Bash — curl Wallhaven search endpoint, verify field availability
- Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — model + source changes):
├── Task 1: Enrich Wallpaper model (5 new fields) [quick]
├── Task 2: Fix WallhavenSource.createWallpaper() mapping [quick]
└── Task 3: Verify Wallhaven search API fields via curl [quick]

Wave 2 (After Wave 1 — UI integration, MAX PARALLEL):
├── Task 4: Integrate ThumbnailPipeline into recentHistoryCard [quick]
├── Task 5: Add ViewThatFits adaptive info to currentWallpaperCard [visual-engineering]
├── Task 6: Add ViewThatFits adaptive info to recentHistoryCard entries [visual-engineering]
├── Task 7: Add color swatches display component [visual-engineering]
└── Task 8: MenuBarView HistorySheetView thumbnail + rich info [quick]

Wave 3 (After Wave 2 — verification):
└── Task 9: Full build + QA run-through all scenarios [quick]

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 1 → Task 4 → Task 9 → F1-F4
Parallel Speedup: ~55% faster than sequential
Max Concurrent: 5 (Wave 2)
```

### Dependency Matrix

- **1**: - - 4,5,6,7,8
- **2**: - - 4,5,6,7,8
- **3**: - - 4 (validation only, not blocking)
- **4**: 1,2 - 9
- **5**: 1,2 - 9
- **6**: 1,2,4 - 9
- **7**: 1,2 - 9
- **8**: 1,2 - 9
- **9**: 4,5,6,7,8 - F1-F4

### Agent Dispatch Summary

- **Wave 1**: **3** — T1 → `quick`, T2 → `quick`, T3 → `quick`
- **Wave 2**: **5** — T4 → `quick`, T5 → `visual-engineering`, T6 → `visual-engineering`, T7 → `visual-engineering`, T8 → `quick`
- **Wave 3**: **1** — T9 → `quick`
- **FINAL**: **4** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Enrich Wallpaper Model with 5 New Fields

  **What to do**:
  - Modify `VarietyMacOS/Data/Models/Wallpaper.swift`:
    - Add 5 new optional properties after `subreddit` (line 18):
      ```swift
      @Published var tags: [String]?
      @Published var colors: [String]?
      @Published var views: Int?
      @Published var favorites: Int?
      @Published var fileType: String?
      ```
    - Update `init()` to accept new parameters with default `nil` values
    - Add new CodingKeys: `case tags, colors, views, favorites, fileType`
    - Update `init(from decoder:)` to decode new fields with `decodeIfPresent`
    - Update `encode(to encoder:)` to encode new fields with `encodeIfPresent`
    - Add computed property `var colorSwatches: [Color]` that converts hex strings to SwiftUI Colors
    - Add computed property `var fileTypeDisplay: String` that converts "image/jpeg" → "JPEG", "image/png" → "PNG"
    - Add computed property `var viewsDisplay: String` (formatted with commas, e.g., "12,345")

  **Must NOT do**:
  - Do NOT remove any existing fields or CodingKeys
  - Do NOT make new fields non-optional (must preserve backward compat)
  - Do NOT change the encoder/decoder strategy

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Straightforward property addition with Codable handling
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `swiftui-pro`: No UI code, model-only changes
    - `swift-concurrency-pro`: No concurrency changes

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Tasks 4, 5, 6, 7, 8
  - **Blocked By**: None

  **References**:
  - `VarietyMacOS/Data/Models/Wallpaper.swift:6-18` — Current property declarations
  - `VarietyMacOS/Data/Models/Wallpaper.swift:63-68` — Current CodingKeys
  - `VarietyMacOS/Data/Models/Wallpaper.swift:70-89` — Current decoder
  - `VarietyMacOS/Data/Models/Wallpaper.swift:91-110` — Current encoder
  - `VarietyMacOS/Data/Models/Wallpaper.swift:27-59` — Current init

  **Acceptance Criteria**:
  - [ ] 5 new properties compile as `@Published var`
  - [ ] Codable round-trip: encode → decode preserves new fields
  - [ ] Existing wallpaper JSON (without new fields) still decodes (backward compat)
  - [ ] `colorSwatches` computed property returns valid SwiftUI Colors from hex strings
  - [ ] `viewsDisplay` returns comma-formatted string

  **QA Scenarios**:
  ```
  Scenario: Codable round-trip with new fields
    Tool: Bash (swift test or xcodebuild)
    Preconditions: Create a Wallpaper with new fields set
    Steps:
      1. Encode wallpaper to JSON
      2. Decode JSON back to Wallpaper
      3. Assert: tags, colors, views, favorites, fileType match original values
    Expected Result: All new fields survive encode/decode cycle
    Evidence: .sisyphus/evidence/task-1-codable.txt

  Scenario: Backward compatibility with old JSON
    Tool: Bash (swift test)
    Preconditions: JSON string without new fields
    Steps:
      1. Decode old JSON (no tags, colors, views, etc.)
      2. Assert: wallpaper decodes successfully
      3. Assert: tags, colors, views, favorites, fileType are nil
    Expected Result: Old JSON still loads, new fields default to nil
    Evidence: .sisyphus/evidence/task-1-backward-compat.txt

  Scenario: Color hex to SwiftUI Color conversion
    Tool: Bash (swift test)
    Steps:
      1. Create wallpaper with colors: ["#663399", "#cc3333"]
      2. Assert: colorSwatches.count == 2
      3. Assert: First color is purple, second is red-ish
    Expected Result: Hex strings correctly converted to Colors
    Evidence: .sisyphus/evidence/task-1-colors.txt
  ```

  **Commit**: YES (groups with Task 2)
  - Message: `feat: add tags, colors, views, favorites, fileType to Wallpaper model`
  - Files: `VarietyMacOS/Data/Models/Wallpaper.swift`

- [x] 2. Fix WallhavenSource.createWallpaper() — Map ALL Search Fields

  **What to do**:
  - Modify `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift`:
    - In `createWallpaper()` (line 154-170): Map ALL fields from `WallhavenWallpaper` to `Wallpaper`:
      - `tags`: `data.tags?.map { $0.name }` (tag names as string array)
      - `colors`: `data.colors` (hex strings)
      - `views`: `data.views`
      - `favorites`: `data.favorites`
      - `fileType`: `data.fileType`
      - `fileSize`: `data.fileSize` (already available, just pass it)
      - `createdAt`: parse ISO date string `"2018-10-31 01:23:10"` → Date
    - Add a DateFormatter: `yyyy-MM-dd HH:mm:ss` for Wallhaven date strings
    - Change `title` to use the actual title (if available) or fallback to category
    - Change `description` to be more descriptive than just purity string
    - Build: `xcodebuild clean build` to verify compiles

  **Must NOT do**:
  - Do NOT make extra API calls (search-only strategy)
  - Do NOT change the WallhavenSource protocol conformance
  - Do NOT remove existing field mappings

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple data mapping in existing method
  - **Skills**: [`swift-concurrency-pro`]
    - `swift-concurrency-pro`: Verify no async issues in data mapping
  - **Skills Evaluated but Omitted**:
    - `swiftui-pro`: No UI code

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Tasks 4, 5, 6, 7, 8
  - **Blocked By**: None (can run alongside Task 1)

  **References**:
  - `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift:154-170` — Current createWallpaper() to modify
  - `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift:180-201` — WallhavenWallpaper model (source of data)
  - `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift:232-240` — WallhavenTag model (has .name field)
  - `VarietyMacOS/Data/Models/Wallpaper.swift:27-59` — Updated Wallpaper init (Task 1)

  **Acceptance Criteria**:
  - [ ] tags mapped as `data.tags?.map { $0.name }`
  - [ ] colors mapped directly as `data.colors`
  - [ ] views and favorites mapped as Int
  - [ ] fileType mapped as String
  - [ ] fileSize mapped as Int
  - [ ] createdAt parsed from ISO date string
  - [ ] Build succeeds with 0 errors

  **QA Scenarios**:
  ```
  Scenario: Wallhaven wallpaper created with all fields
    Tool: Bash (curl + xcodebuild)
    Preconditions: Network available
    Steps:
      1. Run: curl -s "https://wallhaven.cc/api/v1/search?sorting=random&atleast=1920x1080&seed=123" | python3 -c "
  import json, sys
  data = json.load(sys.stdin)
  w = data['data'][0]
  print(f'tags: {len(w.get(\"tags\",[]))}')
  print(f'colors: {w.get(\"colors\",[])}')
  print(f'views: {w.get(\"views\",0)}')
  print(f'favorites: {w.get(\"favorites\",0)}')
  print(f'fileType: {w.get(\"file_type\",\"\")}')
  "
      2. Verify: API returns tags array (search endpoint DOES NOT return tags — verify this)
      3. Build: xcodebuild clean build → BUILD SUCCEEDED
    Expected Result: All fields available from API, build succeeds
    Evidence: .sisyphus/evidence/task-2-wallhaven-fields.txt

  Scenario: Date parsing works correctly
    Tool: Bash (swift test)
    Steps:
      1. Pass "2018-10-31 01:23:10" to the formatter
      2. Assert: Date object created with correct values
    Expected Result: Wallhaven date format parses correctly
    Evidence: .sisyphus/evidence/task-2-date-parse.txt
  ```

  **Commit**: YES (groups with Task 1)
  - Message: `fix: map all Wallhaven search-result fields to Wallpaper model`
  - Files: `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift`

- [x] 3. Verify Wallhaven API Fields via curl

  **What to do**:
  - Run curl against Wallhaven search API to confirm field availability
  - Check which fields are actually present in search results (not detail endpoint)
  - Verify: tags may NOT be in search results (librarian found this). Adjust Task 2 if needed.
  - Save response sample to evidence file for future reference

  **Must NOT do**:
  - Do NOT modify any code during this task

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: curl commands only, no code changes
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: Task 2 (inform field mapping)
  - **Blocked By**: None

  **References**:
  - Wallhaven API docs: https://wallhaven.cc/help/api

  **Acceptance Criteria**:
  - [ ] API response captured in evidence file
  - [ ] Field presence documented (which fields are in search results)
  - [ ] If tags NOT present, Task 2 plan adjusted (tags = nil for now)
  - [ ] File with sample response saved

  **QA Scenarios**:
  ```
  Scenario: Verify Wallhaven search endpoint response
    Tool: Bash (curl)
    Steps:
      1. Run: curl -s "https://wallhaven.cc/api/v1/search?sorting=random&atleast=1920x1080&seed=42" > /tmp/wallhaven-sample.json
      2. Check: cat /tmp/wallhaven-sample.json | python3 -c "
  import json, sys
  data = json.load(sys.stdin)
  w = data['data'][0]
  print('Fields present:')
  for k in w.keys():
      print(f'  {k}: {type(w[k]).__name__}')
      "
      3. Document which of these are present: tags, colors, views, favorites, file_type, file_size, created_at
    Expected Result: Field presence confirmed and documented
    Evidence: .sisyphus/evidence/task-3-api-fields.txt
  ```

  **Commit**: NO
  - (Investigation only, no code changes)

---

- [x] 4. Integrate ThumbnailPipeline into Recent History Card

  **What to do**:
  - Modify `VarietyMacOS/VarietyMacOSApp.swift` recentHistoryCard (lines 332-380):
    - Replace static `Image(systemName: "photo")` (line 357) with async thumbnail loading
    - Create a `ThumbnailPipeline` instance (no `.shared` singleton, instantiate directly)
    - For each entry: use `.task` modifier to call `let pipeline = ThumbnailPipeline(); await pipeline.thumbnail(for:)`
    - Bridge NSImage → Image: `Image(nsImage: thumbnail)`
    - Handle nil wallpaper (decoded entries): show `Image(systemName: "questionmark.circle")` fallback
    - Add loading state: show `ProgressView()` while thumbnail loads
    - Add error state: show `Image(systemName: "photo")` on failure
    - Cancel task on disappear (use `.task` for auto-cancellation)
    - Add pre-warming: call `let pipeline = ThumbnailPipeline(); await pipeline.prewarmCache(for:)` on `.onAppear`

  **Must NOT do**:
  - Do NOT call Wallpaper.loadImage() (uses full image, not thumbnail)
  - Do NOT create new View structs (keep inline in ContentView)
  - Do NOT remove text-only information (title + timestamp stay)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: View modification with pipeline integration, clear pattern
  - **Skills**: [`swiftui-pro`, `swift-concurrency-pro`]
    - `swiftui-pro`: SwiftUI .task modifier and async image loading patterns
    - `swift-concurrency-pro`: @MainActor Task cancellation
  - **Skills Evaluated but Omitted**:
    - `impeccable`: Visual polish handled in Tasks 5-7

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 7, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2

  **References**:
  - `VarietyMacOS/VarietyMacOSApp.swift:332-380` — Current recentHistoryCard to modify
  - `VarietyMacOS/Pipeline/ThumbnailPipeline.swift` — thumbnail(for:) and prewarmCache(for:) interface
  - `VarietyMacOS/Data/Models/WallpaperHistory.swift:121-157` — HistoryEntry model (wallpaper may be nil)
  - `VarietyMacOS/Pipeline/ThumbnailTypes.swift` — ThumbnailResult type

  **Acceptance Criteria**:
  - [ ] History entries show actual wallpaper thumbnails (not SF Symbol)
  - [ ] Thumbnails load asynchronously without blocking UI
  - [ ] Loading state shows ProgressView spinner
  - [ ] Error state falls back to photo SF Symbol
  - [ ] Nil wallpaper entries show questionmark.circle
  - [ ] Prefetch triggers on history card appear

  **QA Scenarios**:
  ```
  Scenario: Thumbnails load in history card after wallpaper fetch
    Tool: Build + Playwright
    Preconditions: Fresh app with no history
    Steps:
      1. Launch app
      2. Click "Next Wallpaper" → wait for wallpaper to apply
      3. Scroll to Recent History card
      4. Assert: card shows 1 entry
      5. Wait up to 5s for thumbnail to load
      6. Assert: entry shows actual image thumbnail (not photo SF Symbol)
      7. Assert: entry still shows title and timestamp
      8. Click "Next Wallpaper" again
      9. Assert: card now shows 2 entries, both with thumbnails
    Expected Result: History shows real thumbnails for all entries
    Evidence: .sisyphus/evidence/task-4-history-thumbnails.png

  Scenario: Thumbnails survive app restart (cache hit)
    Tool: Build + Playwright
    Preconditions: History has entries with loaded thumbnails
    Steps:
      1. Close app
      2. Reopen app
      3. Scroll to Recent History card
      4. Assert: thumbnails load from disk cache (ThumbnailCache)
      5. Assert: load time < 1s per thumbnail
    Expected Result: Cached thumbnails persist across restarts
    Evidence: .sisyphus/evidence/task-4-cache-persistence.png
  ```

  **Commit**: YES
  - Message: `feat: integrate ThumbnailPipeline into Recent History card`
  - Files: `VarietyMacOS/VarietyMacOSApp.swift`

- [x] 5. Add ViewThatFits Adaptive Info to Current Wallpaper Card

  **What to do**:
  - Modify `VarietyMacOS/VarietyMacOSApp.swift` currentWallpaperCard (lines 117-196):
    - Wrap the info panel section (lines 141-177) in `ViewThatFits(in: .horizontal)`:
      - **Compact view** (small window):
        - Source badge + title (1 line)
        - Resolution + file type (1 line)
      - **Full view** (large window, min 500px):
        - Source badge + title + author (1-2 lines)
        - Resolution + file type + file size (1 line)
        - If Wallhaven: views count, favorites count (1 line)
        - If Wallhaven: color swatches row (5-6 small circles)
        - Date (createdAt or downloadDate) (1 line)
    - Add `if let colors = wallpaper.colors` color swatches:
      - HStack of small circles (16x16) with border
      - Each circle filled with hex color
      - Max 6 colors displayed
    - Keep existing image display section unchanged

  **Must NOT do**:
  - Do NOT remove the main image display section (lines 130-138)
  - Do NOT remove the no-wallpaper placeholder state (lines 179-194)
  - Do NOT change the card's overall padding/corner radius

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: UI layout with adaptive sizing, color display, information hierarchy
  - **Skills**: [`swiftui-pro`, `impeccable`]
    - `swiftui-pro`: ViewThatFits and adaptive layout patterns
    - `impeccable`: Visual polish, information hierarchy, color swatch design
  - **Skills Evaluated but Omitted**:
    - `swift-concurrency-pro`: No concurrency changes

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6, 7, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2

  **References**:
  - `VarietyMacOS/VarietyMacOSApp.swift:117-196` — Current currentWallpaperCard to modify
  - `VarietyMacOS/VarietyMacOSApp.swift:141-177` — Info panel section to wrap in ViewThatFits
  - `VarietyMacOS/Data/Models/Wallpaper.swift:114-136` — Computed properties (displayTitle, resolutionString, fileSizeString)
  - `VarietyMacOS/Data/Models/Wallpaper.swift` — New colorSwatches, viewsDisplay, fileTypeDisplay (Task 1)

  **Acceptance Criteria**:
  - [ ] Compact layout shows: source + title + resolution + fileType
  - [ ] Full layout adds: author, views, favorites, color swatches, date
  - [ ] Color swatches display as small filled circles with white border
  - [ ] Transition between layouts is automatic (no manual toggle)
  - [ ] Both layouts fit without scrolling at their target sizes
  - [ ] Compact layout works at 400px window width
  - [ ] Full layout activates at ~500px+ window width

  **QA Scenarios**:
  ```
  Scenario: Compact view at small window size
    Tool: Build + Playwright
    Preconditions: Wallpaper loaded with rich metadata
    Steps:
      1. Launch app, resize window to 420px width
      2. Observe Current Wallpaper card info section
      3. Assert: Shows source badge, title, resolution, file type
      4. Assert: Does NOT show author, views, favorites, colors
      5. Screenshot compact view
    Expected Result: Compact layout, clean and minimal
    Evidence: .sisyphus/evidence/task-5-compact-view.png

  Scenario: Full view at large window size
    Tool: Build + Playwright
    Preconditions: Same wallpaper loaded
    Steps:
      1. Resize window to 700px width
      2. Observe Current Wallpaper card info section
      3. Assert: Shows author name, views count, favorites count
      4. Assert: Color swatches row visible (small colored circles)
      5. Assert: Date displayed
      6. Screenshot full view
    Expected Result: Full layout with all metadata visible
    Evidence: .sisyphus/evidence/task-5-full-view.png

  Scenario: Smooth transition between sizes
    Tool: Build + Playwright
    Steps:
      1. Start at 420px → capture
      2. Drag resize to 700px → capture
      3. Assert: Transition at ~500px
      4. Drag back to 420px → capture
    Expected Result: Seamless ViewThatFits transition, no glitches
    Evidence: .sisyphus/evidence/task-5-transition.png
  ```

  **Commit**: YES (groups with Task 6)
  - Message: `feat: add adaptive info panel to Current Wallpaper card`
  - Files: `VarietyMacOS/VarietyMacOSApp.swift`

- [x] 6. Add Adaptive Info to Recent History Card Entries

  **What to do**:
  - Modify `VarietyMacOS/VarietyMacOSApp.swift` recentHistoryCard entry row (lines 356-373):
    - Wrap info text in `ViewThatFits(in: .horizontal)`:
      - **Compact**: source icon + title (1 line) + timestamp
      - **Full**: source icon + title + author (1 line) + resolution + fileType + timestamp (1 line)
    - Keep thumbnail on the left (unchanged size: 40x40)
    - Use `.lineLimit(1)` for all text lines

  **Must NOT do**:
  - Do NOT make thumbnails bigger (keep 40x40 to avoid dominating the card)
  - Do NOT remove the timestamp display
  - Do NOT change the card's padding or background

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Adaptive list item layout with info hierarchy
  - **Skills**: [`swiftui-pro`, `impeccable`]
    - `swiftui-pro`: ViewThatFits in list items
    - `impeccable`: Typography, spacing, visual rhythm in list items
  - **Skills Evaluated but Omitted**:
    - `swift-concurrency-pro`: No concurrency changes

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 7, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2, 4

  **References**:
  - `VarietyMacOS/VarietyMacOSApp.swift:355-373` — Current history entry row to modify
  - `VarietyMacOS/VarietyMacOSApp.swift:141-177` — Task 5 adaptive info pattern to follow
  - `VarietyMacOS/Data/Models/Wallpaper.swift:114-136` — Computed properties

  **Acceptance Criteria**:
  - [ ] Compact: shows source icon + title + timestamp
  - [ ] Full: adds author name, resolution, file type
  - [ ] Entries have consistent height in both modes
  - [ ] Thumbnail stays 40x40 in both modes
  - [ ] Works with 5 entries without scrolling

  **QA Scenarios**:
  ```
  Scenario: History entries adapt to window width
    Tool: Build + Playwright
    Preconditions: 3+ history entries with rich metadata
    Steps:
      1. Resize to 420px → observe history entries
      2. Assert: Each shows icon + title + timestamp (compact)
      3. Screenshot compact
      4. Resize to 700px
      5. Assert: Each shows icon + title + author + resolution + timestamp (full)
      6. Screenshot full
    Expected Result: Entries show richer info at larger sizes
    Evidence: .sisyphus/evidence/task-6-history-adaptive.png
  ```

  **Commit**: YES (groups with Task 5)
  - Message: `feat: add adaptive info to Recent History card entries`
  - Files: `VarietyMacOS/VarietyMacOSApp.swift`

- [x] 7. Add Color Swatches Display Component

  **What to do**:
  - Add a reusable view in `VarietyMacOS/VarietyMacOSApp.swift` (near FlowLayout or at bottom):
    - Create `WallpaperColorSwatches` view:
      - `let colors: [String]` (hex codes)
      - `let maxDisplay: Int = 6`
      - HStack of colored circles (16x16)
      - White border (1px) around each circle
      - If > maxDisplay colors: show "+N" badge
      - Tooltip/first color has a subtle outline to distinguish from background
    - Integrate into:
      - currentWallpaperCard full view (Task 5)
      - (Future: history entries if needed)
  - Use `Color(hex:)` extension or inline hex parsing:
    ```swift
    extension Color {
        init(hex: String) {
            let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let r = Double((int >> 16) & 0xFF) / 255
            let g = Double((int >> 8) & 0xFF) / 255
            let b = Double(int & 0xFF) / 255
            self.init(red: r, green: g, blue: b)
        }
    }
    ```

  **Must NOT do**:
  - Do NOT use 3rd party color libraries
  - Do NOT create a separate Swift file (keep in VarietyMacOSApp.swift)

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Visual component with color handling and layout
  - **Skills**: [`swiftui-pro`, `impeccable`]
    - `swiftui-pro`: SwiftUI component patterns
    - `impeccable`: Color swatch visual design (size, spacing, borders)
  - **Skills Evaluated but Omitted**:
    - `swift-concurrency-pro`: No concurrency changes

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6, 8)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2

  **References**:
  - `VarietyMacOS/VarietyMacOSApp.swift:595-634` — FlowLayout pattern (style to follow)
  - `VarietyMacOS/Data/Models/Wallpaper.swift` — colors field type is [String]? (hex codes)
  - `VarietyMacOS/Data/Models/Wallpaper.swift` — colorSwatches computed property (Task 1)

  **Acceptance Criteria**:
  - [ ] Colors display as small circles (16x16) with white borders
  - [ ] Hex string "#663399" renders as purple circle
  - [ ] Max 6 colors displayed, "+2" badge for overflow
  - [ ] Circles are evenly spaced with 4px gaps
  - [ ] Handles nil/empty colors gracefully (shows nothing)

  **QA Scenarios**:
  ```
  Scenario: Color swatches render correctly
    Tool: Build + Playwright
    Steps:
      1. Create wallpaper with colors: ["#663399", "#cc3333", "#3399cc", "#99cc33", "#333333", "#ff9900"]
      2. Observe Current Wallpaper card in full mode
      3. Assert: 6 colored circles visible
      4. Assert: Each circle has correct approximate color (purple, red, blue, green, dark, orange)
      5. Screenshot
    Expected Result: Correct color swatches displayed
    Evidence: .sisyphus/evidence/task-7-swatches.png

  Scenario: Overflow handled with +N badge
    Tool: Build + Playwright
    Steps:
      1. Create wallpaper with 8 colors
      2. Assert: 6 circles + "+2" text badge
    Expected Result: Overflow indicator visible
    Evidence: .sisyphus/evidence/task-7-overflow.png
  ```

  **Commit**: YES
  - Message: `feat: add color swatches display component for wallpaper metadata`
  - Files: `VarietyMacOS/VarietyMacOSApp.swift`

- [x] 8. MenuBarView HistorySheetView Thumbnail + Rich Info

  **What to do**:
  - Modify `VarietyMacOS/App/MenuBarView.swift` HistorySheetView (find the history sheet struct):
    - Replace static icon with async thumbnail via ThumbnailPipeline (same pattern as Task 4)
    - Add richer info display (same ViewThatFits pattern as Task 6)
    - Keep existing Done button and layout structure

  **Must NOT do**:
  - Do NOT change the sheet presentation (keep .sheet)
  - Do NOT change the Done button

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Same pattern as Tasks 4 + 6, applied to a different view
  - **Skills**: [`swiftui-pro`, `swift-concurrency-pro`]
    - `swiftui-pro`: Sheet view thumbnail patterns
    - `swift-concurrency-pro`: @MainActor task handling
  - **Skills Evaluated but Omitted**:
    - `impeccable`: Already handled in Tasks 5-7

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6, 7)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 1, 2

  **References**:
  - `VarietyMacOS/App/MenuBarView.swift` — HistorySheetView to modify
  - `VarietyMacOS/VarietyMacOSApp.swift` — Task 4 thumbnail pattern to copy
  - `VarietyMacOS/Pipeline/ThumbnailPipeline.swift` — thumbnail(for:) interface

  **Acceptance Criteria**:
  - [ ] HistorySheetView shows thumbnails (not SF Symbols)
  - [ ] Thumbnails load asynchronously
  - [ ] Richer metadata displayed (same compact/full pattern)
  - [ ] Done button still dismisses sheet

  **QA Scenarios**:
  ```
  Scenario: MenuBar history shows thumbnails
    Tool: Build + Playwright
    Steps:
      1. Open MenuBarView popover
      2. Click "History..."
      3. Assert: HistorySheetView shows entries with thumbnails
      4. Assert: Entries show richer info (title + resolution + timestamp)
      5. Click Done → sheet dismisses
    Expected Result: History sheet shows thumbnails and metadata
    Evidence: .sisyphus/evidence/task-8-menubar-history.png
  ```

  **Commit**: YES
  - Message: `fix: add thumbnails and rich info to MenuBarView history sheet`
  - Files: `VarietyMacOS/App/MenuBarView.swift`

---

- [x] 9. Full Build + QA Run-through All Scenarios

  **What to do**:
  - Run `xcodebuild clean build` — verify 0 errors, 0 warnings
  - Execute all QA scenarios from Tasks 1-8 in sequence
  - Capture evidence screenshots
  - Verify backward compatibility: old wallpaper JSON still decodes
  - Report results summary

  **Must NOT do**:
  - Do NOT modify any code during QA
  - Do NOT skip any scenario

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Structured verification, no code changes
  - **Skills**: [`swiftui-pro`]
    - `swiftui-pro`: UI verification guidance
  - **Skills Evaluated but Omitted**:
    - `swift-testing-pro`: Not writing tests

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (after all Wave 2 tasks)
  - **Blocks**: Final Verification Wave
  - **Blocked By**: Tasks 4, 5, 6, 7, 8

  **References**:
  - All evidence files from Tasks 1-8
  - `.sisyphus/evidence/` directory

  **Acceptance Criteria**:
  - [ ] `xcodebuild clean build` → BUILD SUCCEEDED, 0 warnings
  - [ ] All 8 task-specific QA scenarios pass
  - [ ] Backward compatibility verified
  - [ ] Evidence files captured for all scenarios

  **QA Scenarios**:
  ```
  Scenario: Full build succeeds
    Tool: Bash (xcodebuild)
    Steps:
      1. Run: xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -destination 'platform=macOS' clean build
      2. Assert: BUILD SUCCEEDED
      3. Assert: 0 warnings
    Expected Result: Clean build
    Evidence: .sisyphus/evidence/task-9-build.txt

  Scenario: Full QA matrix
    Tool: Build + Playwright + Bash
    Steps:
      1. Build app
      2. Launch app
      3. Execute Task 4 scenarios (history thumbnails)
      4. Execute Task 5 scenarios (current wallpaper adaptive)
      5. Execute Task 6 scenarios (history adaptive)
      6. Execute Task 7 scenarios (color swatches)
      7. Execute Task 8 scenarios (menubar history)
      8. Verify all evidence files exist
    Expected Result: All QA scenarios pass
    Evidence: .sisyphus/evidence/task-9-qa-summary.md
  ```

  **Commit**: NO
  - (QA only, no code changes)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.
>
> **Do NOT auto-proceed after verification. Wait for user's explicit approval.**

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run app). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .sisyphus/evidence/.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [9/9] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Run `xcodebuild clean build`. Review all changed files for: force-unwraps, empty catch blocks, `print()` instead of `Logger`, unused imports. Check AI slop: excessive comments, over-abstraction, generic names (data/result/item/temp).
  Output: `Build [PASS/FAIL] | Lint [N issues] | VERDICT: APPROVE/REJECT`

- [x] F3. **Real Manual QA** — `unspecified-high` (+ `playwright` skill)
  Start from clean build. Execute EVERY QA scenario from EVERY task — follow exact steps, capture evidence. Test cross-task integration: thumbnails in both ContentView AND MenuBarView. Test backward compatibility: old history JSON still loads. Test edge cases: nil wallpaper entries, missing colors, empty tags.
  Output: `Bug-1 [FIXED/NOT] | Feature-2 [DONE/NOT] | Feature-3 [DONE/NOT] | Integration [N/N] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: "What to do" vs actual diff. Verify no scope creep. Check "Must NOT do" compliance. Detect cross-task contamination. Flag unaccounted changes.
  Output: `Tasks [9/9 compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `feat: enrich Wallpaper model and Wallhaven source`
  - T1-T2: `VarietyMacOS/Data/Models/Wallpaper.swift`, `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift`

- **Wave 2**: `feat: ThumbnailPipeline integration, adaptive info, color swatches`
  - T4: `VarietyMacOS/VarietyMacOSApp.swift`
  - T5-T6-T7: `VarietyMacOS/VarietyMacOSApp.swift`
  - T8: `VarietyMacOS/App/MenuBarView.swift`

- **Wave 3**: `chore: QA run-through, all evidence captured`
  - T9: No code changes

---

## Success Criteria

### Verification Commands
```bash
# Build
xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -destination 'platform=macOS' clean build

# Wallhaven API field check
curl -s "https://wallhaven.cc/api/v1/search?sorting=random&atleast=1920x1080&seed=42" | python3 -c "
import json, sys
d = json.load(sys.stdin)['data'][0]
print('Fields:', sorted(d.keys()))
"

# Memory check (after 10 fetches)
# Instruments Memory Debugger → < 150MB peak
```

### Final Checklist
- [ ] All "Must Have" present (ThumbnailPipeline integration, model enrichment, adaptive info, color swatches)
- [ ] All "Must NOT Have" absent (no detail API calls, no protocol changes, no new files, no extra deps)
- [ ] All 9 tasks completed
- [ ] Build succeeds with 0 errors
- [ ] Recent History shows real thumbnails (not SF Symbols)
- [ ] Wallhaven wallpapers show views, favorites, colors, fileType
- [ ] Info panels adapt to window size (compact ↔ full)
- [ ] Backward compatibility: existing history JSON still decodes
- [ ] Existing P0 supplement fixes (Tasks 1-6) still work (no regression)