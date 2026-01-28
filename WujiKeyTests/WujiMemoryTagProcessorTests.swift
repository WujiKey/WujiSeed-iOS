//
//  WujiMemoryTagProcessorTests.swift
//  WujiKeyTests
//
//  WujiMemoryTagProcessor unit tests
//  Tag processor: normalize, deduplicate, sort, concatenate
//

import XCTest
@testable import WujiKey

class WujiMemoryTagProcessorTests: XCTestCase {

    // MARK: - Basic Processing Tests

    func testBasicProcessing() {
        let testCases: [(input: [String], expected: String, description: String)] = [
            (["花果山", "水帘洞", "山腰"], "山腰水帘洞花果山", "Basic Chinese tags"),
            (["apple", "banana", "cherry"], "applebananacherry", "Basic English tags"),
            (["ABC", "abc", "Abc"], "abc", "Case deduplication"),
            (["hello", "world"], "helloworld", "Two tags"),
            (["single"], "single", "Single tag"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiMemoryTagProcessor.process(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Tag Normalization Tests

    func testTagNormalization() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("Hello", "hello", "Uppercase to lowercase"),
            ("  hello  ", "hello", "Trim whitespace"),
            ("ＨＥＬＬＯ", "hello", "Full-width to half-width"),
            ("你好，世界", "你好,世界", "Chinese punctuation to ASCII"),
            ("Test！", "test!", "Chinese exclamation mark"),
            ("（括号）", "(括号)", "Chinese parentheses"),
            ("", "", "Empty string"),
            ("   ", "", "Only whitespace"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiMemoryTagProcessor.normalizeTag(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Whitespace Normalization Tests

    func testWhitespaceNormalization() {
        let testCases: [(input: String, expected: String, description: String)] = [
            // Full-width space
            ("New　York", "new york", "Full-width space (U+3000)"),
            ("hello　　world", "hello world", "Multiple full-width spaces"),

            // Tab characters
            ("hello\tworld", "hello world", "Tab character"),
            ("hello\t\tworld", "hello world", "Multiple tabs"),

            // Mixed whitespace
            ("hello \t world", "hello world", "Mixed space and tab"),
            ("hello\n\nworld", "hello world", "Multiple newlines"),
            ("hello \t\n world", "hello world", "Mixed whitespace types"),

            // Non-breaking space
            ("hello\u{00A0}world", "hello world", "Non-breaking space (U+00A0)"),

            // Zero-width space
            ("hello\u{200B}world", "hello world", "Zero-width space (U+200B)"),

            // Word joiner
            ("hello\u{2060}world", "hello world", "Word joiner (U+2060)"),

            // BOM / Zero-width no-break space
            ("hello\u{FEFF}world", "hello world", "ZWNBSP/BOM (U+FEFF)"),

            // Combined cases
            ("New　York\tCity", "new york city", "Full-width space + tab"),
            ("hello\u{200B}\u{3000}world", "hello world", "Zero-width + full-width space"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiMemoryTagProcessor.normalizeTag(input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Tag Parsing Tests

    func testTagParsing() {
        let testCases: [(input: String, expected: [String], description: String)] = [
            ("花果山 水帘洞 山腰", ["花果山", "水帘洞", "山腰"], "Space separated"),
            ("花果山,水帘洞,山腰", ["花果山", "水帘洞", "山腰"], "Half-width comma separated"),
            ("花果山，水帘洞，山腰", ["花果山", "水帘洞", "山腰"], "Full-width comma separated"),
            ("花果山;水帘洞;山腰", ["花果山", "水帘洞", "山腰"], "Half-width semicolon separated"),
            ("花果山；水帘洞；山腰", ["花果山", "水帘洞", "山腰"], "Full-width semicolon separated"),
            ("花果山、水帘洞、山腰", ["花果山", "水帘洞", "山腰"], "Chinese enumeration comma"),
            ("花果山 水帘洞,山腰；test", ["花果山", "水帘洞", "山腰", "test"], "Mixed separators"),
            ("  花果山  ,  水帘洞  ", ["花果山", "水帘洞"], "Extra whitespace"),
            ("", [], "Empty string"),
            ("   ", [], "Only whitespace"),
            ("单个标签", ["单个标签"], "No separator"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiMemoryTagProcessor.parseTags(from: input)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Deduplication Tests

    func testDeduplication() {
        let testCases: [(input: [String], expectedCount: Int, description: String)] = [
            (["apple", "Apple", "APPLE"], 1, "Case duplicates"),
            (["hello", "world", "hello"], 2, "Exact duplicates"),
            (["Ａ", "A", "ａ"], 1, "Full/half-width duplicates"),
            (["test", "Test", "TEST", "tEsT"], 1, "Multiple case variants"),
            (["unique1", "unique2", "unique3"], 3, "No duplicates"),
        ]

        for (input, expectedCount, description) in testCases {
            let count = WujiMemoryTagProcessor.uniqueCount(input)
            XCTAssertEqual(count, expectedCount, "\(description) failed")
        }
    }

    // MARK: - Unicode Sorting Tests

    func testUnicodeSorting() {
        // Test sorting order correctness
        let testCases: [(input: [String], description: String)] = [
            (["c", "a", "b"], "English letters"),
            (["花果山", "水帘洞", "山腰"], "Chinese characters"),
            (["123", "abc", "中文"], "Mixed characters"),
            (["Z", "a", "M"], "Mixed case (sorted after normalization)"),
        ]

        for (input, description) in testCases {
            let result = WujiMemoryTagProcessor.process(input)
            let normalized = input.map { WujiMemoryTagProcessor.normalizeTag($0) }
                .filter { !$0.isEmpty }
            let sortedNormalized = normalized.sorted()

            // Verify result is sorted concatenation
            let expectedResult = sortedNormalized.joined()
            XCTAssertEqual(result, expectedResult, "\(description) sorting failed")
        }
    }

    // MARK: - Concatenation Tests

    func testConcatenation() {
        let testCases: [(input: [String], expected: String, description: String)] = [
            (["a", "b", "c"], "abc", "Simple concatenation"),
            (["花", "果", "山"], "山果花", "Chinese concatenation (sorted)"),
            (["hello", "world"], "helloworld", "English concatenation"),
            (["你好", "world"], "world你好", "Mixed (English first)"),
        ]

        for (input, expected, description) in testCases {
            let result = WujiMemoryTagProcessor.process(input)

            // Verify no space separator
            XCTAssertFalse(result.contains(" "), "Result should not contain space separator")
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Validation Tests

    func testValidation() {
        let testCases: [(input: [String], minimum: Int, expected: Bool, description: String)] = [
            (["a", "b", "c"], 3, true, "Exactly 3 tags, minimum 3"),
            (["a", "b"], 3, false, "Only 2 tags, minimum 3"),
            (["a", "b", "c", "d"], 3, true, "4 tags, minimum 3"),
            (["a", "A", "b"], 3, false, "Only 2 after dedup, minimum 3"),
            (["", "  ", "a"], 3, false, "Only 1 valid tag"),
            ([], 3, false, "Empty array"),
            (["a", "b", "c", "d", "e"], 5, true, "5 tags, minimum 5"),
        ]

        for (input, minimum, expected, description) in testCases {
            let result = WujiMemoryTagProcessor.isValidCount(input, minimum: minimum)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Edge Cases Tests

    func testEdgeCases() {
        // Empty input
        XCTAssertEqual(WujiMemoryTagProcessor.process([]), "", "Empty array should return empty string")
        XCTAssertEqual(WujiMemoryTagProcessor.process([""]), "", "Array with empty string should return empty")
        XCTAssertEqual(WujiMemoryTagProcessor.process(["", "  ", "\t"]), "", "Only whitespace should return empty")

        // Special characters
        let specialChars = ["@#$", "!@#", "***"]
        let specialResult = WujiMemoryTagProcessor.process(specialChars)
        XCTAssertFalse(specialResult.isEmpty, "Special characters should be preserved")

        // Very long tag
        let longTag = String(repeating: "a", count: 1000)
        let longResult = WujiMemoryTagProcessor.process([longTag])
        XCTAssertEqual(longResult.count, 1000, "Long tag should be preserved")

        // Unicode special characters
        let unicodeTags = ["😀", "🎉", "emoji"]
        let emojiResult = WujiMemoryTagProcessor.process(unicodeTags)
        XCTAssertFalse(emojiResult.isEmpty, "Emoji should be preserved")
    }

    // MARK: - Real World Examples Tests

    func testRealWorldExamples() {
        // Simulate actual user input
        let testCases: [(input: [String], description: String)] = [
            (["女娲", "补天石", "诞生"], "Journey to the West scene 1"),
            (["八九年", "学礼", "找神仙"], "Journey to the West scene 2"),
            (["敖广", "借兵器", "行头"], "Journey to the West scene 3"),
            (["三番五次", "菩萨", "帮忙"], "Journey to the West scene 4"),
            (["释迦摩尼", "成佛", "圣地"], "Journey to the West scene 5"),
        ]

        for (input, description) in testCases {
            let result = WujiMemoryTagProcessor.process(input)
            let count = WujiMemoryTagProcessor.uniqueCount(input)

            XCTAssertGreaterThanOrEqual(count, 3, "\(description): Should have at least 3 unique tags")
            XCTAssertFalse(result.isEmpty, "\(description): Result should not be empty")
        }
    }

    // MARK: - Determinism Tests

    func testDeterminism() {
        let testInputs: [[String]] = [
            ["花果山", "水帘洞", "山腰"],
            ["Apple", "Banana", "Cherry"],
            ["测试", "Test", "テスト"],
        ]

        for input in testInputs {
            var results = Set<String>()

            // Process same input 100 times
            for _ in 0..<100 {
                let result = WujiMemoryTagProcessor.process(input)
                results.insert(result)
            }

            XCTAssertEqual(results.count, 1, "Same input should produce same output")
        }

        // Test order independence
        let input1 = ["a", "b", "c"]
        let input2 = ["c", "a", "b"]
        let input3 = ["b", "c", "a"]

        let result1 = WujiMemoryTagProcessor.process(input1)
        let result2 = WujiMemoryTagProcessor.process(input2)
        let result3 = WujiMemoryTagProcessor.process(input3)

        XCTAssertEqual(result1, result2, "Different order should produce same result")
        XCTAssertEqual(result2, result3, "Different order should produce same result")
    }

    // MARK: - Integration Tests

    func testParseAndProcess() {
        let testCases: [(input: String, expected: String, description: String)] = [
            ("花果山 水帘洞 山腰", "山腰水帘洞花果山", "Space separated input"),
            ("花果山,水帘洞,山腰", "山腰水帘洞花果山", "Comma separated input"),
            ("Apple, Banana, Cherry", "applebananacherry", "English comma separated"),
            ("  hello  ,  HELLO  ,  world  ", "helloworld", "With spaces and duplicates"),
        ]

        for (input, expected, description) in testCases {
            let tags = WujiMemoryTagProcessor.parseTags(from: input)
            let result = WujiMemoryTagProcessor.process(tags)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    // MARK: - Merged Memory Tags Tests

    /// Test merging memory1 and memory2 tags (simulates PlacesDataManager.memoryProcessed)
    func testMergedMemoryTags() {
        // Simulate the new merged processing logic:
        // memory1Tags + memory2Tags -> unified sort -> concatenate

        let testCases: [(memory1: [String], memory2: [String], expected: String, description: String)] = [
            // Basic case: tags from both memories are merged and sorted together
            (
                ["女娲", "补天石", "诞生"],
                ["山腰", "水帘洞", "花果山"],
                "女娲山腰水帘洞花果山补天石诞生",  // Unicode sorted order
                "Journey to West location 1"
            ),
            // English tags
            (
                ["apple", "banana"],
                ["cherry", "date"],
                "applebananacherrydate",
                "English tags merged"
            ),
            // Mixed language
            (
                ["hello", "world"],
                ["你好", "世界"],
                "helloworld世界你好",  // English sorted before Chinese
                "Mixed language merged"
            ),
            // Duplicates across memory1 and memory2 should be deduplicated
            (
                ["apple", "banana"],
                ["banana", "cherry"],
                "applebananacherry",
                "Cross-memory deduplication"
            ),
            // Case insensitive deduplication across memories
            (
                ["Apple", "Banana"],
                ["apple", "cherry"],
                "applebananacherry",
                "Case insensitive cross-memory deduplication"
            ),
            // Empty memory2
            (
                ["a", "b", "c"],
                [],
                "abc",
                "Empty memory2"
            ),
            // Empty memory1
            (
                [],
                ["x", "y", "z"],
                "xyz",
                "Empty memory1"
            ),
        ]

        for (memory1, memory2, expected, description) in testCases {
            // This simulates PlacesDataManager.PlaceData.memoryProcessed
            let allTags = memory1 + memory2
            let result = WujiMemoryTagProcessor.process(allTags)
            XCTAssertEqual(result, expected, "\(description) failed")
        }
    }

    /// Test that merged processing is order-independent
    func testMergedMemoryOrderIndependence() {
        let memory1Tags = ["女娲", "补天石", "诞生"]
        let memory2Tags = ["山腰", "水帘洞", "花果山"]

        // Order 1: memory1 + memory2
        let result1 = WujiMemoryTagProcessor.process(memory1Tags + memory2Tags)

        // Order 2: memory2 + memory1
        let result2 = WujiMemoryTagProcessor.process(memory2Tags + memory1Tags)

        // Order 3: interleaved
        let interleaved = [memory1Tags[0], memory2Tags[0], memory1Tags[1], memory2Tags[1], memory1Tags[2], memory2Tags[2]]
        let result3 = WujiMemoryTagProcessor.process(interleaved)

        XCTAssertEqual(result1, result2, "memory1+memory2 should equal memory2+memory1")
        XCTAssertEqual(result2, result3, "Different arrangements should produce same result")
    }

    /// Test real-world example from test data
    func testRealWorldMergedMemory() {
        // From PlacesDataManager test data
        let testData: [(memory1: [String], memory2: [String])] = [
            (["女娲", "补天石", "诞生"], ["山腰", "水帘洞", "花果山"]),
            (["八九年", "学礼", "找神仙"], ["菩提祖师", "七十二变", "筋斗云"]),
            (["敖广", "借兵器", "行头"], ["定海神针", "一万三千五百斤", "如意金箍棒"]),
            (["三番五次", "菩萨", "帮忙"], ["白龙马", "取经", "西天"]),
            (["释迦摩尼", "成佛", "圣地"], ["九九八十一难", "法门", "修行"]),
        ]

        for (index, data) in testData.enumerated() {
            let allTags = data.memory1 + data.memory2
            let result = WujiMemoryTagProcessor.process(allTags)

            // Verify 6 unique tags (no overlap in test data)
            XCTAssertEqual(WujiMemoryTagProcessor.uniqueCount(allTags), 6, "Location \(index + 1) should have 6 unique tags")

            // Verify result is non-empty
            XCTAssertFalse(result.isEmpty, "Location \(index + 1) result should not be empty")

            // Verify determinism
            let result2 = WujiMemoryTagProcessor.process(allTags)
            XCTAssertEqual(result, result2, "Location \(index + 1) should be deterministic")
        }
    }

    // MARK: - Performance Tests

    func testProcessingPerformance() {
        let tags = (0..<100).map { "tag\($0)" }

        measure {
            for _ in 0..<100 {
                _ = WujiMemoryTagProcessor.process(tags)
            }
        }
    }

    func testParsingPerformance() {
        let input = (0..<100).map { "tag\($0)" }.joined(separator: ", ")

        measure {
            for _ in 0..<100 {
                _ = WujiMemoryTagProcessor.parseTags(from: input)
            }
        }
    }
}
