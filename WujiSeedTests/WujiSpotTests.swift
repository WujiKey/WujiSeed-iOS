//
//  WujiSpotTests.swift
//  WujiSeedTests
//
//  WujiSpot unit tests
//  Tests location record with merged memory processing
//
//  Data source: wujikey_v1_vector_1.json (for coordinates and memory data)
//

import XCTest
@testable import WujiSeed

class WujiSpotTests: XCTestCase {

    // MARK: - Test Data

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
    }

    // MARK: - Initialization Tests

    func testBasicInitialization() {
        // Use first location from test vector
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "山腰水帘洞花果山")
        XCTAssertNotNil(spot, "Should create WujiSpot with valid inputs")
        XCTAssertEqual(spot?.place.latitude, "34.61709", "Latitude should match")
        XCTAssertEqual(spot?.place.longitude, "119.19184", "Longitude should match")
        XCTAssertEqual(spot?.memory.normalized, "山腰水帘洞花果山", "Memory should be normalized")
    }

    func testInitializationWithInvalidCoordinates() {
        let spot = WujiSpot(coordinates: "invalid", memory: "test")
        XCTAssertNil(spot, "Should return nil for invalid coordinates")
    }

    func testInitializationWithEmptyMemory() {
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "")
        XCTAssertNil(spot, "Should return nil for empty memory")
    }

    func testInitializationWithWhitespaceOnlyMemory() {
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "   ")
        XCTAssertNil(spot, "Should return nil for whitespace-only memory")
    }

    // MARK: - Memory Normalization Tests

    func testMemoryNormalization() {
        // Memory should be normalized using WujiNormalizer
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "  Hello  WORLD  ")
        XCTAssertNotNil(spot)
        XCTAssertEqual(spot?.memory.normalized, "hello world", "Memory should be normalized")
    }

    func testMemoryWithChinesePunctuation() {
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "你好，世界！")
        XCTAssertNotNil(spot)
        XCTAssertEqual(spot?.memory.normalized, "你好,世界!", "Chinese punctuation should be converted")
    }

    // MARK: - KeyMaterial Tests

    func testKeyMaterialGeneration() {
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "testmemory")
        XCTAssertNotNil(spot)

        let keyMaterial = spot?.keyMaterial()
        XCTAssertNotNil(keyMaterial, "Should generate keyMaterial")

        // KeyMaterial format: memory(UTF-8) + cellIndex(8 bytes big-endian)
        // Memory "testmemory" = 10 bytes
        // CellIndex = 8 bytes
        // Total should be 18 bytes
        XCTAssertEqual(keyMaterial?.count, 18, "KeyMaterial should be memory + 8 bytes for cellIndex")
    }

    // MARK: - Position Code Tests

    func testPositionCode() {
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: "test")
        XCTAssertNotNil(spot)

        let positionCode = spot?.positionCode()
        XCTAssertNotNil(positionCode, "Should calculate position code")
        XCTAssertTrue((1...9).contains(positionCode!), "Position code should be 1-9")

        // Verify it matches the golden vector
        XCTAssertEqual(positionCode, location.positionCode,
            "Position code should match golden vector value")
    }

    // MARK: - Batch Processing Tests

    func testBatchProcessing() {
        // Use test vector data (Journey to the West locations)
        let spots = testVector.spots
        XCTAssertEqual(spots.count, 5, "Should have 5 spots from test vector")

        // Process spots
        let result = WujiSpot.process(spots)

        switch result {
        case .success(let processResult):
            XCTAssertEqual(processResult.keyMaterials.count, 5, "Should have 5 keyMaterials")
            XCTAssertEqual(processResult.positionCodes.count, 5, "Should have 5 position codes")
            XCTAssertFalse(processResult.combinedData.isEmpty, "Combined data should not be empty")

            // All position codes should be 1-9
            for code in processResult.positionCodes {
                XCTAssertTrue((1...9).contains(code), "Position code \(code) should be 1-9")
            }

        case .failure(let error):
            XCTFail("Processing failed: \(error)")
        }
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let location = testVector.locations[0]
        let spot1 = WujiSpot(coordinates: location.coordinate, memory: "test")
        let spot2 = WujiSpot(coordinates: location.coordinate, memory: "test")
        let spot3 = WujiSpot(coordinates: location.coordinate, memory: "different")

        XCTAssertEqual(spot1, spot2, "Same inputs should be equal")
        XCTAssertNotEqual(spot1, spot3, "Different memory should not be equal")
    }

    // MARK: - Integration with WujiMemoryTagProcessor Tests

    func testIntegrationWithTagProcessor() {
        // Simulate the full flow: separate tags -> merge -> process -> create spot
        let memory1Tags = ["女娲", "补天石", "诞生"]
        let memory2Tags = ["山腰", "水帘洞", "花果山"]

        // Merge and process (as done in PlacesDataManager.memoryProcessed)
        let allTags = memory1Tags + memory2Tags
        let processedMemory = WujiMemoryTagProcessor.process(allTags)

        // Create spot with processed memory using test vector coordinate
        let location = testVector.locations[0]
        let spot = WujiSpot(coordinates: location.coordinate, memory: processedMemory)
        XCTAssertNotNil(spot, "Should create spot with processed memory")

        // Verify memory is correctly stored
        XCTAssertEqual(spot?.memory.normalized, processedMemory, "Memory should match processed value")

        // Verify keyMaterial can be generated
        XCTAssertNotNil(spot?.keyMaterial(), "Should generate keyMaterial")
    }

    func testMergedVsSeparateMemoryProducesDifferentResults() {
        // This test documents that the new merged approach produces DIFFERENT results
        // than the old separate approach (which is expected - it's a breaking change)

        let memory1Tags = ["女娲", "补天石", "诞生"]
        let memory2Tags = ["山腰", "水帘洞", "花果山"]

        // New approach: merge all tags, then sort
        let mergedProcessed = WujiMemoryTagProcessor.process(memory1Tags + memory2Tags)

        // Old approach: sort each separately, then concatenate
        let memory1Processed = WujiMemoryTagProcessor.process(memory1Tags)
        let memory2Processed = WujiMemoryTagProcessor.process(memory2Tags)

        // Sort the two processed strings and concatenate
        let oldApproachResult: String
        if memory1Processed <= memory2Processed {
            oldApproachResult = memory1Processed + memory2Processed
        } else {
            oldApproachResult = memory2Processed + memory1Processed
        }

        // They should be different (this documents the breaking change)
        XCTAssertNotEqual(mergedProcessed, oldApproachResult,
            "Merged approach should produce different result than old separate approach")

        // Document what each approach produces
        print("New merged approach: \(mergedProcessed)")
        print("Old separate approach: \(oldApproachResult)")
    }
}
