## ADDED Requirements

### Requirement: 文本归一化稳定性基准

系统必须确保文本归一化算法（NFKC → CaseFold → Trim → CollapseWS → AsciiPunctNorm）在所有版本中产生完全一致的输出结果。

#### Scenario: 相同输入产生相同归一化结果
- **WHEN** 对相同的用户标识符字符串执行归一化
- **THEN** 所有版本必须产生字节级完全相同的归一化结果

#### Scenario: 黄金向量验证文本归一化
- **WHEN** 使用黄金向量中的 `name` 字段进行归一化
- **THEN** 结果必须与 `normalizedName` 字段完全匹配

#### Scenario: Unicode 边界情况稳定性
- **WHEN** 输入包含复杂 Unicode 字符（组合字符、全角标点、异体字）
- **THEN** 归一化结果必须可预测且可重现

### Requirement: BLAKE2b-128 盐生成稳定性基准

系统必须确保 BLAKE2b-128 盐生成算法在所有版本中对相同的归一化标识符产生完全一致的 16 字节盐值。

#### Scenario: 相同归一化名称产生相同盐值
- **WHEN** 对相同的归一化标识符执行 BLAKE2b-128(Normalize(name) + "WUJI-Key-V1:Memory-Based Seed Phrases")
- **THEN** 所有版本必须产生完全相同的 16 字节盐值

#### Scenario: 黄金向量验证盐生成
- **WHEN** 使用黄金向量中的 `normalizedName` 字段生成盐
- **THEN** 结果必须与 `nameSaltHex` 字段完全匹配

### Requirement: F9Grid 地理编码稳定性基准

系统必须确保 F9Grid 地理编码算法（单元格索引 + 9 宫格位置代码）在所有版本中对相同的经纬度坐标产生完全一致的编码结果。

#### Scenario: 相同坐标产生相同编码
- **WHEN** 对相同的经纬度坐标执行 F9Grid 编码
- **THEN** 所有版本必须产生完全相同的单元格索引（8 字节大端）和位置代码（1-9）

#### Scenario: 黄金向量验证地理编码
- **WHEN** 使用黄金向量中的 `locations[].coordinate` 字段进行编码
- **THEN** 结果必须与 `locations[].positionCode` 字段完全匹配

#### Scenario: 跨半球坐标稳定性
- **WHEN** 输入包含南半球（负纬度）或西半球（负经度）坐标
- **THEN** F9Grid 编码必须正确处理负坐标并产生可重现的结果

### Requirement: 记忆标签处理稳定性基准

系统必须确保记忆标签处理器（归一化 → 去重 → Unicode 排序 → 拼接）在所有版本中对相同的输入标签产生完全一致的处理结果。

#### Scenario: 相同标签产生相同处理结果
- **WHEN** 对相同的记忆标签数组执行归一化、去重、Unicode 排序和拼接
- **THEN** 所有版本必须产生字节级完全相同的处理结果

#### Scenario: 黄金向量验证记忆处理
- **WHEN** 使用黄金向量中的 `locations[].memory1Tags` 和 `memory2Tags` 字段
- **THEN** 处理结果必须与 `locations[].memoryProcessed` 字段完全匹配

#### Scenario: Unicode 排序稳定性
- **WHEN** 输入包含多语言标签（中文、日文、英文混合）
- **THEN** Unicode 排序必须在所有版本和平台上产生一致的顺序

### Requirement: Argon2id 密钥派生稳定性基准

系统必须确保 Argon2id 密钥派生算法在所有版本中对相同的输入参数产生完全一致的 32 字节密钥输出。

#### Scenario: 相同输入产生相同密钥
- **WHEN** 使用相同的密码（keyMaterial）、盐（nameSalt）和参数（memory/iterations/parallelism）
- **THEN** 所有版本必须产生完全相同的 32 字节密钥

#### Scenario: 黄金向量验证密钥派生
- **WHEN** 使用黄金向量中的参数执行 Argon2id
- **THEN** 结果必须与 `keyDataHex` 字段完全匹配

#### Scenario: 参数稳定性保证
- **WHEN** 使用生产环境参数（256MB/7 iterations/1 parallelism）
- **THEN** 所有版本必须使用完全相同的参数值和算法实现

### Requirement: BIP39 助记词生成稳定性基准

系统必须确保 BIP39 助记词生成算法在所有版本中对相同的 256 位熵产生完全一致的 24 个助记词。

#### Scenario: 相同熵产生相同助记词
- **WHEN** 对相同的 32 字节密钥（256 位熵）执行 BIP39 编码
- **THEN** 所有版本必须产生完全相同的 24 个单词

#### Scenario: 黄金向量验证助记词生成
- **WHEN** 使用黄金向量中的 `keyDataHex` 字段生成助记词
- **THEN** 结果必须与 `mnemonics` 字段的 24 个单词完全匹配

#### Scenario: BIP39 标准合规性
- **WHEN** 执行 BIP39 助记词生成
- **THEN** 必须严格遵循 BIP39 标准（前 253 位 + 3 位填充 + 8 位校验和）

### Requirement: XChaCha20-Poly1305 加密稳定性基准

系统必须确保 XChaCha20-Poly1305 加密算法在所有版本中对相同的输入产生完全一致的加密备份。

#### Scenario: 相同输入产生相同加密备份
- **WHEN** 使用相同的助记词、keyMaterials、positionCodes 和 salt 生成加密备份
- **THEN** 所有版本必须产生完全相同的加密备份数据

#### Scenario: 黄金向量验证加密备份
- **WHEN** 使用黄金向量中的参数生成加密备份
- **THEN** 结果必须与 `encryptedBackupBase64` 字段完全匹配

#### Scenario: 10 种组合的确定性
- **WHEN** 生成 10 个独立的加密块（对应 C(5,3)=10 种 3-location 组合）
- **THEN** 每个组合必须产生可重现的确定性结果

### Requirement: 依赖库版本锁定

系统必须明确锁定所有加密相关依赖库的版本，防止依赖升级破坏向后兼容性。

#### Scenario: Swift-Sodium 版本锁定
- **WHEN** 构建或更新项目
- **THEN** 必须使用精确的 Swift-Sodium 0.9.1 版本

#### Scenario: F9Grid 版本锁定
- **WHEN** 构建或更新项目
- **THEN** 必须使用精确的 F9Grid 1.1.0 版本

#### Scenario: 依赖升级影响评估
- **WHEN** 需要升级依赖库
- **THEN** 必须先通过完整的黄金向量测试验证不影响输出

### Requirement: 稳定性基准文档化

系统必须维护完整的 V1 版本稳定性基准文档，明确标注所有关键算法的规范和兼容性保证。

#### Scenario: 算法规范文档化
- **WHEN** 查阅技术规范文档
- **THEN** 必须包含所有关键算法的详细描述和示例

#### Scenario: 兼容性承诺文档化
- **WHEN** 查阅版本兼容性文档
- **THEN** 必须明确标注 V1 版本的稳定性保证和向后兼容策略

#### Scenario: 黄金向量维护文档化
- **WHEN** 查阅黄金向量文档
- **THEN** 必须包含向量生成方法、验证清单和跨平台实现指南
