//
//  CryptoUtilsTests.swift
//  WujiSeedTests
//
//  CryptoUtils unit tests - cryptographic operations
//  Tests for SHA256, BLAKE2b, Argon2id
//

import XCTest
@testable import WujiSeed

class CryptoUtilsTests: XCTestCase {

    // MARK: - SHA256 Tests

    func testSHA256Basic() {
        // Test vector from NIST
        let input = "abc".data(using: .utf8)!
        let hash = CryptoUtils.sha256(input)

        XCTAssertEqual(hash.count, 32, "SHA256 should produce 32 bytes")

        // Expected hash for "abc"
        let expectedHex = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        let actualHex = hash.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actualHex, expectedHex, "SHA256 hash mismatch")
    }

    func testSHA256EmptyString() {
        let input = "".data(using: .utf8)!
        let hash = CryptoUtils.sha256(input)

        XCTAssertEqual(hash.count, 32)

        // Expected hash for empty string
        let expectedHex = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        let actualHex = hash.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(actualHex, expectedHex)
    }

    func testSHA256LongInput() {
        // Test with longer input
        let input = String(repeating: "a", count: 1000).data(using: .utf8)!
        let hash = CryptoUtils.sha256(input)

        XCTAssertEqual(hash.count, 32, "SHA256 should always produce 32 bytes")
    }

    // MARK: - BLAKE2b Tests

    func testBLAKE2bBasic() {
        let input = "Hello, World!".data(using: .utf8)!
        let hash = CryptoUtils.blake2b(data: input)

        XCTAssertNotNil(hash, "BLAKE2b should return a hash")
        XCTAssertEqual(hash?.count, 32, "Default BLAKE2b should produce 32 bytes")
    }

    func testBLAKE2bString() {
        let hash = CryptoUtils.blake2b(string: "Hello, World!")

        XCTAssertNotNil(hash, "BLAKE2b string should return a hash")
        XCTAssertEqual(hash?.count, 32)
    }

    func testBLAKE2bCustomLength() {
        let input = "test".data(using: .utf8)!

        // Test various output lengths
        let lengths = [16, 32, 48, 64]
        for length in lengths {
            let hash = CryptoUtils.blake2b(data: input, outputLength: length)
            XCTAssertNotNil(hash, "BLAKE2b should work with \(length) byte output")
            XCTAssertEqual(hash?.count, length, "Output should be \(length) bytes")
        }
    }

    func testBLAKE2bInvalidLength() {
        let input = "test".data(using: .utf8)!

        // Test invalid lengths
        XCTAssertNil(CryptoUtils.blake2b(data: input, outputLength: 0), "Length 0 should fail")
        XCTAssertNil(CryptoUtils.blake2b(data: input, outputLength: 65), "Length 65 should fail")
        XCTAssertNil(CryptoUtils.blake2b(data: input, outputLength: -1), "Negative length should fail")
    }

    func testBLAKE2bEmptyInput() {
        let input = "".data(using: .utf8)!
        let hash = CryptoUtils.blake2b(data: input)

        XCTAssertNotNil(hash, "BLAKE2b should handle empty input")
        XCTAssertEqual(hash?.count, 32)
    }

    // MARK: - Salt Generation Tests

    func testSaltSuffix() {
        XCTAssertEqual(CryptoUtils.WujiBlake2bSaltSuffix, "WUJI-Key-V1:Memory-Based Seed Phrases", "Salt suffix should match")
    }

    // MARK: - Argon2id Parameter Tests

    func testArgon2idParameters() {
        let params = CryptoUtils.Argon2Parameters.standard

        XCTAssertEqual(params.memoryKB, 256 * 1024, "Memory should be 256 MB")
        XCTAssertEqual(params.iterations, 7, "Iterations should be 7")
        XCTAssertEqual(params.parallelism, 1, "Parallelism should be 1")
    }

    func testArgon2idBasic() {
        let password = "test password".data(using: .utf8)!
        let salt = Data(repeating: 0x00, count: 16)  // Must be 16 bytes

        // Use lighter parameters for testing
        let lightParams = CryptoUtils.Argon2Parameters(
            memoryKB: 64 * 1024,  // 64 MB
            iterations: 1,
            parallelism: 1
        )

        let key = CryptoUtils.argon2id(password: password, salt: salt, parameters: lightParams)

        XCTAssertNotNil(key, "Argon2id should return a key")
        XCTAssertEqual(key?.count, 32, "Default output should be 32 bytes")
    }

    func testArgon2idDifferentPasswords() {
        let password1 = "password1".data(using: .utf8)!
        let password2 = "password2".data(using: .utf8)!
        let salt = Data(repeating: 0x00, count: 16)  // Must be 16 bytes

        let lightParams = CryptoUtils.Argon2Parameters(
            memoryKB: 64 * 1024,
            iterations: 1,
            parallelism: 1
        )

        let key1 = CryptoUtils.argon2id(password: password1, salt: salt, parameters: lightParams)
        let key2 = CryptoUtils.argon2id(password: password2, salt: salt, parameters: lightParams)

        XCTAssertNotNil(key1)
        XCTAssertNotNil(key2)
        XCTAssertNotEqual(key1, key2, "Different passwords should produce different keys")
    }

    func testArgon2idDifferentSalts() {
        let password = "password".data(using: .utf8)!
        let salt1 = Data(repeating: 0x00, count: 16)  // Must be 16 bytes
        let salt2 = Data(repeating: 0xFF, count: 16)  // Must be 16 bytes

        let lightParams = CryptoUtils.Argon2Parameters(
            memoryKB: 64 * 1024,
            iterations: 1,
            parallelism: 1
        )

        let key1 = CryptoUtils.argon2id(password: password, salt: salt1, parameters: lightParams)
        let key2 = CryptoUtils.argon2id(password: password, salt: salt2, parameters: lightParams)

        XCTAssertNotNil(key1)
        XCTAssertNotNil(key2)
        XCTAssertNotEqual(key1, key2, "Different salts should produce different keys")
    }

    func testArgon2idInvalidSaltLength() {
        let password = "password".data(using: .utf8)!
        let invalidSalt = Data(repeating: 0x00, count: 32)  // Wrong length

        let lightParams = CryptoUtils.Argon2Parameters(
            memoryKB: 64 * 1024,
            iterations: 1,
            parallelism: 1
        )

        let key = CryptoUtils.argon2id(password: password, salt: invalidSalt, parameters: lightParams)
        XCTAssertNil(key, "Invalid salt length should return nil")
    }

    // MARK: - Cross-function Tests

    func testBLAKE2bThenSHA256() {
        let input = "chain test".data(using: .utf8)!

        guard let blake2bHash = CryptoUtils.blake2b(data: input) else {
            XCTFail("BLAKE2b should succeed")
            return
        }

        let sha256Hash = CryptoUtils.sha256(blake2bHash)

        XCTAssertEqual(sha256Hash.count, 32)
        XCTAssertNotEqual(blake2bHash, sha256Hash, "Different algorithms should produce different hashes")
    }

    // MARK: - Performance Tests

    func testSHA256Performance() {
        let input = String(repeating: "a", count: 1000).data(using: .utf8)!
        measure {
            for _ in 0..<1000 {
                _ = CryptoUtils.sha256(input)
            }
        }
    }

    func testBLAKE2bPerformance() {
        let input = String(repeating: "a", count: 1000).data(using: .utf8)!
        measure {
            for _ in 0..<1000 {
                _ = CryptoUtils.blake2b(data: input)
            }
        }
    }
}
