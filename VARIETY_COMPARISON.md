# Variety macOS vs Variety (Linux) 功能对比

本文档对比了 Variety macOS 与原始 Variety (Linux) 的功能差异，并列出改进建议。

## 已实现的功能

### 壁纸源 (Wallpaper Sources)

| 源 | Variety Linux | Variety macOS | 状态 |
|---|---|---|---|
| Unsplash | ✅ | ✅ | 已实现 |
| Bing | ✅ | ✅ | 已实现 |
| Wallhaven | ✅ | ✅ | 已实现 (带重试机制) |
| Reddit | ✅ | ✅ | 已实现 |
| ArtStation | ✅ (RSS) | ✅ (RSS) | 已实现 (RSS 方式) |
| Local Files | ✅ | ✅ | 已实现 (递归扫描) |
| National Geographic | ✅ | ❌ | 待实现 |
| Flickr | ✅ | ❌ | 待实现 |
| 500px | ✅ | ❌ | 待实现 |
| Equestria Daily | ✅ | ❌ | 待实现 |

### 核心功能

| 功能 | Variety Linux | Variety macOS | 状态 |
|---|---|---|---|
| 定时更换壁纸 | ✅ | ✅ | 已实现 |
| 多显示器支持 | ✅ | ✅ | 已实现 |
| 本地文件夹扫描 | ✅ | ✅ | 已实现 (递归) |
| 图片缓存 | ✅ | ✅ | 已实现 (内存 + 磁盘) |
| 重试机制 | ✅ | ✅ | 已实现 (指数退避) |
| 限流处理 | ✅ | ✅ | 已实现 |
| 用户代理模拟 | ✅ | ✅ | 已实现 |
| 安全模式 (NSFW 过滤) | ✅ | ❌ | 待实现 |
| 图片过滤效果 | ✅ | ✅ | 已实现 (Core Image) |
| 桌面引用/时钟 | ✅ | ❌ | 待实现 |
| 收藏夹操作 | ✅ | ❌ | 待实现 |
| 下载配额管理 | ✅ | ❌ | 待实现 |
| 壁纸自动轮播 | ✅ | ✅ | 已实现 |

## 关键设计模式对比

### 1. 下载器架构 (Downloader Architecture)

**Variety Linux:**
```python
# 分层架构
Downloader (基类)
  ├─ DefaultDownloader (默认下载器)
  │    └─ SimpleDownloader (简单下载器)
  │         └─ BingDownloader, UnsplashDownloader, etc.
  └─ WallhavenDownloader (特殊处理)
```

**Variety macOS:**
```swift
// 扁平架构
WallpaperSource (协议)
  ├─ BingSource
  ├─ UnsplashSource
  ├─ WallhavenSource (带重试)
  └─ ArtStationSource (RSS)
```

**建议:** macOS 版本已经采用了更简洁的设计，但可以考虑添加一个 `BaseWallpaperSource` 来共享通用逻辑。

### 2. 队列机制 (Queue System)

**Variety Linux:**
- 使用 `fill_queue()` 预填充队列
- 队列大小：20-100 个项目
- 节流控制：`max_downloads_per_hour`, `max_queue_fills_per_hour`

**Variety macOS:**
- 当前实现：单次获取
- 缺少：预填充队列机制

**建议:** 添加队列缓存机制，减少 API 调用频率。

### 3. 安全模式 (Safe Mode)

**Variety Linux:**
```python
SAFE_MODE_BLACKLIST = {
    "woman", "women", "model", "models", "boob", "boobs",
    "lingerie", "bikini", "sexy", "bra", "panties", ...
}

def is_unsafe(self, extra_metadata):
    if self.is_safe_mode_enabled() and "keywords" in extra_metadata:
        blacklisted = set(k.lower() for k in extra_metadata["keywords"]) & SAFE_MODE_BLACKLIST
        return (True, blacklisted) if blacklisted else (False, [])
    return False, []
```

**Variety macOS:** 未实现

**建议实现:**
```swift
struct SafeModeFilter {
    static let blacklistedKeywords = Set([
        "woman", "women", "model", "models", "boob", "boobs",
        "lingerie", "bikini", "sexy", "bra", "panties",
        // ... 更多关键词
    ])
    
    static func isUnsafe(keywords: [String]) -> (Bool, [String]) {
        let blacklisted = Set(keywords.map { $0.lowercased() })
            .intersection(blacklistedKeywords)
        return (blacklisted.isEmpty, blacklisted)
    }
}
```

### 4. 元数据管理 (Metadata Management)

**Variety Linux:**
- 使用 `Exiv2` 库写入 EXIF/XMP 元数据
- 备用方案：JSON sidecar 文件 (`.metadata.json`)

**Variety macOS:**
- 当前：无元数据写入
- 建议：使用 `Core Image` 的元数据 API

### 5. 图片过滤 (Image Filters)

**Variety Linux:**
```python
filters = [
    [False, "Keep original", ""],
    [False, "Grayscale", "-type Grayscale"],
    [False, "Heavy blur", "-blur 120x40"],
    [False, "Oil painting", "-paint 6"],
    [False, "Charcoal painting", "-charcoal 3"],
    [False, "Pointilism", "-spread 10 -noise 3"],
    [False, "Pixellate", "-scale 3% -scale 3333%"],
]
```
使用 ImageMagick 命令

**Variety macOS:**
```swift
enum WallpaperFilter {
    case original
    case grayscale
    case blur
    case oilPaint
    case sharpen
    case vignette
    // 使用 Core Image CIFilter
}
```
✅ 已实现，使用 GPU 加速

## 待实现功能列表

### 高优先级 (P0)

1. **安全模式 (Safe Mode)**
   - NSFW 关键词过滤
   - 基于标签的内容过滤
   - 用户自定义黑名单

2. **下载配额管理**
   - 限制下载文件夹大小
   - 自动清理旧壁纸
   - 下载统计

3. **收藏夹管理**
   - 收藏/取消收藏壁纸
   - 收藏夹操作配置 (复制/移动)
   - 收藏夹文件夹同步

### 中优先级 (P1)

4. **桌面引用和时钟**
   - 引用叠加 (名人名言)
   - 数字时钟显示
   - 自定义字体和位置

5. **更多壁纸源**
   - National Geographic
   - Flickr
   - 500px
   - DeviantArt

6. **智能过滤**
   - 最小分辨率过滤
   - 宽高比过滤
   - 颜色偏好

### 低优先级 (P2)

7. **统计和报告**
   - 下载统计
   - 使用报告
   - 来源分布

8. **同步功能**
   - 跨设备同步收藏夹
   - 配置同步

9. **插件系统**
   - 自定义下载器插件
   - 自定义过滤器插件

## 代码质量对比

| 方面 | Variety Linux | Variety macOS |
|---|---|---|
| 语言 | Python 3.9+ | Swift 5.9+ |
| 类型安全 | 动态类型 | 静态类型 ✅ |
| 并发模型 | 线程 | async/await ✅ |
| 错误处理 | 异常 | Result/throws ✅ |
| 测试覆盖率 | ~60% | 目标>80% |
| 文档 | 基础 | 待完善 |

## 总结

Variety macOS 已经在核心功能上取得了良好进展：
- ✅ 所有主要壁纸源已实现
- ✅ 重试机制和限流处理已完善
- ✅ 图片过滤使用 GPU 加速
- ✅ 现代化架构 (async/await, SwiftUI)

需要加强的领域：
- ❌ 安全模式 (NSFW 过滤)
- ❌ 队列缓存机制
- ❌ 元数据管理
- ❌ 桌面引用/时钟
- ❌ 下载配额管理

## 参考实现

建议参考 Variety Linux 的以下文件进行改进：
- `variety/plugins/builtin/downloaders/DefaultDownloader.py` - 下载器基类
- `variety/plugins/builtin/downloaders/WallhavenDownloader.py` - Wallhaven API 处理
- `variety/Util.py` - 工具函数
- `variety/Options.py` - 配置管理
