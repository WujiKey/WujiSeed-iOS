# 无忌 (WUJI Key)

> 将难忘的记忆转化为可恢复的助记词。

无忌是一款 iOS 应用，通过用户可记忆的信息（个人标识、地理位置及记忆）生成高熵 BIP39 助记词。与传统随机数生成器不同，无忌让用户能够在完全离线的情况下，通过相同的输入信息重复恢复相同的助记词。

[English](README.md) | 中文

---

## 特性

- **确定性生成** — 相同输入始终产生相同助记词
- **高安全性** — 组合熵超过 274 bits
- **完全离线** — 所有加密运算在本地完成，无网络请求
- **BIP39 兼容** — 生成标准 24 词助记词
- **3-of-5 容错恢复** — 5 组地点及记忆中任意 3 组即可恢复
- **多语言支持** — 英语、简体中文、繁體中文、日本語、Español

## 工作原理

### 生成流程

1. **个人标识** → BLAKE2b-128 生成 16 字节随机盐
2. **5 组地点及记忆** → F9Grid 编码 + 文本标准化 → 排序拼接
3. **Argon2id KDF** (256MB/7次) → 256-bit 主密钥
4. **BIP39 编码** → 256 bits + 8 bits 校验和 → 24 个助记词

### 恢复方式

- **方法一**: 加密备份 + 个人标识 + 任意 3 组地点及记忆
- **方法二**: 方位码 + 个人标识 + 全部 5 组地点及记忆（无需加密备份）

## 技术规格

| 组件 | 规格 |
|------|------|
| 密钥派生 | Argon2id (256MB, 7次迭代, 1线程) |
| 盐生成 | BLAKE2b-128 (16 字节) |
| 加密 | XChaCha20-Poly1305 AEAD |
| 容错方案 | C(5,3) 组合加密 (10 个加密块) |
| 地理编码 | F9Grid 网格系统 |
| 助记词 | BIP39 标准 (256 bits + 8 bits 校验) |

## 构建

### 环境要求

- iOS 12.0+
- Xcode 14.0+
- Swift 5.0+

### 编译

```bash
# 克隆仓库
git clone https://github.com/WujiSeed/WujiSeed.git
cd WujiSeed

# 打开项目
open WujiSeed.xcodeproj

# 命令行构建
xcodebuild -project WujiSeed.xcodeproj \
  -scheme WujiSeed \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### 运行测试

```bash
xcodebuild test -project WujiSeed.xcodeproj \
  -scheme WujiSeed \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 依赖

- [Swift-Sodium](https://github.com/jedisct1/swift-sodium) 0.9.1 — Argon2id 实现
- [F9Grid](https://github.com/WujiKey/F9Grid) — 地理网格编码

## 文档

- [WujiSeed 协议规范 (中文)](Docs/WujiSeed-Technical-Specification-zh.md)
- [WujiSeed Protocol Specification (English)](Docs/WujiSeed-Technical-Specification.md)

## 安全注意事项

- 在专用离线设备上使用
- 开启飞行模式后再运行
- 助记词仅存于内存，退出即清除
- 5 组地点应分散且私密
- 记忆文本避免使用公开信息

## 许可证

Apache License 2.0

---

**无忌** — 無忌 無記 無所顧忌 | For the Memories That Never Fade
