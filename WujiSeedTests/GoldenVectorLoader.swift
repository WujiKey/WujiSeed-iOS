//
//  GoldenVectorLoader.swift
//  WujiSeedTests
//
//  Loads golden test vectors from JSON files
//  Single source of truth - all tests should use this loader instead of hardcoding values
//

import Foundation
@testable import WujiSeed

/// Golden test vector data structure matching test_vector_*.json files
struct GoldenTestVector: Codable {
    let version: String
    let description: String
    let name: String
    let normalizedName: String
    let nameSaltHex: String
    let locations: [Location]
    let keyDataHex: String
    let mnemonics: [String]
    let encryptedBackupBase64: String
    let argon2Parameters: Argon2Params

    struct Location: Codable {
        let index: Int
        let coordinate: String
        let memoryTags: [String]
        let memoryProcessed: String
        let positionCode: Int
        let note: String?
    }

    struct Argon2Params: Codable {
        let memoryKB: Int
        let iterations: Int
        let parallelism: Int
    }
}

/// Loader for golden test vectors
class GoldenVectorLoader {

    /// Load a golden test vector from JSON file
    /// - Parameter filename: JSON filename (without path, e.g., "test_vector_1")
    /// - Returns: GoldenTestVector or nil if loading fails
    static func load(_ filename: String) -> GoldenTestVector? {
        // Try to find file in test bundle
        guard let bundle = Bundle(for: GoldenVectorLoader.self) else {
            print("❌ Failed to get test bundle")
            return nil
        }

        guard let path = bundle.path(forResource: filename, ofType: "json") else {
            print("❌ File not found: \(filename).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            let vector = try decoder.decode(GoldenTestVector.self, from: data)
            return vector
        } catch {
            print("❌ Failed to load \(filename).json: \(error)")
            return nil
        }
    }

    /// Convert GoldenTestVector locations to WujiSpot array
    /// - Parameter vector: Golden test vector
    /// - Returns: Array of WujiSpot
    static func createSpots(from vector: GoldenTestVector) -> [WujiSpot] {
        return vector.locations.compactMap { location in
            WujiSpot(coordinates: location.coordinate, memory: location.memoryProcessed)
        }
    }

    /// Create WujiName from golden test vector
    /// - Parameter vector: Golden test vector
    /// - Returns: WujiName or nil
    static func createName(from vector: GoldenTestVector) -> WujiName? {
        return WujiName(raw: vector.name)
    }

    /// Get Argon2id parameters from golden test vector
    /// - Parameter vector: Golden test vector
    /// - Returns: CryptoUtils.Argon2Parameters
    static func getArgon2Parameters(from vector: GoldenTestVector) -> CryptoUtils.Argon2Parameters {
        return CryptoUtils.Argon2Parameters(
            memoryKB: vector.argon2Parameters.memoryKB,
            iterations: vector.argon2Parameters.iterations,
            parallelism: vector.argon2Parameters.parallelism
        )
    }

    /// Get encrypted backup data from golden test vector
    /// - Parameter vector: Golden test vector
    /// - Returns: Data or nil if base64 decoding fails
    static func getEncryptedBackup(from vector: GoldenTestVector) -> Data? {
        return Data(base64Encoded: vector.encryptedBackupBase64)
    }

    /// Get expected position codes from golden test vector
    /// - Parameter vector: Golden test vector
    /// - Returns: Array of position codes in sorted order
    static func getPositionCodes(from vector: GoldenTestVector) -> [Int] {
        return vector.locations
            .sorted { $0.index < $1.index }
            .map { $0.positionCode }
    }
}

// MARK: - Convenience Extensions

extension GoldenTestVector {

    /// Create WujiSpot array from this vector's locations
    var spots: [WujiSpot] {
        return GoldenVectorLoader.createSpots(from: self)
    }

    /// Create WujiName from this vector's name
    var wujiName: WujiName? {
        return GoldenVectorLoader.createName(from: self)
    }

    /// Get Argon2id parameters
    var argon2Params: CryptoUtils.Argon2Parameters {
        return GoldenVectorLoader.getArgon2Parameters(from: self)
    }

    /// Get encrypted backup data
    var encryptedData: Data? {
        return GoldenVectorLoader.getEncryptedBackup(from: self)
    }

    /// Get position codes array
    var positionCodes: [Int] {
        return GoldenVectorLoader.getPositionCodes(from: self)
    }

    /// Get name salt as Data
    var nameSalt: Data? {
        return Data(hex: nameSaltHex)
    }

    /// Get key data as Data
    var keyData: Data? {
        return Data(hex: keyDataHex)
    }
}

// MARK: - Data Hex Extension

extension Data {
    /// Initialize Data from hex string
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}
