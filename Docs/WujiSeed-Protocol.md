# WujiSeed Protocol Specification

**Protocol Version:** `WUJI-Key-V1`
**Document Version:** 1.0
**Date:** 2026-01

---

## Abstract

WujiSeed is an innovative cryptocurrency mnemonic generation and backup protocol with a core philosophy:

> **Use what you remember to generate what you can't.**

Users only need to remember:
- One **personal identifier** (e.g., name, email)
- **5 meaningful locations** with associated memory keywords

The protocol deterministically converts these inputs into standard BIP39 mnemonics using BLAKE2b and Argon2id cryptographic primitives, providing bank-grade security while supporting memory forgiveness recovery (only 3 locations needed with encrypted backup).

---

## 1. Generation Flow

```
+---------------------------------------------------------------------+
|                        User Inputs                                   |
+---------------------------------------------------------------------+
|  Personal Identifier (name/email)                                    |
|  +-- Text Normalization --> Normalize(identifier)                    |
|  +-- Salt Derivation --> BLAKE2b-128 --> salt (16 bytes)            |
|                                                                      |
|  5 Locations x (coordinates + two memory keywords)                   |
|  +-- Coordinates --> F9Grid cell index + position code              |
|  +-- Keywords --> Normalization + sorting                            |
|  +-- Combined encoding --> keyMaterial (sorted by bytes)             |
+---------------------------------------------------------------------+
|                        Key Derivation                                |
+---------------------------------------------------------------------+
|  Argon2id(                                                           |
|    entropy = keyMaterial[0] || keyMaterial[1] || ... || [4],        |
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

---

## 2. Data Structures

### 2.1 Spot (Location Record)

```
Spot = {
  place:       WujiPlace,    // Geographic coordinates
  memory1Tags: [String],   // First memory keyword tags (1-3 tags, recommended 1 highly personal keyword)
  memory2Tags: [String]    // Second memory keyword tags (1-3 tags, recommended 1 highly personal keyword)
}
```

### 2.2 Location Encoding

```
keyMaterial = processedMemory(UTF-8) + cellIndex(8 bytes big-endian)
```

**Encoding Rules:**
- `processedMemory`: All tags normalized, merged, deduplicated, sorted by Unicode order, and concatenated without separators
- `cellIndex`: F9Grid cell index, 8-byte big-endian (see Appendix C)

---

## 3. Encrypted Backup (Memory Forgiveness Fault Tolerance)

### 3.1 Design Rationale

To enable "recovery with only 3 locations," the protocol generates C(5,3)=10 independent encrypted blocks. Each block is encrypted with a key derived from a different 3-location combination.

```
10 Combinations:
  {0,1,2} {0,1,3} {0,1,4} {0,2,3} {0,2,4}
  {0,3,4} {1,2,3} {1,2,4} {1,3,4} {2,3,4}
```

### 3.2 Encryption Algorithm

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

---

## 4. Recovery Algorithm

### 4.1 Method 1: Encrypted Backup Recovery

**Applicable Scenario:** User has encrypted backup file but only remembers 3-5 locations

**Recovery Process:**
1. Enumerate all combinations of N known locations choose 3
2. Enumerate all combinations of 5 position codes choose 3 (10 combinations)
3. For each combination, derive key using Argon2id and attempt to decrypt the 10 encrypted blocks
4. Return mnemonic when decryption succeeds and checksum passes

### 4.2 Method 2: Full Memory Recovery

**Applicable Scenario:** User has no backup file but completely remembers all 5 locations, memory keywords, and 5 position codes
Use the same generation logic to recover the mnemonic. Position codes are needed to correct GPS drift and find the original grid ID.

---

## Appendix A: Salt Derivation

Generate Argon2id salt from personal identifier (16 bytes):

```
salt = BLAKE2b-128(UTF8(Normalize(identifier)) + UTF8("WUJI-Key-V1:Memory-Based Seed Phrases"))
```

- Output: 16 bytes (128 bits)
- Version suffix ensures salt changes with protocol upgrades

---

## Appendix B: Text Normalization

### B.1 Normalization Pipeline

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

### B.2 Punctuation Mapping

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

## Appendix C: F9Grid Encoding

### C.1 Cell Index

**Purpose:** Convert geographic coordinates to hierarchical cell unique identifier

```
cellIndex = F9Grid.CellIndex(lat, lng)  // Int64
```

**Encoding Rules:**
- Input: Latitude and longitude coordinates (lat, lng)
- Output: Int64 cell index
- Encoding: 8-byte big-endian

### C.2 Position Code

**Purpose:** Correct GPS drift by identifying coordinate position within cell

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

**How it works:**
- GPS drift may cause coordinates to fall into adjacent cells
- Position code records original coordinate position within cell
- During recovery, position code helps find the original cell index

**Interfaces:**

| Function | Input | Output | Description |
|----------|-------|--------|-------------|
| `CellIndex` | (lat, lng) | Int64 | Hierarchical cell unique identifier |
| `PositionCode` | (lat, lng) | 1-9 | 9-grid position within cell |
| `FindOriginalCell` | (lat, lng, code) | Int64 | Correct GPS drift using position code |

---

## References

- [BIP39: Mnemonic code for generating deterministic keys](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [Argon2: Password Hashing Function](https://datatracker.ietf.org/doc/html/rfc9106)
- [BLAKE2: Secure Hash Function](https://www.blake2.net/)
- [XChaCha20-Poly1305](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-xchacha)
