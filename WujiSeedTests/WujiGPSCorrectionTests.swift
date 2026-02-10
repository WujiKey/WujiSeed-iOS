//
//  WujiGPSCorrectionTests.swift
//  WujiSeedTests
//
//  Test GPS correction functionality by generating multiple coordinates
//  that map to the same F9Grid cellId (for testing GPS error tolerance)
//

import XCTest
@testable import WujiSeed
import F9Grid

class WujiGPSCorrectionTests: XCTestCase {

    // MARK: - Test Data Structures

    struct GPSCorrectionTestVector: Codable {
        let version: String
        let description: String
        let purpose: String
        let generatedAt: String
        let testCases: [TestCase]

        struct TestCase: Codable {
            let name: String
            let baseCoordinate: String
            let cellId: String
            let cellIdHex: String
            let note: String
            let coordinates: [CoordinateVariant]
            let hemisphere: String
        }

        struct CoordinateVariant: Codable {
            let coordinate: String
            let lat: Double
            let lng: Double
            let positionCode: Int
            let cellIdVerification: String
            let description: String
        }
    }

    // MARK: - Helper Methods

    /// Generate coordinates within the same F9Grid cell by sampling the 9-grid positions
    /// - Parameters:
    ///   - baseLat: Base latitude
    ///   - baseLng: Base longitude
    /// - Returns: Array of (lat, lng, positionCode, description)
    func generateSameCellCoordinates(baseLat: Double, baseLng: Double) -> [(lat: Double, lng: Double, positionCode: Int, description: String)] {
        guard let baseCell = F9Grid.cell(lat: String(baseLat), lng: String(baseLng)) else {
            print("❌ Failed to get cell for base coordinate")
            return []
        }

        let baseCellId = baseCell.index
        var results: [(Double, Double, Int, String)] = []

        // Get cell bounds
        let bounds = baseCell.bounds()
        let minLat = bounds.minLat
        let maxLat = bounds.maxLat
        let minLng = bounds.minLng
        let maxLng = bounds.maxLng

        // Generate 9 sample points for the 9-grid (3x3) within the cell
        // Position codes:
        // 4(NW)  9(N)   2(NE)
        // 3(W)   5(C)   7(E)
        // 8(SW)  1(S)   6(SE)

        let positions: [(rowFactor: Double, colFactor: Double, code: Int, name: String)] = [
            (0.75, 0.5, 9, "North"),           // Top middle
            (0.75, 0.75, 2, "Northeast"),      // Top right
            (0.5, 0.75, 7, "East"),            // Middle right
            (0.25, 0.75, 6, "Southeast"),      // Bottom right
            (0.25, 0.5, 1, "South"),           // Bottom middle
            (0.25, 0.25, 8, "Southwest"),      // Bottom left
            (0.5, 0.25, 3, "West"),            // Middle left
            (0.75, 0.25, 4, "Northwest"),      // Top left
            (0.5, 0.5, 5, "Center")            // Center
        ]

        for (rowFactor, colFactor, expectedCode, name) in positions {
            // Calculate coordinate within cell
            let lat = Double(minLat) + (Double(maxLat) - Double(minLat)) * rowFactor
            let lng = Double(minLng) + (Double(maxLng) - Double(minLng)) * colFactor

            // Verify it's in the same cell
            guard let cell = F9Grid.cell(lat: String(lat), lng: String(lng)) else {
                print("⚠️  Failed to get cell for \(name) position")
                continue
            }

            if cell.index == baseCellId {
                // Calculate actual position code
                let actualPositionCode = cell.positionCode(lat: Decimal(lat), lng: Decimal(lng)) ?? -1

                results.append((lat, lng, actualPositionCode, "\(name) (expected: \(expectedCode), actual: \(actualPositionCode))"))
            } else {
                print("⚠️  \(name) position fell outside cell bounds")
            }
        }

        return results
    }

    /// Format cell ID as hex string
    func cellIdToHex(_ cellId: Int64) -> String {
        return String(format: "0x%016llX", cellId)
    }

    /// Get hemisphere description
    func hemisphereDescription(lat: Double, lng: Double) -> String {
        let ns = lat >= 0 ? "Northern" : "Southern"
        let ew = lng >= 0 ? "Eastern" : "Western"
        return "\(ns) & \(ew)"
    }

    // MARK: - Test Vector Generation

    /// Generate GPS correction test vectors and save to JSON
    /// This test is disabled by default - enable to regenerate vectors
    func testGenerateGPSCorrectionVectors() throws {
        // Base coordinates from existing test vectors
        let baseCoordinates: [(lat: Double, lng: Double, name: String, note: String)] = [
            (34.617090, 119.191840, "Huaguo Mountain (花果山)", "Journey to the West - Monkey King birthplace"),
            (35.066260, 107.614560, "Subhodi's Cave (菩提祖师)", "Journey to the West - Learning 72 transformations"),
            (11.373300, 142.591700, "East Sea Dragon Palace (东海龙宫)", "Journey to the West - Golden Cudgel source"),
            (30.0444, 31.2357, "Cairo, Egypt", "Moses Exodus - Slavery and oppression"),
            (28.5392, 33.9752, "Mount Sinai", "Moses Exodus - Ten Commandments"),
            (-33.9249, 18.4241, "Cape Town, South Africa", "Southern Hemisphere - Journey's symbolic end"),
            (40.7128, -74.0060, "New York, USA", "Western Hemisphere - Symbol of freedom")
        ]

        var testCases: [GPSCorrectionTestVector.TestCase] = []

        for (index, coord) in baseCoordinates.enumerated() {
            print("\n[\(index + 1)/\(baseCoordinates.count)] Processing: \(coord.name)")
            print("  Base: \(String(format: "%.6f, %.6f", coord.lat, coord.lng))")

            // Get base cell
            guard let baseCell = F9Grid.cell(lat: String(coord.lat), lng: String(coord.lng)) else {
                print("  ❌ Failed to get cell")
                continue
            }

            let baseCellId = baseCell.index
            let baseCellIdHex = cellIdToHex(baseCellId)

            print("  Cell ID: \(baseCellId) (\(baseCellIdHex))")

            // Generate variants within the same cell
            let variants = generateSameCellCoordinates(baseLat: coord.lat, baseLng: coord.lng)
            print("  Generated \(variants.count) coordinates in same cell")

            var coordinates: [GPSCorrectionTestVector.CoordinateVariant] = []

            // Add base coordinate
            let basePositionCode = baseCell.positionCode(lat: Decimal(coord.lat), lng: Decimal(coord.lng)) ?? -1
            coordinates.append(GPSCorrectionTestVector.CoordinateVariant(
                coordinate: String(format: "%.6f, %.6f", coord.lat, coord.lng),
                lat: coord.lat,
                lng: coord.lng,
                positionCode: basePositionCode,
                cellIdVerification: baseCellIdHex,
                description: "Original coordinate (base)"
            ))

            // Add variants
            for (i, variant) in variants.enumerated() {
                // Verify cell ID matches
                if let variantCell = F9Grid.cell(lat: String(variant.lat), lng: String(variant.lng)),
                   variantCell.index == baseCellId {
                    coordinates.append(GPSCorrectionTestVector.CoordinateVariant(
                        coordinate: String(format: "%.6f, %.6f", variant.lat, variant.lng),
                        lat: variant.lat,
                        lng: variant.lng,
                        positionCode: variant.positionCode,
                        cellIdVerification: cellIdToHex(variantCell.index),
                        description: variant.description
                    ))
                }
            }

            testCases.append(GPSCorrectionTestVector.TestCase(
                name: coord.name,
                baseCoordinate: String(format: "%.6f, %.6f", coord.lat, coord.lng),
                cellId: String(baseCellId),
                cellIdHex: baseCellIdHex,
                note: coord.note,
                coordinates: coordinates,
                hemisphere: hemisphereDescription(lat: coord.lat, lng: coord.lng)
            ))

            print("  ✅ Added \(coordinates.count) coordinates (including base)")
        }

        // Create final vector
        let dateFormatter = ISO8601DateFormatter()
        let vector = GPSCorrectionTestVector(
            version: "1.0",
            description: "GPS correction test vectors - multiple coordinates mapping to same F9Grid cellId",
            purpose: "Verify that GPS coordinates within the same F9Grid cell are correctly identified and can be corrected using position codes. Tests GPS error tolerance and cell boundary handling.",
            generatedAt: dateFormatter.string(from: Date()),
            testCases: testCases
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let jsonData = try encoder.encode(vector)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Save to file
        let outputPath = "/Users/shell/Source/WujiSeed-iOS/WujiSeedTests/GoldenVectors/gps_correction_vectors.json"
        try jsonString.write(toFile: outputPath, atomically: true, encoding: .utf8)

        print("\n" + "=".repeating(60))
        print("✅ GPS Correction Vectors Generated Successfully")
        print("=".repeating(60))
        print("Output: \(outputPath)")
        print("Test cases: \(testCases.count)")
        print("Total coordinates: \(testCases.reduce(0) { $0 + $1.coordinates.count })")
        print()

        // Print summary
        for testCase in testCases {
            print("• \(testCase.name): \(testCase.coordinates.count) coordinates in cell \(testCase.cellIdHex)")
        }
    }

    // MARK: - Validation Tests

    /// Test that generated vectors are valid
    func testValidateGPSCorrectionVectors() throws {
        let vectorsPath = "/Users/shell/Source/WujiSeed-iOS/WujiSeedTests/GoldenVectors/gps_correction_vectors.json"

        guard FileManager.default.fileExists(atPath: vectorsPath) else {
            print("⚠️  GPS correction vectors not found. Run testGenerateGPSCorrectionVectors() first.")
            return
        }

        let jsonData = try Data(contentsOf: URL(fileURLWithPath: vectorsPath))
        let decoder = JSONDecoder()
        let vectors = try decoder.decode(GPSCorrectionTestVector.self, from: jsonData)

        print("\nValidating GPS Correction Vectors...")
        print("Version: \(vectors.version)")
        print("Test cases: \(vectors.testCases.count)")

        for testCase in vectors.testCases {
            print("\n📍 \(testCase.name)")
            print("   Cell ID: \(testCase.cellId) (\(testCase.cellIdHex))")
            print("   Hemisphere: \(testCase.hemisphere)")
            print("   Coordinates: \(testCase.coordinates.count)")

            // Verify all coordinates map to same cell
            for coord in testCase.coordinates {
                guard let cell = F9Grid.cell(lat: String(coord.lat), lng: String(coord.lng)) else {
                    XCTFail("Failed to get cell for coordinate: \(coord.coordinate)")
                    continue
                }

                let cellIdStr = String(cell.index)
                XCTAssertEqual(cellIdStr, testCase.cellId,
                              "Coordinate \(coord.coordinate) has different cellId: \(cellIdStr) vs \(testCase.cellId)")

                // Verify position code
                let actualPositionCode = cell.positionCode(lat: Decimal(coord.lat), lng: Decimal(coord.lng))
                XCTAssertNotNil(actualPositionCode, "Failed to calculate position code for \(coord.coordinate)")
                XCTAssertEqual(actualPositionCode, coord.positionCode,
                              "Position code mismatch for \(coord.coordinate): \(actualPositionCode ?? -1) vs \(coord.positionCode)")
            }

            print("   ✅ All coordinates verified")
        }

        print("\n✅ GPS Correction Vectors Validation Complete")
    }

    // MARK: - GPS Correction Logic Tests

    /// Test GPS correction using position codes
    func testGPSCorrectionWithPositionCodes() throws {
        // Test that slightly different coordinates in the same cell can be corrected
        let baseCoord = (lat: 34.617090, lng: 119.191840)

        guard let baseCell = F9Grid.cell(lat: String(baseCoord.lat), lng: String(baseCoord.lng)) else {
            XCTFail("Failed to get base cell")
            return
        }

        let baseCellId = baseCell.index
        let basePositionCode = baseCell.positionCode(lat: Decimal(baseCoord.lat), lng: Decimal(baseCoord.lng))!

        print("\n🧪 Testing GPS Correction")
        print("Base: \(String(format: "%.6f, %.6f", baseCoord.lat, baseCoord.lng))")
        print("Cell ID: \(baseCellId)")
        print("Position Code: \(basePositionCode)")

        // Generate a slightly offset coordinate (simulating GPS error)
        let offsetLat = baseCoord.lat + 0.0001  // ~11 meters offset
        let offsetLng = baseCoord.lng + 0.0001

        guard let offsetCell = F9Grid.cell(lat: String(offsetLat), lng: String(offsetLng)) else {
            XCTFail("Failed to get offset cell")
            return
        }

        print("\nOffset coordinate: \(String(format: "%.6f, %.6f", offsetLat, offsetLng))")
        print("Offset Cell ID: \(offsetCell.index)")

        // Test findOriginalCell with base position code
        let correctedCellId = F9Grid.findOriginalCell(
            lat: String(offsetLat),
            lng: String(offsetLng),
            originalPositionCode: basePositionCode
        )

        print("Corrected Cell ID: \(correctedCellId ?? -1)")

        if offsetCell.index == baseCellId {
            // Offset is still in the same cell - correction should return same cell
            XCTAssertEqual(correctedCellId, baseCellId,
                          "Correction should preserve cell ID when offset is within same cell")
            print("✅ Offset within same cell - no correction needed")
        } else {
            // Offset crossed cell boundary - correction should find original cell
            XCTAssertEqual(correctedCellId, baseCellId,
                          "Correction should find original cell ID when offset crosses boundary")
            print("✅ Offset crossed boundary - correction recovered original cell")
        }
    }
}
