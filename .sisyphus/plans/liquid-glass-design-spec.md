# VarietyMacOS Pro Liquid Glass 视觉设计规范

**创建时间**: 2026-05-12  
**设计语言**: Apple Liquid Glass (macOS Sonoma/Ventana+)  
**状态**: 专家组审议稿 v1.0

---

## 🎨 Liquid Glass 设计语言核心原则

### 什么是 Liquid Glass？

**Liquid Glass** 是 Apple 在 macOS Sonoma 及后续版本中引入的最新视觉设计语言，特点包括：

| 特征 | 描述 | 与传统 Material 的区别 |
|------|------|---------------------|
| **流动性** | 背景色如液体般流动、融合 | 传统 Material 是静态模糊 |
| **多层折射** | 多层玻璃叠加产生光折射效果 | 传统 Material 是单层模糊 |
| **动态响应** | 随内容和壁纸实时变化 | 传统 Material 固定不变 |
| **边缘光晕** | 内容边缘有微妙光晕 (Halo) | 传统 Material 无此效果 |
| **深度层次** | Z 轴层次更明显，悬浮感更强 | 传统 Material 层次平坦 |

### Liquid Glass vs Material

```swift
// ❌ 传统 Material (旧方案)
.background(.ultraThinMaterial)
.background(.thickMaterial)

// ✅ Liquid Glass (新方案)
.background(.regularMaterial)
    .blur(radius: 40)
    .brightness(0.15)
    .contrast(1.1)
    .overlay(
        // 边缘光晕效果
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    )
```

---

## 🌊 Liquid Glass 在 VarietyMacOS Pro 的实现

### 右栏：动态液体背景

#### 核心视觉效果

```
┌─────────────────────────────────────────┐
│  ╔═══════════════════════════════════╗  │
│  ║                                   ║  │
│  ║     [ 壁纸主图 ]                   ║  │
│  ║                                   ║  │
│  ╚═══════════════════════════════════╝  │
│         ↓↓↓ 向下渗透 ↓↓↓                │
│  ╔═══════════════════════════════════╗  │
│  ║   液体背景 (模糊 + 流动感)          ║  │
│  ║   - 亮度提升 15%                   ║  │
│  ║   - 对比度提升 10%                 ║  │
│  ║   - 饱和度降低 20%                 ║  │
│  ╚═══════════════════════════════════╝  │
└─────────────────────────────────────────┘
```

#### 实现代码 (Liquid Glass 版本)

```swift
struct LiquidGlassBackground: View {
    let wallpaper: Wallpaper?
    @State private var dominantColor: Color = .clear
    @State private var scrollOffset: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 基础液体层 - 动态流动效果
                if let wallpaper = wallpaper {
                    LiquidLayer(
                        color: dominantColor,
                        scrollOffset: scrollOffset,
                        isAnimating: isAnimating
                    )
                }
                
                // 2. 玻璃折射层 - 多层模糊叠加
                GlassRefractionLayer(wallpaper: wallpaper)
                    .opacity(0.6)
                
                // 3. 边缘光晕层 - Liquid Glass 特色
                EdgeHaloLayer(color: dominantColor)
                    .opacity(0.4)
                
                // 4. 内容层
                CurrentWallpaperContent(wallpaper: wallpaper)
                    .shadow(color: dominantColor.opacity(0.3), radius: 20)
            }
        }
        .onAppear {
            extractDominantColor()
        }
        .onChange(of: wallpaper) { _, newWallpaper in
            // 液体流动动画
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            } completion: {
                isAnimating = false
            }
        }
    }
}

// MARK: - 液体层
struct LiquidLayer: View {
    let color: Color
    let scrollOffset: CGFloat
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 基础色
            color
            
            // 液体流动效果
            if isAnimating {
                // 流动动画
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.8),
                                color.opacity(0.4),
                                color.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 50)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: scrollOffset
                    )
            }
        }
        .blur(radius: 60)
        .brightness(-0.2)
        .contrast(0.8)
        .offset(y: scrollOffset * 0.3)
    }
}

// MARK: - 玻璃折射层
struct GlassRefractionLayer: View {
    let wallpaper: Wallpaper?
    
    var body: some View {
        Group {
            if let wallpaper = wallpaper,
               let url = wallpaper.localURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        // 多层模糊模拟折射
                        .blur(radius: 40)
                        .brightness(0.1)
                        .contrast(1.1)
                        .saturation(0.8)
                }
            }
        }
    }
}

// MARK: - 边缘光晕层
struct EdgeHaloLayer: View {
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [
                        color.opacity(0.5),
                        color.opacity(0.2),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .blur(radius: 8)
    }
}
```

---

## 🎨 三栏 Liquid Glass 层次结构

### 完整布局

```swift
struct AppRootView: View {
    @State private var wallpaper: Wallpaper?
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        HSplitView {
            // 左栏：Sidebar - 保持轻盈
            SidebarView()
                .frame(minWidth: 200, idealWidth: 250)
                .background {
                    // Liquid Glass 效果：超轻材质 + 微弱光晕
                    LiquidGlassBackground(style: .sidebar)
                        .ignoresSafeArea()
                }
            
            // 中栏：Content - 中等强度
            ContentView()
                .frame(minWidth: 300)
                .background {
                    LiquidGlassBackground(style: .content)
                        .ignoresSafeArea()
                }
            
            // 右栏：Current - 完整 Liquid Glass
            CurrentWallpaperView(wallpaper: $wallpaper)
                .frame(minWidth: 350, idealWidth: 400)
                .background {
                    LiquidGlassBackground(
                        wallpaper: wallpaper,
                        style: .currentWallpaper
                    )
                    .ignoresSafeArea()
                }
        }
    }
}

// MARK: - Liquid Glass 样式枚举
enum LiquidGlassStyle {
    case sidebar      // 左栏：最轻，10% 强度
    case content      // 中栏：中等，30% 强度
    case currentWallpaper // 右栏：完整，100% 强度
    
    var intensity: CGFloat {
        switch self {
        case .sidebar: return 0.1
        case .content: return 0.3
        case .currentWallpaper: return 1.0
        }
    }
    
    var blurRadius: CGFloat {
        switch self {
        case .sidebar: return 80
        case .content: return 60
        case .currentWallpaper: return 40
        }
    }
}
```

### 视觉层次对比

| 层级 | 左栏 (Sidebar) | 中栏 (Content) | 右栏 (Current) |
|------|---------------|---------------|---------------|
| **背景强度** | 10% | 30% | 100% |
| **模糊半径** | 80px | 60px | 40px |
| **亮度调整** | -10% | -15% | -20% |
| **对比度** | 0.9 | 0.8 | 0.7 |
| **边缘光晕** | 无 | 微弱 | 明显 |
| **滚动同步** | 否 | 部分 | 完全 |
| **材质类型** | `.ultraThinMaterial` | `.regularMaterial` | 自定义 Liquid Glass |

---

## 🌊 Liquid Glass 动态效果

### 1. 壁纸切换动画

```swift
// 液体流动式切换
.transition {
    $0
        .scaleEffect(1.05)
        .blur(radius: 30)
        .opacity(0)
}
.insertion {
    $0
        .scaleEffect(0.95)
        .blur(radius: 20)
}
.animation(.spring(response: 0.8, dampingFraction: 0.7))
```

### 2. 滚动视差效果

```swift
struct ParallaxScrollModifier: ViewModifier {
    let scrollOffset: CGFloat
    let intensity: CGFloat
    
    func modifyContent(content: Content) -> some View {
        content
            .offset(y: scrollOffset * intensity)
            .scaleEffect(1.0 + abs(scrollOffset) * 0.001)
    }
}

// 使用
.background {
    LiquidGlassBackground(wallpaper: wallpaper)
        .modifier(ParallaxScrollModifier(
            scrollOffset: scrollOffset,
            intensity: 0.3
        ))
}
```

### 3. 边缘光晕呼吸动画

```swift
struct BreathingHaloModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func modifyContent(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3 * sin(phase)),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 4)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever()) {
                    phase = .pi * 2
                }
            }
    }
}
```

---

## 🎨 Liquid Glass 颜色处理

### 主色提取算法 (Liquid Glass 优化版)

```swift
import CoreImage
import Accelerate

final class LiquidColorExtractor {
    func extractDominantColor(from image: NSImage) -> NSColor {
        // 1. 缩小到 64x64 加速
        let resized = image.resized(to: CGSize(width: 64, height: 64))
        
        guard let cgImage = resized.cgImage(
            forProposedRect: nil, context: nil, hints: nil
        ) else {
            return .windowBackground
        }
        
        // 2. Core Image 处理
        let ciImage = CIImage(cgImage: cgImage)
        
        // 3. 区域平均色
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(ciImage.extent, forKey: kCIInputExtentKey)
        
        let output = filter.outputImage!
        let context = CIContext()
        
        var pixel = [UInt32](repeating: 0, count: 1)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            componentFormat: .RGBA8,
            colorSpace: .sRGB
        )
        
        // 4. 提取 RGBA
        let r = CGFloat((pixel[0] & 0xFF)) / 255.0
        let g = CGFloat((pixel[0] & 0xFF00) >> 8) / 255.0
        let b = CGFloat((pixel[0] & 0xFF0000) >> 16) / 255.0
        
        let originalColor = NSColor(red: r, green: g, blue: b, alpha: 1.0)
        
        // 5. Liquid Glass 优化调整
        return originalColor
            .liquidGlassAdjusted() // 关键调整
    }
}

extension NSColor {
    /// Liquid Glass 专用颜色调整
    func liquidGlassAdjusted() -> NSColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // Liquid Glass 特点：
        // 1. 降低饱和度 (更柔和)
        // 2. 提升亮度 (更通透)
        // 3. 微调色相 (更温暖)
        
        return NSColor(
            hue: h,
            saturation: s * 0.6,    // 降低 40% 饱和度
            brightness: min(b * 1.2, 1.0), // 提升 20% 亮度
            alpha: a * 0.7          // 降低不透明度
        )
    }
}
```

---

## ✅ Liquid Glass 验收标准

### 视觉验收

| 检查项 | 标准 | 验证方法 |
|--------|------|---------|
| **液体流动感** | 背景色有轻微流动动画 | 观察壁纸切换时是否有"流动"感 |
| **多层折射** | 至少 2 层模糊叠加 | 检查代码中 blur 层数 ≥ 2 |
| **边缘光晕** | 右上角有微妙光晕 | 肉眼可见但不突兀 |
| **呼吸动画** | 光晕有 3s 周期呼吸效果 | 使用 Instruments 查看动画 |
| **滚动同步** | 背景随内容滚动（阻尼 0.3） | 滚动时观察背景延迟 |

### 性能验收

| 指标 | 目标 | 测量工具 |
|------|------|---------|
| 初始渲染时间 | < 150ms | Xcode Metrics |
| 滚动帧率 | ≥ 55 FPS | Core Animation Instrument |
| CPU 占用 | < 5% (M 系列) | Activity Monitor |
| 内存增加 | < 25MB | Memory Profiler |

### 兼容性验收

- [ ] macOS 14+ 正常工作
- [ ] 深色/浅色模式自动适配
- [ ] 低性能设备降级方案（关闭流动动画）
- [ ] 多显示器配置正常

---

**文档版本**: 1.0 (Liquid Glass)  
**最后更新**: 2026-05-12  
**状态**: 待用户确认  
**下一步**: 用户确认后进行技术实现
