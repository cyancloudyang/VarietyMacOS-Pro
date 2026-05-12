// Task 1.3: 中栏与左栏适配 - 代码草稿
// 在用户添加 Liquid Glass 文件到 Xcode 项目后执行此集成

// MARK: - SidebarView 适配 (左栏 - 强度 0.1)
// 文件：VarietyMacOS/App/SidebarView.swift

/*
在 SidebarView 中添加：

import VarietyMacOS // 确保导入

struct SidebarView: View {
    // 添加状态变量
    @State private var sidebarIntensity: CGFloat = 0.1
    
    var body: some View {
        List {
            // ... 现有内容
        }
        .background {
            // 添加 Liquid Glass 背景（低强度）
            LiquidGlassBackground(
                wallpaper: wallpaperManager.currentWallpaper,
                intensity: sidebarIntensity, // 0.1 = 10% 强度
                scrollOffset: 0,
                isAnimating: false // 左栏不启用流动动画
            )
            .ignoresSafeArea()
        }
    }
}
*/

// MARK: - Content View 适配 (中栏 - 强度 0.3)
// 文件：VarietyMacOS/App/SourcesContentView.swift 或其他内容视图

/*
在相应的内容视图中添加：

struct SourcesContentView: View {
    @State private var contentIntensity: CGFloat = 0.3
    
    var body: some View {
        ScrollView {
            // ... 现有内容
        }
        .background {
            LiquidGlassBackground(
                wallpaper: wallpaperManager.currentWallpaper,
                intensity: contentIntensity, // 0.3 = 30% 强度
                scrollOffset: scrollOffset,
                isAnimating: false // 中栏不启用流动动画
            )
            .ignoresSafeArea()
        }
    }
}
*/

// MARK: - 三栏强度梯度总结
/*
| 栏位 | 强度 | 流动动画 | 滚动同步 |
|------|------|---------|---------|
| 右栏 (Current) | 1.0 (100%) | ✅ 开启 | ✅ 开启 (阻尼 0.3) |
| 中栏 (Content) | 0.3 (30%)  | ❌ 关闭 | ⚠️ 部分同步 |
| 左栏 (Sidebar) | 0.1 (10%)  | ❌ 关闭 | ❌ 不同步 |

这样设计确保：
1. 视觉焦点在右栏（当前壁纸）
2. 中栏有轻微背景溢出，保持层次
3. 左栏保持清晰，便于导航
*/
