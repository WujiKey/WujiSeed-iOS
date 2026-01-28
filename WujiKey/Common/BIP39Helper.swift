//
//  BIP39Helper.swift
//  WujiKey
//
//  BIP39 seed phrase tools - encoding, decoding, validation, generation
//

import Foundation

/// BIP39 seed phrase helper class
/// Provides encoding, decoding, validation and generation functions
class BIP39Helper {

    // MARK: - Constants

    private enum Constants {
        static let bitsPerMnemonicWord = 11       // Number of bits per BIP39 seed phrase word
        static let bip39WordlistSize = 2048       // Total words in BIP39 wordlist (2^11)
    }

    // MARK: - Standard Mode: Direct 256-bit to 24 Words

    /// Generate 24 BIP39 seed phrase words from 256-bit data (standard mode)
    ///
    /// - Parameter data: 256-bit (32 bytes) entropy data
    /// - Returns: Array of 24 BIP39 seed phrase words, nil if input is invalid
    static func generate24Words(from data: Data) -> [String]? {
        guard data.count == 32 else { return nil }

        // 1. Convert 256 bits to binary string
        let binary256 = Utils.dataToBinaryString(data)
        guard binary256.count == 256 else { return nil }

        // 2. First 253 bits generate first 23 words
        let binary253 = String(binary256.prefix(253))
        var words: [String] = []

        // Each 11 bits generates one word
        for i in 0..<23 {
            let start = binary253.index(binary253.startIndex, offsetBy: i * 11)
            let end = binary253.index(start, offsetBy: 11)
            let binary11 = String(binary253[start..<end])

            guard let index = Int(binary11, radix: 2),
                  index < bip39List.count else {
                return nil
            }
            words.append(bip39List[index])
        }

        // 3. Remaining 3 bits as entropy for 24th word
        let entropy3Binary = String(binary256.suffix(3))

        // 4. Calculate SHA256 checksum
        guard let entropyData = Utils.binaryStringToData(binary256) else { return nil }
        let hash = CryptoUtils.sha256(entropyData)
        let checksum8Binary = String(Utils.dataToBinaryString(hash).prefix(8))

        // 5. 24th word = 3-bit entropy + 8-bit checksum
        let word24IndexBinary = entropy3Binary + checksum8Binary
        guard let word24Index = Int(word24IndexBinary, radix: 2),
              word24Index < bip39List.count else {
            return nil
        }

        words.append(bip39List[word24Index])

        return words
    }

    // MARK: - Seed Phrase Encoding/Decoding (264 bits)

    /// Encode 24 BIP39 seed phrase words to 264-bit data
    ///
    /// BIP39 structure: 24 words × 11 bits = 264 bits
    /// Contains: 256 bits entropy + 8 bits checksum
    ///
    /// - Parameter words: 24 BIP39 seed phrase words
    /// - Returns: 33-byte (264-bit) data, nil if input is invalid
    static func wordsToData(_ words: [String]) -> Data? {
        // Validate word count
        guard words.count == 24 else { return nil }

        // Convert 24 words to indices
        var indices: [Int] = []
        for word in words {
            guard let index = bip39List.firstIndex(of: word.lowercased()) else {
                return nil
            }
            indices.append(index)
        }

        // Convert 24 indices to binary string (24 × 11 = 264 bits)
        var binary264 = ""
        for index in indices {
            let binary11 = Utils.padLeft(String(index, radix: 2), toLength: 11, withPad: "0")
            binary264 += binary11
        }

        // 264 bits = 33 bytes
        guard binary264.count == 264 else { return nil }

        var data = Data()
        for i in stride(from: 0, to: 264, by: 8) {
            let start = binary264.index(binary264.startIndex, offsetBy: i)
            let end = binary264.index(start, offsetBy: 8)
            let byte = String(binary264[start..<end])
            if let byteValue = UInt8(byte, radix: 2) {
                data.append(byteValue)
            } else {
                return nil
            }
        }

        return data  // 33 bytes
    }

    /// Decode 264-bit data to 24 BIP39 seed phrase words
    ///
    /// - Parameter data: 33-byte (264-bit) data
    /// - Returns: 24 BIP39 seed phrase words, nil if data is invalid
    static func dataToWords(_ data: Data) -> [String]? {
        // Validate data length: 33 bytes = 264 bits
        guard data.count == 33 else { return nil }

        // Convert to binary string
        let binary264 = data.map { byte in
            Utils.padLeft(String(byte, radix: 2), toLength: 8, withPad: "0")
        }.joined()

        guard binary264.count == 264 else { return nil }

        // Each 11 bits converts to one word
        var words: [String] = []
        for i in 0..<24 {
            let start = binary264.index(binary264.startIndex, offsetBy: i * 11)
            let end = binary264.index(start, offsetBy: 11)
            let binary11 = String(binary264[start..<end])

            guard let index = Int(binary11, radix: 2),
                  index < bip39List.count else {
                return nil
            }
            words.append(bip39List[index])
        }

        return words
    }

    // MARK: - Validation

    /// Validate 24 BIP39 seed phrase words
    ///
    /// - Parameter words: 24 seed phrase words
    /// - Returns: (isValid, errorMessage)
    static func validate24Words(_ words: [String]) -> (isValid: Bool, error: String?) {
        // 1. Validate word count
        guard words.count == 24 else {
            return (false, "Seed phrase word count must be 24, current: \(words.count)")
        }

        // 2. Validate each word is in wordlist and get indices
        var indices: [Int] = []
        for (index, word) in words.enumerated() {
            guard let wordIndex = bip39List.firstIndex(of: word.lowercased()) else {
                return (false, "Word #\(index + 1) '\(word)' is not in BIP39 wordlist")
            }
            indices.append(wordIndex)
        }

        // 3. Convert 24 indices to binary string (24 × 11 = 264 bits)
        var binary264 = ""
        for index in indices {
            let binary11 = Utils.padLeft(String(index, radix: 2), toLength: 11, withPad: "0")
            binary264 += binary11
        }

        // 4. Separate entropy and checksum
        // First 256 bits is entropy, last 8 bits is checksum
        let entropy256Binary = String(binary264.prefix(256))
        let checksum8Binary = String(binary264.suffix(8))

        // 5. Calculate expected checksum from entropy
        guard let entropyData = Utils.binaryStringToData(entropy256Binary) else {
            return (false, "Entropy data conversion failed")
        }

        let hash = CryptoUtils.sha256(entropyData)
        let expectedChecksum8Binary = String(Utils.dataToBinaryString(hash).prefix(8))

        // 6. Verify checksum
        if checksum8Binary != expectedChecksum8Binary {
            return (false, "Checksum verification failed, seed phrase may be incorrect")
        }

        return (true, nil)
    }
}
