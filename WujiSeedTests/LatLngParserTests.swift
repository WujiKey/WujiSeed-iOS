//
//  LatLngParserTests.swift
//  WujiSeedTests
//
//  LatLngParser unit tests - coordinate format parsing
//

import XCTest
@testable import WujiSeed

class LatLngParserTests: XCTestCase {

    // MARK: - Decimal Format Tests (DD)

    func testDecimalFormat() {
        let testCases: [(input: String, expectedLat: Double, expectedLon: Double, description: String)] = [
            ("18.6992452, 98.9227733", 18.6992452, 98.9227733, "Standard DD format"),
            ("39.9042, 116.4074", 39.9042, 116.4074, "Beijing coordinates"),
            ("-33.8688, 151.2093", -33.8688, 151.2093, "Sydney (southern hemisphere)"),
            ("51.5074, -0.1278", 51.5074, -0.1278, "London (western hemisphere)"),
            ("-34.6037, -58.3816", -34.6037, -58.3816, "Buenos Aires (both negative)"),
            ("0.0, 0.0", 0.0, 0.0, "Origin point"),
            ("90, 180", 90.0, 180.0, "Max positive values"),
            ("-90, -180", -90.0, -180.0, "Max negative values"),
        ]

        for (input, expectedLat, expectedLon, description) in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertTrue(result.isValid, "\(description): Should be valid")
            XCTAssertEqual(result.latitude, expectedLat, accuracy: 0.0000001, "\(description): Latitude mismatch")
            XCTAssertEqual(result.longitude, expectedLon, accuracy: 0.0000001, "\(description): Longitude mismatch")
        }
    }

    func testDecimalFormatWithFullWidthComma() {
        let result = LatLngParser.parse("39.9042，116.4074")
        XCTAssertTrue(result.isValid, "Full-width comma should be accepted")
        XCTAssertEqual(result.latitude, 39.9042, accuracy: 0.0000001)
        XCTAssertEqual(result.longitude, 116.4074, accuracy: 0.0000001)
    }

    func testDecimalFormatWithExtraSpaces() {
        let result = LatLngParser.parse("  39.9042  ,  116.4074  ")
        XCTAssertTrue(result.isValid, "Extra spaces should be trimmed")
        XCTAssertEqual(result.latitude, 39.9042, accuracy: 0.0000001)
        XCTAssertEqual(result.longitude, 116.4074, accuracy: 0.0000001)
    }

    // MARK: - Parentheses Format Tests

    func testParenthesesFormat() {
        let testCases: [(input: String, expectedLat: Double, expectedLon: Double, description: String)] = [
            ("(18.6992452, 98.9227733)", 18.6992452, 98.9227733, "Half-width parentheses"),
            ("（39.9042, 116.4074）", 39.9042, 116.4074, "Full-width parentheses"),
            ("(39.9042，116.4074)", 39.9042, 116.4074, "Mixed parentheses and comma"),
        ]

        for (input, expectedLat, expectedLon, description) in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertTrue(result.isValid, "\(description): Should be valid")
            XCTAssertEqual(result.latitude, expectedLat, accuracy: 0.0000001, "\(description): Latitude mismatch")
            XCTAssertEqual(result.longitude, expectedLon, accuracy: 0.0000001, "\(description): Longitude mismatch")
        }
    }

    // MARK: - DMS Format Tests

    func testDMSFormat() {
        let testCases: [(input: String, expectedLat: Double, expectedLon: Double, description: String)] = [
            ("18°41'57\"N 98°55'21\"E", 18.69917, 98.92250, "Standard DMS format"),
            ("39°54'15\"N 116°24'26\"E", 39.90417, 116.40722, "Beijing DMS"),
            ("33°52'8\"S 151°12'33\"E", -33.86889, 151.20917, "Sydney DMS (southern)"),
            ("51°30'26\"N 0°7'40\"W", 51.50722, -0.12778, "London DMS (western)"),
        ]

        for (input, expectedLat, expectedLon, description) in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertTrue(result.isValid, "\(description): Should be valid")
            XCTAssertEqual(result.latitude, expectedLat, accuracy: 0.001, "\(description): Latitude mismatch")
            XCTAssertEqual(result.longitude, expectedLon, accuracy: 0.001, "\(description): Longitude mismatch")
        }
    }

    func testDMSFormatWithDecimalSeconds() {
        let result = LatLngParser.parse("18°41'57.5\"N 98°55'21.8\"E")
        XCTAssertTrue(result.isValid, "DMS with decimal seconds should be valid")
        XCTAssertEqual(result.latitude, 18.69931, accuracy: 0.0001)
        XCTAssertEqual(result.longitude, 98.92272, accuracy: 0.0001)
    }

    func testDMSFormatWithChineseDirection() {
        let result = LatLngParser.parse("18°41'57\"北 98°55'21\"东")
        XCTAssertTrue(result.isValid, "DMS with Chinese direction should be valid")
        XCTAssertEqual(result.latitude, 18.69917, accuracy: 0.001)
        XCTAssertEqual(result.longitude, 98.92250, accuracy: 0.001)
    }

    // MARK: - Chinese Format Tests

    func testChineseFormat() {
        let testCases: [(input: String, expectedLat: Double, expectedLon: Double, description: String)] = [
            ("北18.699°, 东98.922°", 18.699, 98.922, "Chinese direction with degree"),
            ("北39.9042, 东116.4074", 39.9042, 116.4074, "Chinese direction without degree"),
            ("南33.8688, 东151.2093", -33.8688, 151.2093, "Southern hemisphere"),
            ("北51.5074, 西0.1278", 51.5074, -0.1278, "Western hemisphere"),
        ]

        for (input, expectedLat, expectedLon, description) in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertTrue(result.isValid, "\(description): Should be valid")
            XCTAssertEqual(result.latitude, expectedLat, accuracy: 0.0000001, "\(description): Latitude mismatch")
            XCTAssertEqual(result.longitude, expectedLon, accuracy: 0.0000001, "\(description): Longitude mismatch")
        }
    }

    // MARK: - Range Validation Tests

    func testLatitudeOutOfRange() {
        let testCases = [
            "91, 116.4074",
            "-91, 116.4074",
            "100, 0",
        ]

        for input in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertFalse(result.isValid, "Latitude out of range should be invalid: \(input)")
        }
    }

    func testLongitudeOutOfRange() {
        let testCases = [
            "39.9042, 181",
            "39.9042, -181",
            "0, 200",
        ]

        for input in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertFalse(result.isValid, "Longitude out of range should be invalid: \(input)")
        }
    }

    // MARK: - Invalid Input Tests

    func testEmptyInput() {
        let result = LatLngParser.parse("")
        XCTAssertFalse(result.isValid, "Empty string should be invalid")
    }

    func testWhitespaceOnlyInput() {
        let result = LatLngParser.parse("   ")
        XCTAssertFalse(result.isValid, "Whitespace only should be invalid")
    }

    func testInvalidFormat() {
        let testCases = [
            "not a coordinate",
            "abc, def",
            "12345",
            "39.9042",
            "39.9042, ",
            ", 116.4074",
        ]

        for input in testCases {
            let result = LatLngParser.parse(input)
            XCTAssertFalse(result.isValid, "Invalid format should be rejected: \(input)")
        }
    }

    // MARK: - toDMSFormat Tests

    func testToDMSFormat() {
        let dms = LatLngParser.toDMSFormat(latitude: 18.69917, longitude: 98.92250)
        XCTAssertTrue(dms.contains("18°"), "Should contain latitude degrees")
        XCTAssertTrue(dms.contains("98°"), "Should contain longitude degrees")
        XCTAssertTrue(dms.contains("N") || dms.contains("S"), "Should contain N/S direction")
        XCTAssertTrue(dms.contains("E") || dms.contains("W"), "Should contain E/W direction")
    }

    func testToDMSFormatNegativeCoordinates() {
        let dms = LatLngParser.toDMSFormat(latitude: -33.8688, longitude: -58.3816)
        XCTAssertTrue(dms.contains("S"), "Southern latitude should have S")
        XCTAssertTrue(dms.contains("W"), "Western longitude should have W")
    }

    // MARK: - Formatted String Tests

    func testFormattedString() {
        let result = LatLngParser.parse("39.9042, 116.4074")
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.formattedString.isEmpty, "Formatted string should not be empty")
        XCTAssertTrue(result.formattedString.contains(","), "Formatted string should contain comma")
    }

    func testFormattedStringInvalid() {
        let result = LatLngParser.parse("invalid")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.formattedString, "", "Invalid result should have empty formatted string")
    }

    // MARK: - Determinism Tests

    func testDeterminism() {
        let inputs = [
            "39.9042, 116.4074",
            "18°41'57\"N 98°55'21\"E",
            "北18.699°, 东98.922°",
        ]

        for input in inputs {
            var results = Set<String>()
            for _ in 0..<100 {
                let result = LatLngParser.parse(input)
                let key = "\(result.latitude),\(result.longitude)"
                results.insert(key)
            }
            XCTAssertEqual(results.count, 1, "Same input should produce same output: \(input)")
        }
    }

    // MARK: - Performance Tests

    func testParsingPerformance() {
        let input = "39.9042, 116.4074"
        measure {
            for _ in 0..<1000 {
                _ = LatLngParser.parse(input)
            }
        }
    }
}
