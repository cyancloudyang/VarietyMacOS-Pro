# VarietyMacOS 死锁问题修复

## 问题现象
1. 第一次点击 "Next" 或 "Fetch" 可以正常工作
2. 第二次点击后一直显示 "Fetching..." 状态
3. 第三次点击后应用完全死机无响应

## 根本原因

### 原因 1: `isLoading` 标志未正确重置
- `fetchNewWallpaper()` 在 `do` 块开始时设置 `isLoading = true`
- 但在 `do` 块内调用 `await applyWallpaper()` 时，如果发生任何异常，`isLoading` 永远不会重置
- 导致后续调用都被 `guard !isLoading` 阻挡

### 原因 2: 嵌套的 `@MainActor` 调用
- `fetchNewWallpaper()` 标记为 `@MainActor`
- 内部调用 `await applyWallpaper()` 也标记为 `@MainActor`
- 在某些情况下导致死锁

### 原因 3: Task.detached 滥用
- `ContentView` 中使用 `Task.detached` 调用 `nextWallpaper()`
- `nextWallpaper()` 本身在 `@MainActor` 上
- 导致执行上下文混乱

## 修复方案

### 1. 使用 `defer` 确保状态重置
```swift
@MainActor
private func fetchNewWallpaper() async {
    guard !isLoading else { return }
    
    isLoading = true
    defer {
        isLoading = false  // 确保一定会重置
    }
    
    // ... 执行逻辑
}
```

### 2. 添加详细日志
```swift
print("🔄 Next wallpaper requested")
print("📥 Fetching from \(source.displayName)...")
print("✓ Fetched: \(wallpaper.title ?? "Untitled")")
print("🖼️ Applying to desktop...")
print("✓ Done")
```

### 3. 简化调用链
移除 `Task.detached`，直接使用：
```swift
Button(action: {
    Task { @MainActor in
        status = "Fetching..."
        await wallpaperManager.nextWallpaper()
        status = "Done"
    }
}) {
    Label("Next", systemImage: "arrow.right.circle")
}
```

### 4. 添加防护逻辑
```swift
if isLoading {
    print("⚠️ Already loading, skipping")
    return
}
```

## 测试方法

### 步骤 1: 运行应用
```bash
open /Users/cycloudyang/Library/Developer/Xcode/DerivedData/VarietyMacOS-batsjpzpmnkymqaercygbmofcijm/Build/Products/Debug/VarietyMacOS.app
```

### 步骤 2: 多次点击测试
1. 点击 "Next" 按钮
2. 等待状态变为 "Done"
3. 再次点击 "Next" 按钮
4. 重复多次

### 预期行为
- 每次点击都应该正常工作
- 状态显示： "Fetching..." → "Done"
- 不会死机或卡住
- 日志输出清晰显示每一步

### 查看日志
在 Xcode 控制台查看：
```
🔄 Next wallpaper requested
🆕 Fetching new wallpaper
📥 Fetching from Bing...
✓ Fetched: xxx
🖼️ Applying to desktop...
✓ Done
```

## 技术细节

### defer 语句的作用
```swift
isLoading = true
defer {
    isLoading = false  // 无论函数如何返回，这里都会执行
}

// 即使这里抛出异常，isLoading 也会被重置
try await someAsyncOperation()
```

### @MainActor 的正确使用
```swift
// ✅ 正确：在 MainActor 上定义
@MainActor
func nextWallpaper() async {
    // 可以直接更新 UI
    status = "Loading"
    await someAsyncWork()
}

// ✅ 正确：在 Task 中指定 @MainActor
Task { @MainActor in
    await object.nextWallpaper()
}

// ❌ 错误：可能导致死锁
Task.detached {
    await object.nextWallpaper()  // nextWallpaper 需要 MainActor
}
```

## 验证清单

- [x] 第一次点击 "Next" 正常工作
- [x] 第二次点击 "Next" 正常工作
- [x] 连续点击多次不会死机
- [x] 状态正确显示（Fetching... → Done）
- [x] 日志输出清晰
- [x] 错误处理正常

---

**修复日期**: 2026-05-05  
**状态**: ✅ 已修复
