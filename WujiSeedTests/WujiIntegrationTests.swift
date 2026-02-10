//
//  WujiIntegrationTests.swift
//  WujiSeedTests
//
//  End-to-end integration tests:
//  Name + 5 places/memories → 24 mnemonics → encrypted backup → decrypt with 3 places (with coordinate drift)
//
//  Data source: wujikey_v1_vector_1.json (Journey to the West)
//

import XCTest
@testable import WujiSeed

class WujiIntegrationTests: XCTestCase {

    // MARK: - Test Vector

    /// Test vector loaded from wujikey_v1_vector_1.json
    private var testVector: GoldenTestVector!

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Load test vector from JSON
        guard let vector = GoldenVectorLoader.load("wujikey_v1_vector_1") else {
            XCTFail("Failed to load wujikey_v1_vector_1.json")
            return
        }
        testVector = vector

        print("✅ Loaded wujikey_v1_vector_1.json for integration tests: \(testVector.name)")
    }

    // MARK: - Helper Methods

    /// Create WujiSpots from test vector
    private func createSpots() -> [WujiSpot] {
        return testVector.spots
    }

    /// Generate mnemonics from spots and name (full generation flow)
    private func generateMnemonics(spots: [WujiSpot], wujiName: WujiName) -> (mnemonics: [String], keyMaterials: [Data], positionCodes: [Int])? {
        // Process spots
        guard case .success(let processResult) = WujiSpot.process(spots) else {
            return nil
        }

        let passwordData = processResult.combinedData
        let keyMaterials = processResult.keyMaterials
        let positionCodes = processResult.positionCodes

        // Argon2id: combinedData + nameSalt → keyData (using test vector params)
        guard let keyData = CryptoUtils.argon2id(
            password: passwordData,
            salt: wujiName.salt,
            parameters: testVector.argon2Params
        ) else {
            return nil
        }

        // BIP39: keyData → 24 mnemonics
        guard let mnemonics = BIP39Helper.generate24Words(from: keyData) else {
            return nil
        }

        return (mnemonics, keyMaterials, positionCodes)
    }

    // MARK: - Test: Full Generation Flow

    /// Test: Name + 5 places → 24 mnemonics (deterministic)
    func testGenerationProduces24Mnemonics() {
        let spots = createSpots()
        XCTAssertEqual(spots.count, 5, "Should create 5 spots")

        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let result = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        XCTAssertEqual(result.mnemonics.count, 24, "Should generate 24 mnemonics")
        XCTAssertEqual(result.keyMaterials.count, 5, "Should have 5 key materials")
        XCTAssertEqual(result.positionCodes.count, 5, "Should have 5 position codes")

        // All position codes should be 1-9
        for code in result.positionCodes {
            XCTAssertTrue((1...9).contains(code), "Position code \(code) should be 1-9")
        }

        // All mnemonics should be non-empty
        for word in result.mnemonics {
            XCTAssertFalse(word.isEmpty, "Mnemonic word should not be empty")
        }

        // Verify matches golden vector
        XCTAssertEqual(result.mnemonics, testVector.mnemonics,
            "Generated mnemonics should match golden vector")
        XCTAssertEqual(result.positionCodes, testVector.positionCodes,
            "Generated position codes should match golden vector")
    }

    /// Test: Generation is deterministic
    func testGenerationDeterminism() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let result1 = generateMnemonics(spots: spots, wujiName: wujiName),
              let result2 = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        XCTAssertEqual(result1.mnemonics, result2.mnemonics, "Same inputs should produce same mnemonics")
        XCTAssertEqual(result1.positionCodes, result2.positionCodes, "Same inputs should produce same position codes")
    }

    // MARK: - Test: Encrypt + Decrypt (Full 5 spots)

    /// Test: Encrypt with 5 spots, decrypt with same 5 spots
    func testEncryptAndDecryptWith5Spots() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed: \(encryptResult)")
            return
        }

        XCTAssertFalse(encrypted.data.isEmpty, "Encrypted data should not be empty")

        // Decrypt with all 5 spots
        let decryptResult = WujiReserve.decrypt(
            data: encrypted.data,
            spots: spots,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let decrypted) = decryptResult else {
            XCTFail("Decryption failed: \(decryptResult)")
            return
        }

        XCTAssertEqual(decrypted.mnemonics, genResult.mnemonics, "Decrypted mnemonics should match original")
    }

    // MARK: - Test: Recovery with 3 spots (exact coordinates)

    /// Test: Encrypt with 5 spots, recover with only 3 spots (exact coordinates)
    func testRecoveryWith3SpotsExact() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Recovery with 3 spots (first 3)
        let recoverySpots = Array(spots[0..<3])
        let recoveryInput = WujiReserve.RecoveryInput(
            spots: recoverySpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encrypted.data,
            argon2Params: testVector.argon2Params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        guard case .success(let recovered) = recoveryResult else {
            XCTFail("Recovery failed: \(recoveryResult)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, genResult.mnemonics, "Recovered mnemonics should match original")
    }

    /// Test: Recovery works with any 3 out of 5 spots
    func testRecoveryWithAny3Of5Spots() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Try all C(5,3)=10 combinations of 3 spots
        let combinations: [[Int]] = [
            [0, 1, 2], [0, 1, 3], [0, 1, 4], [0, 2, 3], [0, 2, 4],
            [0, 3, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [2, 3, 4]
        ]

        for combo in combinations {
            let recoverySpots = combo.map { spots[$0] }
            let recoveryInput = WujiReserve.RecoveryInput(
                spots: recoverySpots,
                allPositionCodes: genResult.positionCodes,
                nameSalt: wujiName.salt,
                capsuleData: encrypted.data,
                argon2Params: testVector.argon2Params
            )

            let result = WujiReserve.decryptWithRecovery(input: recoveryInput)

            guard case .success(let recovered) = result else {
                XCTFail("Recovery failed for combination \(combo): \(result)")
                continue
            }

            XCTAssertEqual(recovered.mnemonics, genResult.mnemonics,
                "Recovered mnemonics should match for combination \(combo)")
        }
    }

    // MARK: - Test: Recovery with coordinate drift (F9Grid tolerance)

    /// Test: Recovery succeeds when coordinates are slightly offset but within the same F9Grid cell
    func testRecoveryWithCoordinateDrift() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt with original spots
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Create drifted spots: add tiny offset within same F9Grid sub-cell
        // F9Grid cell height is 3/8000° = 0.000375° in latitude
        // Position code divides each cell into 3×3 = 9 zones, each ~0.000125°
        // Keep drift within ~0.00003° to stay in the same position code zone
        let driftedLocations: [(coord: String, memory: String)] = [
            ("34.617070, 119.191860", testVector.locations[0].memoryProcessed),  // ~2m drift
            ("35.066280, 107.614540", testVector.locations[1].memoryProcessed),  // ~2m drift
            ("11.373280, 142.591720", testVector.locations[2].memoryProcessed),  // ~2m drift
        ]

        var driftedSpots: [WujiSpot] = []
        for data in driftedLocations {
            guard let spot = WujiSpot(coordinates: data.coord, memory: data.memory) else {
                XCTFail("Failed to create drifted spot")
                return
            }
            driftedSpots.append(spot)
        }

        // Verify drifted spots resolve to same cellIndex via position code correction
        // During generation: cellIndex() (no correction) is used
        // During recovery: cellIndex(correctedBy:) is used to find the original cell
        for (i, driftedSpot) in driftedSpots.enumerated() {
            let originalSpot = spots[i]
            let originalIndex = originalSpot.place.cellIndex()
            let driftedIndex = driftedSpot.place.cellIndex(correctedBy: genResult.positionCodes[i])
            XCTAssertNotNil(originalIndex, "Original spot \(i) should have a cellIndex")
            XCTAssertNotNil(driftedIndex, "Drifted spot \(i) should have a corrected cellIndex")
            // Note: These may differ if the drift is too large. The real test is whether
            // decryptWithRecovery succeeds, which handles all the correction logic internally.
        }

        // Recovery with drifted coordinates
        let recoveryInput = WujiReserve.RecoveryInput(
            spots: driftedSpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encrypted.data,
            argon2Params: testVector.argon2Params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        guard case .success(let recovered) = recoveryResult else {
            XCTFail("Recovery with drifted coordinates failed: \(recoveryResult)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, genResult.mnemonics,
            "Recovered mnemonics should match even with coordinate drift")
    }

    /// Test: Recovery with larger drift that crosses F9Grid cell boundary but stays within position code correction range
    func testRecoveryWithLargerDrift() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Larger drift: ~0.000125° = one F9Grid sub-cell step
        // This may cross into an adjacent position code zone but findOriginalCell
        // should correct it back to the original cell using the stored position code
        let driftedLocations: [(coord: String, memory: String)] = [
            ("34.617200, 119.191960", testVector.locations[0].memoryProcessed),  // ~12m drift
            ("35.066370, 107.614680", testVector.locations[1].memoryProcessed),  // ~12m drift
            ("11.373190, 142.591820", testVector.locations[2].memoryProcessed),  // ~12m drift
        ]

        var driftedSpots: [WujiSpot] = []
        for data in driftedLocations {
            guard let spot = WujiSpot(coordinates: data.coord, memory: data.memory) else {
                XCTFail("Failed to create drifted spot")
                return
            }
            driftedSpots.append(spot)
        }

        // Verify drifted spots can be corrected (may or may not match exactly)
        for (i, driftedSpot) in driftedSpots.enumerated() {
            let correctedIndex = driftedSpot.place.cellIndex(correctedBy: genResult.positionCodes[i])
            XCTAssertNotNil(correctedIndex, "Drifted spot \(i) should be correctable")
        }

        // Recovery with drifted coordinates
        let recoveryInput = WujiReserve.RecoveryInput(
            spots: driftedSpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encrypted.data,
            argon2Params: testVector.argon2Params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        guard case .success(let recovered) = recoveryResult else {
            XCTFail("Recovery with larger drift failed: \(recoveryResult)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, genResult.mnemonics,
            "Recovered mnemonics should match even with larger coordinate drift")
    }

    // MARK: - Test: Negative cases

    /// Test: Recovery fails with wrong memory
    func testRecoveryFailsWithWrongMemory() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Create spots with wrong memory
        let wrongSpots: [WujiSpot] = [
            WujiSpot(coordinates: testLocations[0].coord, memory: "错误的记忆内容一二三")!,
            WujiSpot(coordinates: testLocations[1].coord, memory: "错误的记忆内容四五六")!,
            WujiSpot(coordinates: testLocations[2].coord, memory: "错误的记忆内容七八九")!,
        ]

        let recoveryInput = WujiReserve.RecoveryInput(
            spots: wrongSpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encrypted.data,
            argon2Params: testVector.argon2Params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        if case .success = recoveryResult {
            XCTFail("Recovery should fail with wrong memory")
        }
        // Expected: failure (decryption should not succeed with wrong key material)
    }

    /// Test: Recovery fails with wrong name
    func testRecoveryFailsWithWrongName() {
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: testVector.argon2Params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Try recovery with wrong name salt
        guard let wrongName = WujiName(raw: "猪八戒") else {
            XCTFail("Failed to create wrong WujiName")
            return
        }

        let recoverySpots = Array(spots[0..<3])
        let recoveryInput = WujiReserve.RecoveryInput(
            spots: recoverySpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wrongName.salt,
            capsuleData: encrypted.data,
            argon2Params: testVector.argon2Params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        if case .success = recoveryResult {
            XCTFail("Recovery should fail with wrong name")
        }
    }
}
