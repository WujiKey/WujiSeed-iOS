# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

**📋 For detailed architecture, development workflow, and project conventions, see [openspec/config.yaml](openspec/config.yaml)**

## Project Overview

WujiSeed is an iOS application that generates BIP39 mnemonic phrases using a memory-based system. Users create mnemonics by combining a personal identifier with 5 meaningful geographic locations and associated memories.

**Key Technologies**: Swift 5, UIKit (programmatic), Swift-Sodium, F9Grid
**Platform**: iOS 12.0+
**Security**: Offline-first, memory-only (no persistence), BIP39 compliant

## Quick Commands

```bash
# Build (Debug)
xcodebuild -project WujiSeed.xcodeproj -scheme WujiSeed -configuration Debug \
  -destination 'platform=iOS Simulator,id=C4F92C22-C0C1-45DF-BC81-B52C77D41A22' build

# Run all tests
xcodebuild test -project WujiSeed.xcodeproj -scheme WujiSeed \
  -destination 'platform=iOS Simulator,id=C4F92C22-C0C1-45DF-BC81-B52C77D41A22'

# Run specific test class
xcodebuild test -project WujiSeed.xcodeproj -scheme WujiSeed \
  -destination 'platform=iOS Simulator,id=C4F92C22-C0C1-45DF-BC81-B52C77D41A22' \
  -only-testing:WujiSeedTests/WujiRegressionTests
```

## Architecture Summary

### Core Flow
1. **Name Input** → Text normalization → BLAKE2b-256 salt generation
2. **Places & Memories** → F9Grid encoding + position codes (1-9) → Tag processing
3. **Key Derivation** → Argon2id (password=locations+memories, salt=name salt)
4. **Mnemonic Generation** → BIP39 24-word phrase
5. **Backup** → XChaCha20-Poly1305 encryption + 3-of-5 Shamir secret sharing

### Key Components
- **WujiLib/**: Business logic (crypto, normalization, geo encoding)
- **UI/**: View controllers (wizard flow, no persistence)
- **Common/**: Shared utilities (Theme, LanguageManager)

### Critical Algorithms
```
Text Normalization: AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))
Salt Generation:    BLAKE2b-256(Normalize(name) + "Forgetless-V1")
Geographic:         F9Grid cell index + 9-grid position code (1-9 layout)
KDF:                Argon2id (3 presets: Fast/Balanced/Intensive)
```

**9-Grid Position Layout:**
```
4(NW)  9(N)   2(NE)
3(W)   5(C)   7(E)
8(SW)  1(S)   6(SE)
```

## Development Workflow

**This project uses OpenSpec for structured development:**

1. **Before implementing features**: Check `openspec/changes/` for active changes
2. **For new features**: Use OpenSpec workflow (proposal → tasks → implementation → verification)
3. **Architecture & conventions**: See `openspec/config.yaml`
4. **All changes**: Follow rules defined in `openspec/config.yaml`

## Testing Requirements

- **Golden Vectors**: `wujikey_v1_vector_1.json` (Journey to the West), `wujikey_v1_vector_2.json` (Moses Exodus)
- **Regression Tests**: Must pass after any crypto/normalization changes
- **Coverage**: All WujiLib business logic must have unit tests
- **Simulator**: iPhone 17 (iOS 26.2) - `C4F92C22-C0C1-45DF-BC81-B52C77D41A22`

## Localization

All user-facing text must have translations in **5 languages**:
- `en.lproj` (English)
- `zh-Hans.lproj` (Simplified Chinese)
- `zh-Hant.lproj` (Traditional Chinese)
- `ja.lproj` (Japanese)
- `es.lproj` (Spanish)

Use `LanguageManager` for runtime language switching.

## Important Constraints

- ⚠️ **No Storyboards/XIBs** - All UI is programmatic
- ⚠️ **No Persistence** - Mnemonics only in memory during session
- ⚠️ **Offline-First** - No network calls ever
- ⚠️ **Whitepaper Authority** - Specification takes precedence over code
- ⚠️ **Backward Compatibility** - Current version uses F9Grid (NOT PlusCode)
- ⚠️ **Test Coverage** - WujiLib changes require corresponding tests

## File References

- `openspec/config.yaml` - Architecture, tech stack, development rules
- `TOOLS.md` - Local development notes and commands
- `WujiSeedTests/GoldenVectors/README.md` - Test vector documentation
