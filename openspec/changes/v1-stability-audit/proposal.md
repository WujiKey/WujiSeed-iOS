## 为什么要做这个

V1 已经上线了，用户用它生成了助记词和加密备份。现在的问题是：

**如果升级代码，会不会把用户的助记词搞坏？**

- 重构代码可能改变输出
- 依赖库升级可能改变算法行为
- 平台差异（iOS 版本、Swift 编译器）可能影响结果
- 文档和代码不一致

现在需要**审计一遍**，搞清楚哪些东西绝对不能改，把测试补全，防止以后出问题。

## 要做什么

### 核心任务
1. **检查 7 个核心算法**是否和黄金向量一致
   - 文本归一化、BLAKE2b-128 盐、F9Grid 编码、记忆标签处理、Argon2id、BIP39、XChaCha20-Poly1305 加密

2. **验证 2 个黄金向量**（西游记、Moses Exodus）能不能覆盖所有情况

3. **找出风险点**
   - Swift-Sodium 0.9.1 和 F9Grid 1.1.0 通过测试评估能否升级
   - 新版本 iOS 会不会改变 Unicode 排序？
   - 负坐标（南半球、西半球）处理对不对？

4. **补测试**
   - 单元测试：每个算法单独测
   - 回归测试：黄金向量完整跑一遍
   - CI/CD：测试不通过就不让合并代码

5. **写清楚规矩**
   - 哪些代码改了要特别小心
   - 依赖库升级的测试流程
   - 黄金向量怎么用

## 会改动哪些地方

**代码文件**（只检查，不改算法）
- `WujiLib/WujiNormalizer.swift` - 文本归一化
- `WujiLib/CryptoUtils.swift` - 加密相关
- `WujiLib/WujiMemoryTagProcessor.swift` - 记忆标签处理
- `Common/BIP39Helper.swift` - 助记词生成

**测试文件**（会补充测试）
- `WujiSeedTests/GoldenVectors/` - 黄金向量
- `WujiSeedTests/WujiRegressionTests.swift` - 回归测试

**依赖库**（锁死版本）
- Swift-Sodium 0.9.1
- F9Grid 1.1.0

**流程**（会加强制要求）
- CI/CD 必须跑黄金向量测试
- 代码审查要检查兼容性
- 文档要写清楚 V1 稳定性保证
