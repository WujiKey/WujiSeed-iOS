# WujiSeed 协议规范

**协议版本:** `WUJI-Key-V1`
**文档版本:** 1.0
**日期:** 2026-01

---

## 摘要

WujiSeed 是一个创新的加密货币助记词生成与备份协议。它通过将用户的**个人记忆**（姓名、地点、故事）转化为确定性的 BIP39 助记词，实现"无需记忆助记词本身"的目标。本协议采用 BLAKE2b、Argon2id 等现代密码学原语，提供军用级安全性，同时支持 3-of-5 门限恢复方案。

---

## 1. 设计目标

### 1.1 核心理念

传统助记词方案要求用户记住或安全存储 24 个随机单词。WujiSeed 采用不同的方法：

> **用记得住的，生成记不住的。**

用户只需记住：
- 一个**个人标识**（如姓名、邮箱）
- **5 个有意义的地点**及其相关记忆

协议将这些输入确定性地转换为标准 BIP39 助记词。

### 1.2 安全目标

| 目标 | 实现方式 |
|------|----------|
| **离线优先** | 所有计算本地完成，无网络请求 |
| **抗暴力破解** | Argon2id 256MB 内存硬化 |
| **门限恢复** | 仅需 3/5 地点即可恢复 |
| **确定性输出** | 相同输入始终产生相同助记词 |
| **前向保密** | 每个加密块使用随机填充 |

---

## 2. 协议概述

### 2.1 生成流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                     用户输入                                     │
├─────────────────────────────────────────────────────────────────┤
│  个人标识（姓名/邮箱）                                           │
│  ├── 文本标准化 ──→ Normalize(identifier)                      │
│  └── 盐值派生 ──→ BLAKE2b-128 ──→ salt (16字节)                │
│                                                                  │
│  5个地点 × (坐标 + 两条记忆)                                     │
│  ├── 坐标 ──→ F9Grid单元格索引 + 方位码                         │
│  ├── 记忆文本 ──→ 标准化 + 排序                                  │
│  └── 合并编码 ──→ keyMaterial (按字节序排列)                     │
├─────────────────────────────────────────────────────────────────┤
│                     密钥派生                                     │
├─────────────────────────────────────────────────────────────────┤
│  Argon2id(                                                       │
│    password = keyMaterial[0] ‖ keyMaterial[1] ‖ ... ‖ [4],      │
│    salt = 16字节盐值,                                            │
│    memory = 256 MB,                                              │
│    iterations = 7                                                │
│  ) ──→ 256位熵值                                                 │
├─────────────────────────────────────────────────────────────────┤
│                     BIP39 编码                                   │
├─────────────────────────────────────────────────────────────────┤
│  256位熵值 ──→ 23个单词 (253位)                                  │
│  剩余3位 + SHA256校验和(8位) ──→ 第24个单词                      │
│                                                                  │
│  输出: 24个 BIP39 助记词                                         │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 恢复流程

**方法一：加密备份恢复（推荐）**
- 需要：加密备份文件 + 个人标识 + 任意 3 个地点
- 尝试次数：最多 10 次 Argon2id

**方法二：完全记忆恢复**
- 需要：个人标识 + 全部 5 个地点 + 方位码
- 无需备份文件，纯粹依赖记忆

---

## 3. 文本标准化

### 3.1 标准化流程

所有用户输入文本必须经过标准化处理，确保不同输入方式产生一致结果：

```
Normalize(s) = AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))
```

**处理步骤：**

| 步骤 | 函数 | 说明 | 示例 |
|------|------|------|------|
| 1 | NFKC | Unicode 兼容性标准化 | `Ｈｅｌｌｏ` → `Hello` |
| 2 | CaseFold | 大小写折叠 | `Hello` → `hello` |
| 3 | Trim | 移除首尾空白 | `  hello  ` → `hello` |
| 4 | CollapseWS | 折叠连续空白为单个空格 | `hello   world` → `hello world` |
| 5 | AsciiPunctNorm | 中日韩标点转 ASCII | `，。！` → `,.!` |

### 3.2 标点映射表

```
中文/全角标点 ──→ ASCII 标点
  ，  ──→  ,    （逗号）
  。  ──→  .    （句号）
  ！  ──→  !    （感叹号）
  ？  ──→  ?    （问号）
  ：  ──→  :    （冒号）
  ；  ──→  ;    （分号）
  （）──→  ()   （括号）
  【】──→  []   （方括号）
  「」──→  ''   （引号）
  『』──→  ""   （双引号）
  ——  ──→  -    （破折号）
  …   ──→  ...  （省略号）
```

---

## 4. 数据结构

### 4.1 地点记录 (Spot)

每个地点包含三个组成部分：

```
Spot = {
  place:       WujiPlace,    // 地理坐标
  memory1Tags: [String],   // 第一组记忆关键词标签（1-3个，推荐1个高度个性化关键词）
  memory2Tags: [String]    // 第二组记忆关键词标签（1-3个，推荐1个高度个性化关键词）
}
```

**记忆标签处理：**
- 每个地点有两个记忆输入区域，每个区域需要 1-3 个关键词标签
- 推荐：每个记忆区域使用 1 个高度个性化的关键词，以获得最强安全性
- 最少：每个记忆区域 1 个标签（每个地点共 2 个标签）
- 最多：每个记忆区域 3 个标签（每个地点共 6 个标签）
- 每个标签单独进行标准化处理（NFKC → CaseFold → Trim → AsciiPunctNorm）
- 在每个记忆区域内：标签经过去重、按 Unicode 字典序排序后，无分隔符直接拼接

### 4.2 地点编码

**目的：** 将地点信息转换为固定格式的二进制数据，用于密钥派生。

```
┌─────────────────────────────────────────────────────────────────┐
│  keyMaterial = sortedProcessedMemory1(UTF-8) +                  │
│                sortedProcessedMemory2(UTF-8) +                  │
│                cellIndex(8字节大端序)                            │
└─────────────────────────────────────────────────────────────────┘
```

**编码规则：**

1. **标签标准化**：每个标签进行 (NFKC → CaseFold → Trim → AsciiPunctNorm) 处理
2. **标签去重**：在每个记忆区域内移除重复标签
3. **标签排序**：在每个记忆区域内按 Unicode 字典序排列
4. **拼接**：将排序后的标签无分隔符直接拼接，形成处理后的记忆字符串
5. **记忆排序**：两个处理后的记忆字符串按 Unicode 字典序排列（小的在前）
6. **单元格索引**：F9Grid 返回的 Int64，转为 8 字节大端序

**示例：**
```
输入:
  memory1Tags = ["2020年", "初次旅行", "日落"]
  memory2Tags = ["东京", "樱花", "春天"]
  coordinates = (35.6762, 139.6503)

每个记忆区域内标准化并排序:
  memory1: "2020年", "初次旅行", "日落" → "2020年初次旅行日落"
  memory2: "东京", "春天", "樱花" → "东京春天樱花"

两个记忆之间排序 (Unicode字典序):
  sorted1 = "2020年初次旅行日落"  // '2' < '东'
  sorted2 = "东京春天樱花"

编码:
  keyMaterial = UTF8("2020年初次旅行日落") +
                UTF8("东京春天樱花") +
                BE64(cellIndex)
```

### 4.3 方位码 (Position Code)

F9Grid 将每个单元格划分为 9 个子区域，用 1-9 编码：

```
┌───┬───┬───┐
│ 4 │ 9 │ 2 │   NW  N  NE
├───┼───┼───┤
│ 3 │ 5 │ 7 │   W   C  E
├───┼───┼───┤
│ 8 │ 1 │ 6 │   SW  S  SE
└───┴───┴───┘
```

**用途：** GPS 漂移可能导致坐标落入相邻单元格。方位码允许在恢复时找回原始单元格。

---

## 5. 密码学原语

### 5.1 BLAKE2b-128

**用途：** 从个人标识生成 Argon2id 盐值

```
salt = BLAKE2b-128(UTF8(Normalize(identifier)) + UTF8("WUJI-Key-V1:Memory-Based Seed Phrases"))
```

- 输出：16 字节（128 位）
- 添加版本后缀确保协议升级时盐值变化

### 5.2 Argon2id

**用途：** 内存硬化的密钥派生，防止暴力破解

**参数配置：**

| 参数 | 值 | 说明 |
|------|-----|------|
| 内存 | 256 MB | 阻止 GPU/ASIC 并行攻击 |
| 迭代 | 7 | 增加计算时间 |
| 并行度 | 1 | 单线程执行 |
| 输出 | 32 字节 | 256 位密钥/熵值 |
| 版本 | 1.3 (0x13) | Argon2id 标准版本 |

**安全分析：**

```
单次 Argon2id 耗时: ~3-5 秒（移动设备）
暴力破解成本:
  - 假设攻击者猜测地点组合
  - 每次尝试需 256MB 内存 + 3-5秒时间
  - 10亿次尝试 ≈ 95年 × 256GB 内存
```

### 5.3 XChaCha20-Poly1305

**用途：** 加密备份中的助记词数据

| 参数 | 长度 | 说明 |
|------|------|------|
| 密钥 | 32 字节 | Argon2id 派生 |
| 随机数 | 24 字节 | 自动生成，消除复用风险 |
| 认证标签 | 16 字节 | 防篡改验证 |

### 5.4 SHA-256

**用途：** BIP39 校验和计算

```
checksum = SHA-256(entropy)[0:8]  // 取前 8 位
```

---

## 6. 助记词生成

### 6.1 盐值派生

```
输入: identifier (个人标识字符串)
输出: salt (16 字节)

1. normalized ← Normalize(identifier)
2. input ← UTF8(normalized) + UTF8("WUJI-Key-V1:Memory-Based Seed Phrases")
3. salt ← BLAKE2b-128(input)
```

### 6.2 地点处理

```
输入: spots[5] (5个地点记录)
输出: keyMaterials[5], positionCodes[5]

对于每个 spot[i]:
  1. keyMaterial[i] ← spot[i].keyMaterial()
  2. positionCode[i] ← spot[i].positionCode()

按 keyMaterial 字节序排序:
  (keyMaterials, positionCodes) ← sort_together_by_keyMaterial()
```

### 6.3 熵值派生

```
输入: keyMaterials[5], salt (16 字节)
输出: entropy (32 字节)

1. password ← keyMaterials[0] ‖ keyMaterials[1] ‖ ... ‖ keyMaterials[4]
2. entropy ← Argon2id(password, salt, 256MB, 7次)
```

### 6.4 BIP39 编码

```
输入: entropy (32 字节 = 256 位)
输出: words[24]

1. bits ← 熵值的二进制表示 (256位)

2. 生成前 23 个单词:
   for i = 0 to 22:
     index ← bits[11i : 11(i+1)]  // 每 11 位
     words[i] ← BIP39_WORDLIST[index]

3. 生成第 24 个单词:
   remaining ← bits[253:256]           // 剩余 3 位
   checksum ← SHA-256(entropy)[0:8]    // 前 8 位
   index ← remaining ‖ checksum        // 共 11 位
   words[23] ← BIP39_WORDLIST[index]
```

### 6.5 完整算法

```
┌────────────────────────────────────────────────────────────────────────┐
│  GenerateMnemonic(identifier, spots[5])                                │
├────────────────────────────────────────────────────────────────────────┤
│  1. salt ← DeriveSalt(identifier)                   // 16 字节        │
│  2. (keyMaterials, positionCodes) ← ProcessSpots(spots)               │
│  3. entropy ← Argon2id(concat(keyMaterials), salt)  // 32 字节        │
│  4. words ← BIP39Encode(entropy)                    // 24 个单词      │
│  5. return (words, positionCodes)                                      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 7. 加密备份 (3-of-5 门限方案)

### 7.1 设计原理

为实现"仅需 3 个地点即可恢复"，协议生成 C(5,3)=10 个独立加密块。每个块使用不同的 3 地点组合派生的密钥加密。加密后组合顺序随机打乱，无法从索引推断原始组合。

### 7.2 明文格式

```
┌──────────────────────────────────────────┐
│  助记词数据 (33 字节)                     │
│  24 个单词 × 11 位 = 264 位 = 33 字节    │
├──────────────────────────────────────────┤
│  随机填充 (16 字节)                       │
│  每个块使用不同的随机填充                  │
└──────────────────────────────────────────┘
总计: 49 字节明文
```

### 7.3 AAD 构造

关联数据 (AAD) 用于 AEAD 认证：

```
AAD = Magic(4) + Version(1) + Options(1) + PositionCodes(3)

其中:
  Magic   = [0x57, 0x55, 0x4A, 0x49]  // "WUJI" (ASCII)
  Version = 0x01
  Options = 0x00 (保留)
  PositionCodes = 5个方位码压缩为3字节
```

### 7.4 加密算法

```
┌────────────────────────────────────────────────────────────────────────┐
│  Encrypt(words[24], keyMaterials[5], positionCodes[5], salt)          │
├────────────────────────────────────────────────────────────────────────┤
│  1. mnemonicData ← WordsToBytes(words)          // 33 字节            │
│  2. sortedKM ← sort(keyMaterials)               // 按字节序排序       │
│  3. AAD ← BuildAAD(positionCodes)               // 9 字节             │
│                                                                        │
│  4. 对于每个组合 {a, b, c} ∈ C(5,3):                                  │
│       password ← sortedKM[a] ‖ sortedKM[b] ‖ sortedKM[c]             │
│       key ← Argon2id(password, salt)            // 32 字节            │
│       padding ← RandomBytes(16)                                        │
│       plaintext ← mnemonicData ‖ padding        // 49 字节            │
│       (ciphertext, tag, nonce) ← XChaCha20Poly1305.Encrypt(           │
│                                    plaintext, key, AAD)               │
│       blocks[j] ← {nonce, ciphertext, tag}                            │
│                                                                        │
│  5. shuffledBlocks ← DeterministicShuffle(blocks, sortedKM)           │
│  6. return Serialize(positionCodes, shuffledBlocks)                    │
└────────────────────────────────────────────────────────────────────────┘
```

### 7.5 确定性打乱

加密块经过确定性打乱，隐藏组合与块的对应关系：

```
seed ← BLAKE2b-256(KM[0] ‖ "|" ‖ KM[1] ‖ ... ‖ "|block-shuffle-seed")
shuffled ← FisherYates(blocks, seed)
```

---

## 8. 恢复算法

### 8.1 方法一：加密备份恢复

**适用场景：** 用户有加密备份文件，但只记得 3-5 个地点

```
┌────────────────────────────────────────────────────────────────────────┐
│  DecryptWithRecovery(backup, spots[N], allPositionCodes[5], salt)     │
│  其中 3 ≤ N ≤ 5                                                        │
├────────────────────────────────────────────────────────────────────────┤
│  1. spotCombos ← C(N, 3)              // N个地点选3个的组合           │
│  2. posCodeCombos ← C(5, 3) = 10      // 5个方位码选3个的组合         │
│                                                                        │
│  3. 对于每个 spotCombo:                                                │
│       对于每个 posCodeCombo:                                           │
│         selectedSpots ← spots[spotCombo]                               │
│         selectedCodes ← allPositionCodes[posCodeCombo]                 │
│         keyMaterials ← ProcessSpots(selectedSpots, selectedCodes)      │
│         password ← concat(sort(keyMaterials))                          │
│         key ← Argon2id(password, salt)                                 │
│                                                                        │
│         对于每个加密块:                                                 │
│           plaintext ← TryDecrypt(block, key, AAD)                      │
│           if 成功 && ValidChecksum(plaintext):                         │
│             return BytesToWords(plaintext)                             │
│                                                                        │
│  4. return 失败                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Argon2id 尝试次数：**

| 已知地点数 | 尝试次数 |
|-----------|---------|
| 3 | 1 × 10 = 10 |
| 4 | 4 × 10 = 40 |
| 5 | 10 × 10 = 100 |

**优化：** 使用密码缓存去重，避免重复 Argon2id 计算。

### 8.2 方法二：完全记忆恢复

**适用场景：** 用户没有备份文件，但完整记得所有 5 个地点

```
直接调用 GenerateMnemonic(identifier, spots[5])
```

此方法需要方位码来修正可能的 GPS 漂移。

---

## 9. 二进制格式

### 9.1 整体结构

```
┌─────────┬─────────┬─────────┬────────────────┬───────────────┬─────────┬────────────────┬─────────┐
│ Magic   │ Version │ Options │ PayloadLength  │ PositionCodes │ Count   │ Blocks[10]     │ CRC32   │
│ 4 字节  │ 1 字节  │ 1 字节  │ 2 字节 (BE)    │ 3 字节        │ 1 字节  │ 可变长度       │ 4 字节  │
└─────────┴─────────┴─────────┴────────────────┴───────────────┴─────────┴────────────────┴─────────┘
```

### 9.2 块结构

```
┌─────────────────┬─────────────┬──────────────────────┬─────────────┐
│ BlockLength     │ Nonce       │ Ciphertext           │ Tag         │
│ 2 字节 (BE)     │ 24 字节     │ 49 字节              │ 16 字节     │
└─────────────────┴─────────────┴──────────────────────┴─────────────┘
每块总长: 2 + 24 + 49 + 16 = 91 字节
```

### 9.3 方位码编码

```
5 个方位码 (P₀...P₄)，每个 1-9，压缩为 3 字节:

  字节 0 = (P₀ << 4) | P₁
  字节 1 = (P₂ << 4) | P₃
  字节 2 = (P₄ << 4) | 0
```

### 9.4 典型文件大小

```
头部:           8 字节
方位码:         3 字节
块数量:         1 字节
10 个块:        91 × 10 = 910 字节
CRC32:          4 字节
─────────────────────────────
总计:           926 字节
```

---

## 10. 安全性分析

### 10.1 威胁模型

| 威胁 | 防护措施 |
|------|----------|
| 暴力破解盐值 | BLAKE2b 128位输出，2^128 组合 |
| 暴力破解密钥 | Argon2id 256MB，阻止并行攻击 |
| 备份文件泄露 | 需要 3 个地点才能解密 |
| GPS 漂移 | 方位码修正机制 |
| 侧信道攻击 | 本地设备安全边界外，需用户自行保护 |

### 10.2 安全假设

1. **用户设备安全**：攻击者无法访问用户设备内存
2. **地点保密**：至少 3 个地点对攻击者未知
3. **密码学原语安全**：BLAKE2b、Argon2id、XChaCha20-Poly1305 无已知漏洞

### 10.3 最佳实践

- 选择**独特且私密**的地点（不要选择公开的热门景点）
- 记忆文本应包含**个人化细节**（日期、感受、细节描述）
- **离线使用**：生成助记词时开启飞行模式
- **备份分离**：加密备份与地点提示分开存储

---

## 附录 A: F9Grid 接口

F9Grid 是独立的地理编码系统，提供以下接口：

| 函数 | 输入 | 输出 | 描述 |
|------|------|------|------|
| `CellIndex` | (lat, lng) | Int64 | 层级单元格唯一标识符 |
| `PositionCode` | (lat, lng) | 1-9 | 单元格内 9 宫格位置 |
| `FindOriginalCell` | (lat, lng, code) | Int64 | 使用方位码修正 GPS 漂移 |

---

## 附录 B: 实现检查清单

- [ ] 所有整数使用大端字节序
- [ ] 所有字符串使用 UTF-8 编码
- [ ] 排序使用字节字典序比较
- [ ] 随机数使用 CSPRNG 生成
- [ ] Argon2id 使用版本 1.3 (0x13)
- [ ] 标准化流程严格按顺序执行
- [ ] 助记词验证包括 BIP39 校验和检查

---

## 附录 C: 测试向量

### C.1 文本标准化

```
输入:  "  ＨＥＬＬＯ　　ＷＯＲＬＤ！  "
输出: "hello world!"

步骤:
  NFKC:       "  HELLO  WORLD!  "
  CaseFold:   "  hello  world!  "
  Trim:       "hello  world!"
  CollapseWS: "hello world!"
  AsciiPunct: "hello world!"
```

### C.2 盐值生成

```
输入:
  identifier = "test@example.com"

计算:
  normalized = "test@example.com"
  input = "test@example.comWUJI-Key-V1:Memory-Based Seed Phrases"
  salt = BLAKE2b-128(UTF8(input))
       = [16 字节盐值]
```

### C.3 BIP39 索引

```
单词 "abandon" → 索引 0    → 二进制 "00000000000"
单词 "zoo"     → 索引 2047 → 二进制 "11111111111"

24 个单词 × 11 位 = 264 位 = 33 字节
```

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0 | 2026-01 | 初始规范 |

---

## 参考资料

- [BIP39: 生成确定性密钥的助记词规范](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [Argon2: 密码哈希函数](https://datatracker.ietf.org/doc/html/rfc9106)
- [BLAKE2: 安全哈希函数](https://www.blake2.net/)
- [XChaCha20-Poly1305](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-xchacha)
