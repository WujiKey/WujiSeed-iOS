## 为什么 (Why)

WujiSeed-Protocol V1 版本已投入生产使用，用户已经基于当前实现生成了助记词和加密备份。在未来版本升级过程中，必须确保向后兼容性：相同的输入参数必须始终生成完全相同的助记词，已有的加密备份必须能够成功恢复。需要建立完整的稳定性审计机制和回归测试保障体系，防止代码重构或算法优化破坏兼容性。

## 要改变什么 (What Changes)

- 建立 V1 版本核心算法的稳定性基准（文本归一化、BLAKE2b-128 盐生成、F9Grid 编码、Argon2id 密钥派生、BIP39 生成、XChaCha20-Poly1305 加密）
- 审计现有两个黄金测试向量（Journey to the West、Moses Exodus）的覆盖完整性
- 验证所有关键数据转换路径的确定性和可重现性
- 识别可能影响向后兼容性的潜在风险点（依赖库升级、平台差异、算法实现变更）
- 制定防御性编码规范和测试要求，确保未来修改不破坏 V1 兼容性
- 建立跨平台兼容性验证机制（iOS、Android、JavaScript 等）

## 能力范围 (Capabilities)

### 新增能力 (New Capabilities)

- `v1-stability-baseline`: 建立 V1 版本核心算法的稳定性基准和验证规范
- `compatibility-testing`: 完整的向后兼容性测试框架和黄金向量验证机制
- `encryption-recovery-audit`: 加密备份生成和恢复的端到端审计验证

### 修改的能力 (Modified Capabilities)

*（暂无需要修改现有规范的能力，此次变更专注于审计和验证）*

## 影响范围 (Impact)

**受影响的代码模块：**
- `WujiLib/WujiNormalizer.swift`: 文本归一化算法（AsciiPunctNorm、CollapseWS、Trim、CaseFold、NFKC）
- `WujiLib/CryptoUtils.swift`: BLAKE2b-128 盐生成、Argon2id 密钥派生、XChaCha20-Poly1305 加密
- `WujiLib/WujiMemoryTagProcessor.swift`: 记忆标签处理器（归一化、去重、Unicode 排序、拼接）
- `Common/BIP39Helper.swift`: BIP39 助记词生成（256 位熵 → 24 个单词）
- `WujiSeedTests/GoldenVectors/`: 黄金测试向量（wujikey_v1_vector_1.json、wujikey_v1_vector_2.json）
- `WujiSeedTests/WujiRegressionTests.swift`: 回归测试套件

**依赖项：**
- Swift-Sodium 0.9.1（Libsodium 加密库绑定）
- F9Grid 1.1.0（地理网格编码库）

**系统级影响：**
- 测试框架需要确保覆盖所有关键数据转换路径
- 文档需要明确标注 V1 版本的稳定性保证和兼容性承诺
- 代码审查流程需要增加向后兼容性检查清单
- CI/CD 流程需要强制执行黄金向量回归测试
