# Code Review Checklist — V1 Compatibility

Use this checklist when reviewing pull requests that modify WujiSeed code.

## Pre-Review: Automated Checks

Before manual review, verify CI passes:

- [ ] ✅ Golden vector regression tests pass (`WujiRegressionTests`)
- [ ] ✅ Dependency version check passes (Swift-Sodium 0.9.1, F9Grid 1.1.0)
- [ ] ✅ Full test suite passes
- [ ] ⚠️ Check warnings for high-risk file modifications

## HIGH RISK: Algorithm Modifications

**If ANY of these files are modified, STOP and perform enhanced review:**

### WujiNormalizer.swift
- [ ] Does the change affect the 5-step normalization flow?
  - NFKC → CaseFold → Trim → CollapseWS → AsciiPunctNorm
- [ ] Are string operations locale-independent?
- [ ] Does golden vector test verify `normalizedName` matches?
- [ ] **BLOCKER**: If normalization output changes for any existing input → REJECT PR

### CryptoUtils.swift
- [ ] Has `WujiBlake2bSaltSuffix` constant changed?
  - **BLOCKER**: Must remain `"WUJI-Key-V1:Memory-Based Seed Phrases"`
- [ ] Have Argon2id parameters changed?
  - **BLOCKER**: Must remain 256MB / 7 iterations / 1 parallelism
- [ ] Does BLAKE2b output length remain 16 bytes (128 bits)?
- [ ] Does golden vector verify `nameSaltHex` and `keyDataHex` match?

### WujiMemoryTagProcessor.swift
- [ ] Has tag normalization logic changed?
- [ ] Has deduplication logic changed?
- [ ] **CRITICAL**: Has Unicode sort order changed?
  - Must use code point sorting, NOT locale-specific
- [ ] Does tag concatenation remain separator-free?
- [ ] Does golden vector verify `memoryProcessed` matches?

### BIP39Helper.swift
- [ ] Has entropy-to-mnemonic conversion changed?
- [ ] Is checksum calculation still SHA256-based (8 bits)?
- [ ] Is BIP39 wordlist unchanged?
- [ ] Does golden vector verify exact 24-word `mnemonics` sequence?

### WujiReserve.swift (Encryption)
- [ ] Has XChaCha20-Poly1305 encryption changed?
- [ ] Are all 10 C(5,3) combinations still generated?
- [ ] Has binary format structure changed?
  - Magic bytes, version, block layout
- [ ] Is nonce derivation deterministic?
- [ ] Does golden vector verify `encryptedBackupBase64` matches?

**If answer to ANY blocker question is YES → REJECT PR immediately**

## MEDIUM RISK: Integration Code

### F9Grid Integration
- [ ] Has coordinate parsing changed?
- [ ] Are negative coordinates (Southern/Western hemispheres) handled correctly?
- [ ] Has position code mapping changed?
- [ ] Does golden vector verify all 10 `positionCode` values match?

### WujiName.swift
- [ ] Has salt generation call changed?
- [ ] Is normalization applied before salt generation?
- [ ] Does `WujiBlake2bSaltSuffix` usage remain correct?

### Coordinate Parsing (LatLngParser)
- [ ] Are negative values parsed correctly?
- [ ] Is precision maintained (no rounding errors)?
- [ ] Are edge cases tested (poles, date line)?

## LOW RISK: Safe Modifications

These changes typically don't affect V1 compatibility:

- [ ] UI code (ViewControllers, themes, layout)
- [ ] Localization strings (non-algorithmic text)
- [ ] Logging and debugging
- [ ] Session state management (in-memory only)
- [ ] Comments and documentation

**Still verify**: Changes don't accidentally import modified high-risk code.

## Dependency Changes

### Swift-Sodium Upgrade
- [ ] Is upgrade necessary (security patch, critical bug)?
- [ ] Has upgrade been tested in isolated branch?
- [ ] Do **all** golden vector tests pass with new version?
- [ ] Have intermediate cryptographic outputs been verified?
- [ ] Is upgrade documented in STABILITY.md audit history?

### F9Grid Upgrade
- [ ] Is upgrade necessary?
- [ ] Do golden vectors pass for all 10 location `positionCode` values?
- [ ] Have negative coordinate cases been tested?
- [ ] Is upgrade documented?

### Other Dependencies
- [ ] Does dependency affect UI only (safe)?
- [ ] Does dependency touch cryptographic or encoding logic (high risk)?

## Testing Requirements

### For HIGH RISK changes:
- [ ] Run `WujiRegressionTests` locally before review
- [ ] Verify CI golden vector tests pass
- [ ] Check for test coverage of modified code paths
- [ ] Request intermediate output logging for manual verification

### For MEDIUM RISK changes:
- [ ] Run relevant unit tests (`WujiNormalizerTests`, `CryptoUtilsTests`, etc.)
- [ ] Verify CI passes
- [ ] Check edge case coverage

### For LOW RISK changes:
- [ ] CI passes
- [ ] No unintended side effects

## Documentation Review

- [ ] Is `STABILITY.md` updated if algorithm behavior explained?
- [ ] Is `CLAUDE.md` updated if development workflow changes?
- [ ] Are code comments accurate?
- [ ] Is `README.md` updated if user-facing behavior changes?

## Backward Compatibility Verification

### Questions to Ask:
1. **Can old mnemonics still be generated from same inputs?**
   - If NO → REJECT (or require V2 migration)

2. **Can old encrypted backups still be decrypted?**
   - If NO → REJECT (or require V2 migration)

3. **Do golden vectors still pass 100%?**
   - If NO → REJECT (fix the code, don't change vectors)

4. **Are all intermediate outputs identical to golden vectors?**
   - `normalizedName`, `nameSaltHex`, `memoryProcessed`, `positionCode`, `keyDataHex`
   - If ANY differ → REJECT

## PR Approval Checklist

Before approving:

- [ ] All automated CI checks pass
- [ ] Manual testing performed for modified components
- [ ] Golden vector regression tests pass
- [ ] No breaking changes to V1 algorithms
- [ ] Documentation updated as needed
- [ ] Code follows project conventions (see `openspec/config.yaml`)

## Emergency: Breaking Change Detected

If a breaking change is already merged:

1. **DO NOT** merge additional PRs
2. **REVERT** the breaking commit immediately
3. Run golden vector tests to confirm revert fixes compatibility
4. Investigate root cause
5. If breaking change is intentional → Design V2 migration per `STABILITY.md`

## Reference

- **Stability Baseline**: [`STABILITY.md`](STABILITY.md)
- **Golden Vectors**: [`WujiSeedTests/GoldenVectors/README.md`](WujiSeedTests/GoldenVectors/README.md)
- **Test Execution**: [`CLAUDE.md`](CLAUDE.md) — Quick Commands section

---

**When in doubt, ask**: Is this change necessary? Does it risk user data recovery?

**If unsure**: Request additional review from crypto/security expert.
