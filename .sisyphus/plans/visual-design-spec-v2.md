# VarietyMacOS Pro 视觉设计文档 v2.0

**创建时间**: 2026-05-12  
**设计愿景**: "内敛的和谐、高级的质感、生命的活力、稳固的安心"  
**参考标准**: macOS Sonoma/Ventana 最新人机界面指南 (HIG)

---

## 🎨 设计理念

### 核心原则

| 原则 | 描述 | 实现方式 |
|------|------|----------|
| **内敛的和谐** | 背景不喧宾夺主，而是衬托内容 | 降低背景亮度/对比度，使用羽化渐变 |
| **高级的质感** | 利用 macOS 原生能力 | 玻璃材质 (`.ultraThinMaterial`)、系统色板 |
| **生命的活力** | 随壁纸和交互动态响应 | 滚动同步、渐隐渐现过渡动画 |
| **稳固的安心** | 布局稳定、可预测 | 保持三栏结构，动效平滑不突兀 |

### 视觉层次

```
┌─────────────────────────────────────────────────────────────┐
│  左栏 (Sidebar)           中栏 (Content)      右栏 (Current) │
│  ┌─────────────┐        ┌──────────┐      ┌──────────────┐ │
│  │ Collections │        │          │      │  当前壁纸预览  │ │
│  │ ├ Current   │        │  列表内容  │      │  ┌────────┐  │ │
│  │ ├ Favorites │        │          │      │  │ 壁纸图片 │  │ │
│  │ ├ History   │        │          │      │  └────────┘  │ │
│  │ └ Sources   │        │          │      │              │ │
│  │             │        │          │      │  Quick Actions│ │
│  └─────────────┘        └──────────┘      └──────────────┘ │
│                                                               │
│  背景色溢出路径：右栏 → 中栏 → 左栏 (渐变减弱)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🖼️ 右栏壁纸背景效果详解

### 视觉效果需求

#### 1. 静态状态（无滚动）
- **壁纸主图**: 显示在右栏上部，固定位置
- **背景溢出**: 从壁纸边缘提取主色，向外扩散
  - 亮度降低 40%
  - 对比度降低 30%
  - 高斯模糊半径：60px
  - 不透明度：60% → 0% (从右向左渐变)

#### 2. 滚动状态
- **壁纸图片向上滚动** → 背景色同步向上移动
- **视觉效果**: 仿佛壁纸"浸泡"在液体中，液体随内容流动
- **影响范围**: 
  - 右栏：背景色完全覆盖
  - 中栏右侧：背景色延伸 20-30%
  - 左栏：几乎不影响（保持玻璃材质）

#### 3. 壁纸切换动画
- **旧壁纸**: 渐隐 (fade out) 300ms ease-out
- **新壁纸**: 渐现 (fade in) 300ms ease-in
- **背景色**: 交叉渐变，保持连续性

### 技术实现方案

#### 方案 A：Core Image + Metal 着色器 (推荐)

```swift
import SwiftUI
import CoreImage
import Metal

/// 动态壁纸背景视图
struct DynamicWallpaperBackground: View {
    let wallpaper: Wallpaper?
    @State private var dominantColor: Color = .clear
    @State private var imagePosition: CGFloat = 0.0 // 滚动偏移
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 基础背景色
                dominantColor
                    .opacity(0.6)
                
                // 2. 壁纸缩略图（模糊、放大）
                if let wallpaper = wallpaper {
                    AsyncImage(url: wallpaper.localURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 60)
                            .scaleEffect(1.2)
                            .opacity(0.5)
                    }
                    .frame(width: geometry.size.width * 1.5,
                           height: geometry.size.height * 1.5)
                    .offset(y: imagePosition * 0.3) // 滚动同步
                }
                
                // 3. 从右向左的渐变遮罩
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.8),
                        Color.black.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .trailing,
                    endPoint: .leading
                )
            }
            .ignoresSafeArea()
        }
        .onAppear {
            extractDominantColor()
        }
    }
    
    private func extractDominantColor() {
        // 使用 Core Image 提取主色
        guard let wallpaper = wallpaper,
              let url = wallpaper.localURL else { return }
        
        // 异步加载并分析
        Task {
            let color = await ColorExtractor.dominantColor(from: url)
            dominantColor = color
        }
    }
}

/// 颜色提取工具
final class ColorExtractor {
    static func dominantColor(from url: URL) async -> Color {
        await withCheckedContinuation { continuation in
            let image = CIImage(contentsOf: url)
            let filter = CIFilter(name: "CIAreaAverage")!
            filter.setValue(image, forKey: kCIInputImageKey)
            
            // ... 提取主色逻辑
            let dominant = extractAverageColor(image!)
            continuation.resume(returning: dominant)
        }
    }
}
```

#### 方案 B：SwiftUI 原生实现 (简化版)

```swift
struct GlassyWallpaperBackground: View {
    let wallpaper: Wallpaper?
    @State private var backgroundColor: Color = .windowBackground
    
    var body: some View {
        ZStack {
            // 1. 基础背景
            backgroundColor
                .ignoresSafeArea()
            
            // 2. 壁纸背景层（模糊）
            if let wallpaper = wallpaper,
               let imageURL = wallpaper.localURL {
                ImageLoadProxy(url: imageURL)
                    .map { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 50)
                            .brightness(-0.2)
                            .contrast(0.7)
                            .opacity(0.5)
                    }
                    .ignoresSafeArea()
            }
            
            // 3. 从右向左的渐变遮罩
            LinearGradient(
                colors: [
                    backgroundColor.opacity(0.8),
                    backgroundColor.opacity(0.4),
                    backgroundColor.opacity(0.1),
                    Color.clear
                ],
                startPoint: .trailing,
                endPoint: .leading
            )
            .ignoresSafeArea()
        }
        .onChange(of: wallpaper) { _, newWallpaper in
            // 壁纸切换时的平滑过渡
            withAnimation(.easeInOut(duration: 0.4)) {
                updateBackgroundColor()
            }
        }
    }
}
```

---

## 📐 三栏布局与背景关系

### 层级结构

```swift
struct AppRootView: View {
    @State private var wallpaper: Wallpaper?
    @State private var scrollOffset: CGFloat = 0.0
    
    var body: some View {
        HSplitView { // 假设有水平分割容器
            // 左栏：Sidebar
            SidebarView()
                .frame(minWidth: 200, idealWidth: 250)
                .background(.ultraThinMaterial) // 玻璃材质
                .overlay {
                    // 背景色溢出效果（弱）
                    BackgroundSpilloverView(
                        intensity: 0.1, // 10% 强度
                        offset: scrollOffset
                    )
                }
            
            // 中栏：Content List
            ContentView()
                .frame(minWidth: 300)
                .background {
                    // 背景色溢出效果（中等）
                    BackgroundSpilloverView(
                        intensity: 0.3, // 30% 强度
                        offset: scrollOffset
                    )
                }
            
            // 右栏：Current Wallpaper
            CurrentWallpaperView(wallpaper: $wallpaper)
                .frame(minWidth: 350, idealWidth: 400)
                .background {
                    // 完整背景效果
                    DynamicWallpaperBackground(wallpaper: wallpaper)
                        .offset(y: scrollOffset)
                }
        }
    }
}
```

### 背景色溢出梯度

| 栏位 | 背景强度 | 模糊半径 | 不透明度 | 滚动同步 |
|------|---------|---------|---------|---------|
| **右栏** | 100% | 60px | 60% | ✅ 完全同步 |
| **中栏右侧** | 30% | 80px | 20% | ⚠️ 部分同步 |
| **中栏左侧** | 10% | 100px | 10% | ❌ 不同步 |
| **左栏** | 0% | - | - | ❌ 保持玻璃材质 |

---

## 🎬 动画与过渡效果

### 壁纸切换动画

```swift
// 当前壁纸变化时的处理
.onChange(of: wallpaperManager.currentWallpaper) { oldWallpaper, newWallpaper in
    withAnimation(.easeInOut(duration: 0.4)) {
        // 1. 旧壁纸渐隐
        currentOpacity = 0.0
        
        // 2. 更新壁纸
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            wallpaper = newWallpaper
            
            // 3. 新壁纸渐现
            withAnimation(.easeInOut(duration: 0.3)) {
                currentOpacity = 1.0
            }
        }
    }
}
```

### 滚动同步动画

```swift
// ScrollView 内监听滚动位置
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 在 CurrentWallpaperView 中
var body: some View {
    ScrollView {
        VStack {
            // 内容
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .scrollView).origin.y
                    )
            }
        }
    }
    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
        // 背景同步滚动（带阻尼）
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            backgroundOffset = offset * 0.3 // 减缓系数
        }
    }
}
```

---

## 🎨 颜色与材质规范

### 主色提取算法

```swift
import CoreImage
import Accelerate

final class DominantColorExtractor {
    func extract(from image: NSImage) -> NSColor {
        // 1. 缩放到 64x64 加速计算
        let resized = image.resized(to: CGSize(width: 64, height: 64))
        
        // 2. 转换为 CGImage
        guard let cgImage = resized.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .windowBackground
        }
        
        // 3. 使用 Core Image 分析
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAreaAverage")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        // 4. 输出平均色
        let output = filter.outputImage!
        let context = CIContext()
        var pixel = [UInt32](repeating: 0, count: 1)
        context.render(output, toBitmap: &pixel, rowBytes: 4,
                       componentFormat: .RGBA8, colorSpace: .sRGB)
        
        let r = CGFloat((pixel[0] & 0xFF)) / 255.0
        let g = CGFloat((pixel[0] & 0xFF00) >> 8) / 255.0
        let b = CGFloat((pixel[0] & 0xFF0000) >> 16) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
            .adjustedForBackground() // 降低亮度/对比度
    }
}

extension NSColor {
    func adjustedForBackground() -> NSColor {
        // 降低亮度 40%，对比度 30%
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        return NSColor(hue: h,
                       saturation: s * 0.7, // 降低饱和度
                       brightness: b * 0.6, // 降低亮度
                       alpha: a * 0.6)      // 降低不透明度
    }
}
```

### 玻璃材质使用规范

| 场景 | 材质类型 | 使用位置 |
|------|---------|---------|
| 侧边栏背景 | `.ultraThinMaterial` | SidebarView |
| 弹窗/浮层 | `.thickMaterial` | Sheets, Modals |
| 工具栏 | `.regularMaterial` | Toolbar, TabBar |
| 按钮悬停 | `.ultraThinMaterial` | Button hover states |

---

## 📐 性能优化策略

### 1. 图像缓存

```swift
final class BackgroundCache {
    private let cache = NSCache<NSString, NSImage>()
    private let blurCache = NSCache<NSString, NSImage>()
    
    func getBlurred(image: NSImage, radius: CGFloat = 60) -> NSImage {
        let key = "\(image.hash)_\(radius)"
        if let cached = blurCache.object(forKey: key as NSString) {
            return cached
        }
        
        let blurred = image.applyBlur(radius: radius)
        blurCache.setObject(blurred, forKey: key as NSString)
        return blurred
    }
}
```

### 2. 延迟渲染

- 仅在视图进入屏幕时才计算背景
- 滚动时使用低分辨率背景（节流）
- 停止滚动后替换为高分辨率

### 3. Metal 着色器优化

对于 M 系列芯片，使用 Metal 着色器实时计算模糊和颜色提取，性能优于 Core Image。

---

## ✅ 验收标准

### 视觉效果验收

- [ ] 右栏背景色从壁纸边缘自然溢出
- [ ] 背景色亮度降低 40%，对比度降低 30%
- [ ] 滚动时背景同步移动（阻尼系数 0.3）
- [ ] 壁纸切换时有 300ms 交叉渐变动画
- [ ] 左栏保持玻璃材质，不受背景溢出影响

### 性能验收

- [ ] 初始加载时间 < 200ms
- [ ] 滚动帧率 ≥ 55 FPS
- [ ] 内存占用增加 < 20MB
- [ ] CPU 占用 < 5%（M 系列芯片）

### 兼容性验收

- [ ] macOS 14+ 正常工作
- [ ] 深色/浅色模式自动适配
- [ ] 多显示器配置正常
- [ ] 低性能设备降级方案（关闭动态效果）

---

**文档版本**: 2.0  
**最后更新**: 2026-05-12  
**状态**: 待用户确认  
**下一步**: 用户确认后进行技术可行性验证和实现
