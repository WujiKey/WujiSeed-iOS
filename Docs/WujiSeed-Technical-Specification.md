# WujiSeed Protocol Specification

**Protocol Version:** `WUJI-Key-V1`
**Document Version:** 1.0
**Date:** 2026-01

---

## Abstract

WujiSeed is an innovative cryptocurrency mnemonic generation and backup protocol. It transforms users' **personal memories** (name, locations, stories) into deterministic BIP39 mnemonics, achieving the goal of "never needing to memorize the mnemonic itself." The protocol employs modern cryptographic primitives including BLAKE2b and Argon2id, providing military-grade security while supporting a 3-of-5 threshold recovery scheme.

---

## 1. Design Goals

### 1.1 Core Philosophy

Traditional mnemonic schemes require users to memorize or securely store 24 random words. WujiSeed takes a different approach:

> **Use what you remember to generate what you can't.**

Users only need to remember:
- One **personal identifier** (e.g., name, email)
- **5 meaningful locations** with associated memories

The protocol deterministically converts these inputs into standard BIP39 mnemonics.

### 1.2 Security Goals

| Goal | Implementation |
|------|----------------|
| **Offline-First** | All computations performed locally, no network requests |
| **Brute-Force Resistant** | Argon2id with 256MB memory hardening |
| **Threshold Recovery** | Only 3/5 locations required for recovery |
| **Deterministic Output** | Same inputs always produce same mnemonic |
| **Forward Secrecy** | Random padding per encrypted block |

---

## 2. Protocol Overview

### 2.1 Generation Flow

```
+---------------------------------------------------------------------+
|                        User Inputs                                   |
+---------------------------------------------------------------------+
|  Personal Identifier (name/email)                                    |
|  +-- Text Normalization --> Normalize(identifier)                    |
|  +-- Salt Derivation --> BLAKE2b-128 --> salt (16 bytes)            |
|                                                                      |
|  5 Locations x (coordinates + two memories)                          |
|  +-- Coordinates --> F9Grid cell index + position code              |
|  +-- Memory texts --> Normalization + sorting                        |
|  +-- Combined encoding --> keyMaterial (sorted by bytes)             |
+---------------------------------------------------------------------+
|                        Key Derivation                                |
+---------------------------------------------------------------------+
|  Argon2id(                                                           |
|    password = keyMaterial[0] || keyMaterial[1] || ... || [4],       |
|    salt = 16-byte salt,                                              |
|    memory = 256 MB,                                                  |
|    iterations = 7                                                    |
|  ) --> 256-bit entropy                                               |
+---------------------------------------------------------------------+
|                        BIP39 Encoding                                |
+---------------------------------------------------------------------+
|  256-bit entropy --> 23 words (253 bits)                            |
|  Remaining 3 bits + SHA256 checksum (8 bits) --> 24th word          |
|                                                                      |
|  Output: 24 BIP39 mnemonic words                                     |
+---------------------------------------------------------------------+
```

### 2.2 Recovery Methods

**Method 1: Encrypted Backup Recovery (Recommended)**
- Requires: Encrypted backup file + Personal identifier + Any 3 locations
- Attempts: Up to 10 Argon2id operations

**Method 2: Full Memory Recovery**
- Requires: Personal identifier + All 5 locations + Position codes
- No backup file needed, relies purely on memory

---

## 3. Text Normalization

### 3.1 Normalization Pipeline

All user input text must undergo normalization to ensure consistent results from different input methods:

```
Normalize(s) = AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))
```

**Processing Steps:**

| Step | Function | Description | Example |
|------|----------|-------------|---------|
| 1 | NFKC | Unicode compatibility normalization | `Hello` -> `Hello` |
| 2 | CaseFold | Case folding | `Hello` -> `hello` |
| 3 | Trim | Remove leading/trailing whitespace | `  hello  ` -> `hello` |
| 4 | CollapseWS | Collapse consecutive whitespace to single space | `hello   world` -> `hello world` |
| 5 | AsciiPunctNorm | Convert CJK punctuation to ASCII | `,.!` -> `,.!` |

### 3.2 Punctuation Mapping

```
CJK/Full-width Punctuation --> ASCII Punctuation
  ,  -->  ,    (comma)
  .  -->  .    (period)
  !  -->  !    (exclamation)
  ?  -->  ?    (question)
  :  -->  :    (colon)
  ;  -->  ;    (semicolon)
  () -->  ()   (parentheses)
  [] -->  []   (brackets)
  '' -->  ''   (quotes)
  "" -->  ""   (double quotes)
  -- -->  -    (dash)
  ...-->  ...  (ellipsis)
```

---

## 4. Data Structures

### 4.1 Spot (Location Record)

Each location contains three components:

```
Spot = {
  place:       WujiPlace,    // Geographic coordinates
  memory1Tags: [String],   // First memory keyword tags (minimum 3 tags)
  memory2Tags: [String]    // Second memory keyword tags (minimum 3 tags)
}
```

**Memory Tags Processing:**
- Each location has two memory input areas, each requiring minimum 3 keyword tags
- Total minimum 6 tags per location (3 + 3)
- Each tag is normalized individually (NFKC → CaseFold → Trim → AsciiPunctNorm)
- Within each memory area: tags are deduplicated, sorted by Unicode order, and concatenated without separators

### 4.2 Location Encoding

**Purpose:** Convert location information into fixed-format binary data for key derivation.

```
+---------------------------------------------------------------------+
|  keyMaterial = sortedProcessedMemory1(UTF-8) +                       |
|                sortedProcessedMemory2(UTF-8) +                       |
|                cellIndex(8 bytes big-endian)                         |
+---------------------------------------------------------------------+
```

**Encoding Rules:**

1. **Tag Normalization**: Each tag processed with (NFKC → CaseFold → Trim → AsciiPunctNorm)
2. **Tag Deduplication**: Remove duplicate tags within each memory area
3. **Tag Sorting**: Sort tags by Unicode lexicographic order within each memory area
4. **Concatenation**: Join sorted tags without separators to form processed memory string
5. **Memory Sorting**: Two processed memory strings sorted by Unicode lexicographic order (smaller first)
6. **Cell Index**: Int64 from F9Grid, converted to 8-byte big-endian

**Example:**
```
Input:
  memory1Tags = ["2020", "First Trip", "sunset"]
  memory2Tags = ["tokyo", "cherry blossom", "spring"]
  coordinates = (35.6762, 139.6503)

Normalized and sorted within each memory:
  memory1: "2020", "first trip", "sunset" → "2020first tripsunset"
  memory2: "cherry blossom", "spring", "tokyo" → "cherry blossomspringtokyo"

Sorted between memories (Unicode lexicographic):
  sorted1 = "2020first tripsunset"      // '2' < 'c'
  sorted2 = "cherry blossomspringtokyo"

Encoded:
  keyMaterial = UTF8("2020first tripsunset") +
                UTF8("cherry blossomspringtokyo") +
                BE64(cellIndex)
```

### 4.3 Position Code

F9Grid divides each cell into 9 sub-regions, encoded 1-9:

```
+---+---+---+
| 4 | 9 | 2 |   NW  N  NE
+---+---+---+
| 3 | 5 | 7 |   W   C  E
+---+---+---+
| 8 | 1 | 6 |   SW  S  SE
+---+---+---+
```

**Purpose:** GPS drift may cause coordinates to fall into adjacent cells. Position codes allow finding the original cell during recovery.

---

## 5. Cryptographic Primitives

### 5.1 BLAKE2b-128

**Purpose:** Generate Argon2id salt from personal identifier

```
salt = BLAKE2b-128(UTF8(Normalize(identifier)) + UTF8("WUJI-Key-V1:Memory-Based Seed Phrases"))
```

- Output: 16 bytes (128 bits)
- Version suffix ensures salt changes with protocol upgrades

### 5.2 Argon2id

**Purpose:** Memory-hard key derivation to prevent brute-force attacks

**Parameter Configuration:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| Memory | 256 MB | Blocks GPU/ASIC parallel attacks |
| Iterations | 7 | Increases computation time |
| Parallelism | 1 | Single-threaded execution |
| Output | 32 bytes | 256-bit key/entropy |
| Version | 1.3 (0x13) | Standard Argon2id version |

**Security Analysis:**

```
Single Argon2id time: ~3-5 seconds (mobile device)
Brute-force cost:
  - Assuming attacker guesses location combinations
  - Each attempt requires 256MB memory + 3-5 seconds
  - 1 billion attempts = ~95 years x 256GB memory
```

### 5.3 XChaCha20-Poly1305

**Purpose:** Encrypt mnemonic data in backup

| Parameter | Length | Description |
|-----------|--------|-------------|
| Key | 32 bytes | Derived from Argon2id |
| Nonce | 24 bytes | Auto-generated, eliminates reuse risk |
| Auth Tag | 16 bytes | Tamper-proof verification |

### 5.4 SHA-256

**Purpose:** BIP39 checksum calculation

```
checksum = SHA-256(entropy)[0:8]  // First 8 bits
```

---

## 6. Mnemonic Generation

### 6.1 Salt Derivation

```
Input: identifier (personal identifier string)
Output: salt (16 bytes)

1. normalized <- Normalize(identifier)
2. input <- UTF8(normalized) + UTF8("WUJI-Key-V1:Memory-Based Seed Phrases")
3. salt <- BLAKE2b-128(input)
```

### 6.2 Location Processing

```
Input: spots[5] (5 location records)
Output: keyMaterials[5], positionCodes[5]

For each spot[i]:
  1. keyMaterial[i] <- spot[i].keyMaterial()
  2. positionCode[i] <- spot[i].positionCode()

Sort by keyMaterial byte order:
  (keyMaterials, positionCodes) <- sort_together_by_keyMaterial()
```

### 6.3 Entropy Derivation

```
Input: keyMaterials[5], salt (16 bytes)
Output: entropy (32 bytes)

1. password <- keyMaterials[0] || keyMaterials[1] || ... || keyMaterials[4]
2. entropy <- Argon2id(password, salt, 256MB, 7 iterations)
```

### 6.4 BIP39 Encoding

```
Input: entropy (32 bytes = 256 bits)
Output: words[24]

1. bits <- binary representation of entropy (256 bits)

2. Generate first 23 words:
   for i = 0 to 22:
     index <- bits[11i : 11(i+1)]  // 11 bits each
     words[i] <- BIP39_WORDLIST[index]

3. Generate 24th word:
   remaining <- bits[253:256]           // Remaining 3 bits
   checksum <- SHA-256(entropy)[0:8]    // First 8 bits
   index <- remaining || checksum       // Total 11 bits
   words[23] <- BIP39_WORDLIST[index]
```

### 6.5 Complete Algorithm

```
+------------------------------------------------------------------------+
|  GenerateMnemonic(identifier, spots[5])                                 |
+------------------------------------------------------------------------+
|  1. salt <- DeriveSalt(identifier)                   // 16 bytes       |
|  2. (keyMaterials, positionCodes) <- ProcessSpots(spots)               |
|  3. entropy <- Argon2id(concat(keyMaterials), salt)  // 32 bytes       |
|  4. words <- BIP39Encode(entropy)                    // 24 words       |
|  5. return (words, positionCodes)                                       |
+------------------------------------------------------------------------+
```

---

## 7. Encrypted Backup (3-of-5 Threshold Scheme)

### 7.1 Design Rationale

To enable "recovery with only 3 locations," the protocol generates C(5,3)=10 independent encrypted blocks. Each block is encrypted with a key derived from a different 3-location combination.

```
10 Combinations:
  {0,1,2} {0,1,3} {0,1,4} {0,2,3} {0,2,4}
  {0,3,4} {1,2,3} {1,2,4} {1,3,4} {2,3,4}
```

### 7.2 Plaintext Format

```
+------------------------------------------+
|  Mnemonic Data (33 bytes)                |
|  24 words x 11 bits = 264 bits = 33 bytes|
+------------------------------------------+
|  Random Padding (16 bytes)               |
|  Each block uses different random padding|
+------------------------------------------+
Total: 49 bytes plaintext
```

### 7.3 AAD Construction

Associated Authenticated Data (AAD) for AEAD:

```
AAD = Magic(4) + Version(1) + Options(1) + PositionCodes(3)

Where:
  Magic   = [0x57, 0x55, 0x4A, 0x49]  // "WUJI" (ASCII)
  Version = 0x01
  Options = 0x00 (reserved)
  PositionCodes = 5 position codes packed into 3 bytes
```

### 7.4 Encryption Algorithm

```
+------------------------------------------------------------------------+
|  Encrypt(words[24], keyMaterials[5], positionCodes[5], salt)           |
+------------------------------------------------------------------------+
|  1. mnemonicData <- WordsToBytes(words)          // 33 bytes           |
|  2. sortedKM <- sort(keyMaterials)               // Sort by bytes      |
|  3. AAD <- BuildAAD(positionCodes)               // 9 bytes            |
|                                                                         |
|  4. For each combination {a, b, c} in C(5,3):                          |
|       password <- sortedKM[a] || sortedKM[b] || sortedKM[c]            |
|       key <- Argon2id(password, salt)            // 32 bytes           |
|       padding <- RandomBytes(16)                                        |
|       plaintext <- mnemonicData || padding        // 49 bytes          |
|       (ciphertext, tag, nonce) <- XChaCha20Poly1305.Encrypt(           |
|                                    plaintext, key, AAD)                |
|       blocks[j] <- {nonce, ciphertext, tag}                            |
|                                                                         |
|  5. shuffledBlocks <- DeterministicShuffle(blocks, sortedKM)           |
|  6. return Serialize(positionCodes, shuffledBlocks)                    |
+------------------------------------------------------------------------+
```

### 7.5 Deterministic Shuffle

Encrypted blocks undergo deterministic shuffling to hide the combination-to-block mapping:

```
seed <- BLAKE2b-256(KM[0] || "|" || KM[1] || ... || "|block-shuffle-seed")
shuffled <- FisherYates(blocks, seed)
```

---

## 8. Recovery Algorithm

### 8.1 Method 1: Encrypted Backup Recovery

**Applicable Scenario:** User has encrypted backup file but only remembers 3-5 locations

```
+------------------------------------------------------------------------+
|  DecryptWithRecovery(backup, spots[N], allPositionCodes[5], salt)      |
|  where 3 <= N <= 5                                                      |
+------------------------------------------------------------------------+
|  1. spotCombos <- C(N, 3)              // Combinations of N choose 3   |
|  2. posCodeCombos <- C(5, 3) = 10      // Combinations of 5 choose 3   |
|                                                                         |
|  3. For each spotCombo:                                                 |
|       For each posCodeCombo:                                            |
|         selectedSpots <- spots[spotCombo]                               |
|         selectedCodes <- allPositionCodes[posCodeCombo]                 |
|         keyMaterials <- ProcessSpots(selectedSpots, selectedCodes)      |
|         password <- concat(sort(keyMaterials))                          |
|         key <- Argon2id(password, salt)                                 |
|                                                                         |
|         For each encrypted block:                                       |
|           plaintext <- TryDecrypt(block, key, AAD)                      |
|           if success && ValidChecksum(plaintext):                       |
|             return BytesToWords(plaintext)                              |
|                                                                         |
|  4. return failure                                                      |
+------------------------------------------------------------------------+
```

**Argon2id Attempt Count:**

| Known Locations | Attempts |
|-----------------|----------|
| 3 | 1 x 10 = 10 |
| 4 | 4 x 10 = 40 |
| 5 | 10 x 10 = 100 |

**Optimization:** Use password caching for deduplication to avoid redundant Argon2id computations.

### 8.2 Method 2: Full Memory Recovery

**Applicable Scenario:** User has no backup file but completely remembers all 5 locations

```
Directly call GenerateMnemonic(identifier, spots[5])
```

This method requires position codes to correct potential GPS drift.

---

## 9. Binary Format

### 9.1 Overall Structure

```
+---------+---------+---------+----------------+---------------+---------+----------------+---------+
| Magic   | Version | Options | PayloadLength  | PositionCodes | Count   | Blocks[10]     | CRC32   |
| 4 bytes | 1 byte  | 1 byte  | 2 bytes (BE)   | 3 bytes       | 1 byte  | variable       | 4 bytes |
+---------+---------+---------+----------------+---------------+---------+----------------+---------+
```

### 9.2 Block Structure

```
+-----------------+-------------+----------------------+-------------+
| BlockLength     | Nonce       | Ciphertext           | Tag         |
| 2 bytes (BE)    | 24 bytes    | 49 bytes             | 16 bytes    |
+-----------------+-------------+----------------------+-------------+
Per block total: 2 + 24 + 49 + 16 = 91 bytes
```

### 9.3 Position Code Encoding

```
5 position codes (P0...P4), each 1-9, packed into 3 bytes:

  Byte 0 = (P0 << 4) | P1
  Byte 1 = (P2 << 4) | P3
  Byte 2 = (P4 << 4) | 0
```

### 9.4 Typical File Size

```
Header:          8 bytes
Position codes:  3 bytes
Block count:     1 byte
10 blocks:       91 x 10 = 910 bytes
CRC32:           4 bytes
-----------------------------
Total:           926 bytes
```

---

## 10. Security Analysis

### 10.1 Threat Model

| Threat | Mitigation |
|--------|------------|
| Salt brute-force | BLAKE2b 128-bit output, 2^128 combinations |
| Key brute-force | Argon2id 256MB blocks parallel attacks |
| Backup file leak | Requires 3 locations to decrypt |
| GPS drift | Position code correction mechanism |
| Side-channel attacks | Outside local device security boundary, user responsibility |

### 10.2 Security Assumptions

1. **User Device Security**: Attacker cannot access user device memory
2. **Location Secrecy**: At least 3 locations unknown to attacker
3. **Cryptographic Primitive Security**: No known vulnerabilities in BLAKE2b, Argon2id, XChaCha20-Poly1305

### 10.3 Best Practices

- Choose **unique and private** locations (avoid popular public landmarks)
- Memory texts should include **personalized details** (dates, feelings, descriptions)
- **Use offline**: Enable airplane mode when generating mnemonics
- **Separate backups**: Store encrypted backup separately from location hints

---

## Appendix A: F9Grid Interface

F9Grid is an independent geographic encoding system providing these interfaces:

| Function | Input | Output | Description |
|----------|-------|--------|-------------|
| `CellIndex` | (lat, lng) | Int64 | Hierarchical cell unique identifier |
| `PositionCode` | (lat, lng) | 1-9 | 9-grid position within cell |
| `FindOriginalCell` | (lat, lng, code) | Int64 | Correct GPS drift using position code |

---

## Appendix B: Implementation Checklist

- [ ] All integers use big-endian byte order
- [ ] All strings use UTF-8 encoding
- [ ] Sorting uses byte lexicographic comparison
- [ ] Random numbers generated using CSPRNG
- [ ] Argon2id uses version 1.3 (0x13)
- [ ] Normalization pipeline executed in strict order
- [ ] Mnemonic validation includes BIP39 checksum check

---

## Appendix C: Test Vectors

### C.1 Text Normalization

```
Input:  "  HELLO  WORLD!  "
Output: "hello world!"

Steps:
  NFKC:       "  HELLO  WORLD!  "
  CaseFold:   "  hello  world!  "
  Trim:       "hello  world!"
  CollapseWS: "hello world!"
  AsciiPunct: "hello world!"
```

### C.2 Salt Generation

```
Input:
  identifier = "test@example.com"

Calculation:
  normalized = "test@example.com"
  input = "test@example.comWUJI-Key-V1:Memory-Based Seed Phrases"
  salt = BLAKE2b-128(UTF8(input))
       = [16 bytes salt]
```

### C.3 BIP39 Index

```
Word "abandon" -> index 0    -> binary "00000000000"
Word "zoo"     -> index 2047 -> binary "11111111111"

24 words x 11 bits = 264 bits = 33 bytes
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-12 | Initial specification |
| 2.0 | 2024-12 | Whitepaper format restructure, added security analysis and best practices |
| 2.1 | 2026-01 | Replaced free-text memory with tag-based input (2 memory areas × 3 tags = 6 tags per location) |

---

## References

- [BIP39: Mnemonic code for generating deterministic keys](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [Argon2: Password Hashing Function](https://datatracker.ietf.org/doc/html/rfc9106)
- [BLAKE2: Secure Hash Function](https://www.blake2.net/)
- [XChaCha20-Poly1305](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-xchacha)
