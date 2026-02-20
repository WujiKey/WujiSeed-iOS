//
//  WujiSpot.swift
//  WujiSeed
//
//  Location record - combines coordinate (WujiPlace) and two memories (WujiMemory)
//  Provides keyMaterial generation and batch processing
//

import Foundation

/// Location record - combines coordinate and memory fragment
/// Top-level container for place-based mnemonic generation
struct WujiSpot {

    // MARK: - Properties

    /// Geographic coordinate
    let place: WujiPlace

    /// Combined memory fragment (all tags merged and sorted)
    let memory: WujiMemory

    // MARK: - Initialization

    /// Create from raw inputs with single combined memory
    /// - Parameters:
    ///   - coordinates: Coordinate string (supports DD, DMS, Chinese formats)
    ///   - memory: Combined memory text (all tags merged and sorted)
    /// - Returns: WujiSpot if coordinate parsing succeeds and memory is valid, nil otherwise
    init?(coordinates: String, memory: String) {
        guard let place = WujiPlace(from: coordinates) else { return nil }
        let m = WujiMemory(raw: memory)
        guard m.isValid else { return nil }
        self.place = place
        self.memory = m
    }

    /// Create from parsed components
    /// - Parameters:
    ///   - place: Parsed coordinate
    ///   - memory: Combined memory fragment
    init(place: WujiPlace, memory: WujiMemory) {
        self.place = place
        self.memory = memory
    }

    // MARK: - KeyMaterial

    /// Generate Argon2id input material as binary Data
    ///
    /// Format: memory(UTF-8) + cellIndex(8 bytes big-endian)
    ///
    /// When using place name mode (no coordinates), cellIndex is fixed to 0.
    /// The place name is included as a tag in the memory string instead.
    ///
    /// - Parameter positionCode: Optional position code for cellIndex correction
    /// - Returns: KeyMaterial Data or nil if cellIndex cannot be determined
    func keyMaterial(correctedBy positionCode: Int? = nil) -> Data? {
        guard let index = place.cellIndex(correctedBy: positionCode) else {
            return nil
        }
        // Memory data (already merged and sorted, with \u{1F} separator)
        var data = Data(memory.normalized.utf8)
        // Append cellIndex as 8-byte big-endian
        // Note: For place name mode, cellIndex = 0 (all zeros)
        var bigEndianIndex = index.bigEndian
        data.append(Data(bytes: &bigEndianIndex, count: 8))
        return data
    }

    /// Get position code for current coordinates
    /// - Returns: Position code (1-9) or nil if calculation fails
    func positionCode() -> Int? {
        place.positionCode()
    }
}

// MARK: - Batch Processing

extension WujiSpot {

    /// Processing result containing keyMaterials and position codes
    struct ProcessResult {
        /// All keyMaterials concatenated (for Argon2id input)
        let combinedData: Data

        /// Individual keyMaterials (sorted)
        let keyMaterials: [Data]

        /// Position codes (in same order as keyMaterials)
        let positionCodes: [Int]
    }

    /// Processing errors
    enum ProcessError: Error, LocalizedError {
        case invalidSpotCount(Int, expected: Int)
        case cellConversionFailed(index: Int)
        case positionCodeCorrectionFailed(index: Int, positionCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidSpotCount(let count, let expected):
                return "Expected \(expected) spots, got: \(count)"
            case .cellConversionFailed(let index):
                return "Spot \(index + 1) cell conversion failed"
            case .positionCodeCorrectionFailed(let index, let positionCode):
                return "Spot \(index + 1) position code (\(positionCode)) correction failed"
            }
        }
    }

    // MARK: - Generation Mode

    /// Batch process spots (generation mode)
    /// - Parameters:
    ///   - spots: Array of WujiSpot
    ///   - requiredCount: Required number of spots (default 5)
    /// - Returns: Processing result or error
    static func process(_ spots: [WujiSpot], requiredCount: Int = 5) -> Result<ProcessResult, ProcessError> {
        processInternal(spots, positionCodes: nil, requiredCount: requiredCount)
    }

    // MARK: - Recovery Mode

    /// Batch process spots with position code correction (recovery mode)
    ///
    /// Position code order notes:
    /// - During generation: position codes are in keyMaterial sorted order
    /// - During recovery: passed position codes should also be in sorted order
    /// - This method first sorts by initial keyMaterial, then matches position codes for correction
    ///
    /// - Parameters:
    ///   - spots: Array of WujiSpot
    ///   - positionCodes: Position codes array (in sorted order)
    /// - Returns: Processing result or error
    static func process(_ spots: [WujiSpot], positionCodes: [Int]) -> Result<ProcessResult, ProcessError> {
        guard spots.count == positionCodes.count else {
            return .failure(.invalidSpotCount(positionCodes.count, expected: spots.count))
        }
        return processInternal(spots, positionCodes: positionCodes, requiredCount: spots.count)
    }

    // MARK: - Private Implementation

    /// Internal processing implementation
    /// Supports both generation mode (positionCodes = nil) and recovery mode (positionCodes provided)
    private static func processInternal(_ spots: [WujiSpot], positionCodes: [Int]?, requiredCount: Int) -> Result<ProcessResult, ProcessError> {
        guard spots.count == requiredCount else {
            return .failure(.invalidSpotCount(spots.count, expected: requiredCount))
        }

        // Step 1: Calculate initial keyMaterial for sorting (using current cell)
        var indexed: [(index: Int, spot: WujiSpot, keyMaterial: Data)] = []
        for (i, spot) in spots.enumerated() {
            guard let km = spot.keyMaterial() else {
                return .failure(.cellConversionFailed(index: i))
            }
            indexed.append((i, spot, km))
        }

        // Step 2: Sort by initial keyMaterial (Data is lexicographically comparable)
        let sorted = indexed.sorted { $0.keyMaterial.lexicographicallyPrecedes($1.keyMaterial) }

        // Step 3: Calculate final keyMaterial and positionCode for each spot
        var finalData: [(keyMaterial: Data, positionCode: Int)] = []

        for (sortedIndex, item) in sorted.enumerated() {
            let correctionCode = positionCodes?[sortedIndex]

            // Get final keyMaterial (with or without correction)
            guard let finalKM = item.spot.keyMaterial(correctedBy: correctionCode) else {
                if let code = correctionCode {
                    return .failure(.positionCodeCorrectionFailed(index: item.index, positionCode: code))
                } else {
                    return .failure(.cellConversionFailed(index: item.index))
                }
            }

            // Get position code
            let finalPC: Int
            if let code = correctionCode {
                finalPC = code
            } else {
                guard let code = item.spot.positionCode() else {
                    return .failure(.cellConversionFailed(index: item.index))
                }
                finalPC = code
            }

            finalData.append((finalKM, finalPC))
        }

        // Step 4: Re-sort by final keyMaterial (order may change after correction)
        let finalSorted = finalData.sorted { $0.keyMaterial.lexicographicallyPrecedes($1.keyMaterial) }

        // Step 5: Extract results
        let keyMaterials = finalSorted.map { $0.keyMaterial }
        let finalPositionCodes = finalSorted.map { $0.positionCode }
        var combinedData = Data()
        for km in keyMaterials {
            combinedData.append(km)
        }

        #if DEBUG
        WujiLogger.info("WujiSpot: Processed \(spots.count) spots, keyMaterial total size=\(combinedData.count) bytes")
        #endif

        return .success(ProcessResult(
            combinedData: combinedData,
            keyMaterials: keyMaterials,
            positionCodes: finalPositionCodes
        ))
    }
}

// MARK: - Equatable

extension WujiSpot: Equatable {
    static func == (lhs: WujiSpot, rhs: WujiSpot) -> Bool {
        lhs.place == rhs.place && lhs.memory == rhs.memory
    }
}

// MARK: - CustomStringConvertible

extension WujiSpot: CustomStringConvertible {
    var description: String {
        "WujiSpot(\(place.decimalString), memory: \(memory.normalized.prefix(20))...)"
    }
}
