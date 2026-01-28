//
//  WujiMemory.swift
//  WujiKey
//
//  Memory fragment - encapsulates a single memory text with normalization
//

import Foundation

/// Memory fragment - a single memory text for a location
/// Handles normalization (tags are merged and sorted at input layer)
struct WujiMemory {

    // MARK: - Properties

    /// Normalized memory text (read-only, computed from raw input)
    let normalized: String

    // MARK: - Initialization

    /// Create from raw text (auto-normalizes using WujiNormalizer)
    /// - Parameter raw: Raw memory text input
    init(raw: String) {
        self.normalized = WujiNormalizer.normalize(raw)
    }

    // MARK: - Validation

    /// Whether memory is non-empty after normalization
    var isValid: Bool {
        !normalized.isEmpty
    }
}

// MARK: - Equatable

extension WujiMemory: Equatable {
    static func == (lhs: WujiMemory, rhs: WujiMemory) -> Bool {
        lhs.normalized == rhs.normalized
    }
}

// MARK: - Comparable

extension WujiMemory: Comparable {
    static func < (lhs: WujiMemory, rhs: WujiMemory) -> Bool {
        lhs.normalized < rhs.normalized
    }
}

// MARK: - CustomStringConvertible

extension WujiMemory: CustomStringConvertible {
    var description: String {
        "WujiMemory(\"\(normalized.prefix(20))...\")"
    }
}
