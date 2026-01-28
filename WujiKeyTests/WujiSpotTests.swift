//
//  WujiSpotTests.swift
//  WujiKeyTests
//
//  WujiSpot unit tests
//  Tests location record with merged memory processing
//

import XCTest
@testable import WujiKey

class WujiSpotTests: XCTestCase {

    // MARK: - Initialization Tests

    func testBasicInitialization() {
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "山腰水帘洞花果山")
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
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "")
        XCTAssertNil(spot, "Should return nil for empty memory")
    }

    func testInitializationWithWhitespaceOnlyMemory() {
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "   ")
        XCTAssertNil(spot, "Should return nil for whitespace-only memory")
    }

    // MARK: - Memory Normalization Tests

    func testMemoryNormalization() {
        // Memory should be normalized using WujiNormalizer
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "  Hello  WORLD  ")
        XCTAssertNotNil(spot)
        XCTAssertEqual(spot?.memory.normalized, "hello world", "Memory should be normalized")
    }

    func testMemoryWithChinesePunctuation() {
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "你好，世界！")
        XCTAssertNotNil(spot)
        XCTAssertEqual(spot?.memory.normalized, "你好,世界!", "Chinese punctuation should be converted")
    }

    // MARK: - KeyMaterial Tests

    func testKeyMaterialGeneration() {
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "testmemory")
        XCTAssertNotNil(spot)

        let keyMaterial = spot?.keyMaterial()
        XCTAssertNotNil(keyMaterial, "Should generate keyMaterial")

        // KeyMaterial format: memory(UTF-8) + cellIndex(8 bytes big-endian)
        // Memory "testmemory" = 10 bytes
        // CellIndex = 8 bytes
        // Total should be 18 bytes
        XCTAssertEqual(keyMaterial?.count, 18, "KeyMaterial should be memory + 8 bytes for cellIndex")
    }

    func testKeyMaterialDeterminism() {
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "女娲山腰水帘洞补天石花果山诞生")
        XCTAssertNotNil(spot)

        var results = Set<Data>()
        for _ in 0..<100 {
            if let km = spot?.keyMaterial() {
                results.insert(km)
            }
        }

        XCTAssertEqual(results.count, 1, "Same spot should always produce same keyMaterial")
    }

    // MARK: - Position Code Tests

    func testPositionCode() {
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: "test")
        XCTAssertNotNil(spot)

        let positionCode = spot?.positionCode()
        XCTAssertNotNil(positionCode, "Should calculate position code")
        XCTAssertTrue((1...9).contains(positionCode!), "Position code should be 1-9")
    }

    // MARK: - Batch Processing Tests

    func testBatchProcessing() {
        // Create 5 spots with merged memory strings (Unicode sorted order)
        let testData: [(coord: String, memory: String)] = [
            ("34.617090, 119.191840", "女娲山腰水帘洞花果山补天石诞生"),
            ("35.066260, 107.614560", "七十二变八九年学礼找神仙筋斗云菩提祖师"),
            ("11.373300, 142.591700", "一万三千五百斤借兵器如意金箍棒定海神针敖广行头"),
            ("29.976330, 122.389360", "三番五次取经帮忙白龙马菩萨西天"),
            ("24.695100, 84.991300", "九九八十一难修行圣地成佛法门释迦摩尼"),
        ]

        var spots: [WujiSpot] = []
        for data in testData {
            guard let spot = WujiSpot(coordinates: data.coord, memory: data.memory) else {
                XCTFail("Failed to create spot")
                return
            }
            spots.append(spot)
        }

        XCTAssertEqual(spots.count, 5, "Should have 5 spots")

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

    func testBatchProcessingDeterminism() {
        let testData: [(coord: String, memory: String)] = [
            ("34.617090, 119.191840", "女娲山腰水帘洞花果山补天石诞生"),
            ("35.066260, 107.614560", "七十二变八九年学礼找神仙筋斗云菩提祖师"),
            ("11.373300, 142.591700", "一万三千五百斤借兵器如意金箍棒定海神针敖广行头"),
            ("29.976330, 122.389360", "三番五次取经帮忙白龙马菩萨西天"),
            ("24.695100, 84.991300", "九九八十一难修行圣地成佛法门释迦摩尼"),
        ]

        var spots: [WujiSpot] = []
        for data in testData {
            guard let spot = WujiSpot(coordinates: data.coord, memory: data.memory) else {
                XCTFail("Failed to create spot")
                return
            }
            spots.append(spot)
        }

        // Process multiple times
        var combinedResults = Set<Data>()
        var positionCodeResults = Set<[Int]>()

        for _ in 0..<10 {
            if case .success(let result) = WujiSpot.process(spots) {
                combinedResults.insert(result.combinedData)
                positionCodeResults.insert(result.positionCodes)
            }
        }

        XCTAssertEqual(combinedResults.count, 1, "Combined data should be deterministic")
        XCTAssertEqual(positionCodeResults.count, 1, "Position codes should be deterministic")
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let spot1 = WujiSpot(coordinates: "34.617090, 119.191840", memory: "test")
        let spot2 = WujiSpot(coordinates: "34.617090, 119.191840", memory: "test")
        let spot3 = WujiSpot(coordinates: "34.617090, 119.191840", memory: "different")

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

        // Create spot with processed memory
        let spot = WujiSpot(coordinates: "34.617090, 119.191840", memory: processedMemory)
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
