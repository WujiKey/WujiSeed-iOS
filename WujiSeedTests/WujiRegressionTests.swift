//
//  WujiRegressionTests.swift
//  WujiSeedTests
//
//  Golden vector regression tests - loads test vectors from JSON files to ensure
//  backward compatibility across upgrades. If any of these tests fail after
//  a code change, it means the change broke compatibility with existing data.
//
//  ⚠️ DO NOT modify the JSON files! They are the source of truth.
//  If a test fails, it means the code change is incompatible.
//
//  Data source: wujikey_v1_vector_1.json, wujikey_v1_vector_2.json
//

import XCTest
@testable import WujiSeed

class WujiRegressionTests: XCTestCase {

    // MARK: - Test Vectors

    /// Vector 1: Journey to the West (吴承恩《西游记》)
    /// Loaded from: wujikey_v1_vector_1.json
    private var vector1: GoldenTestVector!

    /// Vector 2: Moses Exodus
    /// Loaded from: wujikey_v1_vector_2.json
    private var vector2: GoldenTestVector!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Load test vectors from JSON files
        guard let v1 = GoldenVectorLoader.load("wujikey_v1_vector_1") else {
            XCTFail("Failed to load wujikey_v1_vector_1.json")
            return
        }
        vector1 = v1

        guard let v2 = GoldenVectorLoader.load("wujikey_v1_vector_2") else {
            XCTFail("Failed to load wujikey_v1_vector_2.json")
            return
        }
        vector2 = v2

        // Verify vectors loaded correctly
        XCTAssertEqual(vector1.locations.count, 5, "Vector 1 should have 5 locations")
        XCTAssertEqual(vector2.locations.count, 5, "Vector 2 should have 5 locations")
        XCTAssertEqual(vector1.mnemonics.count, 24, "Vector 1 should have 24 mnemonics")
        XCTAssertEqual(vector2.mnemonics.count, 24, "Vector 2 should have 24 mnemonics")

        print("✅ Loaded wujikey_v1_vector_1.json: \(vector1.name)")
        print("✅ Loaded wujikey_v1_vector_2.json: \(vector2.name)")
    }

    // MARK: - Vector 1 Tests

    /// Test Vector 1: Name normalization and salt generation
    func testVector1_NameSalt() {
        guard let wujiName = vector1.wujiName else {
            XCTFail("Failed to create WujiName from vector1")
            return
        }

        XCTAssertEqual(wujiName.normalized, vector1.normalizedName,
            "Normalized name must match golden vector")

        let saltHex = wujiName.salt.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(saltHex, vector1.nameSaltHex,
            "Name salt must match golden vector")
    }

    /// Test Vector 1: Position codes from spot processing
    func testVector1_PositionCodes() {
        let spots = vector1.spots
        XCTAssertEqual(spots.count, 5, "Should create 5 spots from vector1")

        guard case .success(let result) = WujiSpot.process(spots) else {
            XCTFail("WujiSpot.process failed for vector1")
            return
        }

        XCTAssertEqual(result.positionCodes, vector1.positionCodes,
            "Position codes must match golden vector")
    }

    /// Test Vector 1: Memory processing matches expected values
    func testVector1_MemoryProcessing() {
        for (index, location) in vector1.locations.enumerated() {
            let processedMemory = WujiMemoryTagProcessor.process(location.memoryTags)
            XCTAssertEqual(processedMemory, location.memoryProcessed,
                "Memory processing for location \(index + 1) must match golden vector")
        }
    }

    /// Test Vector 1: Full generation produces expected mnemonics
    func testVector1_GenerateMnemonics() {
        let spots = vector1.spots
        guard let wujiName = vector1.wujiName else {
            XCTFail("WujiName creation failed")
            return
        }

        guard case .success(let processResult) = WujiSpot.process(spots) else {
            XCTFail("WujiSpot.process failed")
            return
        }

        guard let keyData = CryptoUtils.argon2id(
            password: processResult.combinedData,
            salt: wujiName.salt,
            parameters: vector1.argon2Params
        ) else {
            XCTFail("Argon2id failed")
            return
        }

        let keyDataHex = keyData.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(keyDataHex, vector1.keyDataHex,
            "KeyData must match golden vector — KDF backward compatibility broken!")

        guard let mnemonics = BIP39Helper.generate24Words(from: keyData) else {
            XCTFail("BIP39 generation failed")
            return
        }

        XCTAssertEqual(mnemonics, vector1.mnemonics,
            "Mnemonics must match golden vector — backward compatibility broken!")
    }

    /// Test Vector 1: Decrypt golden backup with all 5 spots
    func testVector1_DecryptBackupWith5Spots() {
        let spots = vector1.spots
        guard let wujiName = vector1.wujiName else {
            XCTFail("WujiName creation failed")
            return
        }

        guard let encryptedData = vector1.encryptedData else {
            XCTFail("Failed to decode encrypted backup base64")
            return
        }

        let result = WujiReserve.decrypt(
            data: encryptedData,
            spots: spots,
            positionCodes: vector1.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: vector1.argon2Params
        )

        guard case .success(let decrypted) = result else {
            XCTFail("Decryption of golden backup failed — backward compatibility broken! Error: \(result)")
            return
        }

        XCTAssertEqual(decrypted.mnemonics, vector1.mnemonics,
            "Decrypted mnemonics must match golden vector")
    }

    /// Test Vector 1: Recovery from golden backup with 3 spots (3-of-5 threshold)
    func testVector1_RecoverBackupWith3Spots() {
        let spots = vector1.spots
        guard let wujiName = vector1.wujiName else {
            XCTFail("WujiName creation failed")
            return
        }

        guard let encryptedData = vector1.encryptedData else {
            XCTFail("Failed to decode encrypted backup base64")
            return
        }

        // Try recovery with first 3 spots
        let recoverySpots = Array(spots[0..<3])
        let input = WujiReserve.RecoveryInput(
            spots: recoverySpots,
            allPositionCodes: vector1.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encryptedData,
            argon2Params: vector1.argon2Params
        )

        let result = WujiReserve.decryptWithRecovery(input: input)

        guard case .success(let recovered) = result else {
            XCTFail("Recovery with 3 spots failed — threshold recovery broken! Error: \(result)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, vector1.mnemonics,
            "Recovered mnemonics must match golden vector")
    }

    // MARK: - Vector 2 Tests

    /// Test Vector 2: Name normalization and salt generation
    func testVector2_NameSalt() {
        guard let wujiName = vector2.wujiName else {
            XCTFail("Failed to create WujiName from vector2")
            return
        }

        XCTAssertEqual(wujiName.normalized, vector2.normalizedName,
            "Normalized name must match golden vector")

        let saltHex = wujiName.salt.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(saltHex, vector2.nameSaltHex,
            "Name salt must match golden vector")
    }

    /// Test Vector 2: Position codes from spot processing
    func testVector2_PositionCodes() {
        let spots = vector2.spots
        XCTAssertEqual(spots.count, 5, "Should create 5 spots from vector2")

        guard case .success(let result) = WujiSpot.process(spots) else {
            XCTFail("WujiSpot.process failed for vector2")
            return
        }

        XCTAssertEqual(result.positionCodes, vector2.positionCodes,
            "Position codes must match golden vector")
    }

    /// Test Vector 2: Memory processing matches expected values
    func testVector2_MemoryProcessing() {
        for (index, location) in vector2.locations.enumerated() {
            let processedMemory = WujiMemoryTagProcessor.process(location.memoryTags)
            XCTAssertEqual(processedMemory, location.memoryProcessed,
                "Memory processing for location \(index + 1) must match golden vector")
        }
    }

    /// Test Vector 2: Full generation produces expected mnemonics
    func testVector2_GenerateMnemonics() {
        let spots = vector2.spots
        guard let wujiName = vector2.wujiName else {
            XCTFail("WujiName creation failed")
            return
        }

        guard case .success(let processResult) = WujiSpot.process(spots) else {
            XCTFail("WujiSpot.process failed")
            return
        }

        guard let keyData = CryptoUtils.argon2id(
            password: processResult.combinedData,
            salt: wujiName.salt,
            parameters: vector2.argon2Params
        ) else {
            XCTFail("Argon2id failed")
            return
        }

        let keyDataHex = keyData.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(keyDataHex, vector2.keyDataHex,
            "KeyData must match golden vector — KDF backward compatibility broken!")

        guard let mnemonics = BIP39Helper.generate24Words(from: keyData) else {
            XCTFail("BIP39 generation failed")
            return
        }

        XCTAssertEqual(mnemonics, vector2.mnemonics,
            "Mnemonics must match golden vector — backward compatibility broken!")
    }

    /// Test Vector 2: Decrypt golden backup with all 5 spots
    func testVector2_DecryptBackupWith5Spots() {
        let spots = vector2.spots
        guard let wujiName = vector2.wujiName else {
            XCTFail("WujiName creation failed")
            return
        }

        guard let encryptedData = vector2.encryptedData else {
            XCTFail("Failed to decode encrypted backup base64")
            return
        }

        let result = WujiReserve.decrypt(
            data: encryptedData,
            spots: spots,
            positionCodes: vector2.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: vector2.argon2Params
        )

        guard case .success(let decrypted) = result else {
            XCTFail("Decryption of golden backup failed — backward compatibility broken! Error: \(result)")
            return
        }

        XCTAssertEqual(decrypted.mnemonics, vector2.mnemonics,
            "Decrypted mnemonics must match golden vector")
    }

    /// Test Vector 2: Recovery from golden backup with 3 spots (3-of-5 threshold)
    func testVector2_RecoverBackupWith3Spots() {
        let spots = vector2.spots
        guard let wujiName = vector2.wujiName else {
            XCTFail("WujiName creation failed")
            return
        }

        guard let encryptedData = vector2.encryptedData else {
            XCTFail("Failed to decode encrypted backup base64")
            return
        }

        // Try recovery with first 3 spots
        let recoverySpots = Array(spots[0..<3])
        let input = WujiReserve.RecoveryInput(
            spots: recoverySpots,
            allPositionCodes: vector2.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encryptedData,
            argon2Params: vector2.argon2Params
        )

        let result = WujiReserve.decryptWithRecovery(input: input)

        guard case .success(let recovered) = result else {
            XCTFail("Recovery with 3 spots failed — threshold recovery broken! Error: \(result)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, vector2.mnemonics,
            "Recovered mnemonics must match golden vector")
    }

    // MARK: - Cross-Vector Tests

    /// Test: Vector 1 and Vector 2 should produce different outputs
    func testVectorsProduceDifferentOutputs() {
        XCTAssertNotEqual(vector1.normalizedName, vector2.normalizedName,
            "Different inputs should produce different normalized names")
        XCTAssertNotEqual(vector1.nameSaltHex, vector2.nameSaltHex,
            "Different inputs should produce different salts")
        XCTAssertNotEqual(vector1.keyDataHex, vector2.keyDataHex,
            "Different inputs should produce different key data")
        XCTAssertNotEqual(vector1.mnemonics, vector2.mnemonics,
            "Different inputs should produce different mnemonics")
    }

    /// Test: Vector parameters match expected production values
    func testVectorsUseProductionParameters() {
        // Both vectors should use production Argon2id parameters
        XCTAssertEqual(vector1.argon2Parameters.memoryKB, 256 * 1024,
            "Vector 1 should use 256MB memory")
        XCTAssertEqual(vector1.argon2Parameters.iterations, 7,
            "Vector 1 should use 7 iterations")
        XCTAssertEqual(vector1.argon2Parameters.parallelism, 1,
            "Vector 1 should use 1 thread")

        XCTAssertEqual(vector2.argon2Parameters.memoryKB, 256 * 1024,
            "Vector 2 should use 256MB memory")
        XCTAssertEqual(vector2.argon2Parameters.iterations, 7,
            "Vector 2 should use 7 iterations")
        XCTAssertEqual(vector2.argon2Parameters.parallelism, 1,
            "Vector 2 should use 1 thread")
    }
}
