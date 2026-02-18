# V1 稳定性审计 - 任务清单

## 1. 验证核心算法与黄金向量一致性

- [x] 1.1 运行现有回归测试，确认 wujikey_v1_vector_1.json 和 wujikey_v1_vector_2.json 完全通过
- [x] 1.2 审计 WujiNormalizer.swift 的 NFKC → CaseFold → Trim → CollapseWS → AsciiPunctNorm 流程
- [x] 1.3 验证 BLAKE2b-128 盐生成使用正确的后缀 "WUJI-Key-V1:Memory-Based Seed Phrases"
- [x] 1.4 检查 F9Grid 地理编码对负坐标（南半球、西半球）的处理
- [x] 1.5 审计 WujiMemoryTagProcessor.swift 的 Unicode 码点排序实现
- [x] 1.6 验证 Argon2id 标准参数（256MB/7 iterations/1 parallelism）
- [x] 1.7 检查 BIP39Helper.swift 严格遵循 BIP39 标准（253 位 + 3 位填充 + 8 位校验和）
- [x] 1.8 验证 XChaCha20-Poly1305 记忆容错机制的 10 个独立加密块生成

## 2. 补充单元测试

- [x] 2.1 WujiNormalizer.swift - 添加边界情况测试（空字符串、极长输入、复杂 Unicode）
- [x] 2.2 CryptoUtils.swift - 添加 BLAKE2b-128 盐生成的单元测试
- [x] 2.3 WujiMemoryTagProcessor.swift - 添加多语言混合标签的排序测试
- [x] 2.4 BIP39Helper.swift - 添加熵值边界情况测试
- [x] 2.5 F9Grid 集成 - 添加极端坐标测试（极地、国际日期变更线附近）
- [x] 2.6 XChaCha20-Poly1305 - 验证所有 10 种 3-location 组合的加密解密

## 3. 黄金向量覆盖分析

- [x] 3.1 分析 Vector 1（西游记）的覆盖范围：中文输入、北半球东半球坐标
- [x] 3.2 分析 Vector 2（Moses Exodus）的覆盖范围：英文输入、南半球西半球坐标
- [x] 3.3 识别未覆盖的边界情况（日文、西班牙文、极端坐标）
- [x] 3.4 评估是否需要增加第三个黄金向量

## 4. 依赖库升级评估

- [x] 4.1 记录当前版本：Swift-Sodium 0.9.1、F9Grid 1.1.0
- [x] 4.2 在隔离环境（单独分支）测试 Swift-Sodium 升级到最新版本
- [x] 4.3 运行完整黄金向量测试，对比所有中间状态和最终输出
- [x] 4.4 在隔离环境测试 F9Grid 升级到最新版本
- [x] 4.5 运行完整黄金向量测试，验证 positionCode 完全一致
- [x] 4.6 记录升级测试结果和兼容性结论

## 5. 文档化稳定性保证

- [x] 5.1 更新 WujiSeedTests/GoldenVectors/README.md - 明确 V1 稳定性承诺
- [x] 5.2 更新 CLAUDE.md - 修正错误的算法描述（已修正部分错误）
- [x] 5.3 在 README.md 中添加 V1 向后兼容性说明
- [x] 5.4 创建 STABILITY.md - 记录稳定性基准、风险点和升级流程
- [x] 5.5 文档化依赖库升级的测试流程（隔离环境 + 黄金向量验证）

## 6. CI/CD 集成

- [x] 6.1 确认现有 CI 配置文件位置和结构
- [x] 6.2 在 CI 流程中添加黄金向量回归测试强制执行
- [x] 6.3 配置测试失败时阻止代码合并
- [x] 6.4 添加依赖库版本检查，防止意外升级
- [x] 6.5 测试 CI 流程：故意破坏一个算法输出，验证 CI 能正确阻断

## 7. 代码审查清单

- [x] 7.1 创建 CODE_REVIEW_CHECKLIST.md - V1 兼容性检查项
- [x] 7.2 列出高风险修改：WujiNormalizer、CryptoUtils、WujiMemoryTagProcessor、BIP39Helper
- [x] 7.3 列出中风险修改：F9Grid 集成代码、加密备份相关代码
- [x] 7.4 明确要求：所有加密算法修改必须跑黄金向量测试
- [x] 7.5 将清单集成到 PR 模板（如果有的话）

## 8. 验证和总结

- [x] 8.1 运行完整测试套件，确保所有测试通过
- [x] 8.2 验证 CI/CD 配置生效
- [x] 8.3 审查所有新增文档的完整性和准确性
- [x] 8.4 创建审计总结报告：发现的问题、已修复的问题、风险评估
- [x] 8.5 向团队演示黄金向量测试流程和依赖升级评估流程
