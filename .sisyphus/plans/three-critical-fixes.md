# Three Critical Fixes: Cold Start, Fetch Success Rate, Ambilight Effect

## TL;DR
> Fix three blocking issues in VarietyMacOS Pro: (1) cold start wallpaper image never displays due to `@Transient` cachedImage not triggering SwiftUI observation, (2) wallpaper fetch returns same images due to Picsum cache key bug and source dedup failures, (3) Ambilight effect colors are too similar and don't radiate from the right column detail image.
>
> **Deliverables**:
> - Cold start always shows current desktop wallpaper in both middle and right columns
> - "Next Wallpaper" successfully fetches a different image ≥80% of the time
> - Ambilight effect radiates vivid, distinct colors from right column image edges
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 1 (SwiftUI observation) → Task 4 (fetch pipeline) → Task 7 (Ambilight)

---

## Context

### Original Request
User reported three critical issues after running the app:
1. Cold start: right column blank, middle column shows loading spinner forever
2. Clicking "Next Wallpaper" frequently fails to get a new/different image
3. Background Ambilight effect doesn't look like Philips Ambilight — colors not radiating from right column

### Interview Summary
**Key Discussions**:
- User provided 3 screenshots (1.png, 2.png, 3.png) showing each issue
- User provided full runtime logs showing exact error patterns
- Root cause analysis performed via code reading + log analysis + 4 parallel explore/librarian agents

**Research Findings**:
- macOS-Ambient-Lighting project: uses CGWindowListCreateImage + dominant color extraction
- Hyperion: downsamples to 64x64, uses LED zone mapping for color extraction
- Muzei-macOS: protocol-based source rotation with proper fallback
- Kingfisher: handles redirect URLs by using the final URL as cache key
- Picsum Photos: `picsum.photos/1920/1080` redirects to `fastly.picsum.photos/id/XXX/...` — different each time

### Metis Review
**Identified Gaps** (addressed):
- `@Transient` property changes don't auto-trigger SwiftUI observation on `@Model` objects — need manual `objectWillChange.send()` or a wrapper
- `clearCachedImage()` in `fetchNewWallpaper()` destroys current display before new one ready — must remove
- Picsum cache key uses original URL, not redirect URL — must use final URL or add nonce
- Wallhaven "random" sorting with empty query returns same first page — must add random page parameter
- Bing Daily only returns 1 image per day — must fetch multiple days and pick random
- DuplicateChecker compares `wallpaper.id` which may be generated identically per source — must compare by `remoteURL.absoluteString`
- Ambilight `onChange(of: wallpaper)` doesn't fire when `cachedImage` changes on the same Wallpaper object

---

## Work Objectives

### Core Objective
Fix three blocking issues so the app works reliably: wallpaper displays on cold start, fetching produces different images, and Ambilight creates a convincing radiating glow effect from the right column.

### Concrete Deliverables
- Cold start: both middle and right columns show current desktop wallpaper image
- "Next Wallpaper": ≥80% success rate for fetching a visually different image
- Ambilight: vivid, distinct edge colors radiating outward from the right column detail image

### Definition of Done
- [ ] `killall VarietyMacOS && open VarietyMacOS.app` → both columns show wallpaper within 2 seconds
- [ ] Click "Next Wallpaper" 5 times → at least 4 produce different images
- [ ] Ambilight background shows distinct colors that match the right column image's edge colors
- [ ] No `noImageAvailable` errors in console for desktop wallpaper loading
- [ ] No `NSURLError -999` cancellation errors during normal operation
- [ ] Build succeeds with zero errors

### Must Have
- Cold start wallpaper image displayed in CurrentWallpaperView AND DetailPlaceholderView
- Picsum cache correctly handles redirect URLs (different image each time)
- Wallhaven fetches from random pages
- Bing fetches from multiple days
- Ambilight extracts distinct edge colors using top-K dominant color algorithm
- Ambilight glow positions radiate from the right column image edges
- `clearCachedImage()` removed from `fetchNewWallpaper()`

### Must NOT Have (Guardrails)
- Must NOT change the NavigationSplitView layout (3-column structure stays)
- Must NOT remove any wallpaper sources (Bing, Wallhaven, Picsum all stay)
- Must NOT add new wallpaper sources
- Must NOT rewrite the entire WallpaperManager or app architecture
- Must NOT use demo/mock data — all images must be real
- Must NOT add unnecessary comments/docstrings
- Must NOT create "simplified" versions of any component

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: NO (no unit test framework configured)
- **Automated tests**: None
- **Framework**: none
- **Agent-Executed QA**: ALWAYS (mandatory for all tasks)

### QA Policy
Every task MUST include agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.
- **macOS App UI**: Build the app, launch it, use `screencapture` + `look_at` multimodal agent for verification
- **Console logs**: Run app, capture `log show` output, verify expected log messages appear
- **Build**: `xcodebuild` must return BUILD SUCCEEDED

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - foundational fixes):
├── Task 1: Fix @Transient cachedImage SwiftUI observation [quick]
├── Task 2: Remove clearCachedImage() from fetchNewWallpaper [quick]
└── Task 3: Fix loadLastWallpaper guaranteed image loading [quick]

Wave 2 (After Wave 1 - fetch pipeline fixes):
├── Task 4: Fix Picsum cache key for redirect URLs [quick]
├── Task 5: Fix Wallhaven random page fetching [quick]
├── Task 6: Fix Bing multi-day fetching + duplicate detection [unspecified-high]
└── Task 7: Prevent NSURLError -999 rapid click cancellation [quick]

Wave 3 (After Wave 2 - Ambilight visual overhaul):
├── Task 8: Rewrite AmbilightColorExtractor with top-K dominant colors [deep]
└── Task 9: Rewrite AmbilightEffect glow positioning from right column [visual-engineering]

Wave FINAL (After ALL tasks):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA - build, launch, verify all 3 fixes (unspecified-high)
└── Task F4: Scope fidelity check (deep)
```

### Dependency Matrix
- **1, 2, 3**: No dependencies (can run in parallel)
- **4, 5, 6, 7**: Depend on Wave 1 completing (need stable image loading first)
- **8**: Depends on Wave 2 (needs varied images to test color extraction)
- **9**: Depends on 8 (needs new color extractor)
- **F1-F4**: Depend on ALL tasks completing

### Agent Dispatch Summary
- **Wave 1**: 3 tasks — all `quick`
- **Wave 2**: 4 tasks — T4-T5,T7 → `quick`, T6 → `unspecified-high`
- **Wave 3**: 2 tasks — T8 → `deep`, T9 → `visual-engineering`
- **FINAL**: 4 tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Fix `@Transient` cachedImage SwiftUI Observation
- [x] 2. Remove `clearCachedImage()` from `fetchNewWallpaper()`
- [x] 3. Fix `loadLastWallpaper()` Guaranteed Image Loading
- [x] 4. Fix Picsum Cache Key for Redirect URLs

**What to do**:
- In `Wallpaper.swift`, add a manual `objectWillChange.send()` call whenever `cachedImage` is set
- Create a computed property or willSet/didSet pattern that notifies observers when cachedImage changes
- Since `@Model` classes conform to `Observable`, add a `setCachedImage(_ image: NSImage?)` method that sets the property AND calls `objectWillChange.send()`
- Replace all direct `wallpaper.cachedImage = image` assignments with `wallpaper.setCachedImage(image)`
- Replace all `wallpaper.cachedImage = nil` with `wallpaper.setCachedImage(nil)`
- In `CurrentWallpaperView.swift`, remove the separate `objectWillChange.send()` call in `reloadCurrentWallpaperImage()` (it will be handled by the new method)

**Must NOT do**:
- Must NOT make `cachedImage` a persisted SwiftData property (it's intentionally transient)
- Must NOT add `@Published` wrapper (incompatible with `@Model`)
- Must NOT change the `@Transient` annotation

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: [`swiftui-pro`]
- `swiftui-pro`: Needed for understanding SwiftUI observation patterns with SwiftData @Model
- **Skills Evaluated but Omitted**:
  - `swift-concurrency-pro`: Not needed — no complex async patterns

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1 (with Tasks 2, 3)
- **Blocks**: Tasks 4-9 (all depend on images displaying correctly)
- **Blocked By**: None

**References**:
**Pattern References**:
- `VarietyMacOS/Data/Models/Wallpaper.swift:39-40` — `@Transient var cachedImage: NSImage?` — the property that needs observation
- `VarietyMacOS/Data/Models/Wallpaper.swift:178-205` — `loadImage()` function — sets cachedImage without notifying
- `VarietyMacOS/App/CurrentWallpaperView.swift:89-101` — checks `wallpaper.cachedImage` for display
- `VarietyMacOS/App/CurrentWallpaperView.swift:248-255` — `reloadCurrentWallpaperImage()` — manually calls `objectWillChange.send()`

**API/Type References**:
- `VarietyMacOS/Data/Models/Wallpaper.swift:7` — `@Model final class Wallpaper` — SwiftData model class

**External References**:
- Apple docs: SwiftData `@Model` and `@Transient` observation behavior — `@Transient` properties are excluded from auto-generated observation

**WHY Each Reference Matters**:
- Wallpaper.swift:39-40 shows the exact property declaration to wrap
- Wallpaper.swift:178-205 shows all places where cachedImage is assigned that need the new method
- CurrentWallpaperView.swift:89-101 shows the UI that reads cachedImage — must react to changes
- CurrentWallpaperView.swift:248-255 shows existing manual notification that can be removed

**Acceptance Criteria**:
- [ ] `Wallpaper.swift` has a `setCachedImage(_:)` method that calls `objectWillChange.send()`
- [ ] All `cachedImage = image` assignments replaced with `setCachedImage(image)`
- [ ] All `cachedImage = nil` assignments replaced with `setCachedImage(nil)`
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Cold start cachedImage triggers UI update
Tool: Bash (xcodebuild + launch + log capture)
Preconditions: App not running, desktop wallpaper set
Steps:
  1. Run: xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -configuration Debug build
  2. Run: killall VarietyMacOS 2>/dev/null; sleep 1
  3. Run: open /tmp/XcodeBuild/Build/Products/Debug/VarietyMacOS.app
  4. Wait 5 seconds
  5. Run: log show --predicate 'processImagePath contains "VarietyMacOS"' --last 10s | grep -E "(Loaded current|setCachedImage)"
Expected Result: Console shows "Loaded current desktop wallpaper" with image size
Failure Indicators: No image loading log, or "noImageAvailable" error
Evidence: .sisyphus/evidence/task-1-cold-start-observation.txt
```

**Commit**: YES
- Message: `fix(wallpaper): Add manual observation for @Transient cachedImage`
- Files: `VarietyMacOS/Data/Models/Wallpaper.swift`, `VarietyMacOS/App/CurrentWallpaperView.swift`
- Pre-commit: `xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -configuration Debug build`

---

- [x] 2. Remove `clearCachedImage()` from `fetchNewWallpaper()`

**What to do**:
- In `WallpaperManager.swift` line 160, remove `currentWallpaper?.clearCachedImage()`
- This call destroys the currently displayed image BEFORE the new one is ready, causing a blank flicker
- The old wallpaper's cachedImage should remain until the new wallpaper is fully loaded and applied
- The new wallpaper's `applyWallpaper()` already sets `currentWallpaper = wallpaper` which replaces the old object

**Must NOT do**:
- Must NOT add a new clearCachedImage call elsewhere in the fetch pipeline
- Must NOT modify the `applyWallpaper()` function

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: []
- **Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1 (with Tasks 1, 3)
- **Blocks**: Tasks 4-9
- **Blocked By**: None

**References**:
**Pattern References**:
- `VarietyMacOS/Core/WallpaperManager.swift:160` — `currentWallpaper?.clearCachedImage()` — the line to remove
- `VarietyMacOS/Core/WallpaperManager.swift:248` — `currentWallpaper = wallpaper` in applyWallpaper — replaces old wallpaper object

**WHY Each Reference Matters**:
- Line 160 is the exact line causing the flicker/disappearing image
- Line 248 shows the replacement happens safely in applyWallpaper

**Acceptance Criteria**:
- [ ] `clearCachedImage()` call removed from `fetchNewWallpaper()`
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Image doesn't disappear during fetch
Tool: Bash (build + launch + log)
Preconditions: App running with current wallpaper displayed
Steps:
  1. Build and launch app
  2. Wait for wallpaper to display
  3. Click "Next Wallpaper"
  4. Observe: current image should remain visible until new one loads
Expected Result: No blank flicker between wallpapers
Failure Indicators: Screen goes blank/gray before new image appears
Evidence: .sisyphus/evidence/task-2-no-flicker.txt
```

**Commit**: YES (group with Task 3)
- Message: `fix(fetch): Remove clearCachedImage from fetchNewWallpaper`
- Files: `VarietyMacOS/Core/WallpaperManager.swift`

---

- [x] 3. Fix `loadLastWallpaper()` Guaranteed Image Loading

**What to do**:
- In `WallpaperManager.swift`, modify `loadLastWallpaper()` to GUARANTEE `cachedImage` is set
- For desktop wallpapers: after `NSImage(contentsOf:)` succeeds, call `desktopWallpaper.setCachedImage(image)` (using new method from Task 1)
- If `NSImage(contentsOf:)` fails for the desktop wallpaper, try using `NSWorkspace.shared.desktopImageURL(for:)` + `NSImage(contentsOf:)` with a retry
- Add `objectWillChange.send()` after setting `currentWallpaper` in `loadLastWallpaper()`
- Remove the `retryDesktopWallpaperLoad()` async retry that runs in `init()` — it's unreliable and creates race conditions
- Instead, if the image can't be loaded synchronously in `init()`, schedule a delayed MainActor task that re-checks and loads

**Must NOT do**:
- Must NOT remove the fallback to `Preferences.shared.lastWallpaper`
- Must NOT add long delays that block app startup

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: [`swiftui-pro`]
- `swiftui-pro`: SwiftUI lifecycle and @MainActor patterns

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1 (with Tasks 1, 2)
- **Blocks**: Tasks 4-9
- **Blocked By**: Task 1 (needs `setCachedImage()` method)

**References**:
**Pattern References**:
- `VarietyMacOS/Core/WallpaperManager.swift:407-470` — `loadLastWallpaper()` function — needs guaranteed image loading
- `VarietyMacOS/Core/WallpaperManager.swift:45-87` — `retryDesktopWallpaperLoad()` — unreliable, should be simplified
- `VarietyMacOS/Core/WallpaperManager.swift:30-42` — `init()` with retry Task — should be simplified

**WHY Each Reference Matters**:
- loadLastWallpaper is the entry point for cold start — must guarantee image
- retryDesktopWallpaperLoad is the unreliable async retry — needs simplification
- init shows where retry is launched — needs cleanup

**Acceptance Criteria**:
- [ ] `loadLastWallpaper()` uses `setCachedImage()` for all image assignments
- [ ] `objectWillChange.send()` called after setting `currentWallpaper`
- [ ] `retryDesktopWallpaperLoad()` simplified or removed
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Cold start shows wallpaper in both columns
Tool: Bash (build + launch + screenshot + look_at)
Preconditions: App not running, desktop wallpaper is a visible image
Steps:
  1. Run: killall VarietyMacOS 2>/dev/null; sleep 1
  2. Run: open /tmp/XcodeBuild/Build/Products/Debug/VarietyMacOS.app
  3. Wait 5 seconds
  4. Run: screencapture -x /tmp/cold_start_test.png
  5. Use look_at agent to analyze: "Is there a wallpaper image visible in both the middle and right columns?"
Expected Result: Both columns show the current desktop wallpaper image
Failure Indicators: Spinner visible, blank right column, "Select a wallpaper" text
Evidence: .sisyphus/evidence/task-3-cold-start-display.png
```

**Commit**: YES (group with Task 2)
- Message: `fix(cold-start): Guarantee cachedImage loaded on startup`
- Files: `VarietyMacOS/Core/WallpaperManager.swift`

---

- [x] 4. Fix Picsum Cache Key for Redirect URLs

**What to do**:
- In `ImageCacheManager.swift`, modify `getImage(for:from:)` to handle HTTP redirects
- Use `URLSession.shared.data(from:)` which automatically follows redirects, BUT capture the final URL after redirect
- Change the cache key for Picsum images: instead of using the original URL (`remote_picsum.photos_/1920/1080`), use the redirected URL (`remote_fastly.picsum.photos_/id/724/...`)
- OR: add a random UUID/timestamp to the cache key for sources that use redirect-based random images
- Implement: after downloading, check if the response URL differs from the request URL — if so, also cache under the final URL
- For Picsum specifically: the `Wallpaper.cacheKey` computed property should include a unique nonce when the source is Picsum (or any source with redirect-based randomness)

**Must NOT do**:
- Must NOT disable disk caching entirely
- Must NOT change the ImageCacheManager's overall architecture

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: []

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 2 (with Tasks 5, 6, 7)
- **Blocks**: Task 8 (needs varied images for Ambilight testing)
- **Blocked By**: Wave 1

**References**:
**Pattern References**:
- `VarietyMacOS/Data/ImageCacheManager.swift:53-72` — `getImage(for:from:)` — uses cache key that doesn't account for redirects
- `VarietyMacOS/Data/ImageCacheManager.swift:195-202` — `cacheKey` computed property — uses `url.host + url.path` which is the same for all Picsum requests
- `VarietyMacOS/Core/WallpaperManager.swift:287-288` — calls `imageCache.getImage(for: wallpaper.cacheKey, from: url)`

**API/Type References**:
- `VarietyMacOS/Data/ImageCacheManager.swift:71` — `URLSession.shared.data(from: url)` — this follows redirects but doesn't return the final URL

**External References**:
- Kingfisher source: Uses `URLSessionTask` delegate to capture final URL after redirect — `task.currentRequest?.url` gives the final URL
- Picsum Photos API: `https://picsum.photos/1920/1080` → 302 redirect → `https://fastly.picsum.photos/id/XXX/1920/1080?hmac=YYY`

**WHY Each Reference Matters**:
- ImageCacheManager.swift:53-72 is where the caching happens — must add redirect awareness
- cacheKey computed property is where the key is generated — must change for Picsum
- Line 287-288 shows how WallpaperManager calls the cache — may need to pass additional info

**Acceptance Criteria**:
- [ ] Two consecutive Picsum fetches return different images (not the same cached one)
- [ ] Cache still works for non-redirect URLs (Wallhaven, Bing)
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Picsum returns different images on consecutive fetches
Tool: Bash (build + launch + log analysis)
Preconditions: App running
Steps:
  1. Build and launch app
  2. Click "Next Wallpaper" twice
  3. Check logs for "Cache miss, downloading" vs "Cache hit"
  4. Check that the two fetched images have different URLs/IDs
Expected Result: Second fetch downloads a new image (cache miss or different redirect URL)
Failure Indicators: Both fetches show "Cache hit (memory)" with same key
Evidence: .sisyphus/evidence/task-4-picsum-cache.txt
```

**Commit**: YES
- Message: `fix(cache): Handle redirect URLs in Picsum cache key`
- Files: `VarietyMacOS/Data/ImageCacheManager.swift`, `VarietyMacOS/Data/Models/Wallpaper.swift`

---

- [x] 5. Fix Wallhaven Random Page Fetching

**What to do**:
- In `WallhavenSource.swift`, modify the API request to include a random page number
- The Wallhaven API supports a `page` parameter — add `&page=\(Int.random(in: 1...10))` to the search URL
- This ensures each fetch returns a different set of results from Wallhaven
- Also: if `searchQuery` is empty, use a random category or keyword to increase variety

**Must NOT do**:
- Must NOT remove the existing retry logic in WallhavenSource
- Must NOT change the API key or authentication

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: []

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 2 (with Tasks 4, 6, 7)
- **Blocks**: Task 8
- **Blocked By**: Wave 1

**References**:
**Pattern References**:
- `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift:55-66` — `fetchWallpaper()` — calls `fetchWallpapers(count: 1)`
- `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift` — `buildSearchURL()` or similar function that constructs the API URL

**External References**:
- Wallhaven API docs: `https://wallhaven.cc/help/api` — supports `page` parameter for pagination

**WHY Each Reference Matters**:
- WallhavenSource.swift fetch logic needs the random page parameter

**Acceptance Criteria**:
- [ ] Wallhaven API URL includes a random page number
- [ ] Two consecutive Wallhaven fetches return different wallpapers
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Wallhaven returns different images on consecutive fetches
Tool: Bash (launch + log)
Steps:
  1. Build and launch app
  2. Click "Next Wallpaper" until a Wallhaven image is fetched
  3. Click again until another Wallhaven image is fetched
  4. Verify the two images have different titles/URLs
Expected Result: Different Wallhaven images each time
Failure Indicators: "Duplicate detected, skipping: general" on every Wallhaven attempt
Evidence: .sisyphus/evidence/task-5-wallhaven-random.txt
```

**Commit**: YES
- Message: `fix(wallhaven): Add random page number to API requests`
- Files: `VarietyMacOS/Sources/Wallhaven/WallhavenSource.swift`

---

- [x] 6. Fix Bing Multi-Day Fetching + Duplicate Detection

**What to do**:
- In `BingSource.swift`, modify `fetchWallpaper()` to request multiple days (count: 7) and pick a random one
- This prevents Bing from always returning the same daily image
- In `DuplicateChecker.swift`, change the comparison to use `remoteURL.absoluteString` instead of `wallpaper.id`
- The current comparison by `wallpaper.id` fails because IDs are generated per-fetch and may collide for the same source
- Also: when a duplicate IS detected, continue to the next source instead of just incrementing the attempt counter
- The `fetchNewWallpaper()` retry loop should try ALL available sources before giving up, not just 3 random picks

**Must NOT do**:
- Must NOT increase the retry count beyond 5 (to avoid excessive API calls)
- Must NOT remove duplicate detection entirely

**Recommended Agent Profile**:
- **Category**: `unspecified-high`
- **Skills**: []

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 2 (with Tasks 4, 5, 7)
- **Blocks**: Task 8
- **Blocked By**: Wave 1

**References**:
**Pattern References**:
- `VarietyMacOS/Sources/Bing/BingSource.swift:33-38` — `fetchWallpaper()` — currently fetches count: 1
- `VarietyMacOS/Sources/Bing/BingSource.swift:41-66` — `fetchWallpapers(count:)` — already supports multiple results
- `VarietyMacOS/Core/DuplicateChecker.swift:11-21` — `isDuplicate()` — compares by `wallpaper.id`
- `VarietyMacOS/Core/WallpaperManager.swift:176-225` — retry loop with 3 attempts

**WHY Each Reference Matters**:
- BingSource already supports fetching multiple images — just need to request more and pick random
- DuplicateChecker comparison logic needs to use URL instead of ID
- Retry loop needs to be smarter about source rotation

**Acceptance Criteria**:
- [ ] Bing fetches 7 days and picks a random one
- [ ] DuplicateChecker compares by `remoteURL.absoluteString`
- [ ] Fetch pipeline tries all available sources before failing
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Bing returns different images, duplicates properly skipped
Tool: Bash (launch + log)
Steps:
  1. Build and launch app
  2. Click "Next Wallpaper" multiple times
  3. Check logs: Bing should sometimes return different images from different days
  4. Check logs: Duplicate detection should skip by URL comparison, not ID
Expected Result: At least some Bing fetches return different images from different days
Failure Indicators: "Duplicate detected, skipping" on every Bing attempt with same title
Evidence: .sisyphus/evidence/task-6-bing-dedup.txt
```

**Commit**: YES
- Message: `fix(sources): Bing multi-day fetch + URL-based duplicate detection`
- Files: `VarietyMacOS/Sources/Bing/BingSource.swift`, `VarietyMacOS/Core/DuplicateChecker.swift`, `VarietyMacOS/Core/WallpaperManager.swift`

---

- [x] 7. Prevent NSURLError -999 Rapid Click Cancellation

**What to do**:
- In `WallpaperManager.swift`, add a guard to prevent `nextWallpaper()` from being called while a fetch is already in progress
- The current `isLoading` flag already exists but may have a race condition
- Ensure `isLoading` is set to `true` BEFORE any async work begins, and `false` in a `defer` block
- Disable the "Next Wallpaper" button while `isLoading` is true (check `CurrentWallpaperView.swift`)
- The -999 error occurs because a new `URLSession.shared.data(from:)` call cancels the previous one — add a dedicated URLSession with ephemeral configuration that doesn't cancel on new requests

**Must NOT do**:
- Must NOT disable the "Next Wallpaper" button permanently
- Must NOT queue requests — just prevent concurrent ones

**Recommended Agent Profile**:
- **Category**: `quick`
- **Skills**: []

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 2 (with Tasks 4, 5, 6)
- **Blocks**: None directly
- **Blocked By**: Wave 1

**References**:
**Pattern References**:
- `VarietyMacOS/Core/WallpaperManager.swift:152-168` — `fetchNewWallpaper()` — has `isLoading` guard
- `VarietyMacOS/App/CurrentWallpaperView.swift:122` — checks `!wallpaperManager.isLoading` before calling nextWallpaper

**WHY Each Reference Matters**:
- The isLoading guard exists but may not fully prevent the -999 error
- The button disabling logic needs to be verified

**Acceptance Criteria**:
- [ ] No `NSURLError -999` errors in console during normal operation
- [ ] "Next Wallpaper" button is disabled while fetching
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Rapid clicks don't cause cancellation errors
Tool: Bash (launch + log)
Steps:
  1. Build and launch app
  2. Click "Next Wallpaper" rapidly 5 times
  3. Check logs for NSURLError -999
Expected Result: No -999 errors in logs
Failure Indicators: "Failed to reload current wallpaper image: Error Domain=NSURLErrorDomain Code=-999"
Evidence: .sisyphus/evidence/task-7-no-cancel.txt
```

**Commit**: YES
- Message: `fix(fetch): Prevent rapid click URL cancellation`
- Files: `VarietyMacOS/Core/WallpaperManager.swift`

---

- [x] 8. Rewrite AmbilightColorExtractor with Top-K Dominant Colors

**What to do**:
- In `AmbilightEffect.swift`, replace the `AmbilightColorExtractor` class with a new implementation using top-K dominant color extraction
- Current approach: `CIAreaAverage` computes the MEAN color → tends toward muddy gray/brown
- New approach: Downsample the edge region to a small size (e.g., 64x64), then cluster the pixels to find the TOP dominant colors using a simple k-means or frequency histogram approach
- For each edge (top, bottom, left, right), extract the top 3 dominant colors and pick the most VIVID one (highest saturation)
- Implementation: Downsample edge region → Convert to HSL → Sort by saturation → Pick the most saturated color that appears in >5% of pixels
- Also extract a separate dominant color for the overall image (most frequent hue)

**Must NOT do**:
- Must NOT add third-party dependencies
- Must NOT use Metal shaders
- Must NOT make extraction async if it can be done synchronously in <50ms

**Recommended Agent Profile**:
- **Category**: `deep`
- **Skills**: [`swiftui-pro`]

**Parallelization**:
- **Can Run In Parallel**: NO
- **Parallel Group**: Wave 3 (sequential with Task 9)
- **Blocks**: Task 9
- **Blocked By**: Wave 2

**References**:
- `VarietyMacOS/Utilities/AmbilightEffect.swift:125-139` — `extractColorsFromImage()` — current CIAreaAverage approach
- `VarietyMacOS/Utilities/AmbilightEffect.swift:142-282` — `AmbilightColorExtractor` class — needs complete rewrite
- Hyperion project: Uses 64x64 downsampled image for LED zone color extraction

**Acceptance Criteria**:
- [ ] New color extractor produces distinct colors per edge (saturation > 0.3)
- [ ] Log output shows meaningfully different RGB values for each edge
- [ ] Extraction completes in <100ms per image
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Color extraction produces distinct vivid edge colors
Tool: Bash (launch + log analysis)
Steps:
  1. Build and launch app
  2. Fetch a colorful wallpaper
  3. Check console for "Ambilight colors extracted" log
  4. Verify: right edge color differs from left edge color by >20% in at least one RGB channel
  5. Verify: at least one edge has saturation > 0.3
Expected Result: Distinct, vivid colors per edge that match the image's visible edge colors
Failure Indicators: All edges show nearly identical RGB values
Evidence: .sisyphus/evidence/task-8-color-extraction.txt
```

**Commit**: YES
- Message: `feat(ambilight): Top-K dominant color extraction for vivid edge colors`
- Files: `VarietyMacOS/Utilities/AmbilightEffect.swift`

---

- [x] 9. Rewrite AmbilightEffect Glow Positioning from Right Column

**What to do**:
- In `AmbilightEffect.swift`, restructure the glow layout to radiate FROM the right column detail image
- Current approach: Fixed glow positions (right 40%, top-right 30%, bottom-right 30%)
- New approach: Position glow sources at the EDGES of the detail view area, radiating outward
- Use `GeometryReader` to get the detail view's frame position, then place glow sources at its 4 edges
- The right edge of the detail image is the PRIMARY glow source (brightest, largest blur)
- The top/bottom edges of the detail image produce secondary glows
- The left edge produces a subtle "spillover" glow that reaches across the window
- Use `RadialGradient` centered on the detail image, expanding outward with the edge colors
- Increase opacity values: primary glow 0.8, secondary 0.5, spillover 0.3
- Increase blur radius: primary 150px, secondary 120px, spillover 100px
- Add `.animation(.easeInOut(duration: 0.5))` for color transitions when wallpaper changes

**Must NOT do**:
- Must NOT use Metal shaders
- Must NOT change the ZStack layering approach
- Must NOT remove the `.blendMode(.screen)`

**Recommended Agent Profile**:
- **Category**: `visual-engineering`
- **Skills**: [`swiftui-pro`]

**Parallelization**:
- **Can Run In Parallel**: NO
- **Parallel Group**: Wave 3 (sequential after Task 8)
- **Blocks**: F1-F4
- **Blocked By**: Task 8

**References**:
- `VarietyMacOS/Utilities/AmbilightEffect.swift:23-99` — Current body with fixed glow positions
- `VarietyMacOS/App/AppNavigationView.swift:93-99` — Where AmbilightEffect is placed in ZStack

**Acceptance Criteria**:
- [ ] Glow sources positioned at the detail view's edges
- [ ] Primary glow radiates from right side of detail image
- [ ] Colors visibly match the edge colors of the displayed wallpaper
- [ ] Color transitions animate smoothly (0.5s easeInOut)
- [ ] `xcodebuild` → BUILD SUCCEEDED

**QA Scenarios**:
```
Scenario: Ambilight radiates from right column image edges
Tool: Bash (launch + screenshot + look_at)
Steps:
  1. Build and launch app
  2. Wait for wallpaper to display in right column
  3. Run: screencapture -x /tmp/ambilight_visual_test.png
  4. Use look_at agent: "Does the background show colored glows radiating from the right column wallpaper image?"
Expected Result: Visible colored glow emanating from the right column image
Failure Indicators: Uniform dark background, or glow not centered on the right column
Evidence: .sisyphus/evidence/task-9-ambilight-radiation.png
```

**Commit**: YES
- Message: `feat(ambilight): Radiate glow from right column detail image edges`
- Files: `VarietyMacOS/Utilities/AmbilightEffect.swift`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
- [x] F2. **Code Quality Review** — `unspecified-high`
- [x] F3. **Real Manual QA** — `unspecified-high`
- [x] F4. **Scope Fidelity Check** — `deep`
For each task: read "What to do", read actual diff. Verify 1:1. Check "Must NOT do" compliance. Output: `Tasks [N/N compliant] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `fix(wallpaper): Manual @Transient observation + remove clearCachedImage + guarantee cold start`
- **Wave 2**: `fix(sources): Picsum cache redirect + Wallhaven random page + Bing multi-day + URL dedup + prevent cancellation`
- **Wave 3**: `feat(ambilight): Top-K dominant colors + radiate from right column`

---

## Success Criteria

### Verification Commands
```bash
cd /Users/cycloudyang/VarietyMacOS-Pro
xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -configuration Debug build
# Expected: BUILD SUCCEEDED
```

### Final Checklist
- [ ] Cold start: both columns show wallpaper within 2 seconds
- [ ] "Next Wallpaper": 4/5 attempts produce different images
- [ ] Ambilight: vivid distinct colors radiating from right column
- [ ] No `noImageAvailable` errors in console
- [ ] No `NSURLError -999` errors in console
- [ ] Build succeeds with zero errors