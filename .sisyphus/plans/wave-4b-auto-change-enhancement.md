# Wave 4B: Auto-Change Enhancement Plan

**Project**: VarietyMacOS Pro (P1 Upgrade)
**Wave Scope**: Intelligent wallpaper rotation with smart scheduling, source priority, duplicate avoidance, and conditional pausing
**Dependencies**: Wave 1 (SwiftData) ✅, Wave 2 (Swift 6) ✅, Wave 3 (NavigationSplitView) ✅, Wave 4A (Wallpaper Management) ✅
**Branch**: `feat/p1-wave4b-auto-change`
**Estimated Effort**: 3-4 agent sessions (12-16 hours)

---

## TL;DR

Wave 4B transforms the basic timer-driven wallpaper rotation into an intelligent, context-aware system:

1. **Smart Scheduling**: Time-based rules (different intervals for work/evening/night), day-of-week rules
2. **Source Priority & Rotation**: Configurable strategies (round-robin, weighted random, smart rating-based)
3. **Duplicate Avoidance**: Track recently applied wallpapers, enforce "don't repeat for X hours/days"
4. **Conditional Pause**: Auto-pause on battery power, when specific apps are fullscreen (presentations/gaming)

All features integrate with existing `WallpaperTimer`, `WallpaperManager`, and `Preferences` systems.

---

## Execution Waves (Sequential)

| Wave | Parallel Group | Tasks | Description |
|------|----------------|-------|-------------|
| **4B.1** | Serial | 1 | Smart Scheduling: time-based intervals, day-of-week rules |
| **4B.2** | Serial | 1 | Source Priority: rotation strategies, weighted selection |
| **4B.3** | Serial | 1 | Duplicate Avoidance: recent history tracking, configurable cooldown |
| **4B.4** | Serial | 1 | Conditional Pause: battery detection, app monitoring |

**Total Tasks**: 4
**Estimated Duration**: 1.5 days (with QA verification)

---

## Detailed TODOs

### 4B.1: Smart Scheduling

**Goal**: Replace single global interval with time-based rules that adapt to time of day and day of week.

#### What To Do:

1. **Extend AppPreferences Model**
   - **File**: `VarietyMacOS/Preferences/Preferences.swift` (EDIT)
   - Add new fields:
     ```swift
     // Smart Scheduling
     var smartSchedulingEnabled: Bool = false
     var scheduleRules: [ScheduleRule] // @Relationship to new model
     ```
   - Keep existing `changeInterval` as fallback/default

2. **Create ScheduleRule Model**
   - **File**: `VarietyMacOS/Preferences/ScheduleRule.swift` (NEW)
   - Define:
     ```swift
     @Model class ScheduleRule {
       var id: String
       var name: String // e.g., "Work Hours", "Evening", "Night"
       var startTime: Double // Seconds from midnight (e.g., 9*3600 = 9 AM)
       var endTime: Double // e.g., 17*3600 = 5 PM
       var daysOfWeek: Set<Int> // 0=Sunday, 1=Monday, etc. {1,2,3,4,5} = Mon-Fri
       var interval: TimeInterval // e.g., 3600 (1 hour)
       var isEnabled: Bool
     }
     ```
   - Default rules (pre-populated):
     - "Work Hours" (Mon-Fri, 9 AM-6 PM, 1 hour interval)
     - "Evening" (Mon-Fri, 6 PM-11 PM, 30 minutes)
     - "Night" (Daily, 11 PM-7 AM, pause/no change)
     - "Weekend" (Sat-Sun, all day, 2 hours)

3. **Schedule Manager**
   - **File**: `VarietyMacOS/Core/ScheduleManager.swift` (NEW)
   - `@MainActor final class`
   - Methods:
     ```swift
     func getCurrentRule() -> ScheduleRule? // Returns active rule based on current time
     func getNextInterval() -> TimeInterval // Returns interval from active rule
     func getNextChangeDate() -> Date? // Calculates next change time
     func validateRule(_ rule: ScheduleRule) -> Bool // Check for conflicts/overlap
     ```

4. **Integrate with WallpaperTimer**
   - **File**: `VarietyMacOS/Core/WallpaperTimer.swift` (EDIT)
   - Replace `interval: TimeInterval` constant with dynamic lookup:
     ```swift
     private var currentInterval: TimeInterval {
       if Preferences.shared.smartSchedulingEnabled {
         return ScheduleManager.shared.getNextInterval()
       } else {
         return Preferences.shared.changeInterval
       }
     }
     ```
   - Add timer to re-evaluate interval at rule transitions (e.g., at 6 PM sharp)

5. **Schedule Editor UI**
   - **File**: `VarietyMacOS/App/ScheduleEditorView.swift` (NEW)
   - SwiftUI form with:
     - Toggle for smart scheduling on/off
     - List of rules with expand/collapse
     - Add/Edit/Delete rule buttons
     - Time picker for start/end
     - Day-of-week multi-select (checkboxes)
     - Interval picker (5 min to 24 hours)

#### Acceptance Criteria:
- [ ] `smartSchedulingEnabled` toggle switches between fixed and smart mode
- [ ] Correct interval applied based on current time
- [ ] Rule transitions happen automatically (no manual restart needed)
- [ ] Schedule editor UI allows creating/editing/deleting rules
- [ ] Default rules pre-populated on first launch
- [ ] No infinite loops or rapid-fire interval changes

#### Agent-Executed QA Scenarios:

**QA-4B.1.1: Time-Based Interval**
```playwright
# Simulate time progression test
1. Set system time to 10:00 AM (work hours)
2. Start timer → observe interval = 1 hour (from Work rule)
3. Fast-forward to 6:00 PM (evening)
4. Observe interval changes to 30 minutes
5. Fast-forward to 11:00 PM (night)
6. Observe interval = "pause" (no change)
```

**QA-4B.1.2: Day-of-Week Rule**
```playwright
1. Set system date to Saturday
2. Verify "Weekend" rule applies (2 hour interval)
3. Set to Monday
4. Verify "Work Hours" rule applies (1 hour)
```

**QA-4B.1.3: Rule Conflict Detection**
```playwright
1. Create overlapping rules: 9 AM-5 PM and 3 PM-9 PM
2. Observe conflict warning in UI
3. Save anyway → system chooses one (documented behavior)
```

---

### 4B.2: Source Priority & Rotation Strategy

**Goal**: Replace "Bing first, then random" with configurable rotation strategies.

#### What To Do:

1. **Define RotationStrategy Enum**
   - **File**: `VarietyMacOS/Core/RotationStrategy.swift` (NEW)
   - Define:
     ```swift
     enum RotationStrategy: String, CaseIterable, Codable {
       case roundRobin = "Round Robin"
       case weightedRandom = "Weighted Random"
       case smartRating = "Smart (Rating-Based)"
       case random = "Pure Random"
     }
     ```

2. **Extend AppPreferences**
   - **File**: `VarietyMacOS/Preferences/Preferences.swift` (EDIT)
   - Add:
     ```swift
     var rotationStrategy: RotationStrategy = .weightedRandom
     var sourceWeights: [WallpaperSourceType: Double] = [:] // Override per-source weights
     var avoidDuplicatesInterval: TimeInterval = 3600 // 1 hour default
     ```

3. **Source Selector Protocol**
   - **File**: `VarietyMacOS/Sources/SourceSelector.swift` (NEW)
   - Protocol:
     ```swift
     protocol SourceSelector {
       func selectSource(availableSources: [WallpaperSource], history: [Wallpaper]) -> WallpaperSource
     }
     ```
   - Implement 4 strategies as separate classes conforming to protocol

4. **Round-Robin Selector**
   - **File**: `VarietyMacOS/Sources/RoundRobinSelector.swift` (NEW)
   - Tracks last-used source index
   - Cycles through enabled sources in order
   - Skips unavailable sources (e.g., no API key)

5. **Weighted Random Selector**
   - **File**: `VarietyMacOS/Sources/WeightedRandomSelector.swift` (NEW)
   - Respects `sourceWeights` from Preferences
   - Higher weight = higher probability
   - Falls back to equal weight if not specified

6. **Smart Rating Selector**
   - **File**: `VarietyMacOS/Sources/SmartRatingSelector.swift` (NEW)
   - Favors sources with higher user ratings (from Wave 4A `userRating`)
   - Uses weighted average of recent wallpapers from each source
   - Learns from user preferences

7. **Integrate with WallpaperManager**
   - **File**: `VarietyMacOS/Core/WallpaperManager.swift` (EDIT)
   - Replace `getNextSource()` with strategy-based selection:
     ```swift
     private func getNextSource(excluding: Set<String>) -> WallpaperSource {
       let selector = RotationStrategyFactory.create(strategy)
       let available = enabledSources
       return selector.selectSource(availableSources: available, history: recentHistory)
     }
     ```

8. **Strategy Picker UI**
   - **File**: `VarietyMacOS/App/SourceSettingsView.swift` (EDIT or NEW)
   - Dropdown to select strategy
   - Weight editor (sliders for each source)
   - Preview: shows probability distribution

#### Acceptance Criteria:
- [ ] Round-robin cycles through all enabled sources
- [ ] Weighted random respects configured weights
- [ ] Smart rating adapts to user preferences
- [ ] Strategy picker UI is intuitive
- [ ] Weights sum to 100% (visualized)
- [ ] No source skipped indefinitely (starvation prevention)

#### Agent-Executed QA Scenarios:

**QA-4B.2.1: Round-Robin Cycle**
```playwright
1. Enable 3 sources: Bing, Unsplash, Wallhaven
2. Set strategy = "Round Robin"
3. Trigger "Next Wallpaper" 10 times
4. Verify sources cycle in order: Bing → Unsplash → Wallhaven → Bing...
```

**QA-4B.2.2: Weighted Random Distribution**
```playwright
1. Set weights: Bing=70%, Unsplash=30%, Wallhaven=0%
2. Trigger "Next Wallpaper" 100 times
3. Count distribution: ~70 Bing, ~30 Unsplash, 0 Wallhaven
4. Allow ±10% variance (statistical noise)
```

**QA-4B.2.3: Smart Rating Adaptation**
```playwright
1. Rate 5 Bing wallpapers 1-star
2. Rate 5 Unsplash wallpapers 5-star
3. Smart strategy should favor Unsplash (>80% of next 10)
```

---

### 4B.3: Duplicate Avoidance

**Goal**: Prevent same wallpaper from appearing twice within configured time window.

#### What To Do:

1. **Recent History Tracker**
   - **File**: `VarietyMacOS/Core/RecentHistoryTracker.swift` (NEW)
   - `@MainActor final class`
   - Tracks last N wallpapers applied (default: 50)
   - Stores: `wallpaperId`, `appliedAt`, `source`
   - Methods:
     ```swift
     func recordApplied(_ wallpaper: Wallpaper)
     func getRecentIds() -> Set<String>
     func wasAppliedRecently(id: String, within: TimeInterval) -> Bool
     func clearOldEntries(olderThan: TimeInterval)
     ```

2. **Duplicate Checker**
   - **File**: `VarietyMacOS/Core/DuplicateChecker.swift` (NEW)
   - Integrates with `RecentHistoryTracker`
   - Methods:
     ```swift
     func isDuplicate(_ wallpaper: Wallpaper, window: TimeInterval) -> Bool
     func filterOutDuplicates(_ wallpapers: [Wallpaper], window: TimeInterval) -> [Wallpaper]
     ```

3. **Extend WallpaperManager Fetch Logic**
   - **File**: `VarietyMacOS/Core/WallpaperManager.swift` (EDIT)
   - In `fetchNewWallpaper()`:
     ```swift
     let candidate = try await source.fetchWallpaper()
     if DuplicateChecker.shared.isDuplicate(candidate, window: avoidDuplicatesInterval) {
       // Skip, fetch from different source
       continue
     }
     ```

4. **SwiftData Persistence**
   - Use existing `HistoryEntry` model
   - Query last N entries instead of separate tracking
   - No new model needed (reuse `WallpaperHistory`)

5. **Configuration UI**
   - **File**: `VarietyMacOS/App/SettingsView.swift` (EDIT)
   - Add "Avoid Duplicates" section:
     - Toggle: Enable/disable
     - Time window: "Don't repeat within X hours/days"
     - Scope: "All sources" or "Per source"

#### Acceptance Criteria:
- [ ] Same wallpaper doesn't reappear within configured window
- [ ] Different wallpapers from same source can appear (if not duplicate)
- [ ] History persists across app restarts
- [ ] Old entries pruned automatically (performance)
- [ ] No false positives (different wallpapers with same ID)

#### Agent-Executed QA Scenarios:

**QA-4B.3.1: Basic Duplicate Prevention**
```playwright
1. Apply wallpaper A from Bing
2. Trigger "Next Wallpaper" immediately
3. Verify wallpaper A does not reappear
4. Wait past duplicate window (or reduce to 5 seconds for test)
5. Wallpaper A can reappear
```

**QA-4B.3.2: Cross-Source Uniqueness**
```playwright
1. Apply wallpaper A (Bing)
2. Apply wallpaper B (Unsplash, same image ID if possible)
3. If IDs match, both blocked; if different, allowed
```

**QA-4B.3.3: History Persistence**
```bash
# Bash: Check SQLite history table
sqlite3 ~/Library/Application\ Support/com.cyancloud.VarietyMacOS-Pro/default.sqlite \
  "SELECT wallpaperId, timestamp FROM HistoryEntry ORDER BY timestamp DESC LIMIT 10;"
# Verify recent wallpapers logged
```

---

### 4B.4: Conditional Auto-Change Pause

**Goal**: Automatically pause wallpaper changes in specific conditions (battery, fullscreen apps).

#### What To Do:

1. **Power Monitor**
   - **File**: `VarietyMacOS/Utilities/PowerMonitor.swift` (NEW)
   - `@MainActor final class: ObservableObject`
   - Uses `IOKit.ps` or `ProcessInfo.processInfo.isLowPowerModeEnabled`
   - Properties:
     ```swift
     @Published var onBattery: Bool
     @Published var batteryLevel: Int
     @Published var isCharging: Bool
     ```
   - Methods:
     ```swift
     func startMonitoring()
     func stopMonitoring()
     ```

2. **App Monitor (Fullscreen Detection)**
   - **File**: `VarietyMacOS/Utilities/AppMonitor.swift` (NEW)
   - Uses `NSWorkspace` notifications:
     - `NSWorkspace.didActivateApplicationNotification`
     - `NSWorkspace.activeSpaceDidChangeNotification`
   - Detects:
     - Frontmost app bundle ID
     - Whether frontmost app is fullscreen
     - Specific apps to watch (e.g., "com.apple.Keynote", "com.apple.iMovie")
   - Properties:
     ```swift
     @Published var isPresentationActive: Bool
     @Published var isGaming: Bool // Heuristic: fullscreen + high CPU/GPU
     @Published var frontmostApp: String
     ```

3. **Conditional Pause Manager**
   - **File**: `VarietyMacOS/Core/ConditionalPauseManager.swift` (NEW)
   - Aggregates all conditions:
     ```swift
     enum PauseCondition {
       case onBattery
       case presentationMode
       case gamingMode
       case screenSharing
       case customApp(String)
     }
     func shouldPause() -> Bool
     func getActiveConditions() -> [PauseCondition]
     ```

4. **Integrate with WallpaperTimer**
   - **File**: `VarietyMacOS/Core/WallpaperTimer.swift` (EDIT)
   - Before firing timer:
     ```swift
     if ConditionalPauseManager.shared.shouldPause() {
       Logger.info("Skipping wallpaper change: \(activeConditions)")
       return
     }
     ```
   - Auto-resume when conditions clear

5. **Pause Configuration UI**
   - **File**: `VarietyMacOS/App/SettingsView.swift` (EDIT)
   - Add "Conditional Pause" section:
     - Checkboxes: "Pause on battery", "Pause during presentations", "Pause during gaming"
     - App list: "Pause when these apps are frontmost" (+, -, toggle)
   - Status indicator: Shows current pause conditions

#### Acceptance Criteria:
- [ ] Wallpaper changes pause when on battery (if enabled)
- [ ] Wallpaper changes pause during Keynote/PowerPoint (if enabled)
- [ ] Auto-resume when conditions clear
- [ ] No false positives (normal app usage doesn't trigger pause)
- [ ] User can configure which conditions to respect

#### Agent-Executed QA Scenarios:

**QA-4B.4.1: Battery Pause**
```playwright
1. Unplug MacBook (or simulate low power mode)
2. Trigger timer → observe skip with log message
3. Plug in → timer resumes
```

**QA-4B.4.2: Presentation Pause**
```playwright
1. Open Keynote, start slideshow (fullscreen)
2. Trigger timer → observe skip
3. Exit Keynote → timer resumes
```

**QA-4B.4.3: Custom App List**
```playwright
1. Add "com.apple.Safari" to pause list
2. Open Safari as frontmost app
3. Trigger timer → observe skip
4. Remove Safari → timer resumes
```

---

## Dependency Graph

```
Wave 1 (SwiftData) ─── Wave 2 (Swift 6) ─── Wave 3 (NavSplit) ─── Wave 4A (Wallpaper Mgmt) ✅
                                                                 │
Wave 4B                                                         │
├── 4B.1: Smart Scheduling                                      │
│   ├── Model: ScheduleRule (NEW)                               │
│   ├── Manager: ScheduleManager                                │
│   └── Uses: existing Preferences                              │
│                                                               │
├── 4B.2: Source Priority                                       │
│   ├── Enum: RotationStrategy                                │
│   ├── Selectors: RoundRobin, Weighted, Smart              │
│   └── Integrates: userRating from 4A                       │
│                                                               │
├── 4B.3: Duplicate Avoidance                                   │
│   ├── Uses: HistoryEntry (existing)                          │
│   └── Tracker: RecentHistoryTracker                          │
│                                                               │
└── 4B.4: Conditional Pause                                    │
    ├── Monitors: PowerMonitor, AppMonitor                     │
    └── Manager: ConditionalPauseManager
```

---

## Files Changed (Wave 4B)

| File | Action | Description |
|------|--------|-------------|
| `VarietyMacOS/Preferences/Preferences.swift` | EDIT | Add `smartSchedulingEnabled`, `rotationStrategy`, `avoidDuplicatesInterval` |
| `VarietyMacOS/Preferences/ScheduleRule.swift` | NEW | Schedule rule @Model |
| `VarietyMacOS/Core/ScheduleManager.swift` | NEW | Time-based rule evaluator |
| `VarietyMacOS/Core/WallpaperTimer.swift` | EDIT | Dynamic interval lookup |
| `VarietyMacOS/Core/RotationStrategy.swift` | NEW | Strategy enum |
| `VarietyMacOS/Sources/SourceSelector.swift` | NEW | Selector protocol |
| `VarietyMacOS/Sources/RoundRobinSelector.swift` | NEW | Round-robin implementation |
| `VarietyMacOS/Sources/WeightedRandomSelector.swift` | NEW | Weighted random implementation |
| `VarietyMacOS/Sources/SmartRatingSelector.swift` | NEW | Rating-based selection |
| `VarietyMacOS/Core/WallpaperManager.swift` | EDIT | Strategy-based source selection |
| `VarietyMacOS/Core/RecentHistoryTracker.swift` | NEW | Recent wallpaper tracker |
| `VarietyMacOS/Core/DuplicateChecker.swift` | NEW | Duplicate detection |
| `VarietyMacOS/Utilities/PowerMonitor.swift` | NEW | Battery/power monitoring |
| `VarietyMacOS/Utilities/AppMonitor.swift` | NEW | Fullscreen app detection |
| `VarietyMacOS/Core/ConditionalPauseManager.swift` | NEW | Aggregates pause conditions |
| `VarietyMacOS/App/ScheduleEditorView.swift` | NEW | Schedule rule editor UI |
| `VarietyMacOS/App/SourceSettingsView.swift` | EDIT/NEW | Strategy picker UI |
| `VarietyMacOS/App/SettingsView.swift` | EDIT | Conditional pause section |

**Total**: 18 files (14 NEW, 4 EDIT, 0 DELETE)

---

## Verification Strategy

### Pre-Implementation Checks:
- [ ] Build succeeds with all prior waves complete
- [ ] Wave 4A features functional (ratings, collections)
- [ ] Branch created: `feat/p1-wave4b-auto-change`

### Post-Task Verification:

**After 4B.1 (Smart Scheduling):**
- [ ] ScheduleRule model compiles and persists
- [ ] ScheduleManager returns correct interval for current time
- [ ] WallpaperTimer adapts interval dynamically
- [ ] Schedule editor UI functional

**After 4B.2 (Source Priority):**
- [ ] All 3 strategies selectable
- [ ] Round-robin cycles correctly
- [ ] Weighted random respects weights
- [ ] Smart rating favors high-rated sources

**After 4B.3 (Duplicate Avoidance):**
- [ ] Recent history tracked in SwiftData
- [ ] Duplicates blocked within window
- [ ] Old entries pruned automatically

**After 4B.4 (Conditional Pause):**
- [ ] Battery detection works
- [ ] Fullscreen app detection works
- [ ] Pause/resume automatic
- [ ] No false positives

### Final Wave Acceptance:
- [ ] All 4B tasks completed
- [ ] LSP diagnostics clean on all changed files
- [ ] Playwright QA passes all scenarios
- [ ] No SwiftData corruption
- [ ] User tested: "Wallpaper changes adapt to time of day, respect my source preferences, avoid duplicates, and pause when I'm presenting"

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Schedule rule conflicts (overlapping times) | MEDIUM | Validate rules on save, show visual timeline |
| Smart rating algorithm biases too strongly | LOW | Add decay factor, ensure exploration (10% random) |
| Fullscreen detection unreliable | MEDIUM | Use multiple heuristics (NSRunningApplication, CGWindowList) |
| Battery monitoring drains power | LOW | Use IOKit notifications (push), not polling |
| Duplicate window too aggressive | LOW | Default to 1 hour, allow user configuration |

---

## Next Steps After Wave 4B

Once Wave 4B passes all QA:
1. Commit to `feat/p1-wave4b-auto-change`
2. Merge to main branch
3. Implement Wave 4C (UI/UX Enhancements) on new branch
4. Final P1 UI debug pass (deferred from Wave 3)

---

**Plan Author**: sisyphus-junior
**Date**: 2026-05-11
**Status**: Ready for /start-work execution
