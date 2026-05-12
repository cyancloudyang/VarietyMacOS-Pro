# VarietyMacOS Pro 综合升级计划 v3.0

**创建时间**: 2026-05-12  
**最后更新**: 2026-05-12  
**设计语言**: Apple Liquid Glass  
**执行策略**: 分阶段、可验证、渐进式增强  

---

## 📋 计划概览

### 项目状态

| 维度 | 状态 | 详情 |
|------|------|------|
| **完成度** | 85% | P1 核心功能已完成 |
| **待完成** | 15% | UI 细节 + AI 增强 + 最终 QA |
| **构建状态** | ✅ BUILD SUCCEEDED | 最新提交 `8df1ad0` |
| **推送状态** | ✅ origin/main 已同步 | 远程一致 |

### 本计划范围

本计划整合以下三大升级方向：

1. **视觉升级**: Liquid Glass 全面落地
2. **AI 增强**: 三阶段智能化路线
3. **体验优化**: 专家组建议的其他改进

---

## 🎨 第一阶段：Liquid Glass 视觉升级（1-2 周）

### 目标

将现有 Material 材质全面升级为 **Liquid Glass** 设计语言，实现用户描述的高级感、和谐感、生命力。

### 关键特性

| 特性 | 描述 | 优先级 |
|------|------|--------|
| **液体流动感** | 背景色缓慢流动（2 秒周期） | 🔴 高 |
| **多层折射** | 至少 2 层模糊叠加模拟玻璃折射 | 🔴 高 |
| **边缘光晕** | 从壁纸四周边缘溢出的主色光晕 | 🔴 高 |
| **滚动同步** | 背景随内容滚动（阻尼 0.3） | 🟡 中 |
| **智能降级** | 低性能设备关闭流动动画 | 🟡 中 |

### 任务分解

#### Task 1.1: 核心组件开发

**目标**: 创建可复用的 Liquid Glass 组件库

**文件**:
- `VarietyMacOS/Utilities/LiquidGlassBackground.swift` (新建)
- `VarietyMacOS/Utilities/LiquidColorExtractor.swift` (新建)
- `VarietyMacOS/Utilities/EdgeHaloModifier.swift` (新建)

**实现内容**:
```swift
// LiquidGlassBackground.swift
struct LiquidGlassBackground: View {
    let wallpaper: Wallpaper?
    let intensity: CGFloat // 0.0-1.0
    let scrollOffset: CGFloat
    
    var body: some View {
        ZStack {
            // 1. 液体层
            LiquidLayer(color: extractColor(), intensity: intensity)
            
            // 2. 折射层
            RefractionLayer(wallpaper: wallpaper)
            
            // 3. 光晕层
            EdgeHaloLayer(color: extractEdgeColor())
        }
        .blur(radius: 60 * (1.0 - intensity))
    }
}
```

**验收标准**:
- [ ] 组件支持强度调节（0.0-1.0）
- [ ] 支持滚动同步（可选）
- [ ] 支持流动动画开关
- [ ] 性能：CPU < 3%, 内存 < 10MB

**预计工时**: 4-6 小时

---

#### Task 1.2: 右栏集成

**目标**: 将 CurrentWallpaperView 升级为 Liquid Glass 风格

**修改文件**:
- `VarietyMacOS/App/CurrentWallpaperView.swift`

**关键改动**:
```swift
// 之前
.background(.ultraThinMaterial)

// 之后
.background {
    LiquidGlassBackground(
        wallpaper: wallpaperManager.currentWallpaper,
        intensity: 1.0,
        scrollOffset: scrollOffset
    )
    .ignoresSafeArea()
}
```

**验收标准**:
- [ ] 右栏背景显示壁纸主色溢出效果
- [ ] 亮度降低 20%，对比度降低 30%
- [ ] 流动动画强度中等（2 秒周期）
- [ ] 滚动时背景同步（阻尼 0.3）
- [ ] 切换壁纸时有 300ms 交叉渐变

**预计工时**: 3-4 小时

---

#### Task 1.3: 中栏与左栏适配

**目标**: 三栏视觉层次统一

**修改文件**:
- `VarietyMacOS/App/SidebarView.swift`
- `VarietyMacOS/App/ContentView.swift` (或对应内容视图)

**强度梯度**:

| 栏位 | 强度 | 模糊半径 | 流动动画 |
|------|------|---------|---------|
| 右栏 | 100% | 40px | ✅ 开启 |
| 中栏 | 30% | 60px | ❌ 关闭 |
| 左栏 | 10% | 80px | ❌ 关闭 |

**验收标准**:
- [ ] 左栏保持 `.ultraThinMaterial` + 10% 背景溢出
- [ ] 中栏 30% 强度背景溢出
- [ ] 三栏过渡自然，无视觉割裂

**预计工时**: 2-3 小时

---

#### Task 1.4: 性能优化与降级

**目标**: 确保低性能设备流畅运行

**实现内容**:
```swift
// 检测设备性能
let isLowPerformance = ProcessInfo.processInfo.performanceCapability == .low

// 降级策略
if isLowPerformance {
    // 关闭流动动画
    // 减少模糊层数
    // 降低分辨率
}
```

**验收标准**:
- [ ] 低性能设备自动关闭流动动画
- [ ] 滚动帧率 ≥ 55 FPS (所有设备)
- [ ] CPU 占用 < 5% (M 系列), < 15% (Intel)

**预计工时**: 2-3 小时

---

### 阶段一验收

| 检查项 | 方法 | 预期结果 |
|--------|------|---------|
| 视觉一致性 | 人工审查 | 三栏过渡自然 |
| 流动效果 | 肉眼观察 | 可感知但不突兀 |
| 边缘光晕 | 肉眼观察 | 右上角可见光晕 |
| 性能测试 | Instruments | FPS ≥ 55, CPU < 5% |
| 兼容性 | 多设备测试 | macOS 14+ 正常 |

---

## 🤖 第二阶段：AI 增强功能（2-3 周）

### 目标

实现三阶段 AI 路线图的 P0 和 P1 功能，提升智能化水平。

### 关键特性

| 功能 | 描述 | 优先级 | 阶段 |
|------|------|--------|------|
| CLI 分析工具 | 命令行壁纸分析 | 🔴 高 | P0 |
| 自动标签 | Vision 场景识别 | 🔴 高 | P0 |
| 偏好记录 | SwiftData 行为存储 | 🟡 中 | P1 |
| 智能推荐 | 协同过滤推荐 | 🟡 中 | P2 |
| 生成壁纸 | 外部 API 集成 | 🟢 低 | P3 |

### 任务分解

#### Task 2.1: CLI 分析工具

**目标**: 创建命令行工具分析壁纸特征

**新建文件**:
- `variety-cli/analyze.swift`
- `variety-cli/extract_colors.swift`
- `variety-cli/detect_scene.swift`

**功能**:
```bash
# 使用示例
$ variety-cli analyze /path/to/wallpaper.jpg

# 输出
{
  "dominantColors": ["#FF6B6B", "#4ECDC4"],
  "brightness": 0.73,
  "contrast": 0.85,
  "tags": ["nature", "sunset", "landscape"],
  "mood": "calm"
}
```

**技术栈**: Vision + Core Image + Accelerate

**验收标准**:
- [ ] 支持单张/批量分析
- [ ] 输出 JSON 格式
- [ ] 分析速度 < 2 秒/张
- [ ] 准确率 ≥ 85% (与人工标注对比)

**预计工时**: 6-8 小时

---

#### Task 2.2: 自动标签生成

**目标**: 使用 Vision 框架自动为壁纸添加标签

**修改文件**:
- `VarietyMacOS/Sources/WallpaperSource.swift` (扩展)
- `VarietyMacOS/Utilities/SceneDetector.swift` (新建)

**实现**:
```swift
import Vision

final class SceneDetector {
    func detect(in image: NSImage) async -> [String] {
        // 1. 场景识别
        // 2. 物体检测
        // 3. 情感分析
        // 4. 返回标签列表
    }
}
```

**验收标准**:
- [ ] 新壁纸导入时自动打标签
- [ ] 标签准确率 ≥ 80%
- [ ] 支持中文标签
- [ ] 支持标签去重和合并

**预计工时**: 4-6 小时

---

#### Task 2.3: 用户偏好记录

**目标**: 使用 SwiftData 记录用户行为，为推荐做准备

**新建模型**:
```swift
@Model
final class UserAction {
    var id: UUID
    var wallpaperId: String
    var action: ActionType // viewed, favorited, skipped, applied
    var timestamp: Date
    var duration: TimeInterval // 观看时长
    
    @Relationship var wallpaper: Wallpaper?
}

enum ActionType: String {
    case viewed, favorited, skipped, applied
}
```

**验收标准**:
- [ ] 记录用户查看、收藏、跳过、应用操作
- [ ] 记录观看时长
- [ ] 数据持久化到 SwiftData
- [ ] 支持查询最近 N 条记录

**预计工时**: 4-6 小时

---

### 阶段二验收

| 功能 | 验收方法 | 预期结果 |
|------|---------|---------|
| CLI 工具 | 命令行测试 | 输出正确 JSON |
| 自动标签 | 人工审查 | 标签准确率 ≥ 80% |
| 偏好记录 | 数据库检查 | 记录完整准确 |

---

## 🎭 第三阶段：体验优化与最终 QA（1-2 周）

### 目标

整合前两阶段成果，进行全链路测试和优化。

### 任务分解

#### Task 3.1: Onboarding 集成

**目标**: 将已有的 OnboardingView 集成到启动流程

**验收标准**:
- [ ] 首次启动显示引导
- [ ] 引导完成后不再显示
- [ ] 支持重新触发引导

**预计工时**: 2-3 小时

---

#### Task 3.2: 全功能端到端测试

**目标**: 验证所有功能正常工作

**测试范围**:
- 壁纸获取、预览、设置
- 收藏、历史、集合管理
- 自动更换
- 搜索功能
- Liquid Glass 效果

**验收标准**:
- [ ] 所有功能正常
- [ ] 无崩溃
- [ ] 性能达标

**预计工时**: 4-6 小时

---

#### Task 3.3: 边界条件测试

**测试场景**:
- [ ] 无网络环境
- [ ] 低存储空间
- [ ] 多显示器配置
- [ ] 深色/浅色模式切换
- [ ] 低性能设备

**预计工时**: 4-6 小时

---

## 📅 总体时间表

### 时间规划

| 阶段 | 内容 | 时间 | 里程碑 |
|------|------|------|--------|
| **准备** | 环境搭建、依赖检查 | 0.5 天 | ✅ 完成 |
| **阶段一** | Liquid Glass 实现 | 5-7 天 | 视觉验收通过 |
| **阶段二** | AI 功能开发 | 7-10 天 | AI 功能可用 |
| **阶段三** | QA 与优化 | 3-5 天 | 生产就绪 |
| **缓冲** | 问题修复 | 3-5 天 | - |

**总计**: 18-27 个工作日（约 4 周）

---

## 📊 验收标准总览

### 功能性验收

| 功能 | 验收方法 | 预期结果 |
|------|---------|---------|
| Liquid Glass | 视觉审查 + 性能测试 | 流动感明显，FPS ≥ 55 |
| CLI 工具 | 命令行测试 | 输出正确 JSON |
| 自动标签 | 人工审查 | 准确率 ≥ 80% |
| 偏好记录 | 数据库检查 | 记录完整 |

### 性能验收

| 指标 | 目标 | 测量工具 |
|------|------|---------|
| 初始加载 | < 200ms | Xcode Metrics |
| 滚动帧率 | ≥ 55 FPS | Core Animation |
| CPU 占用 | < 5% (M) | Activity Monitor |
| 内存增加 | < 25MB | Memory Profiler |

### 兼容性验收

- [ ] macOS 14+ 正常工作
- [ ] 深色/浅色模式适配
- [ ] 多显示器配置正常
- [ ] 低性能设备降级正常

---

## 🎯 下一步行动

### 立即执行

1. **Task 1.1**: 创建 Liquid Glass 核心组件
2. **并行**: Task 2.1 CLI 工具开发

### 负责人分配

| 任务 | 负责人 | 技能要求 |
|------|--------|---------|
| Liquid Glass | UI/UX + 架构师 | SwiftUI, Metal |
| CLI 工具 | AI/ML 工程师 | Vision, Core Image |
| 自动标签 | AI/ML 工程师 | Vision, NLP |
| 偏好记录 | 后端工程师 | SwiftData |

---

**计划版本**: 3.0  
**最后更新**: 2026-05-12  
**状态**: 待用户批准  
**下一步**: 用户确认后启动 Task 1.1
