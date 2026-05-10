# P0 Upgrade Gaps — Close Remaining P0-Upgrade Plan Tasks

## TL;DR

> **Quick Summary**: 修复 P0-upgrade 计划中 T7/T8/T11 三个未完成任务：ImageCacheManager 缓存清理集成、cachedImage 生命周期完善、WallpaperHistory 内存管理 + 缩略图预加载。
>
> **Deliverables**:
> - ImageCacheManager.clearCache() 和 clearMemoryCache() 集成缩略图缓存清理
> - WallpaperManager 内存警告观察器（清除非当前壁纸的 cachedImage）
> - WallpaperHistory.add() 中清除新增条目的 cachedImage
> - WallpaperHistory.prefetchThumbnails() 预加载方法
>
> **Estimated Effort**: Quick
> **Parallel Execution**: YES - 2 waves
> **Critical Path**: Task 1 → Task 3

---

## Context

### Original Request
用户在核实 varietymacos-p0-upgrade.md 计划进展时，发现 T7、T8、T11 三个任务部分完成或未完成，要求为剩余差距创建新的补充计划。

### Interview Summary
**Key Discussions**:
- T7 (ImageCacheManager refactor): 缩略图缓存管理已通过 thumbnailPipeline 属性实现，但 clearCache()/clearMemoryCache() 未集成缩略图清理
- T8 (cachedImage lifecycle): fetchNewWallpaper() 中已调用 clearCachedImage()，但内存警告观察器为空、WallpaperHistory.add() 不清除 cachedImage
- T11 (WallpaperHistory memory): 完全未实现 — 无 prefetchThumbnails()、无 cachedImage 清除
- HistoryListView.swift 不再需要 — HistorySheetView (MenuBarView) 已用 ThumbnailImageView 处理历史显示
- T9 (HistoryThumbnailView) 标记为 N/A — 文件从未创建，round3 用 ThumbnailImageView 解决了同样问题

**Research Findings**:
- `ImageCacheManager.swift:102-118`: `clearCache()` 和 `clearMemoryCache()` 是同步方法，但 `thumbnailPipeline.clearCache()` 是 async
- `WallpaperHistory.swift:22-43`: `add()` 方法在 trim 时清除被移除条目的 cachedImage（line 37），但不清除新添加条目的 cachedImage
- `WallpaperManager.swift:61-64`: `setupMemoryWarningObserver()` 故意留空，注释"macOS handles memory automatically"
- `ThumbnailPipeline.swift` 有 `prewarmCache(for:)` 方法可用于预加载
- ImageCacheManager 不是 Actor（是 final class），混合 sync/async 需要用 Task 包装

### Metis Review
**Identified Gaps** (addressed):
- sync/async 混合问题: ImageCacheManager 的 clearCache() 是同步的，thumbnailPipeline.clearCache() 是 async — 需要用 Task {} 包装异步调用
- 内存警告观察器不应盲目清除所有 cachedImage — 必须保留 currentWallpaper 的缓存
- prefetchThumbnails 需要限制数量和优先级 — 只预加载最近 10 条，避免大量后台请求
- 不创建 HistoryListView.swift — 已有 HistorySheetView 处理显示
- WallpaperHistory.add() 中 strip cachedImage 的时机：在 insert 之后、save 之前

---

## Work Objectives

### Core Objective
关闭 P0-upgrade 计划的三个差距：缓存清理集成、内存生命周期完善、历史预加载。使 ThumbnailPipeline 子系统完整闭环。

### Concrete Deliverables
- `VarietyMacOS/Data/ImageCacheManager.swift` — clearCache()/clearMemoryCache() 集成缩略图清理
- `VarietyMacOS/Core/WallpaperManager.swift` — didReceiveMemoryWarningNotification 观察器实现
- `VarietyMacOS/Data/Models/WallpaperHistory.swift` — add() 清除 cachedImage + prefetchThumbnails()
- `VarietyMacOS/App/MenuBarView.swift` — HistorySheetView onAppear 调用 prefetchThumbnails

### Definition of Done
- [x] ImageCacheManager.clearCache() 同时清理全图和缩略图缓存
- [x] 内存警告时清除所有非当前壁纸的 cachedImage
- [x] WallpaperHistory.add() 后新条目的 cachedImage 为 nil
- [x] prefetchThumbnails() 预加载最近 10 条历史缩略图
- [x] xcodebuild clean build 成功

### Must Have
- clearCache() 和 clearMemoryCache() 必须清理缩略图缓存（不能遗漏）
- 内存警告观察器只清除非当前壁纸的 cachedImage（保留当前壁纸）
- WallpaperHistory.add() 在保存前清除新条目的 cachedImage
- prefetchThumbnails() 使用 Task 后台执行，不阻塞主线程

### Must NOT Have (Guardrails)
- 不将 ImageCacheManager 改为 Actor（保持 final class）
- 不创建 HistoryListView.swift（已有 HistorySheetView）
- 不修改 ThumbnailPipeline 的接口
- 不修改 WallpaperSource 协议
- 不添加新的第三方依赖
- 不在 P0 范围外添加功能
- 不修改 clearCache()/clearMemoryCache() 的签名（保持同步方法，内部用 Task 包装异步）

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: YES (XCTest + 16 test files)
- **Automated tests**: No new tests (gap-closing only, agent QA sufficient)
- **Framework**: XCTest (existing)

### QA Policy
Every task includes agent-executed QA scenarios:
- **Build**: xcodebuild clean build to verify no regressions
- **Module**: Bash for code inspection (grep/cat) to verify implementation
- Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - independent fixes, 2 parallel tasks):
├── Task 1: ImageCacheManager clearCache() thumbnail integration [quick]
└── Task 2: WallpaperHistory.add() cachedImage stripping + prefetchThumbnails() [quick]

Wave 2 (After Wave 1 - memory warning, depends on Task 2):
└── Task 3: WallpaperManager didReceiveMemoryWarningNotification observer [quick]

Wave FINAL (After ALL tasks):
└── Task F1: Build verification + scope check [quick]
```

Critical Path: Task 1 → F1 (parallel with Task 2 → Task 3 → F1)
Parallel Speedup: ~50% faster than sequential
Max Concurrent: 2 (Wave 1)

### Agent Dispatch Summary

- **Wave 1**: **2** - T1 → `quick`, T2 → `quick`
- **Wave 2**: **1** - T3 → `quick`
- **FINAL**: **1** - F1 → `quick`

---

## TODOs

- [x] 1. ImageCacheManager clearCache() Thumbnail Integration

**What to do**:
- Modify `VarietyMacOS/VarietyMacOS/Data/ImageCacheManager.swift`:
- In `clearCache()` (line 102-111): Add `Task { await thumbnailPipeline.clearCache() }` after removing disk cache files. This ensures thumbnail cache is cleared when full cache is cleared.
- In `clearMemoryCache()` (line 115-118): Add `Task { await thumbnailPipeline.clearCache() }` after `memoryCache.removeAllObjects()`. This ensures thumbnail memory cache is also purged on memory cleanup.
- The Task {} wrapper is necessary because `clearCache()`/`clearMemoryCache()` are synchronous methods while `thumbnailPipeline.clearCache()` is async.
- This is a fire-and-forget pattern — we don't need to await the thumbnail cache clearing to complete before returning. The thumbnail cache will be cleared asynchronously shortly after.

**Must NOT do**:
- Do not change `clearCache()` or `clearMemoryCache()` signatures to async
- Do not add `await` directly (would require changing method to async)
- Do not replace the existing `memoryCache.removeAllObjects()` or disk cleanup logic

**Recommended Agent Profile**:
- **Category**: `quick`
- Reason: Two lines added to existing methods
- **Skills**: [`swift-concurrency-pro`]
- `swift-concurrency-pro`: Task {} fire-and-forget pattern correctness in non-async context
- **Skills Evaluated but Omitted**:
- `swiftui-pro`: No UI changes

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1 (with Task 2)
- **Blocks**: None
- **Blocked By**: None

**References**:
- `VarietyMacOS/VarietyMacOS/Data/ImageCacheManager.swift:102-118` - clearCache() and clearMemoryCache() to modify
- `VarietyMacOS/VarietyMacOS/Data/ImageCacheManager.swift:24-25` - thumbnailPipeline property
- `VarietyMacOS/VarietyMacOS/Data/ImageCacheManager.swift:151-153` - clearThumbnailCache() async method (existing pattern to reference)

**WHY Each Reference Matters**:
- ImageCacheManager.swift:102-118 — the exact methods to modify, need to add Task {} blocks
- ImageCacheManager.swift:24-25 — shows how thumbnailPipeline is accessed (private let, no await needed for property access)
- ImageCacheManager.swift:151-153 — shows the existing async thumbnail clearing pattern to match

**Acceptance Criteria**:
- [x] `clearCache()` contains `Task { await thumbnailPipeline.clearCache() }` after disk cleanup
- [x] `clearMemoryCache()` contains `Task { await thumbnailPipeline.clearCache() }` after memoryCache.removeAllObjects()
- [x] Both methods remain synchronous (no async keyword added)
- [x] Build succeeds

**QA Scenarios**:
```
Scenario: clearCache() clears both full and thumbnail caches
Tool: Bash (grep)
Steps:
1. grep -n "thumbnailPipeline.clearCache" VarietyMacOS/Data/ImageCacheManager.swift
2. Assert: 2 matches found (one in clearCache(), one in clearMemoryCache())
3. Assert: Both wrapped in Task { }
Expected Result: Thumbnail cache clearing integrated into both cache methods
Evidence: .sisyphus/evidence/task-1-cache-integration.txt

Scenario: Build succeeds after change
Tool: Bash (xcodebuild)
Steps:
1. xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -destination 'platform=macOS' clean build
2. Assert: BUILD SUCCEEDED
Expected Result: No build errors
Evidence: .sisyphus/evidence/task-1-build.txt
```

**Commit**: YES
- Message: `fix: integrate thumbnail cache clearing into ImageCacheManager clearCache/clearMemoryCache`
- Files: `VarietyMacOS/Data/ImageCacheManager.swift`

- [x] 2. WallpaperHistory cachedImage Stripping + prefetchThumbnails()

**What to do**:
- Modify `VarietyMacOS/VarietyMacOS/Data/Models/WallpaperHistory.swift`:
- In `add(_ wallpaper:)` method (line 22-43): After `entries.insert(entry, at: 0)` (line 30) and BEFORE `saveHistory()` (line 42), add: `wallpaper.clearCachedImage()` — this strips the cachedImage from the wallpaper that was just added to history, freeing memory immediately. The entry already holds a reference to the wallpaper, so the trim logic (lines 33-38) can still access it if needed.
- Note: The existing trim logic (lines 34-38) already clears cachedImage for removed entries — this is good and should be kept.
- Add new method `func prefetchThumbnails()` after `recentEntries()` (around line 60):
```swift
/// Prefetch thumbnails for recent history entries
func prefetchThumbnails() {
    let recentWallpapers = entries.prefix(10).compactMap(\.wallpaper)
    guard !recentWallpapers.isEmpty else { return }
    Task {
        let pipeline = ThumbnailPipeline()
        await pipeline.prewarmCache(for: recentWallpapers)
    }
}
```
- Modify `VarietyMacOS/VarietyMacOS/App/MenuBarView.swift`:
- In HistorySheetView's `onAppear` (wherever it appears), add: `WallpaperHistory.shared.prefetchThumbnails()`
- This ensures thumbnails start loading as soon as the history sheet opens

**Must NOT do**:
- Do not create a separate HistoryListView.swift file
- Do not make prefetchThumbnails() async (keep it fire-and-forget via internal Task)
- Do not prefetch more than 10 entries (avoid excessive background requests)
- Do not modify the trim logic in add() (lines 33-39 are already correct)

**Recommended Agent Profile**:
- **Category**: `quick`
- Reason: Small additions to existing methods + one new method
- **Skills**: [`swift-concurrency-pro`, `swiftui-pro`]
- `swift-concurrency-pro`: Task {} fire-and-forget for prefetch, @MainActor considerations
- `swiftui-pro`: onAppear lifecycle for prefetch trigger
- **Skills Evaluated but Omitted**:
- `swift-testing-pro`: No new test files

**Parallelization**:
- **Can Run In Parallel**: YES
- **Parallel Group**: Wave 1 (with Task 1)
- **Blocks**: Task 3
- **Blocked By**: None

**References**:
- `VarietyMacOS/VarietyMacOS/Data/Models/WallpaperHistory.swift:22-43` - add() method to modify
- `VarietyMacOS/VarietyMacOS/Data/Models/WallpaperHistory.swift:57-60` - recentEntries() (add prefetchThumbnails after this)
- `VarietyMacOS/VarietyMacOS/Data/Models/Wallpaper.swift` - clearCachedImage() method to call
- `VarietyMacOS/VarietyMacOS/Pipeline/ThumbnailPipeline.swift` - prewarmCache(for:) method to use
- `VarietyMacOS/VarietyMacOS/App/MenuBarView.swift` - HistorySheetView onAppear to add prefetch call

**WHY Each Reference Matters**:
- WallpaperHistory.swift:22-43 — the exact method to add cachedImage stripping, and context for where to add it
- WallpaperHistory.swift:57-60 — location to add new prefetchThumbnails() method (after recentEntries)
- Wallpaper.swift — need to confirm clearCachedImage() exists and its signature
- ThumbnailPipeline.swift — need to confirm prewarmCache(for:) exists and its signature
- MenuBarView.swift — need to find HistorySheetView's onAppear to add prefetch trigger

**Acceptance Criteria**:
- [x] WallpaperHistory.add() calls wallpaper.clearCachedImage() before saveHistory()
- [x] prefetchThumbnails() method exists and calls ThumbnailPipeline.prewarmCache with prefix(10)
- [x] HistorySheetView onAppear calls WallpaperHistory.shared.prefetchThumbnails()
- [x] Build succeeds

**QA Scenarios**:
```
Scenario: cachedImage stripped after add()
Tool: Bash (grep)
Steps:
1. grep -n "clearCachedImage" VarietyMacOS/Data/Models/WallpaperHistory.swift
2. Assert: Found in add() method (not just in trim logic at line 37)
3. Assert: Called before saveHistory()
Expected Result: New entries have cachedImage cleared before persistence
Evidence: .sisyphus/evidence/task-2-cachedimage-strip.txt

Scenario: prefetchThumbnails method exists
Tool: Bash (grep)
Steps:
1. grep -n "prefetchThumbnails" VarietyMacOS/Data/Models/WallpaperHistory.swift
2. Assert: Method definition found
3. grep -n "prefetchThumbnails" VarietyMacOS/App/MenuBarView.swift
4. Assert: Called in onAppear
Expected Result: Prefetch method exists and is called from history sheet
Evidence: .sisyphus/evidence/task-2-prefetch.txt

Scenario: Build succeeds
Tool: Bash (xcodebuild)
Steps:
1. xcodebuild clean build
2. Assert: BUILD SUCCEEDED
Expected Result: Clean build
Evidence: .sisyphus/evidence/task-2-build.txt
```

**Commit**: YES
- Message: `fix: strip cachedImage on history add, add prefetchThumbnails for history sheet`
- Files: `VarietyMacOS/Data/Models/WallpaperHistory.swift`, `VarietyMacOS/App/MenuBarView.swift`

- [x] 3. WallpaperManager didReceiveMemoryWarningNotification Observer

**What to do**:
- Modify `VarietyMacOS/VarietyMacOS/Core/WallpaperManager.swift`:
- Replace the empty `setupMemoryWarningObserver()` (line 61-64) with a real implementation:
```swift
private func setupMemoryWarningObserver() {
    NotificationCenter.default.addObserver(
        forName: NSApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
    ) { [weak self] _ in
        guard let self else { return }
        // Clear cached images for all non-current wallpapers
        for wallpaper in self.wallpaperHistory where wallpaper !== self.currentWallpaper {
            wallpaper.clearCachedImage()
        }
        // Also clear cached images in WallpaperHistory entries
        for entry in WallpaperHistory.shared.entries {
            if entry.wallpaper !== self.currentWallpaper {
                entry.wallpaper?.clearCachedImage()
            }
        }
        Logger.info("Memory warning received — cleared non-current cachedImages")
    }
}
```
- Key design: Only clear cachedImage for wallpapers that are NOT the current one. The current wallpaper should keep its cachedImage so the UI continues to display correctly.
- Note: `wallpaperHistory` is WallpaperManager's internal array (separate from WallpaperHistory.shared.entries). We should clear both to be thorough.
- The observer uses `[weak self]` to avoid retain cycles.
- The observer fires on `.main` queue since WallpaperManager is @MainActor.

**Must NOT do**:
- Do not clear currentWallpaper.cachedImage (it's the active display)
- Do not call ImageCacheManager.clearMemoryCache() here (that clears ALL memory including current image)
- Do not use a strong reference to self in the observer closure
- Do not add deinit observer removal (WallpaperManager is a singleton, never deallocates)

**Recommended Agent Profile**:
- **Category**: `quick`
- Reason: Replace empty method with NotificationCenter observer
- **Skills**: [`swift-concurrency-pro`]
- `swift-concurrency-pro`: @MainActor + NotificationCenter + weak self patterns
- **Skills Evaluated but Omitted**:
- `swiftui-pro`: No UI changes

**Parallelization**:
- **Can Run In Parallel**: NO
- **Parallel Group**: Wave 2 (depends on Task 2 for WallpaperHistory.shared reference)
- **Blocks**: F1
- **Blocked By**: Task 2 (need to confirm WallpaperHistory.shared.entries is accessible)

**References**:
- `VarietyMacOS/VarietyMacOS/Core/WallpaperManager.swift:61-64` - Empty setupMemoryWarningObserver() to replace
- `VarietyMacOS/VarietyMacOS/Core/WallpaperManager.swift:26` - wallpaperHistory private property
- `VarietyMacOS/VarietyMacOS/Core/WallpaperManager.swift:13` - currentWallpaper @Published property
- `VarietyMacOS/VarietyMacOS/Data/Models/Wallpaper.swift` - clearCachedImage() method

**WHY Each Reference Matters**:
- WallpaperManager.swift:61-64 — the exact method to replace, currently empty
- WallpaperManager.swift:26 — need to iterate this array for clearing cachedImage
- WallpaperManager.swift:13 — the currentWallpaper to preserve (don't clear this one's image)
- Wallpaper.swift — confirm clearCachedImage() exists

**Acceptance Criteria**:
- [x] setupMemoryWarningObserver() registers for NSApplication.didReceiveMemoryWarningNotification
- [x] Observer closure clears cachedImage for all wallpapers EXCEPT currentWallpaper
- [x] Observer uses [weak self] to avoid retain cycle
- [x] Observer fires on .main queue
- [x] Logger.info called when memory warning fires
- [x] Build succeeds

**QA Scenarios**:
```
Scenario: Memory warning observer registered
Tool: Bash (grep)
Steps:
1. grep -n "didReceiveMemoryWarningNotification" VarietyMacOS/Core/WallpaperManager.swift
2. Assert: Found in setupMemoryWarningObserver() method
3. grep -n "clearCachedImage" VarietyMacOS/Core/WallpaperManager.swift
4. Assert: Found inside the observer closure
5. grep -n "currentWallpaper" VarietyMacOS/Core/WallpaperManager.swift
6. Assert: currentWallpaper is excluded from clearing (check via "where wallpaper !== self.currentWallpaper" or similar)
Expected Result: Observer properly registers and selectively clears cachedImages
Evidence: .sisyphus/evidence/task-3-memory-observer.txt

Scenario: Build succeeds
Tool: Bash (xcodebuild)
Steps:
1. xcodebuild clean build
2. Assert: BUILD SUCCEEDED
Expected Result: Clean build
Evidence: .sisyphus/evidence/task-3-build.txt
```

**Commit**: YES
- Message: `fix: implement didReceiveMemoryWarningNotification observer to clear non-current cachedImages`
- Files: `VarietyMacOS/Core/WallpaperManager.swift`

---

## Final Verification Wave

> 1 review agent runs after all implementation. Present results to user for explicit okay.

- [x] F1. **Build + Scope Verification** — `quick`
Run `xcodebuild clean build`. Verify each task's changes are present in code (grep for key additions). Check no files were modified beyond the 3 target files. Verify no new Swift files created. Verify "Must NOT Have" compliance.
Output: `Build [PASS/FAIL] | T1 [FOUND/MISSING] | T2 [FOUND/MISSING] | T3 [FOUND/MISSING] | Scope [CLEAN/VIOLATED] | VERDICT`

---

## Commit Strategy

- **Task 1**: `fix: integrate thumbnail cache clearing into ImageCacheManager clearCache/clearMemoryCache`
- Files: `VarietyMacOS/Data/ImageCacheManager.swift`

- **Task 2**: `fix: strip cachedImage on history add, add prefetchThumbnails for history sheet`
- Files: `VarietyMacOS/Data/Models/WallpaperHistory.swift`, `VarietyMacOS/App/MenuBarView.swift`

- **Task 3**: `fix: implement didReceiveMemoryWarningNotification observer to clear non-current cachedImages`
- Files: `VarietyMacOS/Core/WallpaperManager.swift`

---

## Success Criteria

### Verification Commands
```bash
# Build
xcodebuild -project VarietyMacOS.xcodeproj -scheme VarietyMacOS -destination 'platform=macOS' clean build

# Verify T1: thumbnail integration
grep -n "thumbnailPipeline.clearCache" VarietyMacOS/VarietyMacOS/Data/ImageCacheManager.swift
# Expected: 2 matches (in clearCache and clearMemoryCache)

# Verify T2: cachedImage stripping + prefetch
grep -n "clearCachedImage" VarietyMacOS/VarietyMacOS/Data/Models/WallpaperHistory.swift
# Expected: Found in add() method + existing trim logic

grep -n "prefetchThumbnails" VarietyMacOS/VarietyMacOS/Data/Models/WallpaperHistory.swift
# Expected: Method definition found

# Verify T3: memory warning observer
grep -n "didReceiveMemoryWarningNotification" VarietyMacOS/VarietyMacOS/Core/WallpaperManager.swift
# Expected: Found in setupMemoryWarningObserver()
```

### Final Checklist
- [x] All "Must Have" present (clearCache integration, memory warning, cachedImage strip, prefetch)
- [x] All "Must NOT Have" absent (no HistoryListView, no ImageCacheManager actor, no API changes)
- [x] All 3 tasks committed
- [x] Build succeeds with 0 errors
- [x] P0-upgrade T7 marked as done (after this plan executes)
- [x] P0-upgrade T8 marked as done (after this plan executes)
- [x] P0-upgrade T11 marked as done (after this plan executes)
