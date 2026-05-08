# VarietyMacOS 测试配置指南

## 概述

本文档说明如何为 VarietyMacOS 项目配置和运行单元测试。

## 当前状态

### 已创建的测试文件

| 文件 | 测试内容 | 测试用例数 |
|------|---------|-----------|
| `VarietyMacOSTests/Models/WallpaperTests.swift` | Wallpaper 模型、Codable、计算属性、WallpaperSourceType | ~25 |
| `VarietyMacOSTests/Utilities/DownloadErrorTests.swift` | DownloadError 所有类型、错误描述、Equatable | ~20 |
| `VarietyMacOSTests/Sources/SourceConfigurationTests.swift` | SourceConfiguration、SourceSelector 权重选择 | ~15 |
| `VarietyMacOSTests/Core/WallpaperManagerTests.swift` | WallpaperError、DisplayMode、WallpaperTimer | ~15 |
| `VarietyMacOSTests/Core/ScreenManagerTests.swift` | ScreenManager 单例、屏幕检测、分辨率、配置 | ~20 |
| `VarietyMacOSTests/Preferences/PreferencesTests.swift` | Preferences 设置、默认值、Codable、重置 | ~25 |
| `VarietyMacOSTests/Data/WallpaperHistoryTests.swift` | WallpaperHistory、WallpaperFavorite、WallpaperCache | ~10 |
| `VarietyMacOSTests/Utilities/FileManagerExtensionsTests.swift` | 文件扩展名、Logger、URL 构造、分辨率辅助 | ~20 |

**总计**: 约 150+ 个测试用例

## 在 Xcode 中配置测试目标

由于 Xcode 项目文件 (`project.pbxproj`) 中的测试目标需要手动配置，请按照以下步骤操作：

### 步骤 1: 打开 Xcode 项目

```bash
open /Users/cycloudyang/VarietyMacOS/VarietyMacOS.xcodeproj
```

### 步骤 2: 添加测试 Target

1. 在 Xcode 中，选择 **File** > **New** > **Target...**
2. 选择 **macOS** > **Unit Testing Bundle**
3. 命名目标为 `VarietyMacOSTests`
4. 确保 **Embed in Xcode Project** 已选中
5. 点击 **Finish**

### 步骤 3: 配置测试 Target

1. 选择项目导航器中的项目文件
2. 选择 `VarietyMacOSTests` target
3. 在 **Build Settings** 中:
   - 设置 **Product Bundle Identifier** 为 `com.yourname.variety-macos.Tests`
   - 设置 **Product Name** 为 `VarietyMacOSTests`
4. 在 **Build Phases** 中:
   - 添加主应用到 **Target Dependencies**
   - 在 **Compile Sources** 中添加所有测试文件

### 步骤 4: 添加测试文件到 Compile Sources

在测试 target 的 **Build Phases** > **Compile Sources** 中添加：

```
VarietyMacOSTests/Models/WallpaperTests.swift
VarietyMacOSTests/Utilities/DownloadErrorTests.swift
VarietyMacOSTests/Utilities/FileManagerExtensionsTests.swift
VarietyMacOSTests/Sources/SourceConfigurationTests.swift
VarietyMacOSTests/Core/WallpaperManagerTests.swift
VarietyMacOSTests/Core/ScreenManagerTests.swift
VarietyMacOSTests/Preferences/PreferencesTests.swift
VarietyMacOSTests/Data/WallpaperHistoryTests.swift
VarietyMacOSTests/VarietyMacOSTests.swift
```

### 步骤 5: 配置测试 Scheme

1. 选择 **Product** > **Scheme** > **Manage Schemes...**
2. 选择 `VarietyMacOS` scheme
3. 点击 **Edit**
4. 选择 **Test** 标签页
5. 添加 `VarietyMacOSTests` 为测试目标
6. 设置 **Enable Parallelization** 为 YES（可选，加速测试）

## 运行测试

### 方法 1: 使用 Xcode

```bash
# 在 Xcode 中按 Cmd+U 运行测试
# 或使用菜单 Product > Test
```

### 方法 2: 使用命令行

```bash
cd /Users/cycloudyang/VarietyMacOS
xcodebuild test \
    -project VarietyMacOS.xcodeproj \
    -scheme VarietyMacOS \
    -destination 'platform=macOS' \
    -enableCodeCoverage YES
```

### 方法 3: 使用测试脚本

```bash
cd /Users/cycloudyang/VarietyMacOS
chmod +x run_tests.sh
./run_tests.sh
```

## 生成测试覆盖率报告

### 使用 Xcode

1. 运行测试后，选择 **Product** > **Generate Coverage Data**
2. 选择 **View** > **Coverage** 查看报告

### 使用命令行

```bash
xcodebuild test \
    -project VarietyMacOS.xcodeproj \
    -scheme VarietyMacOS \
    -destination 'platform=macOS' \
    -enableCodeCoverage YES

# 查看覆盖率报告
open /var/folders/*/T/*xctest*/Coverage.profdata
```

## 测试文件结构

```
VarietyMacOSTests/
├── Models/
│   └── WallpaperTests.swift          # Wallpaper 模型测试
├── Utilities/
│   ├── DownloadErrorTests.swift      # 错误处理测试
│   └── FileManagerExtensionsTests.swift  # 工具类测试
├── Sources/
│   └── SourceConfigurationTests.swift   # 壁纸源配置测试
├── Core/
│   ├── WallpaperManagerTests.swift   # 壁纸管理器测试
│   └── ScreenManagerTests.swift      # 屏幕管理器测试
├── Preferences/
│   └── PreferencesTests.swift        # 偏好设置测试
├── Data/
│   └── WallpaperHistoryTests.swift   # 历史记录测试
└── VarietyMacOSTests.swift           # 基础测试
```

## 测试用例分类

### 单元测试 (Unit Tests)

- **DownloadErrorTests**: 错误描述、HTTP 代码处理、Equatable
- **WallpaperTests**: 初始化、Codable、计算属性、相等性
- **SourceConfigurationTests**: 配置初始化、权重选择、Codable
- **WallpaperManagerTests**: 错误处理、DisplayMode、定时器
- **ScreenManagerTests**: 单例、屏幕检测、分辨率
- **PreferencesTests**: 默认值、设置保存、重置
- **WallpaperHistoryTests**: 历史记录管理
- **FileManagerExtensionsTests**: 文件扩展名、URL 构造

### 集成测试 (Integration Tests)

待实现

### UI 测试 (UI Tests)

待实现

## 常见问题

### Q: 测试无法运行？

A: 确保测试目标已正确配置，并且测试文件已添加到正确的 target 中。

### Q: 测试失败？

A: 检查测试是否正确实现了 `@available(macOS 13.0, *)` 标记，确保与主应用兼容。

### Q: 覆盖率报告显示为 0%？

A: 确保 `-enableCodeCoverage YES` 参数已添加，并且测试确实执行了代码。

## 下一步

1. 在 Xcode 中配置测试目标（见上方步骤）
2. 运行所有测试确保通过
3. 查看测试覆盖率报告
4. 根据需要添加更多测试用例
5. 配置 CI/CD 自动运行测试

## 参考资源

- [Xcode Unit Testing](https://developer.apple.com/documentation/xctest)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing with Collections](https://developer.apple.com/documentation/xctest/testing_with_collections)
