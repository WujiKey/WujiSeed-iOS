## ADDED Requirements

### Requirement: 加密备份确定性验证

系统必须确保加密备份生成算法在所有版本中对相同的输入产生完全确定性的输出。

#### Scenario: 相同输入产生相同加密备份
- **WHEN** 使用相同的 24 个助记词、5 个 keyMaterials、5 个 positionCodes 和 nameSalt
- **THEN** 所有版本必须产生字节级完全相同的加密备份数据

#### Scenario: 黄金向量加密验证
- **WHEN** 使用黄金向量中的参数生成加密备份
- **THEN** 结果必须与 `encryptedBackupBase64` 字段完全匹配

#### Scenario: 随机性消除验证
- **WHEN** 生成加密备份
- **THEN** 必须确保所有随机性来源（nonce、key derivation）是确定性的

### Requirement: 记忆容错机制完整性验证

系统必须验证记忆容错机制的正确性：从 5 个地点中任选 3 个组合，生成 10 个独立的加密块，每个块都用不同的 3-location 组合对同一份助记词进行加密。

#### Scenario: 10 个独立加密块验证
- **WHEN** 生成加密备份
- **THEN** 必须包含所有 10 个 3-location 组合的加密块（{0,1,2}, {0,1,3}, {0,1,4}, {0,2,3}, {0,2,4}, {0,3,4}, {1,2,3}, {1,2,4}, {1,3,4}, {2,3,4}）

#### Scenario: 加密块独立性验证
- **WHEN** 检查每个加密块
- **THEN** 每个块必须使用不同的 3-location 组合独立加密同一份助记词，破解任何一个块都能获得完整助记词

#### Scenario: 确定性洗牌验证
- **WHEN** 生成加密备份
- **THEN** 加密块的顺序必须经过确定性洗牌（DeterministicShuffle），相同输入产生相同顺序

### Requirement: XChaCha20-Poly1305 加密参数验证

系统必须验证 XChaCha20-Poly1305 加密算法的所有参数（nonce、key、plaintext）的正确性。

#### Scenario: Nonce 生成验证
- **WHEN** 为每个 3-location 组合生成 nonce
- **THEN** nonce 必须是 24 字节且从组合的 keyMaterials 确定性派生

#### Scenario: 密钥派生验证
- **WHEN** 为每个 3-location 组合派生加密密钥
- **THEN** 密钥必须从组合的 3 个 keyMaterials + nameSalt 通过 Argon2id 派生

#### Scenario: Plaintext 格式验证
- **WHEN** 准备待加密的明文
- **THEN** 明文必须包含 49 字节（33 字节助记词数据 + 16 字节确定性填充）

### Requirement: 加密备份格式稳定性

系统必须确保加密备份的二进制格式在所有版本中保持稳定，支持向后兼容解密。

#### Scenario: 格式头部验证
- **WHEN** 读取加密备份数据
- **THEN** 必须包含正确的格式头部（"WUJI" 魔术字节 + 版本号）

#### Scenario: 格式版本兼容性
- **WHEN** 遇到不同版本的加密备份格式
- **THEN** 必须能够识别版本并使用相应的解密算法

#### Scenario: 二进制格式文档化
- **WHEN** 查阅技术规范
- **THEN** 必须包含完整的加密备份二进制格式文档

### Requirement: 恢复流程端到端验证

系统必须验证从加密备份恢复助记词的完整流程，确保所有步骤正确执行。

#### Scenario: 黄金向量恢复验证
- **WHEN** 使用黄金向量中的 `encryptedBackupBase64` 和任意 3 个 locations 恢复
- **THEN** 必须恢复出与 `mnemonics` 字段完全相同的 24 个助记词

#### Scenario: 所有 10 种组合恢复验证
- **WHEN** 依次使用所有 10 种 3-location 组合恢复
- **THEN** 每种组合都必须恢复出相同的助记词

#### Scenario: 错误 location 数据验证
- **WHEN** 使用错误的 location 数据（错误的 keyMaterial 或 positionCode）尝试恢复
- **THEN** 解密必须失败（认证失败）

### Requirement: 恢复错误处理验证

系统必须正确处理恢复过程中的各种错误情况，并提供清晰的错误消息。

#### Scenario: 数据损坏检测
- **WHEN** 加密备份数据被损坏（部分字节修改）
- **THEN** 解密时必须检测到认证失败并报告错误

#### Scenario: 格式错误检测
- **WHEN** 加密备份格式不正确（魔术字节错误、版本不支持）
- **THEN** 必须报告格式错误并拒绝解密

#### Scenario: 密钥不匹配检测
- **WHEN** 使用错误的 location 组合或参数
- **THEN** 必须报告密钥派生或解密失败

### Requirement: 性能稳定性验证

系统必须验证加密和恢复操作的性能稳定性，确保在合理时间内完成。

#### Scenario: 加密性能验证
- **WHEN** 生成包含 10 个组合的完整加密备份
- **THEN** 操作必须在可接受的时间内完成（受 Argon2id 参数限制）

#### Scenario: 恢复性能验证
- **WHEN** 从加密备份恢复助记词
- **THEN** 操作必须在可接受的时间内完成（单次 Argon2id 派生 + 解密）

#### Scenario: 性能退化检测
- **WHEN** 在不同版本间对比性能
- **THEN** 性能退化必须控制在可接受范围内

### Requirement: 跨平台恢复兼容性

系统必须确保在一个平台上生成的加密备份能够在其他平台上成功恢复。

#### Scenario: iOS 到 Android 恢复
- **WHEN** 在 iOS 上生成加密备份，在 Android 上恢复
- **THEN** 必须恢复出相同的助记词

#### Scenario: iOS 到 JavaScript 恢复
- **WHEN** 在 iOS 上生成加密备份，在 JavaScript 实现中恢复
- **THEN** 必须恢复出相同的助记词

#### Scenario: 跨平台格式兼容性
- **WHEN** 在不同平台间传输加密备份
- **THEN** Base64 编码和解码必须处理正确

### Requirement: 安全性审计验证

系统必须审计加密备份机制的安全性，确保符合密码学最佳实践。

#### Scenario: 认证加密验证
- **WHEN** 使用 XChaCha20-Poly1305
- **THEN** 必须提供认证加密（AEAD），防止数据被篡改

#### Scenario: 密钥派生安全性验证
- **WHEN** 派生加密密钥
- **THEN** 必须使用 Argon2id（内存困难型 KDF），防止暴力破解

#### Scenario: Nonce 唯一性验证
- **WHEN** 为每个组合生成 nonce
- **THEN** 所有 nonce 必须唯一且不可预测（从 keyMaterials 确定性派生但互不相同）
