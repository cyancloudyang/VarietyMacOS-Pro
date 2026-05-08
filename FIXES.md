# VarietyMacOS 修复说明

## 修复的问题

### 1. Sources 添加功能无响应 ✅

**问题**: 在设置的 Sources 标签页点击 "Add Source..." 没有反应

**修复内容**:
- 重写了 `AddSourceView`，现在可以真正启用/禁用壁纸源
- 添加了 `SourceSelectionButton` 组件，带有所选源的状态显示
- 添加了 `Preferences` 扩展方法 `isSourceEnabled()`、`enableSource()`、`disableSource()`
- 现在点击源即可启用/禁用它

**文件**: `VarietyMacOS/App/SettingsView.swift`

### 2. 菜单点击外部不关闭 ✅

**问题**: 打开菜单后点击外部区域，菜单不会关闭

**修复内容**:
- 将 Popover 的 behavior 改为 `.transient`（这是 macOS 的标准行为）
- 现在点击菜单外部会自动关闭菜单

**文件**: `VarietyMacOS/VarietyMacOSApp.swift`

### 3. 添加测试按钮 ✅

**问题**: 无法快速测试壁纸源是否能正常获取图片

**修复内容**:
- 在菜单栏添加了 "Test Fetch" 按钮
- 点击后会从当前启用的源获取壁纸
- 显示测试结果：✓ 成功 或 ✗ 失败及错误信息
- 测试过程中按钮会禁用并显示 "Testing..."

**文件**: `VarietyMacOS/VarietyMacOS/App/MenuBarView.swift`

## 如何测试

### 1. 运行应用

```bash
cd /Users/cycloudyang/VarietyMacOS
open Build/Products/Debug/VarietyMacOS.app
```

或在 Xcode 中按 `Cmd+R` 运行。

### 2. 测试 Sources 功能

1. 点击菜单栏的 Variety 图标
2. 点击 "Preferences..." 打开设置
3. 切换到 "Sources" 标签
4. 点击 "Add Source..."
5. 点击任意源（如 Unsplash、Bing）来启用它
6. 再次点击可禁用

### 3. 测试壁纸获取

1. 确保至少启用了 一个源（见上一步）
2. 点击菜单栏的 Variety 图标
3. 点击 "Test Fetch" 按钮
4. 等待测试结果：
   - ✓ 开头表示成功（绿色）
   - ✗ 开头表示失败（红色），后面是错误信息

### 4. 测试菜单关闭

1. 点击菜单栏的 Variety 图标
2. 点击菜单外部任意位置
3. 菜单应该立即关闭

## 支持的壁纸源

| 源 | 说明 | API 密钥 |
|---|---|---|
| Unsplash | 高质量图片 | 可选 |
| Bing | 每日壁纸 | 无需 |
| Wallhaven | 社区壁纸 | 可选 |
| Reddit | Reddit 子版块 | 无需 |
| Local | 本地文件夹 | 无需 |

## 测试建议

1. **测试 Unsplash**: 无需 API 密钥，使用公开 API
2. **测试 Bing**: 最简单，直接获取 Bing 每日壁纸
3. **测试 Reddit**: 需要网络，测试 earthporn 等子版块
4. **测试失败场景**: 禁用所有源后点击 Test Fetch，应显示 "No sources enabled"

## 已知问题

- 测试按钮只显示第一个启用源的测试结果
- 如果需要测试特定源，确保只启用该源
- 网络问题可能导致测试失败，请确保网络连接正常

## 下一步

1. 添加 Unsplash API 密钥配置
2. 添加 Wallhaven API 密钥配置
3. 添加 Reddit 子版块配置
4. 改进测试功能，可以选择特定源测试

---

**修复日期**: 2026-05-05
**状态**: ✅ 完成
