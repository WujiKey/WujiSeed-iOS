# V1 Protocol Stability Baseline

This document defines the stability commitments, risk assessment, and upgrade procedures for WujiSeed V1.

## Stability Commitment

**WujiSeed V1 guarantees backward compatibility for all user-generated data.**

Any mnemonic phrase or encrypted backup created with V1 must be recoverable by all future versions. This commitment is enforced through:

1. **Algorithm Freeze**: The 7 core cryptographic and encoding algorithms are immutable
2. **Golden Vector Regression**: All code changes must pass reference test validation
3. **Dependency Locking**: External libraries are version-locked with upgrade validation requirements
4. **CI Enforcement**: Automated testing blocks incompatible changes from merging

## Frozen Components (V1)

### 1. Text Normalization
**Flow**: `AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))`
**File**: `WujiSeed/WujiLib/WujiNormalizer.swift`
**Risk**: HIGH — Any change breaks mnemonic generation

**Immutable Behavior**:
- NFKC Unicode normalization
- Case folding (locale-independent)
- Whitespace trimming and collapsing
- ASCII punctuation normalization

**Test Coverage**:
- Golden vectors verify: `wujikey_v1_vector_1.json`, `wujikey_v1_vector_2.json`
- Unit tests: `WujiSeedTests/WujiNormalizerTests.swift`

### 2. Salt Generation
**Algorithm**: `BLAKE2b-128(Normalize(name) + "WUJI-Key-V1:Memory-Based Seed Phrases")`
**File**: `WujiSeed/WujiLib/CryptoUtils.swift`, `WujiSeed/WujiLib/WujiName.swift`
**Risk**: HIGH — Salt mismatch prevents recovery

**Immutable Values**:
- Output length: 16 bytes (128 bits)
- Suffix string: `"WUJI-Key-V1:Memory-Based Seed Phrases"` (exact match required)
- Hash function: BLAKE2b (libsodium implementation)

**Test Coverage**:
- Golden vectors verify `nameSaltHex` field
- Unit test: `CryptoUtilsTests.testSaltSuffix()`

### 3. F9Grid Geographic Encoding
**Algorithm**: Hierarchical grid system → cell index + 9-grid position code (1-9)
**File**: External dependency `F9Grid` 1.1.0
**Risk**: MEDIUM — Position code changes break encrypted backup recovery

**9-Grid Position Layout**:
```
4(NW)  9(N)   2(NE)
3(W)   5(C)   7(E)
8(SW)  1(S)   6(SE)
```

**Critical Details**:
- Handles negative coordinates (Southern/Western hemispheres) correctly
- Deterministic cell-to-code mapping
- No floating-point rounding variations

**Test Coverage**:
- Golden vectors verify `positionCode` for 10 locations across hemispheres
- Regression tests: `WujiRegressionTests.testVector1_PositionCodes()`, `testVector2_PositionCodes()`

### 4. Memory Tag Processing
**Algorithm**: Normalize → Deduplicate → Unicode Sort → Concatenate
**File**: `WujiSeed/WujiLib/WujiMemoryTagProcessor.swift`
**Risk**: HIGH — Sort order changes break mnemonic generation

**Immutable Behavior**:
- Tags normalized using `WujiNormalizer`
- Case-insensitive deduplication
- **Unicode code point sorting** (not locale-specific)
- Concatenation without separators

**Test Coverage**:
- Golden vectors verify `memoryProcessed` field
- Unit tests: `WujiMemoryTagProcessorTests.swift`

### 5. Argon2id Key Derivation
**Parameters**: 256MB memory, 7 iterations, 1 thread
**File**: `WujiSeed/WujiLib/CryptoUtils.swift`
**Risk**: CRITICAL — Parameter changes make backups unrecoverable

**Immutable Values**:
```swift
memoryKB: 262144      // 256 MB
iterations: 7          // Time cost
parallelism: 1         // Single-threaded
outputLength: 32       // 256-bit key
```

**Test Coverage**:
- Golden vectors verify `keyDataHex` (32-byte output)
- Unit tests: `CryptoUtilsTests` (Argon2id parameter validation)

### 6. BIP39 Mnemonic Generation
**Standard**: BIP39 (Bitcoin Improvement Proposal 39)
**File**: `WujiSeed/Common/BIP39Helper.swift`
**Risk**: CRITICAL — Mnemonic changes lose access to wallets

**Immutable Process**:
1. Take 253 bits of Argon2id output
2. Add 3 bits padding (zeros)
3. Compute 8-bit SHA256 checksum
4. Map 264 bits → 24 words using BIP39 English wordlist

**Test Coverage**:
- Golden vectors verify exact 24-word mnemonic sequence
- Checksum validation in `BIP39Helper.generateMnemonic()`

### 7. XChaCha20-Poly1305 Encryption
**Algorithm**: Authenticated encryption with 3-of-5 fault tolerance
**File**: `WujiSeed/WujiLib/WujiReserve.swift`
**Risk**: HIGH — Encryption format changes prevent backup decryption

**Immutable Details**:
- 10 independent encrypted blocks (C(5,3) combinations)
- Deterministic nonce derivation from keyMaterials
- Binary format: `"WUJI" magic bytes + version + blocks`
- Plaintext: 33 bytes (mnemonic) + 16 bytes (deterministic padding)

**Test Coverage**:
- Golden vectors verify `encryptedBackupBase64`
- Recovery tests validate all 10 combinations

## Dependency Versions

### Swift-Sodium 0.9.1
**Purpose**: BLAKE2b, Argon2id, XChaCha20-Poly1305 implementations
**Lock Reason**: Cryptographic library — algorithm changes break compatibility

**Upgrade Process**:
1. Create isolated branch: `test/swift-sodium-upgrade`
2. Update `Package.resolved` to new version
3. Run golden vector regression tests: `xcodebuild test -only-testing:WujiSeedTests/WujiRegressionTests`
4. Verify **all** intermediate states match:
   - `normalizedName`
   - `nameSaltHex`
   - `memoryProcessed`
   - `positionCode`
   - `keyDataHex`
   - `mnemonics`
   - `encryptedBackupBase64`
5. If ANY value differs → **abort upgrade** or create V2 migration
6. Document results in upgrade log

### F9Grid 1.1.0
**Purpose**: Geographic coordinate to position code conversion
**Lock Reason**: Position code changes break encrypted backup recovery

**Upgrade Process**:
Same as Swift-Sodium, with special focus on:
- Negative coordinate handling (Southern/Western hemispheres)
- Position code determinism for all 10 test vector locations

## Risk Assessment

### HIGH RISK: Code Changes That Break Compatibility

**Never modify these without V2 migration**:
- `WujiNormalizer.swift` — Any change to normalization flow
- `CryptoUtils.WujiBlake2bSaltSuffix` — Salt suffix string
- `CryptoUtils.WujiArgon2id*` — KDF parameters (memory, iterations, parallelism)
- `WujiMemoryTagProcessor.swift` — Sort algorithm or concatenation
- `BIP39Helper.swift` — Entropy-to-mnemonic conversion
- `WujiReserve.swift` — Encryption format or block generation

### MEDIUM RISK: Changes Requiring Careful Testing

- F9Grid integration code — Must preserve position code output
- Coordinate parsing — Must handle negative values correctly
- Unicode handling in tag processor — Must maintain sort order

### LOW RISK: Safe to Modify

- UI code (view controllers, themes, localization)
- Logging and debugging utilities
- Non-cryptographic helper functions
- Session state management (in-memory only)

## Testing Requirements

### Golden Vector Regression (MANDATORY)

**Command**:
```bash
xcodebuild test -project WujiSeed.xcodeproj -scheme WujiSeed \
  -destination 'platform=iOS Simulator,id=C4F92C22-C0C1-45DF-BC81-B52C77D41A22' \
  -only-testing:WujiSeedTests/WujiRegressionTests
```

**Must Pass Before Merge**:
- `testVector1_NameSalt()` — BLAKE2b salt generation
- `testVector1_MemoryProcessing()` — Tag normalization and sorting
- `testVector1_PositionCodes()` — F9Grid encoding
- `testVector1_GenerateMnemonics()` — End-to-end mnemonic generation
- `testVector1_DecryptBackupWith5Spots()` — Encryption format
- `testVector1_RecoverBackupWith3Spots()` — 3-of-5 recovery
- (Same 6 tests for `testVector2_*`)
- `testVectorsProduceDifferentOutputs()` — No collisions
- `testVectorsUseProductionParameters()` — Argon2id parameters

**Test Vectors**:
- `wujikey_v1_vector_1.json` — Journey to the West (Chinese, Northern/Eastern coords)
- `wujikey_v1_vector_2.json` — Moses Exodus (English, Southern/Western coords)

### CI/CD Integration

See `.github/workflows/stability.yml` (created in Phase 6).

## Platform Compatibility

### iOS Version Support

**Minimum**: iOS 12.0
**Risk**: Unicode normalization behavior may vary across iOS versions

**Mitigation**:
- Test golden vectors on iOS 12, 14, 16, 18+
- Document any platform-specific differences
- Lock iOS deployment target in Xcode project

### Swift Compiler

**Current**: Swift 5.x
**Risk**: Swift 6+ may change String normalization internals

**Mitigation**:
- Run golden vectors after Swift compiler upgrades
- Test on multiple Xcode versions before deploying

## Upgrade Decision Framework

### When Considering Dependency Upgrades

**Question 1**: Does the upgrade fix a critical security vulnerability?
- **Yes** → Proceed with upgrade validation process
- **No** → Continue to Question 2

**Question 2**: Does the upgrade add a required feature?
- **Yes** → Proceed with upgrade validation process
- **No** → **Do not upgrade** (stability > new features)

**Question 3**: Did golden vector tests pass 100%?
- **Yes** → Safe to upgrade (document in changelog)
- **No** → **Abort upgrade** or design V2 migration

## V2 Migration Strategy

If a breaking change is unavoidable:

1. **Create V2 Protocol Spec**:
   - Document all algorithm changes
   - Generate new golden vectors
   - Version all binary formats with headers

2. **Implement Dual Support**:
   - Detect V1 vs V2 data automatically
   - Always allow V1 recovery
   - Offer V1 → V2 migration with user consent

3. **Never Delete V1 Code**:
   - Keep V1 recovery logic indefinitely
   - Mark V1 functions as `@available(*, deprecated, message: "V1 compatibility only")`

## Audit History

| Date | Version | Audit Type | Result | Notes |
|------|---------|------------|--------|-------|
| 2026-02-13 | 1.0 | Initial Stability Baseline | ✅ PASS | All golden vectors pass, dependencies locked |

## References

- Golden Vectors: [`WujiSeedTests/GoldenVectors/README.md`](WujiSeedTests/GoldenVectors/README.md)
- Protocol Spec: [`openspec/config.yaml`](openspec/config.yaml)
- Development Guide: [`CLAUDE.md`](CLAUDE.md)

---

**Last Updated**: 2026-02-13
**Protocol Version**: V1
**Audit Status**: ✅ Baseline Established
