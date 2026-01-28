//
//  WujiName.swift
//  WujiKey
//
//  Name fragment - encapsulates name with normalization and salt generation
//

import Foundation

/// Name fragment for mnemonic generation
/// Handles normalization and BLAKE2b salt generation
struct WujiName {

    // MARK: - Properties

    /// Normalized name (read-only, computed from raw input)
    let normalized: String

    /// Salt for Argon2id (16 bytes, BLAKE2b-128 hash of normalized name)
    let salt: Data

    // MARK: - Initialization

    /// Create from raw text (auto-normalizes and generates salt)
    ///
    /// Salt generation follows whitepaper spec:
    /// BLAKE2b-128(Normalize(name) + "WUJI-Key-V1:Memory-Based Seed Phrases")
    ///
    /// - Parameter raw: Raw name text input
    /// - Returns: WujiName if normalization and hash succeed, nil otherwise
    init?(raw: String) {
        let normalized = WujiNormalizer.normalize(raw)
        guard !normalized.isEmpty else { return nil }
        self.normalized = normalized

        // Generate 16-byte salt using BLAKE2b (with version suffix per whitepaper)
        let textWithSuffix = normalized + CryptoUtils.WujiBlake2bSaltSuffix
        guard let hash = CryptoUtils.blake2b(string: textWithSuffix, outputLength: CryptoUtils.WujiArgon2idSaltLength) else {
            return nil
        }
        self.salt = hash
    }

    // MARK: - Validation

    /// Whether name is valid (non-empty and has correct salt length)
    var isValid: Bool {
        !normalized.isEmpty && salt.count == CryptoUtils.WujiArgon2idSaltLength
    }
}

// MARK: - Equatable

extension WujiName: Equatable {
    static func == (lhs: WujiName, rhs: WujiName) -> Bool {
        lhs.normalized == rhs.normalized
    }
}

// MARK: - CustomStringConvertible

extension WujiName: CustomStringConvertible {
    var description: String {
        "WujiName(\"\(normalized.prefix(20))...\")"
    }
}
