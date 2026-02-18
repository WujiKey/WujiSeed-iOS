# Golden Test Vectors

This directory contains golden test vectors for WujiSeed cross-platform verification.

## V1 Stability Commitment

**These golden vectors define the immutable V1 protocol specification.**

- ✅ **Backward Compatibility Guarantee**: Any mnemonic or encrypted backup generated with V1 will **always** be recoverable by future versions
- ✅ **Algorithm Stability**: The 7 core algorithms (normalization, BLAKE2b, F9Grid, tag processing, Argon2id, BIP39, XChaCha20-Poly1305) are **frozen** for V1
- ✅ **Dependency Locking**: Swift-Sodium 0.9.1 and F9Grid 1.1.0 are locked - upgrades require golden vector validation
- ✅ **CI Enforcement**: All code changes must pass golden vector regression tests before merge
- ⚠️ **Breaking Changes Prohibited**: Modifying these vectors or core algorithms constitutes a breaking change to V1

If you need to change core behavior, you must create a V2 protocol with migration support.

## Purpose

These JSON files serve as the **source of truth** for verifying that all platform implementations (iOS, Android, JavaScript, etc.) produce identical results for the same inputs.

## Format

Each JSON file contains:

- **name**: The raw identifier string
- **normalizedName**: The identifier after normalization
- **nameSaltHex**: BLAKE2b-128 hash of (normalized name + "WUJI-Key-V1:Memory-Based Seed Phrases") in hexadecimal
- **locations**: Array of 5 geographic locations with:
  - **coordinate**: Lat/lng coordinate string
  - **memoryTags**: Array of keyword tags (before processing)
  - **memoryProcessed**: Final concatenated and sorted memory string
  - **positionCode**: F9Grid 9-grid position code (1-9)
- **keyDataHex**: Argon2id output (32 bytes) in hexadecimal
- **mnemonics**: Array of 24 BIP39 mnemonic words
- **encryptedBackupBase64**: Encrypted backup data in Base64 encoding
- **argon2Parameters**: KDF parameters used for testing

## Usage

### For iOS Development

The `WujiRegressionTests.swift` file automatically validates against these vectors.

### For Android/JavaScript Development

1. Load the JSON file
2. Implement the same normalization, hashing, and encryption algorithms
3. Verify that your implementation produces:
   - Same `normalizedName` from `name`
   - Same `nameSaltHex` from `normalizedName`
   - Same `memoryProcessed` from `memoryTags` (normalize, dedupe, sort, concatenate)
   - Same position codes from coordinates
   - Same `keyDataHex` from Argon2id
   - Same `mnemonics` from BIP39 generation
   - Ability to decrypt `encryptedBackupBase64` with correct inputs

## Test Vectors

### wujikey_v1_vector_1.json

**Theme**: Journey to the West (西游记)
- **Name**: 吴承恩《西游记》 (Wu Cheng'en "Journey to the West")
- **Locations**: 5 locations related to the Chinese classic novel
  1. 花果山 (Huaguo Mountain) - 34.617090, 119.191840
  2. 菩提祖师处 (Subhodi's Cave) - 35.066260, 107.614560
  3. 东海龙宫 (East Sea Dragon Palace) - 11.373300, 142.591700
  4. 观音菩萨处 (Guanyin's Place) - 29.976330, 122.389360
  5. 灵山 (Vulture Peak) - 24.695100, 84.991300
- **Memory Keywords**: Story elements (1-3 tags per location)
- **Argon2id**: **PRODUCTION parameters** (256MB/7 iterations)

### wujikey_v1_vector_2.json

**Theme**: Moses Exodus (English keywords with extreme geographic distribution)
- **Name**: "Moses: Exodus"
- **Locations**: 5 locations with **extreme geographic distribution** (includes Southern and Western hemispheres)
  1. Cairo, Egypt - 30.0444, 31.2357 (Northern/Eastern) - Oppression
  2. Mount Sinai - 28.5392, 33.9752 (Northern/Eastern) - Ten Commandments
  3. **Cape Town, South Africa** - -33.9249, 18.4241 (**SOUTHERN HEMISPHERE**) - Journey's end
  4. Red Sea - 29.5581, 32.5519 (Northern/Eastern) - Parting waters
  5. **New York, USA** - 40.7128, -74.0060 (**WESTERN HEMISPHERE**) - Freedom symbol
- **Memory Keywords**: All English (2-3 tags per location)
- **Argon2id**: **PRODUCTION parameters** (256MB/7 iterations)

**Note**: Vector2 tests cross-platform implementations with:
- English-only keywords for international compatibility
- Geographically distant coordinates (Southern and Western hemispheres)
- Validates F9Grid position code calculation across hemispheres

---

✅ **Both test vectors use PRODUCTION Argon2id parameters**:
- Memory: 256MB (262144 KB)
- Iterations: 7
- Parallelism: 1 thread

These are the exact parameters used in the production app for maximum security.

## Validation Checklist

✅ Name normalization: NFKC → CaseFold → Trim → CollapseWS → AsciiPunctNorm
✅ Name salt: BLAKE2b-128(normalized name + "WUJI-Key-V1:Memory-Based Seed Phrases")
✅ Memory processing: normalize tags → deduplicate → Unicode sort → concatenate
✅ F9Grid: Coordinates → cell index + position code (1-9)
✅ Argon2id: Derive 32-byte key from memory + name salt
✅ BIP39: Generate 24 words from 256-bit key
✅ Encryption: XChaCha20-Poly1305 backup with memory fault tolerance (10 independent blocks)

## Important Notes

⚠️ **DO NOT modify these files** unless you intentionally want to break backward compatibility.

⚠️ If a test fails against these vectors, it means your implementation is **incompatible** with the reference iOS implementation.

⚠️ The `encryptedBackupBase64` is **deterministic** only when using the exact same Argon2id parameters. Production uses different parameters.

## Generating New Vectors

To generate new golden vectors (only do this for new test cases):

1. Add memory tags to `Vector1.memoryTags` in `WujiRegressionTests.swift`
2. Uncomment the `testGenerateGoldenVectors()` method
3. Run the test
4. Copy the JSON from `/tmp/golden_vectors.json` to this directory
5. Update expected values in the regression tests
6. Remove the temporary test method

## Cross-Platform Implementation Guide

When implementing WujiSeed on a new platform:

1. Start by implementing the basic algorithms:
   - Text normalization (Unicode, case folding, whitespace handling)
   - BLAKE2b hashing (128-bit output for name salt)
   - WujiMemoryTagProcessor (normalize, dedupe, sort, concat)
   - F9Grid position codes

2. Test each algorithm individually against these vectors

3. Implement the full pipeline:
   - Name → salt generation
   - Locations + memories → combined data
   - Argon2id KDF
   - BIP39 mnemonic generation

4. Verify the complete flow produces identical results

5. Implement encryption/decryption and test against `encryptedBackupBase64`

## Contact

For questions about these test vectors or cross-platform implementation guidance, please open an issue in the GitHub repository.
