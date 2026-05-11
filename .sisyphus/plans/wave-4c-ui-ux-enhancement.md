# Wave 4C: UI/UX Enhancement Plan

**Project**: VarietyMacOS Pro (P1 Upgrade)
**Wave Scope**: Modern macOS design language, animations, keyboard shortcuts, drag & drop, context menus, and onboarding experience
**Dependencies**: Wave 1 (SwiftData) ✅, Wave 2 (Swift 6) ✅, Wave 3 (NavigationSplitView) ✅, Wave 4A (Wallpaper Management) ✅, Wave 4B (Auto-Change) ✅
**Branch**: `feat/p1-wave4c-ui-ux`
**Estimated Effort**: 3-4 agent sessions (12-16 hours)

---

## TL;DR

Wave 4C polishes the entire app with modern macOS design patterns and quality-of-life improvements:

1. **Modern macOS Design**: Materials (`.ultraThinMaterial`, `.thickMaterial`), vibrancy effects, unified toolbar style
2. **Animations & Transitions**: Crossfade wallpaper transitions, smooth list animations, hover effects
3. **Keyboard Shortcuts**: Global shortcuts (`⌘N`, `⌘P`, `⌘F`, `⌘S`, `⌘,`) for power users
4. **Drag & Drop**: Drag wallpaper to save, drop images to add to local collection, reorder sources
5. **Context Menus**: Right-click menus for wallpapers (Set as Desktop, Save As, Favorite, Share, View Source)
6. **Onboarding**: First-launch wizard (welcome, choose sources, set interval, done)

All features use native SwiftUI APIs for consistency with macOS Sonoma+ design language.

---

## Execution Waves (Sequential)

| Wave | Parallel Group | Tasks | Description |
|------|----------------|-------|-------------|
| **4C.1** | Serial | 1 | Modern macOS Design: materials, vibrancy, toolbar unification |
| **4C.2** | Serial | 1 | Animations: crossfade transitions, list animations, hover effects |
| **4C.3** | Serial | 1 | Keyboard Shortcuts: global and local shortcuts |
| **4C.4** | Serial | 1 | Drag & Drop: save by dragging, drop to add, reorder sources |
| **4C.5** | Serial | 1 | Context Menus: right-click menus throughout |
| **4C.6** | Serial | 1 | Onboarding: first-launch wizard |

**Total Tasks**: 6
**Estimated Duration**: 1.5-2 days (with QA verification)

---

## Detailed TODOs

### 4C.1: Modern macOS Design Language

**Goal**: Update all UI components to use modern macOS Sonoma+ design patterns.

#### What To Do:

1. **Material Overhaul**
   - **Files**: All view files (`SidebarView.swift`, `CurrentWallpaperView.swift`, `FavoritesContentView.swift`, etc.)
   - Replace:
     - `.background(Color.gray.opacity(0.2))` → `.background(.ultraThinMaterial)`
     - `.background(Color.black.opacity(0.3))` → `.background(.thickMaterial)`
   - Use `.regularMaterial` for content areas
   - Use `.toolbarBackground(.visible)` for unified toolbar

2. **Vibrancy Effects**
   - **File**: `VarietyMacOS/App/SidebarView.swift`
   - Add `.visualEffect()` modifiers for sidebar items on hover
   - Use `NSVisualEffectView` for popover backgrounds

3. **Unified Toolbar**
   - **File**: `VarietyMacOS/VarietyMacOSApp.swift`
   - Apply `.toolbarStyle(.unified)` to main window
   - Add toolbar items: Search, Next, Previous, Favorite, Settings

4. **Consistent Spacing & Typography**
   - **All view files**
   - Use `.padding()` consistently (8, 12, 16, 24, 32 point scale)
   - Use system fonts: `.font(.title)`, `.font(.headline)`, `.font(.body)`, `.font(.caption)`
   - Use `.foregroundStyle(.primary)`, `.secondary` for adaptive colors

5. **SF Symbols Consistency**
   - Audit all icons, replace with SF Symbols where applicable
   - Use `.symbolRenderingMode(.hierarchical)` for multi-color icons
   - Use `.symbolVariant(.fill)` for filled variants

#### Acceptance Criteria:
- [ ] All backgrounds use materials (no hardcoded colors)
- [ ] Sidebar has vibrancy effect on hover
- [ ] Toolbar uses unified style
- [ ] Spacing follows 8pt grid system
- [ ] All icons are SF Symbols
- [ ] Dark mode and light mode both look polished

#### Agent-Executed QA Scenarios:

**QA-4C.1.1: Material Consistency**
```playwright
1. Launch app in light mode
2. Verify sidebar uses .ultraThinMaterial (translucent blur)
3. Toggle dark mode
4. Verify materials adapt (darker blur)
5. Check all content areas use .regularMaterial
```

**QA-4C.1.2: Toolbar Style**
```playwright
1. Open app → observe unified toolbar
2. Toolbar items (Search, Next, Previous) visible
3. Toolbar blurs with content underneath
```

**QA-4C.1.3: SF Symbols Audit**
```bash
# Grep for non-SF icon usage
grep -r "imageNamed\|Image(" VarietyMacOS/App/ | grep -v "systemName"
# Should only find custom images (wallpaper thumbnails, logos)
```

---

### 4C.2: Animations & Transitions

**Goal**: Add smooth, polished animations throughout the app.

#### What To Do:

1. **Crossfade Wallpaper Transitions**
   - **File**: `VarietyMacOS/App/CurrentWallpaperView.swift`
   - Add:
     ```swift
     .transition(.opacity)
     .animation(.easeInOut(duration: 0.5), value: currentWallpaper)
     ```

2. **List Animations**
   - **Files**: `FavoritesContentView.swift`, `HistoryContentView.swift`, `CollectionView.swift`
   - Add `.listRowAnimations(.interactive)` for iOS-style spring animations
   - Use `ForEach(..., id: \.self)` with `.id()` for proper diffing

3. **Hover Effects**
   - **All grid items**
   - Add `.scaleEffect(isHovering ? 1.05 : 1.0)` with `onHover` modifier
   - Use `.buttonStyle(.borderless)` for invisible buttons with hover state

4. **Loading Skeleton**
   - **File**: `VarietyMacOS/App/SkeletonView.swift` (NEW)
   - Shimmer effect while loading thumbnails
   - Use `Gradient` + `animation(.linear(duration: 1.5)).repeatForever()`

5. **Progress Indicators**
   - **File**: `VarietyMacOS/App/DownloadProgressView.swift` (NEW)
   - Circular progress for downloads
   - Use `ProgressView` with custom styling

#### Acceptance Criteria:
- [ ] Wallpaper changes crossfade smoothly
- [ ] List items animate when added/removed
- [ ] Hover effects feel responsive (no lag)
- [ ] Loading states show skeleton/shimmer
- [ ] Download progress visible
- [ ] No janky animations (60 FPS target)

#### Agent-Executed QA Scenarios:

**QA-4C.2.1: Crossfade Transition**
```playwright
1. Navigate to Current Wallpaper view
2. Click "Next Wallpaper"
3. Observe smooth crossfade (0.5s ease-in-out)
4. No flash of unstyled content
```

**QA-4C.2.2: List Animations**
```playwright
1. Go to Favorites
2. Add item (favorite a wallpaper)
3. Observe row slide-in animation
4. Remove item
5. Observe row slide-out + collapse animation
```

**QA-4C.2.3: Hover Responsiveness**
```playwright
1. Hover over wallpaper thumbnail
2. Observe scale effect (1.0 → 1.05)
3. Move mouse away quickly
4. Observe smooth return to 1.0
5. No stutter or frame drops
```

---

### 4C.3: Keyboard Shortcuts

**Goal**: Add global and local keyboard shortcuts for power users.

#### What To Do:

1. **Define Shortcut Commands**
   - **File**: `VarietyMacOS/Utilities/KeyboardShortcuts.swift` (NEW)
   - Use SwiftUI's `.keyboardShortcut()` and `.onKeyPress()` modifiers
   - Define:
     ```swift
     enum AppShortcut: String {
       case next = "n"
       case previous = "p"
       case favorite = "f"
       case skip = "s"
       case settings = ","
       case search = "k"
       case toggleSidebar = "s" // with modifier
     }
     ```

2. **Global Shortcuts (Command Key)**
   - **File**: `VarietyMacOS/VarietyMacOSApp.swift`
   - Add commands to `Commands` scene:
     ```swift
     CommandGroup(replacing: .newItem) {
       Button("Next Wallpaper") {
         WallpaperManager.shared.nextWallpaper()
       }
       .keyboardShortcut("n", modifiers: .command)
     }
     ```

3. **Local Shortcuts (View-Specific)**
   - **File**: All content views
   - Use `.onKeyPress { key, modifiers in ... }` for context-aware shortcuts
   - Example: In SearchView, `⌘F` focuses search field

4. **Shortcut Overlay UI**
   - **File**: `VarietyMacOS/App/KeyboardShortcutsHelpView.swift` (NEW)
   - Accessible via Help menu or `⌘/`
   - Shows all available shortcuts in table format

5. **Menu Bar Integration**
   - **File**: `VarietyMacOS/App/MenuBarView.swift`
   - Ensure menu bar popover respects shortcuts
   - Add Escape key to close popover

#### Acceptance Criteria:
- [ ] `⌘N` triggers next wallpaper
- [ ] `⌘P` triggers previous wallpaper
- [ ] `⌘F` favorites current wallpaper
- [ ] `⌘S` skips to next source
- [ ] `⌘,` opens Settings
- [ ] `⌘K` focuses search field
- [ ] Shortcuts work in all views
- [ ] No conflicts with system shortcuts

#### Agent-Executed QA Scenarios:

**QA-4C.3.1: Global Shortcuts**
```playwright
1. Press ⌘N → observe next wallpaper loads
2. Press ⌘P → observe previous wallpaper returns
3. Press ⌘F → observe favorite added (toast notification)
4. Press ⌘, → Settings window opens
```

**QA-4C.3.2: Context-Aware Shortcuts**
```playwright
1. Navigate to Search view
2. Press ⌘K → search field gains focus
3. Type "nature" → results filter
4. Navigate to Current view
5. Press ⌘K → no search field (no effect)
```

**QA-4C.3.3: Shortcut Conflicts**
```playwright
1. Check ⌘S doesn't conflict with system "Save"
2. If conflict detected, use alternative (e.g., ⌘⌥S)
```

---

### 4C.4: Drag & Drop

**Goal**: Enable intuitive drag-and-drop interactions.

#### What To Do:

1. **Drag Wallpaper to Save**
   - **File**: `VarietyMacOS/App/WallpaperGridItem.swift` (EDIT)
   - Add `.draggable(wallpaper)` modifier
   - Implement `NSItemProvider` for image + metadata

2. **Drop Images to Add**
   - **File**: `VarietyMacOS/App/SourcesContentView.swift` (EDIT)
   - Add `.onDrop(of: [.image, .fileURL])` modifier
   - Handle dropped images:
     - Validate file type (jpg, png, etc.)
     - Copy to local collection folder
     - Add to SwiftData

3. **Reorder Sources**
   - **File**: `VarietyMacOS/App/SourceSettingsView.swift`
   - Use `List(..., onMove: { from, to in ... })`
   - Add drag handles to source rows
   - Persist new order to `SourceConfig`

4. **Drag Collection to Collection**
   - **File**: `VarietyMacOS/App/CollectionView.swift`
   - Drag wallpaper from one collection to another
   - Or drag to "New Collection" button to create and add

#### Acceptance Criteria:
- [ ] Can drag wallpaper thumbnail to Desktop → saves as file
- [ ] Can drag image file from Finder → adds to local collection
- [ ] Can reorder sources in settings
- [ ] Drop targets highlight on hover
- [ ] Invalid drops show error feedback
- [ ] No crashes on malformed drops

#### Agent-Executed QA Scenarios:

**QA-4C.4.1: Drag to Save**
```playwright
1. Drag wallpaper thumbnail to Desktop
2. Verify file saved as "wallpaper-{id}.jpg"
3. Verify file opens in Preview.app
```

**QA-4C.4.2: Drop to Add**
```playwright
1. Drag image file from Finder
2. Drop onto Sources view
3. Observe "Adding to Local collection" toast
4. Navigate to Local source → new wallpaper appears
```

**QA-4C.4.3: Reorder Sources**
```playwright
1. Go to Settings → Sources
2. Drag "Unsplash" above "Bing"
3. Release → order persists after restart
4. Next wallpaper respects new order (round-robin)
```

---

### 4C.5: Context Menus

**Goal**: Add right-click context menus for quick actions.

#### What To Do:

1. **Wallpaper Context Menu**
   - **File**: `VarietyMacOS/App/WallpaperGridItem.swift` (EDIT)
   - Add `.contextMenu { ... }` modifier
   - Items:
     - Set as Desktop
     - Favorite / Unfavorite
     - Add to Collection...
     - Save As...
     - Share...
     - View Source (open URL)
     - Copy Info (metadata as text)

2. **Collection Context Menu**
   - **File**: `VarietyMacOS/App/SidebarView.swift`
   - Right-click collection → Rename, Delete, Add Wallpapers

3. **History Entry Context Menu**
   - **File**: `VarietyMacOS/App/HistoryContentView.swift`
   - Right-click history entry → Re-apply, Remove from History, Favorite

4. **Search Result Context Menu**
   - **File**: `VarietyMacOS/App/SearchView.swift`
   - Same as wallpaper context menu
   - Plus "Search Similar" option

#### Acceptance Criteria:
- [ ] Right-click shows context menu on all wallpaper items
- [ ] Menu items execute correct action
- [ ] Menu disabled when action not applicable (e.g., "Set as Desktop" grayed out if already current)
- [ ] Keyboard shortcuts shown next to menu items
- [ ] No menu on touchpad secondary click (if disabled in system prefs)

#### Agent-Executed QA Scenarios:

**QA-4C.5.1: Wallpaper Context Menu**
```playwright
1. Right-click wallpaper thumbnail
2. Context menu appears with 8 items
3. Click "Favorite" → wallpaper added to favorites
4. Right-click again → "Unfavorite" appears (toggle state)
```

**QA-4C.5.2: Collection Context Menu**
```playwright
1. Right-click collection in sidebar
2. Click "Rename" → inline text input appears
3. Type new name → collection updates
```

**QA-4C.5.3: History Context Menu**
```playwright
1. Right-click history entry
2. Click "Re-apply" → wallpaper set as current
3. Click "Remove" → entry deleted from history
```

---

### 4C.6: Onboarding Experience

**Goal**: Create first-launch wizard to guide new users.

#### What To Do:

1. **Onboarding State Manager**
   - **File**: `VarietyMacOS/Utilities/OnboardingManager.swift` (NEW)
   - `@MainActor final class: ObservableObject`
   - Properties:
     ```swift
     @Published var hasCompletedOnboarding: Bool
     @Published var currentStep: Int = 0
     @Published var selectedSources: Set<WallpaperSourceType> = []
     @Published var chosenInterval: TimeInterval = 1800
     ```
   - Methods: `startOnboarding()`, `completeOnboarding()`, `skipOnboarding()`

2. **Welcome Screen**
   - **File**: `VarietyMacOS/App/OnboardingWelcomeView.swift` (NEW)
   - Title: "Welcome to VarietyMacOS Pro"
   - Subtitle: "Your personalized wallpaper experience"
   - Buttons: "Get Started", "Skip Tour"

3. **Source Selection Screen**
   - **File**: `VarietyMacOS/App/OnboardingSourcesView.swift` (NEW)
   - Grid of source cards (Unsplash, Bing, Wallhaven, etc.)
   - Each card shows preview image + description
   - Toggle to enable/disable
   - "Select All" / "Select None" buttons

4. **Interval Selection Screen**
   - **File**: `VarietyMacOS/App/OnboardingIntervalView.swift` (NEW)
   - Slider: 5 minutes to 24 hours
   - Preset buttons: 5 min, 15 min, 30 min, 1 hour, 3 hours, Daily
   - Preview: "Your wallpaper will change every X"

5. **Completion Screen**
   - **File**: `VarietyMacOS/App/OnboardingDoneView.swift` (NEW)
   - "You're all set!" message
   - Summary: "You enabled 3 sources, wallpaper changes every 30 minutes"
   - Button: "Start Enjoying Wallpapers"

6. **Onboarding Window**
   - **File**: `VarietyMacOS/App/OnboardingWindow.swift` (NEW)
   - Modal window (non-resizable, 600x500)
   - Progress indicator (step 1 of 4)
   - Navigation: Back / Next buttons
   - Escape key closes (with confirmation)

7. **Integrate with App Launch**
   - **File**: `VarietyMacOS/VarietyMacOSApp.swift`
   - Check `OnboardingManager.shared.hasCompletedOnboarding`
   - If false → show onboarding window
   - If true → show main app

#### Acceptance Criteria:
- [ ] Onboarding shows on first launch only
- [ ] User can skip onboarding (but encouraged to complete)
- [ ] Source selection persists to Preferences
- [ ] Interval selection persists to Preferences
- [ ] Progress indicator accurate
- [ ] Back/Next navigation works
- [ ] Escape key closes with confirmation
- [ ] Completion saves `hasCompletedOnboarding = true`

#### Agent-Executed QA Scenarios:

**QA-4C.6.1: First Launch Flow**
```playwright
1. Fresh install (delete prefs)
2. Launch app → onboarding appears
3. Click "Get Started"
4. Select "Unsplash" and "Bing"
5. Set interval to 30 minutes
6. Click "Start Enjoying"
7. Main app appears
8. Restart app → onboarding skipped
```

**QA-4C.6.2: Skip Onboarding**
```playwright
1. Fresh install
2. Click "Skip Tour"
3. Main app appears with defaults
4. No onboarding on restart
```

**QA-4C.6.3: Back/Next Navigation**
```playwright
1. Start onboarding
2. Go to step 2 (sources)
3. Click "Back" → returns to welcome
4. Click "Next" → returns to sources
5. No state lost (selections persist)
```

**QA-4C.6.4: Escape Key**
```playwright
1. Open onboarding step 2
2. Press Escape
3. Confirmation dialog: "Leave onboarding?"
4. Click "Cancel" → stay
5. Press Escape again → click "Leave" → onboarding closes
```

---

## Dependency Graph

```
Wave 1-3 ✅ ─── Wave 4A ✅ ─── Wave 4B ✅
                                    │
Wave 4C                             │
├── 4C.1: Modern Design             │
│   ├── Materials, vibrancy        │
│   └── Toolbar unification         │
│                                   │
├── 4C.2: Animations                │
│   ├── Crossfade transitions      │
│   └── Hover effects              │
│                                   │
├── 4C.3: Keyboard Shortcuts       │
│   ├── Global (⌘N, ⌘P, etc.)     │
│   └── Local (view-specific)      │
│                                   │
├── 4C.4: Drag & Drop              │
│   ├── Save by dragging          │
│   └── Drop to add               │
│                                   │
├── 4C.5: Context Menus            │
│   └── Right-click actions       │
│                                   │
└── 4C.6: Onboarding               │
    └── First-launch wizard
```

---

## Files Changed (Wave 4C)

| File | Action | Description |
|------|--------|-------------|
| `VarietyMacOS/App/SidebarView.swift` | EDIT | Material, vibrancy |
| `VarietyMacOS/App/CurrentWallpaperView.swift` | EDIT | Crossfade transition |
| `VarietyMacOS/App/FavoritesContentView.swift` | EDIT | List animations |
| `VarietyMacOS/App/HistoryContentView.swift` | EDIT | List animations, context menu |
| `VarietyMacOS/App/WallpaperGridItem.swift` | EDIT | Hover effect, draggable, context menu |
| `VarietyMacOS/App/SourcesContentView.swift` | EDIT | Drop target, reorder |
| `VarietyMacOS/App/SearchView.swift` | EDIT | Context menu |
| `VarietyMacOS/VarietyMacOSApp.swift` | EDIT | Toolbar style, commands, onboarding check |
| `VarietyMacOS/Utilities/KeyboardShortcuts.swift` | NEW | Shortcut definitions |
| `VarietyMacOS/Utilities/OnboardingManager.swift` | NEW | Onboarding state management |
| `VarietyMacOS/App/SkeletonView.swift` | NEW | Loading skeleton component |
| `VarietyMacOS/App/DownloadProgressView.swift` | NEW | Progress indicator |
| `VarietyMacOS/App/KeyboardShortcutsHelpView.swift` | NEW | Shortcuts reference UI |
| `VarietyMacOS/App/OnboardingWelcomeView.swift` | NEW | Step 1: Welcome |
| `VarietyMacOS/App/OnboardingSourcesView.swift` | NEW | Step 2: Source selection |
| `VarietyMacOS/App/OnboardingIntervalView.swift` | NEW | Step 3: Interval selection |
| `VarietyMacOS/App/OnboardingDoneView.swift` | NEW | Step 4: Completion |
| `VarietyMacOS/App/OnboardingWindow.swift` | NEW | Modal onboarding container |

**Total**: 18 files (10 NEW, 8 EDIT, 0 DELETE)

---

## Verification Strategy

### Pre-Implementation Checks:
- [ ] Build succeeds with all prior waves complete
- [ ] Wave 4B features functional (smart scheduling, duplicate avoidance, conditional pause)
- [ ] Branch created: `feat/p1-wave4c-ui-ux`

### Post-Task Verification:

**After 4C.1 (Modern Design):**
- [ ] All materials render correctly in light/dark mode
- [ ] Toolbar uses unified style
- [ ] SF Symbols used consistently

**After 4C.2 (Animations):**
- [ ] Crossfade transitions smooth (no jank)
- [ ] List animations work on add/remove
- [ ] Hover effects responsive

**After 4C.3 (Shortcuts):**
- [ ] All global shortcuts functional
- [ ] Local shortcuts context-aware
- [ ] No system conflicts

**After 4C.4 (Drag & Drop):**
- [ ] Drag to save works
- [ ] Drop to add works
- [ ] Reorder sources persists

**After 4C.5 (Context Menus):**
- [ ] Right-click shows menu
- [ ] All menu items functional
- [ ] Toggle states correct

**After 4C.6 (Onboarding):**
- [ ] Shows on first launch
- [ ] Skippable
- [ ] Persists selections
- [ ] Doesn't show on subsequent launches

### Final Wave Acceptance:
- [ ] All 4C tasks completed
- [ ] LSP diagnostics clean on all changed files
- [ ] Playwright QA passes all scenarios
- [ ] No visual regressions
- [ ] User tested: "The app feels polished, responsive, and intuitive"

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Material rendering performance | LOW | Test on older Macs, fallback to solid colors if needed |
| Drag & drop conflicts with system | LOW | Use standard SwiftUI modifiers, test edge cases |
| Keyboard shortcut conflicts | MEDIUM | Document conflicts, provide alternative bindings |
| Onboarding state corruption | LOW | Validate on launch, reset if invalid |
| Animation timing feels off | LOW | User test with default timings, adjust based on feedback |

---

## Next Steps After Wave 4C

Once Wave 4C passes all QA:
1. Commit to `feat/p1-wave4c-ui-ux`
2. Merge to main branch
3. **P1 Upgrade Complete!**
4. Final P1 UI debug pass (address deferred "几个小的问题" from Wave 3)
5. Tag release: `v1.0.0-pro`
6. Prepare release notes for GitHub

---

## Post-Wave 4C: Deferred Debug Pass

Recall from Wave 3 completion:
> User: "我运行测试了一下，发现了几个小的问题，都是与 UI 有关的。要不我们先进行后续的升级计划吧，最后再一起 Debug。"

After Wave 4C completes, return to these deferred UI bugs:
- NavigationSplitView layout issues
- Sidebar selection state
- Detail column placeholder behavior
- Toolbar item visibility
- Dark mode edge cases

Create separate branch `fix/p1-ui-debug` for final polish.

---

**Plan Author**: sisyphus-junior
**Date**: 2026-05-11
**Status**: Ready for /start-work execution
