# VarietyMacOS 使用说明

## 主要变化

现在 VarietyMacOS 是一个**完整的窗口应用**，而不仅仅是菜单栏应用！

### ✅ 已修复
1. 设置窗口可以正常关闭了
2. 添加了完整的主窗口界面
3. 菜单栏图标功能已集成到窗口中
4. 所有功能都可以在窗口中操作

## 如何运行

### 方法 1: Xcode 运行
```bash
# 打开项目
open /Users/cycloudyang/VarietyMacOS/VarietyMacOS.xcodeproj

# 按 Cmd+R 运行
```

### 方法 2: 直接运行已构建的应用
```bash
open /Users/cycloudyang/Library/Developer/Xcode/DerivedData/VarietyMacOS-batsjpzpmnkymqaercygbmofcijm/Build/Products/Debug/VarietyMacOS.app
```

### 方法 3: 命令行构建并运行
```bash
cd /Users/cycloudyang/VarietyMacOS
xcodebuild -scheme VarietyMacOS -destination 'platform=macOS' build
open Build/Products/Debug/VarietyMacOS.app
```

## 界面介绍

### 主窗口
应用打开后会显示主窗口，包含：
- **当前壁纸**：显示当前设置的壁纸预览
- **快捷操作**：Next、Previous、Pause 按钮
- **测试源**：测试当前启用的源是否能正常获取壁纸
- **已启用的源**：显示所有启用的壁纸源

### 设置窗口
点击右上角的齿轮图标打开设置：
- **General**：通用设置（更换间隔、显示模式等）
- **Sources**：管理壁纸源
- **Download**：下载设置
- **About**：关于

## 使用流程

### 1. 首次启动
1. 运行应用后，会看到主窗口
2. 默认可能没有设置壁纸

### 2. 启用壁纸源
1. 点击右上角齿轮图标打开设置
2. 切换到 "Sources" 标签
3. 点击 "Add Source..."
4. 点击想要的源（如 Bing、Unsplash）启用
5. 关闭窗口返回主界面

### 3. 设置壁纸
1. 确保至少启用了 一个源
2. 在主窗口点击 "Set Wallpaper" 按钮
3. 或在菜单选择 Wallpaper > Next

### 4. 测试源
1. 在主窗口找到 "Test Source" 卡片
2. 点击 "Test Fetch" 按钮
3. 查看结果：
   - ✓ Success = 成功
   - ✗ 错误信息 = 失败

## 功能说明

### 主窗口卡片

#### Current Wallpaper（当前壁纸）
- 显示当前壁纸预览
- 显示来源信息
- 显示标题

#### Quick Actions（快捷操作）
- **Next**：获取下一张壁纸
- **Previous**：返回上一张壁纸
- **Pause**：暂停/继续自动切换

#### Test Source（测试源）
- 测试当前启用的源
- 显示测试结果
- 帮助诊断问题

#### Enabled Sources（已启用的源）
- 显示所有启用的源
- 快速查看状态

### 菜单栏
应用仍然保留菜单栏图标（照片图标）：
- 点击显示快捷菜单
- 可以快速切换壁纸
- 可以打开设置

## 键盘快捷键

| 快捷键 | 功能 |
|--------|------|
| Cmd+Right Arrow | 下一张壁纸 |
| Cmd+Left Arrow | 上一张壁纸 |
| Cmd+Space | 暂停/继续 |

## 常见问题

### Q: 为什么点击 Sources 的 Add Source 没反应？
A: 点击 "Add Source..." 按钮后会弹出选择框，点击想要的源即可启用。

### Q: 如何关闭设置窗口？
A: 点击窗口左上角的红色关闭按钮，或按 Cmd+W。

### Q: 如何更改壁纸更换间隔？
A: 打开设置 > General > Change interval，选择时间间隔。

### Q: Test Fetch 显示失败怎么办？
A: 
1. 检查网络连接
2. 确认已启用至少一个源
3. 检查源设置（如 API 密钥）

## 测试状态

- ✅ 144 个测试用例全部通过
- ✅ 构建成功
- ✅ 窗口功能正常
- ✅ 设置功能正常

## 下一步

1. 运行应用查看主窗口
2. 在设置中启用 Bing 源（最简单）
3. 点击主窗口的 "Set Wallpaper" 测试
4. 使用 "Test Fetch" 验证源是否工作

---

**更新日期**: 2026-05-05
**版本**: 1.0.0
**状态**: ✅ 可用
