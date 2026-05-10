# Debug Plan: UI Thumbnail Display Fix

## 目标
修复主界面 Current Wallpaper 卡片无法显示缩略图的问题。

## 问题根因
`WallpaperManager.applyWallpaper()` 在应用到桌面后立即调用 `wallpaper.clearCachedImage()`，导致 UI 绑定的 `@Published var cachedImage` 变为 nil。

## 修复策略

### 方案：延迟清理 + 智能缓存管理

**核心思路**：
1. 保留当前显示壁纸的缓存
2. 在获取新壁纸时清理旧壁纸缓存
3. 内存警告时清理所有非当前壁纸缓存

### 修改清单

#### 1. WallpaperManager.swift

**修改点 1.1**: `applyWallpaper()` - 移除立即清理
```swift
// 删除第 195 行
// wallpaper.clearCachedImage()  // ← 删除此行
```

**修改点 1.2**: `fetchNewWallpaper()` - 在获取前清理
```swift
@MainActor
private func fetchNewWallpaper() async {
  // 清理旧壁纸缓存（如果有）
  currentWallpaper?.clearCachedImage()
  
  // ... 现有逻辑
}
```

**修改点 1.3**: `setupMemoryWarningObserver()` - 实现内存清理
```swift
private func setupMemoryWarningObserver() {
  NSWorkspace.shared.notificationCenter.addObserver(
    self,
    selector: #selector(handleMemoryWarning),
    name: NSWorkspace.didWakeNotification,
    object: nil
  )
}

@objc private func handleMemoryWarning() {
  // 清理非当前壁纸的缓存
  currentWallpaper?.clearCachedImage()
}
```

#### 2. ContentView.swift

**修改点 2.1**: `currentWallpaperCard` - 确保观察器工作
```swift
if let wallpaper = wallpaperManager.currentWallpaper {
  if let image = wallpaper.cachedImage {
    // 显示图片
  } else {
    // 显示占位符
  }
}
```

### 测试验证

1. **功能测试**
   - [ ] 点击 Next Wallpaper 后，Current Wallpaper 卡片显示缩略图
   - [ ] 切换壁纸时，缩略图正确更新
   - [ ] 图片尺寸正确（非拉伸/裁剪）

2. **内存测试**
   - [ ] 连续切换 10 次壁纸，内存增长 < 50MB
   - [ ] 内存警告后，非当前壁纸缓存被清理
   - [ ] 应用重启后无内存泄漏

3. **边界测试**
   - [ ] 快速连续点击 Next（防抖）
   - [ ] 网络错误时的 UI 表现
   - [ ] 大图（4K）加载性能

### 执行步骤

1. **备份当前代码**（已完成）
2. **修改 WallpaperManager.swift**（10 分钟）
3. **修改 ContentView.swift**（5 分钟）
4. **构建验证**（5 分钟）
5. **功能测试**（10 分钟）
6. **内存测试**（10 分钟）

### 成功标准

- ✅ Current Wallpaper 卡片显示缩略图
- ✅ 内存使用稳定（< 150MB）
- ✅ 无崩溃
- ✅ 无图片加载延迟

---

生成时间：2026-05-09
执行优先级：P0（阻塞性问题）
