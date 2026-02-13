//
//  WujiNormalizer.swift
//  WujiSeed
//
//  Protocol normalization implementation
//  Normalization flow: AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))
//

import Foundation

/// F9 Text Normalization Utility Class
/// Implements the protocol-defined normalization flow to ensure consistent output from different inputs
class WujiNormalizer {

    // MARK: - Public Methods

    /// Normalize text (protocol specification)
    ///
    /// Processing flow: AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))
    /// 1. NFKC: Unicode compatibility normalization
    /// 2. CaseFold: Case folding
    /// 3. Trim: Remove leading/trailing whitespace
    /// 4. CollapseWS: Collapse multiple whitespace characters into single space
    /// 5. AsciiPunctNorm: ASCII punctuation normalization
    ///
    /// - Parameter text: Text to normalize
    /// - Returns: Normalized text
    static func normalize(_ text: String) -> String {
        var result = text

        // 1. NFKC: Unicode compatibility normalization
        result = nfkc(result)

        // 2. CaseFold: Case folding
        result = caseFold(result)

        // 3. Trim: Remove leading/trailing whitespace
        result = trim(result)

        // 4. CollapseWS: Collapse multiple whitespace characters into single space
        result = collapseWhitespace(result)

        // 5. AsciiPunctNorm: ASCII punctuation normalization
        result = asciiPunctNorm(result)

        return result
    }

    /// Check if text is properly normalized
    ///
    /// - Parameter text: Text to check
    /// - Returns: true if text is normalized, false otherwise
    static func isNormalized(_ text: String) -> Bool {
        return text == normalize(text)
    }

    /// Convert normalized text to UTF-8 encoded binary data
    ///
    /// - Parameter text: Normalized text
    /// - Returns: UTF-8 encoded binary data, nil if text is not normalized or conversion fails
    static func toUTF8Data(_ text: String) -> Data? {
        // Check if text is normalized
        guard isNormalized(text) else {
            #if DEBUG
            WujiLogger.error("WujiNormalizer: Text not normalized, please call normalize() first")
            WujiLogger.debug("Current text: \"\(text)\"")
            WujiLogger.debug("After normalization: \"\(normalize(text))\"")
            #endif
            return nil
        }

        // Convert to UTF-8 encoding
        guard let data = text.data(using: .utf8) else {
            #if DEBUG
            WujiLogger.error("WujiNormalizer: UTF-8 encoding conversion failed")
            #endif
            return nil
        }

        return data
    }

    // MARK: - Private Methods - Step by Step

    /// Step 1: NFKC - Unicode compatibility normalization
    ///
    /// Convert all compatibility characters to standard form
    /// Example: full-width letters → half-width letters, ligatures → separated letters
    ///
    /// - Parameter text: Input text
    /// - Returns: NFKC normalized text
    private static func nfkc(_ text: String) -> String {
        // Swift's precomposedStringWithCompatibilityMapping corresponds to NFKC
        return text.precomposedStringWithCompatibilityMapping
    }

    /// Step 2: CaseFold - Case folding
    ///
    /// Stricter case conversion than lowercased(), suitable for case-insensitive comparison
    /// Example: German ß → ss, Greek Σ → σ
    ///
    /// - Parameter text: Input text
    /// - Returns: Case-folded text
    private static func caseFold(_ text: String) -> String {
        // Swift's folding method corresponds to CaseFold
        return text.folding(options: .caseInsensitive, locale: nil)
    }

    /// Step 3: Trim - Remove leading/trailing whitespace
    ///
    /// Remove all whitespace characters (spaces, tabs, newlines, etc.) from start and end
    ///
    /// - Parameter text: Input text
    /// - Returns: Trimmed text
    private static func trim(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Step 4: CollapseWS - Collapse whitespace characters
    ///
    /// Collapse multiple consecutive whitespace characters (spaces, tabs, newlines, etc.) into single space
    /// Protocol definition: replaceAll(s,[ \t\n˚​]+, " ")
    ///
    /// - Parameter text: Input text
    /// - Returns: Text with collapsed whitespace
    private static func collapseWhitespace(_ text: String) -> String {
        // Regex pattern: match one or more whitespace characters
        // Includes: space, tab, newline, carriage return, non-breaking space, full-width space, zero-width space, etc.
        // Note: NSRegularExpression doesn't support \u{xxxx} syntax, need to use Unicode characters directly
        let nbsp = "\u{00A0}"            // No-break space
        let fullwidthSpace = "\u{3000}"  // Full-width space
        let zwsp = "\u{200B}"            // Zero-width space
        let wj = "\u{2060}"              // Word joiner
        let zwnbsp = "\u{FEFF}"          // Zero-width no-break space

        let whitespacePattern = "[ \\t\\n\\r\(nbsp)\(fullwidthSpace)\(zwsp)\(wj)\(zwnbsp)]+"

        do {
            let regex = try NSRegularExpression(pattern: whitespacePattern, options: [])
            let range = NSRange(text.startIndex..., in: text)
            let result = regex.stringByReplacingMatches(
                in: text,
                options: [],
                range: range,
                withTemplate: " "
            )
            return result
        } catch {
            #if DEBUG
            WujiLogger.warning("WujiNormalizer: CollapseWS regex failed, falling back to simple replacement")
            WujiLogger.debug("Error details: \(error.localizedDescription)")
            #endif
            // Fallback: simple replacement of common whitespace characters
            var result = text
            result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            result = result.replacingOccurrences(of: "\t", with: " ")
            result = result.replacingOccurrences(of: "\n", with: " ")
            result = result.replacingOccurrences(of: "\r", with: " ")
            result = result.replacingOccurrences(of: "\u{00A0}", with: " ")  // Non-breaking space
            result = result.replacingOccurrences(of: "\u{3000}", with: " ")  // Full-width space
            return result
        }
    }

    /// Step 5: AsciiPunctNorm - ASCII punctuation normalization
    ///
    /// Convert various variant punctuation marks to standard ASCII punctuation
    /// Example: full-width comma → half-width comma, Chinese period → English period
    ///
    /// - Parameter text: Input text
    /// - Returns: Text with normalized punctuation
    private static func asciiPunctNorm(_ text: String) -> String {
        var result = text

        // Punctuation mapping table (Chinese/full-width punctuation → ASCII punctuation)
        let punctuationMap: [String: String] = [
            // Chinese punctuation
            "，": ",",      // Full-width comma
            "。": ".",      // Chinese period
            "！": "!",      // Full-width exclamation mark
            "？": "?",      // Full-width question mark
            "：": ":",      // Full-width colon
            "；": ";",      // Full-width semicolon
            "（": "(",      // Full-width left parenthesis
            "）": ")",      // Full-width right parenthesis
            "【": "[",      // Chinese left bracket
            "】": "]",      // Chinese right bracket
            "、": ",",      // Enumeration comma (convert to comma)
            "《": "<",      // Chinese left book title mark
            "》": ">",      // Chinese right book title mark
            "「": "'",      // Japanese left quotation mark
            "」": "'",      // Japanese right quotation mark
            "『": "\"",     // Japanese left double quotation mark
            "』": "\"",     // Japanese right double quotation mark

            // Unicode quotation marks
            "\u{201C}": "\"",  // " (left double quotation mark)
            "\u{201D}": "\"",  // " (right double quotation mark)
            "\u{2018}": "'",   // ' (left single quotation mark)
            "\u{2019}": "'",   // ' (right single quotation mark)
            "\u{201A}": "'",   // ‚ (single low-9 quotation mark)
            "\u{201E}": "\"",  // „ (double low-9 quotation mark)

            // Dashes and hyphens
            "\u{2013}": "-",   // – (en dash)
            "\u{2014}": "-",   // — (em dash)
            "\u{2015}": "-",   // ― (horizontal bar)

            // Ellipsis
            "…": "...",        // … (horizontal ellipsis)

            // Other full-width symbols
            "＋": "+",
            "－": "-",
            "＊": "*",
            "／": "/",
            "＝": "=",
            "＜": "<",
            "＞": ">",
            "｜": "|",
            "～": "~",
            "＠": "@",
            "＃": "#",
            "＄": "$",
            "％": "%",
            "＾": "^",
            "＆": "&",
            "＿": "_",
        ]

        // Apply all mappings
        for (fullwidth, ascii) in punctuationMap {
            result = result.replacingOccurrences(of: fullwidth, with: ascii)
        }

        return result
    }
}
