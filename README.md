# WUJI Seed (無跡)

> Turn unforgettable memories into recoverable seed phrases.

WUJI Seed is an iOS app that generates high-entropy BIP39 mnemonic phrases from memorable personal inputs — your identity, geographic locations, and associated memories. Unlike traditional random number generators, WUJI Seed allows you to deterministically regenerate the same mnemonic offline, anytime.

English | [中文](README.zh-CN.md)

---

## Features

- **Deterministic Generation** — Same inputs always produce the same mnemonic
- **High Security** — Combined entropy exceeds 274 bits
- **Fully Offline** — All cryptographic operations are local, no network requests
- **BIP39 Compatible** — Generates standard 24-word mnemonics
- **3-of-5 Fault Tolerance** — Recover with any 3 of 5 location-memory pairs
- **Multilingual** — English, 简体中文, 繁體中文, 日本語, Español

## How It Works

### Generation Flow

1. **Personal Identifier** → BLAKE2b-128 generates 16-byte random salt
2. **5 Location-Memory Pairs** → F9Grid encoding + text normalization → sorted concatenation
3. **Argon2id KDF** (256MB / 7 iterations) → 256-bit master key
4. **BIP39 Encoding** → 256 bits + 8-bit checksum → 24 mnemonic words

### Recovery Methods

- **Method 1**: Encrypted backup + identifier + any 3 of 5 location-memory pairs
- **Method 2**: Position codes + identifier + all 5 location-memory pairs (no backup needed)

## Technical Specifications

| Component | Specification |
|-----------|---------------|
| Key Derivation | Argon2id (256MB, 7 iterations, 1 thread) |
| Salt Generation | BLAKE2b-128 (16 bytes) |
| Encryption | XChaCha20-Poly1305 AEAD |
| Fault Tolerance | C(5,3) combinatorial encryption (10 encrypted blocks) |
| Geographic Encoding | F9Grid hierarchical grid system |
| Mnemonic | BIP39 standard (256 bits + 8-bit checksum) |

## Build

### Requirements

- iOS 12.0+
- Xcode 14.0+
- Swift 5.0+


## Dependencies

- [Swift-Sodium](https://github.com/jedisct1/swift-sodium) 0.9.1 — Argon2id implementation
- [F9Grid](https://github.com/WujiKey/F9Grid) — Geographic grid encoding

## Documentation

- [WujiSeed Protocol Specification (English)](Docs/WujiSeed-Technical-Specification.md)
- [WujiSeed 协议规范 (中文)](Docs/WujiSeed-Technical-Specification-zh.md)

## Security Notes

- Use on a dedicated offline device
- Enable airplane mode before running
- Mnemonics are kept in memory only, cleared on exit
- Choose 5 locations that are dispersed and private
- Avoid using publicly known information for memories

## License

Apache License 2.0

---

**WUJI Seed** — For the Memories That Never Fade | 無跡 無記 無所顧忌
