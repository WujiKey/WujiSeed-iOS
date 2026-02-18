# V1 稳定性审计规范

## 核心算法稳定性基准

### 文本归一化
确保 NFKC → CaseFold → Trim → CollapseWS → AsciiPunctNorm 流程在所有版本中产生一致输出。黄金向量必须验证通过。

### BLAKE2b-128 盐生成
确保 BLAKE2b-128(Normalize(name) + "WUJI-Key-V1:Memory-Based Seed Phrases") 产生完全一致的 16 字节盐值。

### F9Grid 地理编码
确保 F9Grid 单元格索引 + 9 宫格位置代码（1-9 布局）在所有版本中对相同坐标产生一致结果。必须正确处理南半球和西半球的负坐标。

### 记忆标签处理
确保归一化 → 去重 → Unicode 排序 → 拼接流程产生一致结果。黄金向量的 `memoryProcessed` 字段必须匹配。

### Argon2id 密钥派生
确保使用标准参数（256MB/7 iterations/1 parallelism）对相同输入产生完全一致的 32 字节密钥。黄金向量的 `keyDataHex` 必须匹配。

### BIP39 助记词生成
确保 256 位熵生成完全一致的 24 个 BIP39 单词。必须严格遵循 BIP39 标准（前 253 位 + 3 位填充 + 8 位校验和）。

### XChaCha20-Poly1305 加密
确保记忆容错机制（10 个独立加密块）对相同输入产生确定性输出。黄金向量的 `encryptedBackupBase64` 必须匹配。

## 测试框架要求

### 黄金向量回归测试
- CI/CD 必须强制执行 wujikey_v1_vector_1.json 和 wujikey_v1_vector_2.json 的完整验证
- 验证所有中间状态：normalizedName、nameSaltHex、memoryProcessed、positionCode、keyDataHex、mnemonics、encryptedBackupBase64
- 任何测试失败必须阻止代码合并

### 单元测试覆盖
- WujiNormalizer.swift - 文本归一化
- CryptoUtils.swift - BLAKE2b、Argon2id、XChaCha20-Poly1305
- WujiMemoryTagProcessor.swift - 记忆标签处理
- BIP39Helper.swift - 助记词生成
- 包含边界情况测试（空字符串、极长输入、特殊字符、极端坐标）

### 依赖库版本锁定
- Swift-Sodium 必须锁定为 0.9.1
- F9Grid 必须锁定为 1.1.0
- 升级前必须通过完整的黄金向量测试验证

### 跨平台兼容性
- 黄金向量 JSON 文件必须作为所有平台（iOS、Android、JavaScript）的验证标准
- 跨平台实现指南必须文档化 Unicode 排序规则、字节序、负坐标处理等关键细节

## 加密备份验证

### 记忆容错机制完整性
- 验证所有 10 个 3-location 组合的加密块存在：{0,1,2}, {0,1,3}, {0,1,4}, {0,2,3}, {0,2,4}, {0,3,4}, {1,2,3}, {1,2,4}, {1,3,4}, {2,3,4}
- 每个块使用不同的 Argon2id 密钥派生（从对应的 3 个 keyMaterials + nameSalt）
- 破解任何一个块都能恢复完整助记词（49 字节明文：33 字节助记词 + 16 字节确定性填充）

### 恢复流程验证
- 使用黄金向量的 encryptedBackupBase64 和任意 3 个 locations 必须能恢复出完全相同的 24 个助记词
- 所有 10 种 3-location 组合都必须恢复出相同结果
- 使用错误的 location 数据必须导致解密失败（认证失败）

### 加密参数验证
- Nonce 必须是 24 字节且从组合的 keyMaterials 确定性派生
- 密钥必须从 3 个 keyMaterials + nameSalt 通过 Argon2id 派生（32 字节）
- 使用 XChaCha20-Poly1305 认证加密（AEAD），防止数据被篡改
- 确定性洗牌（DeterministicShuffle）必须对相同输入产生相同的块顺序

### 二进制格式稳定性
- 加密备份必须包含正确的格式头部（"WUJI" 魔术字节 + 版本号）
- 二进制格式必须在所有版本中保持稳定，支持向后兼容解密
- 跨平台传输必须正确处理 Base64 编码和解码
