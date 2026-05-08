# 测试指南 - Variety macOS

## 已修复的问题

### 1. ArtStation 无法取消勾选 ✅

**测试步骤**:
1. 打开应用，进入设置 (Settings)
2. 点击 "Sources" 标签
3. 点击 "Add Source..." 按钮
4. 点击 ArtStation 行 - 应该显示勾选标记 ✓
5. 再次点击 ArtStation 行 - 勾选标记应该消失 ✗
6. 点击 "Done" 保存设置

**预期结果**: ArtStation 可以正常启用和禁用

---

### 2. 各图源下载测试

#### ArtStation 测试
```bash
# 运行应用后，点击 "Next Wallpaper" 多次
# 观察日志输出
```

**预期行为**:
- ArtStation RSS 优先尝试
- 如果 RSS 失败，自动切换到 API
- 日志显示 "ArtStation RSS failed, falling back to API"

#### Wallhaven 测试
```bash
# 连续点击 "Next Wallpaper" 5-10 次
# 观察是否有重试行为
```

**预期行为**:
- 首次失败后自动重试（最多 5 次）
- 每次重试间隔递增（0.5s, 1s, 2s, 4s, 8s）
- 日志显示 "Retrying with different source..."

#### Bing 测试
```bash
# 点击 "Next Wallpaper"
# 检查是否获取到 Bing 每日壁纸
```

**预期行为**:
- 成功获取 Bing 每日壁纸
- 包含正确的标题和描述
- 分辨率设置为 UHD

#### Reddit 测试
```bash
# 确保启用了 Reddit 源
# 点击 "Next Wallpaper"
```

**预期行为**:
- 跳过 NSFW 内容
- 只获取图片帖子
- 正确解析 imgur 链接

---

## 日志查看

### 实时日志
```bash
# 查看应用日志
log stream --predicate 'processImagePath contains "VarietyMacOS"' --info --debug
```

### 关键日志消息

| 消息 | 说明 |
|------|------|
| `ArtStation RSS failed, falling back to API` | RSS 失败，使用 API 后备 |
| `Retrying with different source...` | 正在重试其他源 |
| `Rate limited by Wallhaven` | Wallhaven 限流 |
| `Skipping NSFW Reddit post` | 跳过 NSFW 内容 |
| `No valid wallpapers found` | 未找到有效壁纸 |

---

## 各源状态

| 源 | 状态 | 备注 |
|---|---|---|
| Unsplash | ⚠️ 需要 API Key | 默认使用 source.unsplash.com |
| Bing | ✅ 工作正常 | 推荐作为默认源 |
| Wallhaven | ✅ 已修复 | 5 次重试机制 |
| Reddit | ✅ 工作正常 | NSFW 过滤 |
| ArtStation | ✅ 已修复 | RSS + API 双重保障 |
| Local | ✅ 工作正常 | 递归扫描 |

---

## 常见问题排查

### 所有源都失败
1. 检查网络连接
2. 检查防火墙设置
3. 查看日志中的错误信息

### Wallhaven 频繁失败
1. 检查是否配置 API key
2. 减少连续请求频率
3. 等待几分钟后重试

### ArtStation 失败
1. RSS feed 可能暂时不可用
2. 自动切换到 API
3. 检查网络连接

---

## 性能测试

### 内存使用
```bash
# 运行应用后，观察 Activity Monitor
# 内存使用应保持在合理范围 (< 200MB)
```

### 响应时间
- Bing: < 2 秒
- Unsplash: < 3 秒
- Wallhaven: < 5 秒 (含重试)
- ArtStation: < 3 秒
- Reddit: < 3 秒

---

## 报告问题

如果发现问题，请提供：
1. 具体的错误日志
2. 操作步骤
3. 系统版本
4. 网络环境（是否需要代理）
