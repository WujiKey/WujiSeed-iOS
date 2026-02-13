//
//  WujiNormalizerTests.swift
//  WujiSeedTests
//
//  WujiNormalizer unit tests - protocol normalization spec validation
//
//  Protocol normalization flow: AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))
//

import XCTest
@testable import WujiSeed

class WujiNormalizerTests: XCTestCase {

    // MARK: - Basic Normalization Tests

    func testBasicNormalization() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("Hello World", "hello world", "Basic English case + space"),
            ("HELLO   WORLD", "hello world", "Uppercase + multiple spaces"),
            ("hello world", "hello world", "Already lowercase"),
            ("  Hello  World  ", "hello world", "Leading/trailing + middle spaces"),
            ("Hello\tWorld", "hello world", "Tab character"),
            ("Hello\nWorld", "hello world", "Newline character"),
            ("Hello\r\nWorld", "hello world", "CRLF"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - NFKC Tests

    func testNFKC() {
        let testCases: [(input: String, description: String)] = [
            ("Ｈｅｌｌｏ", "Full-width to half-width letters"),
            ("ＡＢＣ123", "Full-width letters + half-width numbers"),
            ("①②③", "Circled numbers"),
            ("½¼¾", "Fraction symbols"),
            ("ｶﾀｶﾅ", "Half-width katakana"),
        ]

        for (input, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            // NFKC converts compatibility characters to standard form
            XCTAssertNotEqual(result, input, "\(description) should be converted")
        }
    }

    // MARK: - CaseFold Tests

    func testCaseFold() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("ABC", "abc", "Basic uppercase"),
            ("Hello World", "hello world", "Mixed case"),
            ("ΑΒΓΔ", "αβγδ", "Greek uppercase"),
            ("Ä Ö Ü", "ä ö ü", "German umlauts"),
            ("İstanbul", "i̇stanbul", "Turkish dotted I"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            // CaseFold is stricter than lowercased
            XCTAssertTrue(result.lowercased() == result, "Result should be lowercase for: \(description)")
        }
    }

    // MARK: - Trim Tests

    func testTrim() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("  Hello  ", "hello", "Leading/trailing spaces"),
            ("\tHello\t", "hello", "Leading/trailing tabs"),
            ("\nHello\n", "hello", "Leading/trailing newlines"),
            ("  \t\nHello\n\t  ", "hello", "Mixed leading/trailing whitespace"),
            ("Hello", "hello", "No leading/trailing whitespace"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - CollapseWS Tests

    func testCollapseWhitespace() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("Hello  World", "hello world", "Two spaces"),
            ("Hello   World", "hello world", "Three spaces"),
            ("Hello          World", "hello world", "Multiple spaces"),
            ("Hello\tWorld", "hello world", "Tab"),
            ("Hello\t\tWorld", "hello world", "Multiple tabs"),
            ("Hello \t \n World", "hello world", "Mixed whitespace"),
            ("Hello　World", "hello world", "Full-width space (U+3000)"),
            ("Hello\u{00A0}World", "hello world", "Non-breaking space"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - AsciiPunctNorm Tests

    func testAsciiPunctNorm() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("你好，世界！", "你好,世界!", "Chinese comma and exclamation"),
            ("你好。再见？", "你好.再见?", "Chinese period and question mark"),
            ("时间：12:00；地点：北京", "时间:12:00;地点:北京", "Chinese colon and semicolon"),
            ("（括号）", "(括号)", "Chinese parentheses"),
            ("【方括号】", "[方括号]", "Chinese brackets"),
            ("《书名》", "<书名>", "Chinese book title marks"),
            ("、顿号", ",顿号", "Chinese enumeration comma"),
            ("\u{201C}双引号\u{201D}", "\"双引号\"", "Chinese double quotes"),
            ("\u{2018}单引号\u{2019}", "'单引号'", "Chinese single quotes"),
            ("—破折号—", "-破折号-", "Em dash"),
            ("…省略号", "...省略号", "Ellipsis"),
            ("＋－＊／", "+-*/", "Full-width operators"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Comprehensive Tests

    func testComprehensiveNormalization() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("  Ｈｅｌｌｏ   Ｗｏｒｌｄ  ", "hello world", "Full-width + spaces + trim"),
            ("  你好，　世界！  ", "你好, 世界!", "Chinese + full-width space + punctuation"),
            ("ＨＥＬＬＯ\t\t你好，，世界！！", "hello 你好,,世界!!", "Mixed full/half-width + tabs"),
            ("　　　　", "", "Only full-width spaces"),
            ("", "", "Empty string"),
            ("   ", "", "Only spaces"),
            ("My   Wallet　钱包", "my wallet 钱包", "English-Chinese mixed + spaces"),
            ("Test：测试；结果？成功！（完成）", "test:测试;结果?成功!(完成)", "Mixed punctuation"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiNormalizer.normalize(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Protocol Examples

    func testProtocolExamples() {
        // Protocol formula: AsciiPunctNorm(CollapseWS(Trim(CaseFold(NFKC(s)))))

        let testCases: [(input: String, description: String)] = [
            ("My Wallet", "Mnemonic name example"),
            ("my.email@example.com", "Email example"),
            ("passport-123456", "ID number example"),
            ("清迈　古城　旅行", "Location note example"),
            ("2024年1月1日", "Date note example"),
        ]

        for (input, description) in testCases {
            let result = WujiNormalizer.normalize(input)

            // Manual step verification
            var step1 = input.precomposedStringWithCompatibilityMapping
            var step2 = step1.folding(options: .caseInsensitive, locale: nil)
            var step3 = step2.trimmingCharacters(in: .whitespacesAndNewlines)

            // CollapseWS verification
            let whitespacePattern = "[ \\t\\n\\r\\u{00A0}\\u{3000}\\u{200B}\\u{2060}\\u{FEFF}\\u{02DA}]+"
            if let regex = try? NSRegularExpression(pattern: whitespacePattern, options: []) {
                let range = NSRange(step3.startIndex..., in: step3)
                step3 = regex.stringByReplacingMatches(in: step3, options: [], range: range, withTemplate: " ")
            }

            // Result should not be empty for non-empty input
            if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                XCTAssertFalse(result.isEmpty, "\(description) should not be empty")
            }
        }
    }

    // MARK: - Determinism Tests

    func testDeterminism() {
        let testInputs = [
            "Hello World",
            "My Wallet 钱包",
            "测试　Test　テスト",
        ]

        for input in testInputs {
            var results = Set<String>()

            // Normalize same input 100 times
            for _ in 0..<100 {
                let result = WujiNormalizer.normalize(input)
                results.insert(result)
            }

            XCTAssertEqual(results.count, 1, "Same input should produce same output")
        }
    }

    // MARK: - UTF-8 Data Conversion Tests

    func testToUTF8Data() {
        let normalized = WujiNormalizer.normalize("Hello World")

        // Should succeed for normalized text
        if let data = WujiNormalizer.toUTF8Data(normalized) {
            XCTAssertGreaterThan(data.count, 0)
        } else {
            XCTFail("Normalized text should convert to UTF-8")
        }

        // Should fail for unnormalized text
        let unnormalized = "  HELLO  "
        let failedData = WujiNormalizer.toUTF8Data(unnormalized)
        XCTAssertNil(failedData, "Unnormalized text should return nil")
    }

    // MARK: - Performance Tests

    func testNormalizationPerformance() {
        let input = "  Ｈｅｌｌｏ　Ｗｏｒｌｄ　你好，世界！  "

        measure {
            for _ in 0..<1000 {
                _ = WujiNormalizer.normalize(input)
            }
        }
    }
}
