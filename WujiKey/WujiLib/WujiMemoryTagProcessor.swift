//
//  WujiMemoryTagProcessor.swift
//  WujiKey
//
//  Tag-based memory processor
//  Processes memory fragments as discrete tags: normalize each tag, sort, deduplicate, concatenate
//

import Foundation

/// Processor for tag-based memory input
/// Converts an array of keyword tags into a normalized, sorted, deduplicated string
class WujiMemoryTagProcessor {

    // MARK: - Public Methods

    /// Process tags into final normalized string (sorted + concatenated)
    ///
    /// This is the FINAL step for crypto operations.
    /// Use `normalizedTags()` during collection/display, then `process()` only at final usage.
    ///
    /// Processing flow for each tag:
    /// 1. Trim whitespace
    /// 2. NFKC normalization
    /// 3. CaseFold
    /// 4. AsciiPunctNorm
    /// (Note: CollapseWS is skipped since individual tags should not contain internal spaces)
    ///
    /// Then:
    /// - Filter empty tags
    /// - Remove duplicates (case-insensitive after normalization)
    /// - Sort by Unicode order
    /// - Concatenate without separator
    ///
    /// - Parameter tags: Array of raw tag strings (can be normalized or raw)
    /// - Returns: Final normalized string for crypto operations
    static func process(_ tags: [String]) -> String {
        return tags
            .map { normalizeTag($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .sorted()
            .joined()
    }

    /// Normalize tags without sorting or concatenating
    ///
    /// Use this during tag collection and display.
    /// Sort and concatenation should only happen at final usage (crypto operations).
    ///
    /// - Parameter tags: Array of raw tag strings
    /// - Returns: Array of normalized, deduplicated tags (order preserved from input)
    static func normalizedTags(_ tags: [String]) -> [String] {
        return tags
            .map { normalizeTag($0) }
            .filter { !$0.isEmpty }
            .uniqued()
    }

    /// Normalize a single tag
    ///
    /// Uses WujiNormalizer for full normalization including CollapseWS
    /// This ensures consistent handling of all whitespace characters (full-width space, tabs, zero-width space, etc.)
    ///
    /// - Parameter tag: Raw tag string
    /// - Returns: Normalized tag
    static func normalizeTag(_ tag: String) -> String {
        // Use WujiNormalizer for consistent normalization
        // Flow: NFKC → CaseFold → Trim → CollapseWS → AsciiPunctNorm
        return WujiNormalizer.normalize(tag)
    }

    /// Parse a single input string into tags
    /// Splits by comma, semicolon (full/half-width)
    /// Space is only used as separator when input contains CJK characters
    ///
    /// - Parameter input: Raw input string
    /// - Returns: Array of tag strings
    static func parseTags(from input: String) -> [String] {
        // Base separators: comma, semicolon (both half and full-width), Chinese enumeration comma, tab, newline
        var separators = ",;，；、\t\n"

        // Only add space as separator if input contains CJK characters
        // This allows English phrases like "New York" to remain as one tag
        if containsCJKCharacters(input) {
            separators += " "
        }

        let separatorSet = CharacterSet(charactersIn: separators)

        return input
            .components(separatedBy: separatorSet)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Check if string contains CJK (Chinese, Japanese, Korean) characters
    static func containsCJKCharacters(_ string: String) -> Bool {
        for scalar in string.unicodeScalars {
            // CJK Unified Ideographs and common CJK ranges
            if (0x4E00...0x9FFF).contains(scalar.value) ||    // CJK Unified Ideographs
               (0x3400...0x4DBF).contains(scalar.value) ||    // CJK Extension A
               (0x3000...0x303F).contains(scalar.value) ||    // CJK Punctuation
               (0x3040...0x309F).contains(scalar.value) ||    // Hiragana
               (0x30A0...0x30FF).contains(scalar.value) ||    // Katakana
               (0xAC00...0xD7AF).contains(scalar.value) {     // Korean Hangul
                return true
            }
        }
        return false
    }

    /// Validate tag count
    ///
    /// - Parameters:
    ///   - tags: Array of tags
    ///   - minimum: Minimum required count (default 3)
    /// - Returns: Whether tag count is valid
    static func isValidCount(_ tags: [String], minimum: Int = 3) -> Bool {
        let processed = tags
            .map { normalizeTag($0) }
            .filter { !$0.isEmpty }
            .uniqued()

        return processed.count >= minimum
    }

    /// Get count of unique normalized tags
    ///
    /// - Parameter tags: Array of raw tags
    /// - Returns: Count after normalization and deduplication
    static func uniqueCount(_ tags: [String]) -> Int {
        return tags
            .map { normalizeTag($0) }
            .filter { !$0.isEmpty }
            .uniqued()
            .count
    }

}

// MARK: - Array Extension for Unique

private extension Array where Element: Hashable {
    /// Remove duplicates while preserving order
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
