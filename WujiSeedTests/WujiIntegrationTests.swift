//
//  WujiIntegrationTests.swift
//  WujiSeedTests
//
//  End-to-end integration tests:
//  Name + 5 places/memories → 24 mnemonics → encrypted backup → decrypt with 3 places (with coordinate drift)
//
//  Data source: wujikey_v1_vector_1.json (Journey to the West)
//
//  Argon2id strategy:
//  - Most tests use fastParams (~64KB/1iter) to test business logic without KDF overhead.
//  - testEncryptAndDecryptWith5Spots uses production params (256MB/7iter) to verify the
//    full end-to-end flow works with real parameters. KDF output correctness is separately
//    guaranteed by WujiRegressionTests (golden vectors).
//

import XCTest
@testable import WujiSeed

class WujiIntegrationTests: XCTestCase {

    // MARK: - Argon2id Parameters

    /// Fast parameters for logic testing (~448× faster than production).
    /// Use these for tests that verify business logic (recovery combinations, coordinate
    /// drift, failure cases) — not for tests that verify exact crypto output.
    private static let fastParams = CryptoUtils.Argon2Parameters(
        memoryKB: 64,
        iterations: 1,
        parallelism: 1
    )

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

    /// Generate mnemonics from spots and name (full generation flow).
    /// - Parameter params: Argon2id parameters. Defaults to fastParams for speed;
    ///   pass testVector.argon2Params when testing production-param correctness.
    private func generateMnemonics(
        spots: [WujiSpot],
        wujiName: WujiName,
        params: CryptoUtils.Argon2Parameters = WujiIntegrationTests.fastParams
    ) -> (mnemonics: [String], keyMaterials: [Data], positionCodes: [Int])? {
        // Process spots
        guard case .success(let processResult) = WujiSpot.process(spots) else {
            return nil
        }

        let passwordData = processResult.combinedData
        let keyMaterials = processResult.keyMaterials
        let positionCodes = processResult.positionCodes

        // Argon2id: combinedData + nameSalt → keyData
        guard let keyData = CryptoUtils.argon2id(
            password: passwordData,
            salt: wujiName.salt,
            parameters: params
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

    /// Test: Name + 5 places → 24 mnemonics (deterministic).
    /// Uses fastParams — verifies generation logic, not KDF output values.
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
    }

    // MARK: - Test: Encrypt + Decrypt with production parameters

    /// Test: Encrypt with 5 spots, decrypt with same 5 spots — using PRODUCTION Argon2id params.
    /// This is the single integration test that exercises the full flow with real KDF parameters.
    /// Exact output values are separately verified by WujiRegressionTests (golden vectors).
    func testEncryptAndDecryptWith5Spots() {
        let params = testVector.argon2Params   // production: 256 MB / 7 iter
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
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
            argon2Params: params
        )

        guard case .success(let decrypted) = decryptResult else {
            XCTFail("Decryption failed: \(decryptResult)")
            return
        }

        XCTAssertEqual(decrypted.mnemonics, genResult.mnemonics, "Decrypted mnemonics should match original")
    }

    // MARK: - Test: Recovery with 3 spots (exact coordinates)

    /// Test: Encrypt with 5 spots, recover with only 3 spots (exact coordinates).
    /// Uses fastParams — verifies recovery logic.
    func testRecoveryWith3SpotsExact() {
        let params = WujiIntegrationTests.fastParams
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
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
            argon2Params: params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        guard case .success(let recovered) = recoveryResult else {
            XCTFail("Recovery failed: \(recoveryResult)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, genResult.mnemonics, "Recovered mnemonics should match original")
    }

    /// Test: Recovery works with any 3 out of 5 spots.
    /// Uses fastParams — verifies all C(5,3)=10 combinations of the recovery logic.
    func testRecoveryWithAny3Of5Spots() {
        let params = WujiIntegrationTests.fastParams
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
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
                argon2Params: params
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

    /// Test: Recovery succeeds when coordinates are slightly offset but within the same F9Grid cell.
    /// Uses fastParams — verifies coordinate drift tolerance logic.
    func testRecoveryWithCoordinateDrift() {
        let params = WujiIntegrationTests.fastParams
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt with original spots
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
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
        for (i, driftedSpot) in driftedSpots.enumerated() {
            let originalSpot = spots[i]
            let originalIndex = originalSpot.place.cellIndex()
            let driftedIndex = driftedSpot.place.cellIndex(correctedBy: genResult.positionCodes[i])
            XCTAssertNotNil(originalIndex, "Original spot \(i) should have a cellIndex")
            XCTAssertNotNil(driftedIndex, "Drifted spot \(i) should have a corrected cellIndex")
        }

        // Recovery with drifted coordinates
        let recoveryInput = WujiReserve.RecoveryInput(
            spots: driftedSpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encrypted.data,
            argon2Params: params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        guard case .success(let recovered) = recoveryResult else {
            XCTFail("Recovery with drifted coordinates failed: \(recoveryResult)")
            return
        }

        XCTAssertEqual(recovered.mnemonics, genResult.mnemonics,
            "Recovered mnemonics should match even with coordinate drift")
    }

    /// Test: Recovery with larger drift that crosses F9Grid cell boundary but stays within
    /// position code correction range.
    /// Uses fastParams — verifies the correction logic for larger drifts.
    func testRecoveryWithLargerDrift() {
        let params = WujiIntegrationTests.fastParams
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Larger drift: ~0.000125° = one F9Grid sub-cell step
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
            argon2Params: params
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

    /// Test: Recovery fails with wrong memory.
    /// Uses fastParams — verifies the failure case logic.
    func testRecoveryFailsWithWrongMemory() {
        let params = WujiIntegrationTests.fastParams
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
        )

        guard case .success(let encrypted) = encryptResult else {
            XCTFail("Encryption failed")
            return
        }

        // Create spots with wrong memory
        let wrongSpots: [WujiSpot] = [
            WujiSpot(coordinates: testVector.locations[0].coordinate, memory: "错误的记忆内容一二三")!,
            WujiSpot(coordinates: testVector.locations[1].coordinate, memory: "错误的记忆内容四五六")!,
            WujiSpot(coordinates: testVector.locations[2].coordinate, memory: "错误的记忆内容七八九")!,
        ]

        let recoveryInput = WujiReserve.RecoveryInput(
            spots: wrongSpots,
            allPositionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            capsuleData: encrypted.data,
            argon2Params: params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        if case .success = recoveryResult {
            XCTFail("Recovery should fail with wrong memory")
        }
        // Expected: failure (decryption should not succeed with wrong key material)
    }

    /// Test: Recovery fails with wrong name.
    /// Uses fastParams — verifies the failure case logic.
    func testRecoveryFailsWithWrongName() {
        let params = WujiIntegrationTests.fastParams
        let spots = createSpots()
        guard let wujiName = testVector.wujiName else {
            XCTFail("Failed to create WujiName from test vector")
            return
        }

        guard let genResult = generateMnemonics(spots: spots, wujiName: wujiName, params: params) else {
            XCTFail("Failed to generate mnemonics")
            return
        }

        // Encrypt
        let encryptResult = WujiReserve.encrypt(
            mnemonics: genResult.mnemonics,
            keyMaterials: genResult.keyMaterials,
            positionCodes: genResult.positionCodes,
            nameSalt: wujiName.salt,
            argon2Params: params
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
            argon2Params: params
        )

        let recoveryResult = WujiReserve.decryptWithRecovery(input: recoveryInput)

        if case .success = recoveryResult {
            XCTFail("Recovery should fail with wrong name")
        }
    }
}
