//
//  UtilsTests.swift
//  WujiSeedTests
//
//  Unit tests for Utils
//

import XCTest
@testable import WujiSeed

class UtilsTests: XCTestCase {

    // Utils uses static methods, no instance needed

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Binary String Conversion Tests

    func testBinaryStringToData() {
        // Test valid 8-bit binary string
        let binary8 = "11111111"
        let data8 = Utils.binaryStringToData(binary8)
        XCTAssertNotNil(data8)
        XCTAssertEqual(data8?.count, 1)
        XCTAssertEqual(data8?.first, 0xFF)

        // Test valid 16-bit binary string
        let binary16 = "0000000011111111"
        let data16 = Utils.binaryStringToData(binary16)
        XCTAssertNotNil(data16)
        XCTAssertEqual(data16?.count, 2)
        XCTAssertEqual(Array(data16!), [0x00, 0xFF])

        // Test valid 24-bit binary string
        let binary24 = "000000001111111110101010"
        let data24 = Utils.binaryStringToData(binary24)
        XCTAssertNotNil(data24)
        XCTAssertEqual(data24?.count, 3)
        XCTAssertEqual(Array(data24!), [0x00, 0xFF, 0xAA])

        // Test all zeros
        let binaryZeros = "0000000000000000"
        let dataZeros = Utils.binaryStringToData(binaryZeros)
        XCTAssertNotNil(dataZeros)
        XCTAssertEqual(Array(dataZeros!), [0x00, 0x00])

        // Test all ones
        let binaryOnes = "1111111111111111"
        let dataOnes = Utils.binaryStringToData(binaryOnes)
        XCTAssertNotNil(dataOnes)
        XCTAssertEqual(Array(dataOnes!), [0xFF, 0xFF])

        // Test 256-bit binary (32 bytes)
        let binary256 = String(repeating: "10101010", count: 32)
        let data256 = Utils.binaryStringToData(binary256)
        XCTAssertNotNil(data256)
        XCTAssertEqual(data256?.count, 32)
        XCTAssertTrue(data256!.allSatisfy { $0 == 0xAA })
    }

    func testBinaryStringToDataInvalidLength() {
        // Test invalid length (not multiple of 8)
        let binary7 = "1111111"
        XCTAssertNil(Utils.binaryStringToData(binary7), "7 bits should return nil")

        let binary9 = "111111111"
        XCTAssertNil(Utils.binaryStringToData(binary9), "9 bits should return nil")

        let binary15 = "111111111111111"
        XCTAssertNil(Utils.binaryStringToData(binary15), "15 bits should return nil")

        // Test empty string (0 is a valid multiple of 8)
        let emptyBinary = ""
        let emptyData = Utils.binaryStringToData(emptyBinary)
        XCTAssertNotNil(emptyData)
        XCTAssertEqual(emptyData?.count, 0)

        // Test invalid characters
        let invalidBinary = "1111X111"  // X is invalid
        XCTAssertNil(Utils.binaryStringToData(invalidBinary), "Invalid characters should return nil")

        let invalidBinary2 = "11112222"  // 2 is invalid
        XCTAssertNil(Utils.binaryStringToData(invalidBinary2), "Invalid characters should return nil")
    }

    func testDataToBinaryString() {
        // Test single byte
        let data1 = Data([0xFF])
        XCTAssertEqual(Utils.dataToBinaryString(data1), "11111111")

        let data2 = Data([0x00])
        XCTAssertEqual(Utils.dataToBinaryString(data2), "00000000")

        let data3 = Data([0xAA])  // 10101010
        XCTAssertEqual(Utils.dataToBinaryString(data3), "10101010")

        // Test multiple bytes
        let data4 = Data([0x00, 0xFF])
        XCTAssertEqual(Utils.dataToBinaryString(data4), "0000000011111111")

        let data5 = Data([0x12, 0x34])
        // 0x12 = 00010010, 0x34 = 00110100
        XCTAssertEqual(Utils.dataToBinaryString(data5), "0001001000110100")

        // Test empty data
        let emptyData = Data()
        XCTAssertEqual(Utils.dataToBinaryString(emptyData), "")

        // Test known pattern
        let pattern = Data([0x0F, 0xF0])  // 00001111 11110000
        XCTAssertEqual(Utils.dataToBinaryString(pattern), "0000111111110000")
    }

    // MARK: - Round-trip Conversion Tests

    func testRoundTripBinaryStringConversion() {
        // Test round-trip: Data -> Binary String -> Data
        let originalData = Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])
        let binaryString = Utils.dataToBinaryString(originalData)
        let convertedBack = Utils.binaryStringToData(binaryString)

        XCTAssertNotNil(convertedBack)
        XCTAssertEqual(originalData, convertedBack!)

        // Test with random data
        let randomData = Data([0xAA, 0x55, 0x00, 0xFF, 0x0F, 0xF0])
        let randomBinary = Utils.dataToBinaryString(randomData)
        let randomBack = Utils.binaryStringToData(randomBinary)

        XCTAssertNotNil(randomBack)
        XCTAssertEqual(randomData, randomBack!)
    }

    func testBinaryStringLength() {
        // Verify binary string length is always 8 * data length
        let data1 = Data([0x00])
        XCTAssertEqual(Utils.dataToBinaryString(data1).count, 8)

        let data8 = Data([UInt8](repeating: 0, count: 8))
        XCTAssertEqual(Utils.dataToBinaryString(data8).count, 64)

        let data32 = Data([UInt8](repeating: 0xFF, count: 32))
        XCTAssertEqual(Utils.dataToBinaryString(data32).count, 256)
    }

    func testSHA256WithBinaryConversion() {
        // Test SHA256 followed by binary conversion
        let testData = "test".data(using: .utf8)!
        let hash = CryptoUtils.sha256(testData)
        let binaryHash = Utils.dataToBinaryString(hash)

        // SHA256 produces 32 bytes = 256 bits
        XCTAssertEqual(binaryHash.count, 256)

        // Verify all characters are 0 or 1
        XCTAssertTrue(binaryHash.allSatisfy { $0 == "0" || $0 == "1" })

        // Verify round-trip
        let convertedBack = Utils.binaryStringToData(binaryHash)
        XCTAssertNotNil(convertedBack)
        XCTAssertEqual(hash, convertedBack!)
    }

    // MARK: - hexToDecimal Tests

    func testHexToDecimal() {
        // Test single digit conversions
        XCTAssertEqual(Utils.hexToDecimal("0"), "0")
        XCTAssertEqual(Utils.hexToDecimal("1"), "1")
        XCTAssertEqual(Utils.hexToDecimal("9"), "9")
        XCTAssertEqual(Utils.hexToDecimal("A"), "10")
        XCTAssertEqual(Utils.hexToDecimal("a"), "10")
        XCTAssertEqual(Utils.hexToDecimal("F"), "15")
        XCTAssertEqual(Utils.hexToDecimal("f"), "15")

        // Test multi-digit conversions
        XCTAssertEqual(Utils.hexToDecimal("10"), "16")
        XCTAssertEqual(Utils.hexToDecimal("FF"), "255")
        XCTAssertEqual(Utils.hexToDecimal("100"), "256")
        XCTAssertEqual(Utils.hexToDecimal("FFFF"), "65535")

        // Test mixed case
        XCTAssertEqual(Utils.hexToDecimal("AbCdEf"), "11259375")

        // Test large numbers (SHA256 hash size - 64 hex characters = 32 bytes)
        let largeHex = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        let expectedDecimal = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        XCTAssertEqual(Utils.hexToDecimal(largeHex), expectedDecimal)

        // Test known conversion
        XCTAssertEqual(Utils.hexToDecimal("1A2B3C"), "1715004")
    }

    func testHexToDecimalWithInvalidCharacters() {
        // Invalid characters should be skipped
        let result1 = Utils.hexToDecimal("1G2")  // G is invalid
        // Valid chars are 1 and 2, so result should be 0x12 = 18
        XCTAssertEqual(result1, "18")

        // All invalid characters
        let result2 = Utils.hexToDecimal("XYZ")
        XCTAssertEqual(result2, "0")

        // Empty string
        let result3 = Utils.hexToDecimal("")
        XCTAssertEqual(result3, "0")

        // Mixed valid and invalid
        let result4 = Utils.hexToDecimal("A-B-C")  // Dashes are invalid
        XCTAssertEqual(result4, "2748")  // ABC in hex = 2748 in decimal
    }

    func testHexToDecimalLargeNumbers() {
        // Test numbers that exceed Int64 range
        let hex64Bit = "FFFFFFFFFFFFFFFF"  // Max UInt64
        let expected64Bit = "18446744073709551615"
        XCTAssertEqual(Utils.hexToDecimal(hex64Bit), expected64Bit)

        // Test 128-bit number
        let hex128Bit = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        let expected128Bit = "340282366920938463463374607431768211455"
        XCTAssertEqual(Utils.hexToDecimal(hex128Bit), expected128Bit)
    }

    // MARK: - dataToDecimal Tests

    func testDataToDecimal() {
        // Test empty data
        let emptyData = Data()
        XCTAssertEqual(Utils.dataToDecimal(emptyData), "0")

        // Test single byte
        let singleByte = Data([0xFF])
        XCTAssertEqual(Utils.dataToDecimal(singleByte), "255")

        // Test multiple bytes
        let twoBytes = Data([0x01, 0x00])  // 256 in big-endian
        XCTAssertEqual(Utils.dataToDecimal(twoBytes), "256")

        let fourBytes = Data([0x00, 0x00, 0x01, 0x00])  // 256 in big-endian
        XCTAssertEqual(Utils.dataToDecimal(fourBytes), "256")

        // Test known conversion
        let knownData = Data([0x12, 0x34, 0x56])
        // 0x12 * 256^2 + 0x34 * 256 + 0x56 = 18 * 65536 + 52 * 256 + 86 = 1193046
        XCTAssertEqual(Utils.dataToDecimal(knownData), "1193046")

        // Test 32-byte hash (typical SHA256 output)
        let hashData = Data([UInt8](repeating: 0xFF, count: 32))
        let expectedValue = "115792089237316195423570985008687907853269984665640564039457584007913129639935"
        XCTAssertEqual(Utils.dataToDecimal(hashData), expectedValue)
    }

    func testDataToDecimalEmpty() {
        // Test empty data
        let emptyData = Data()
        let result = Utils.dataToDecimal(emptyData)
        XCTAssertEqual(result, "0", "Empty data should convert to '0'")

        // Test data with all zeros
        let zeroData = Data([0x00, 0x00, 0x00])
        XCTAssertEqual(Utils.dataToDecimal(zeroData), "0")

        // Test data starting with zeros (leading zeros)
        let leadingZeros = Data([0x00, 0x00, 0x01])
        XCTAssertEqual(Utils.dataToDecimal(leadingZeros), "1")
    }

    func testDataToDecimalConsistencyWithHex() {
        // Verify that dataToDecimal and hexToDecimal produce same results
        let hexString = "ABCDEF123456"

        // Convert hex string to data manually
        var data = Data()
        var tempHex = hexString
        while tempHex.count >= 2 {
            let byteString = String(tempHex.prefix(2))
            tempHex = String(tempHex.dropFirst(2))
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
        }

        let hexResult = Utils.hexToDecimal(hexString)
        let dataResult = Utils.dataToDecimal(data)

        XCTAssertEqual(hexResult, dataResult, "hexToDecimal and dataToDecimal should produce same result for equivalent input")
    }
}
