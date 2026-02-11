# WujiTimeCapsule Specification

**Version:** 1.0
**Status:** Draft
**Last Updated:** 2024-12

## Overview

WujiTimeCapsule is an encrypted binary format designed for secure backup and cross-device transfer of 24-word BIP39 mnemonics. It uses XChaCha20-Poly1305 AEAD encryption with redundant key derivation from geographic location data, enabling recovery with only 3 out of 5 location inputs.

## Design Goals

1. **Security**: Military-grade encryption (XChaCha20-Poly1305) with 256-bit keys
2. **Redundancy**: C(5,3)=10 encrypted blocks allow recovery with any 3 of 5 locations
3. **Portability**: Self-contained binary format for cross-device transfer
4. **Integrity**: CRC32 checksum for data corruption detection
5. **Simplicity**: Minimal format with no external dependencies

## Binary Format

### Structure Overview

```
┌─────────────────────────────────────────────────────────┐
│ Header                                                  │
├─────────────────────────────────────────────────────────┤
│   Magic (4 bytes)           57 55 4A 49                 │
│   Version (1 byte)          01                          │
│   Options (1 byte)          00 (reserved)               │
│   Payload Length (2 bytes)  Big-endian                  │
├─────────────────────────────────────────────────────────┤
│ Payload                                                 │
├─────────────────────────────────────────────────────────┤
│   Position Codes (3 bytes)  5 codes packed              │
│   AEAD Section                                          │
│     Block Count (1 byte)    10 (C(5,3) combinations)    │
│     Encrypted Blocks × 10                               │
│       Block Length (2 bytes)                            │
│       Nonce (24 bytes)                                  │
│       Ciphertext (variable)                             │
│       Tag (16 bytes)                                    │
├─────────────────────────────────────────────────────────┤
│ Checksum                                                │
├─────────────────────────────────────────────────────────┤
│   CRC32 (4 bytes)           Big-endian                  │
└─────────────────────────────────────────────────────────┘
```

### Field Definitions

#### Magic (4 bytes)
```
Offset: 0x00
Value:  57 55 4A 49
```
- `57 55 4A 49`: ASCII for "WUJI"

#### Version (1 byte)
```
Offset: 0x04
Value:  0x01
```
Current version is `0x01`. Future versions may introduce additional fields or algorithms.

#### Options (1 byte)
```
Offset: 0x05
Value:  0x00
```
Reserved for future use. Currently must be `0x00`.

#### Payload Length (2 bytes)
```
Offset: 0x06
Format: Big-endian unsigned 16-bit integer
```
Length in bytes of all content following this field, including the CRC32 checksum.

#### Position Codes (3 bytes)
```
Offset: 0x08
Format: Packed nibbles
```
Five position codes (1-9) packed into 3 bytes:

| Byte | High Nibble | Low Nibble |
|------|-------------|------------|
| 0    | Code 1      | Code 2     |
| 1    | Code 3      | Code 4     |
| 2    | Code 5      | (unused)   |

Position codes represent the 9-grid position:
```
4(NW)  9(N)   2(NE)
3(W)   5(C)   7(E)
8(SW)  1(S)   6(SE)
```

#### Block Count (1 byte)
```
Offset: 0x0B
Value:  0x0A (10)
```
Number of encrypted blocks. Always 10 for C(5,3) combinations.

#### Encrypted Blocks (repeated)

Each block contains:

| Field | Size | Description |
|-------|------|-------------|
| Block Length | 2 bytes | Total length (nonce + ciphertext + tag), Big-endian |
| Nonce | 24 bytes | Random XChaCha20 nonce |
| Ciphertext | variable | Encrypted mnemonic words |
| Tag | 16 bytes | Poly1305 authentication tag |

#### CRC32 Checksum (4 bytes)
```
Offset: End - 4
Format: Big-endian unsigned 32-bit integer
```
CRC32 checksum calculated over all preceding bytes (Magic through last encrypted block).

Polynomial: `0xEDB88320` (IEEE 802.3)

## Encryption Scheme

### Algorithm
- **Cipher**: XChaCha20-Poly1305 AEAD
- **Key Size**: 256 bits (32 bytes)
- **Nonce Size**: 192 bits (24 bytes)
- **Tag Size**: 128 bits (16 bytes)

### Key Derivation

For each of the 10 combinations (choosing 3 from 5 locations):

```
input = keyMaterial1 + "|" + keyMaterial2 + "|" + keyMaterial3 + "|" + "WujiTimeCapsule-V1"
key = BLAKE2b-256(input)
```

Where `keyMaterial` is externally pre-processed data (typically: normalized note + F9Grid cell ID).

### Associated Data (AAD)

AEAD authentication covers:
```
AAD = Magic (4) + Version (1) + Options (1) + PositionCodes (3)
```
Total: 9 bytes

### Plaintext Format

The 24 mnemonic words are joined with single spaces:
```
word1 word2 word3 ... word24
```
Encoded as UTF-8.

## Operations

### Encryption Process

1. Validate inputs:
   - 24 mnemonic words
   - 5 location inputs with position codes (1-9)

2. Generate 10 encrypted blocks:
   - For each combination of 3 locations
   - Derive key using BLAKE2b-256
   - Generate random 24-byte nonce
   - Encrypt plaintext with XChaCha20-Poly1305

3. Serialize to binary:
   - Write header (Magic, Version, Options)
   - Calculate and write Payload Length
   - Write Position Codes
   - Write Block Count and all encrypted blocks
   - Calculate and append CRC32

### Decryption Process

1. Parse and validate binary data:
   - Verify Magic bytes
   - Check CRC32 integrity

2. Verify position codes match input locations

3. Attempt decryption:
   - For each encrypted block (corresponding to a 3-location combination)
   - Derive key from the same 3 locations
   - Attempt AEAD decryption
   - If successful, return the 24 mnemonic words

4. Any single successful decryption is sufficient

## Security Considerations

### Strengths
- XChaCha20-Poly1305 provides IND-CCA2 security
- 192-bit nonces eliminate nonce reuse concerns
- BLAKE2b key derivation is resistant to length extension attacks
- Redundant encryption allows partial location recovery

### Recommendations
- Store WUJI files separately from location hints
- Use strong, memorable location notes with high entropy
- Verify mnemonic correctness after decryption (BIP39 checksum)
- Securely delete temporary files after operations

### Threat Model
- **Protected**: Data at rest, transmission interception
- **Not Protected**: Active attacker with access to locations, side-channel attacks

## Implementation Notes

### Minimum File Size

With 24 BIP39 words (average ~80 characters):
```
Header:         8 bytes
Position Codes: 3 bytes
Block Count:    1 byte
Per Block:      2 + 24 + ~80 + 16 = ~122 bytes
10 Blocks:      ~1220 bytes
CRC32:          4 bytes
─────────────────────────────
Total:          ~1236 bytes
```

### Endianness

All multi-byte integers use **Big-endian** byte order.

### Error Handling

| Error | Cause |
|-------|-------|
| Invalid Magic | Not an WUJI file |
| CRC32 Mismatch | Data corruption |
| Position Code Mismatch | Wrong locations provided |
| Decryption Failed | Incorrect location data |

## File Extension

Recommended: `.wuji`

MIME Type (proposed): `application/x-wuji`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 0x01 | 2024-12 | Initial specification |

## References

- [BIP39: Mnemonic code for generating deterministic keys](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
- [XChaCha20-Poly1305](https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-xchacha)
- [BLAKE2: Fast Secure Hashing](https://www.blake2.net/)
- [F9Grid Coordinate System](./F9Grid_Spec.md)
