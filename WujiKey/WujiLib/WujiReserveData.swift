//
//  WujiReserveData.swift
//  WujiKey
//
//  WujiReserve binary format serialization and deserialization
//

import Foundation

/// Single encrypted block in WujiReserve format
struct WujiEncryptedBlock {
    /// Random nonce (24 bytes)
    let nonce: Data

    /// Ciphertext (without tag)
    let ciphertext: Data

    /// Poly1305 tag (16 bytes)
    let tag: Data

    /// Total length (nonce + ciphertext + tag)
    var totalLength: Int {
        nonce.count + ciphertext.count + tag.count
    }
}

/// F9 Reserve binary data structure
///
/// Binary format:
/// ```
/// [ Magic (4 bytes) ]       57 55 4A 49 = "WUJI" (ASCII)
/// [ Version (1 byte) ]      Version number, 01 for first version
/// [ Options (1 byte) ]      Reserved/options byte
/// [ Payload Length (2 bytes, Big-endian) ] Length of remaining content
/// [ PositionCode (3 bytes) ] 5 position codes packed
/// [ AEADSection ]
///     [ Count (1 byte) ]    Number of ciphertext blocks
///     [ Block... ]          Repeated ciphertext blocks
///         [ BlockLength (2 bytes) ] nonce+cipher+tag total length
///         [ Nonce (24 bytes) ]
///         [ Ciphertext (... bytes) ]
///         [ Tag (16 bytes) ]
/// [ Checksum (4 bytes) ]    CRC32 checksum
/// ```
struct WujiReserveData {

    // MARK: - Constants

    /// Magic bytes: "WUJI" (ASCII)
    static let magic: [UInt8] = [0x57, 0x55, 0x4A, 0x49]

    /// Minimum header size: Magic(4) + Version(1) + Options(1) + PayloadLength(2)
    private static let headerSize = 8

    /// Position code byte length
    private static let positionCodeSize = 3

    /// CRC32 checksum size
    private static let checksumSize = 4

    /// Required location count
    static let locationCount = 5

    /// XChaCha20-Poly1305 nonce length
    static let nonceLength = 24

    /// Poly1305 tag length
    static let tagLength = 16

    /// Pre-computed CRC32 lookup table (IEEE 802.3 polynomial)
    private static let crc32Table: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1 != 0) ? (c >> 1) ^ 0xEDB88320 : c >> 1
            }
            return c
        }
    }()

    // MARK: - Errors

    /// Errors during serialization/deserialization
    enum Error: Swift.Error, LocalizedError {
        case insufficientData(String)
        case invalidMagic
        case crc32Mismatch
        case positionCodeEncodingFailed
        case positionCodeDecodingFailed
        case serializationFailed

        var errorDescription: String? {
            switch self {
            case .insufficientData(let field):
                return "Insufficient data: \(field)"
            case .invalidMagic:
                return "Invalid Magic identifier"
            case .crc32Mismatch:
                return "CRC32 verification failed"
            case .positionCodeEncodingFailed:
                return "Position code encoding failed"
            case .positionCodeDecodingFailed:
                return "Position code decoding failed"
            case .serializationFailed:
                return "Serialization failed"
            }
        }
    }

    // MARK: - Properties

    /// Version number
    let version: UInt8

    /// Options byte (reserved, always 0)
    private let options: UInt8 = 0

    /// 5 position codes (1-9)
    let positionCodes: [Int]

    /// Encrypted block list
    let encryptedBlocks: [WujiEncryptedBlock]

    // MARK: - Initialization

    /// Initialize for encryption (create new capsule)
    init(version: UInt8, positionCodes: [Int], encryptedBlocks: [WujiEncryptedBlock]) {
        self.version = version
        self.positionCodes = positionCodes
        self.encryptedBlocks = encryptedBlocks
    }

    // MARK: - AAD (Additional Authenticated Data)

    /// Build AAD for AEAD encryption/decryption
    func buildAAD() -> Data? {
        guard let posCodeData = Self.encodePositionCodes(positionCodes) else { return nil }
        var aad = Data()
        aad.append(contentsOf: Self.magic)
        aad.append(version)
        aad.append(options)
        aad.append(posCodeData)
        return aad
    }

    // MARK: - Encode (serialize to binary)

    /// Serialize to binary data
    func encode() -> Data? {
        var data = Data()

        // 1. Magic (4 bytes)
        data.append(contentsOf: Self.magic)

        // 2. Version (1 byte)
        data.append(version)

        // 3. Options (1 byte)
        data.append(options)

        // Prepare payload
        var payload = Data()

        // 4. PositionCode (3 bytes)
        guard let positionCodeData = Self.encodePositionCodes(positionCodes) else {
            #if DEBUG
            WujiLogger.error("Position code encoding failed")
            #endif
            return nil
        }
        payload.append(positionCodeData)

        // 5. AEAD Section - Count (1 byte)
        payload.append(UInt8(encryptedBlocks.count))

        // Each encrypted block
        for block in encryptedBlocks {
            Self.appendBigEndian(UInt16(block.totalLength), to: &payload)
            payload.append(block.nonce)
            payload.append(block.ciphertext)
            payload.append(block.tag)
        }

        // 6. Payload Length (2 bytes, Big-endian) - includes CRC32
        Self.appendBigEndian(UInt16(payload.count + Self.checksumSize), to: &data)

        // 7. Append payload
        data.append(payload)

        // 8. CRC32 Checksum (4 bytes)
        Self.appendBigEndian(Self.crc32(data), to: &data)

        #if DEBUG
        WujiLogger.info("WujiReserve serialized: \(data.count) bytes")
        #endif
        return data
    }

    // MARK: - Decode (deserialize from binary)

    /// Parse WujiReserveData from binary data
    static func decode(_ data: Data) -> Result<WujiReserveData, Error> {
        var offset = 0

        // 1. Verify minimum size and Magic
        guard data.count >= headerSize else {
            return .failure(.insufficientData("missing header"))
        }

        guard Array(data[0..<4]) == magic else {
            return .failure(.invalidMagic)
        }
        offset = 4

        // 2. Version & Options
        let version = data[offset]
        _ = data[offset + 1]  // options (reserved, not used)
        offset += 2

        // 3. Payload Length
        let payloadLength = readBigEndianUInt16(data, at: offset)
        offset += 2

        // 4. Verify total length
        let expectedTotalLength = offset + Int(payloadLength)
        guard data.count >= expectedTotalLength else {
            return .failure(.insufficientData("incomplete payload"))
        }

        // 5. CRC32 verification
        let checksumOffset = expectedTotalLength - checksumSize
        let storedChecksum = readBigEndianUInt32(data, at: checksumOffset)
        let calculatedChecksum = crc32(data.prefix(checksumOffset))

        guard storedChecksum == calculatedChecksum else {
            return .failure(.crc32Mismatch)
        }

        // 6. PositionCode (3 bytes)
        guard data.count >= offset + positionCodeSize else {
            return .failure(.insufficientData("missing position codes"))
        }
        guard let positionCodes = decodePositionCodes(data.subdata(in: offset..<offset + positionCodeSize)) else {
            return .failure(.positionCodeDecodingFailed)
        }
        offset += positionCodeSize

        // 7. Block Count
        guard data.count >= offset + 1 else {
            return .failure(.insufficientData("missing block count"))
        }
        let blockCount = Int(data[offset])
        offset += 1

        // 8. Parse encrypted blocks
        var encryptedBlocks: [WujiEncryptedBlock] = []
        encryptedBlocks.reserveCapacity(blockCount)

        let minBlockSize = nonceLength + tagLength

        for i in 0..<blockCount {
            guard data.count >= offset + 2 else {
                return .failure(.insufficientData("block \(i + 1) missing length"))
            }

            let blockLength = Int(readBigEndianUInt16(data, at: offset))
            offset += 2

            guard blockLength >= minBlockSize, data.count >= offset + blockLength else {
                return .failure(.insufficientData("block \(i + 1) invalid or insufficient"))
            }

            let nonce = data.subdata(in: offset..<offset + nonceLength)
            offset += nonceLength

            let ciphertextLen = blockLength - minBlockSize
            let ciphertext = data.subdata(in: offset..<offset + ciphertextLen)
            offset += ciphertextLen

            let tag = data.subdata(in: offset..<offset + tagLength)
            offset += tagLength

            encryptedBlocks.append(WujiEncryptedBlock(nonce: nonce, ciphertext: ciphertext, tag: tag))
        }

        #if DEBUG
        WujiLogger.success("WujiReserve parsed successfully, \(encryptedBlocks.count) blocks")
        #endif

        return .success(WujiReserveData(
            version: version,
            positionCodes: positionCodes,
            encryptedBlocks: encryptedBlocks
        ))
    }

    // MARK: - Position Code Encoding

    /// Encode 5 position codes (1-9) to 3 bytes
    static func encodePositionCodes(_ codes: [Int]) -> Data? {
        guard codes.count == locationCount else { return nil }
        guard codes.allSatisfy({ $0 >= 1 && $0 <= 9 }) else { return nil }

        var data = Data(count: positionCodeSize)
        data[0] = UInt8((codes[0] << 4) | codes[1])
        data[1] = UInt8((codes[2] << 4) | codes[3])
        data[2] = UInt8(codes[4] << 4)
        return data
    }

    /// Decode 5 position codes from 3 bytes
    static func decodePositionCodes(_ data: Data) -> [Int]? {
        guard data.count >= positionCodeSize else { return nil }

        let codes = [
            Int((data[0] >> 4) & 0x0F),
            Int(data[0] & 0x0F),
            Int((data[1] >> 4) & 0x0F),
            Int(data[1] & 0x0F),
            Int((data[2] >> 4) & 0x0F)
        ]

        guard codes.allSatisfy({ $0 >= 1 && $0 <= 9 }) else { return nil }
        return codes
    }

    // MARK: - CRC32

    /// Calculate CRC32 checksum
    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = (crc >> 8) ^ crc32Table[Int((crc ^ UInt32(byte)) & 0xFF)]
        }
        return crc ^ 0xFFFFFFFF
    }

    // MARK: - Big-Endian Helpers

    static func appendBigEndian(_ value: UInt16, to data: inout Data) {
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    static func appendBigEndian(_ value: UInt32, to data: inout Data) {
        data.append(UInt8((value >> 24) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    static func readBigEndianUInt16(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }

    static func readBigEndianUInt32(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset]) << 24 | UInt32(data[offset + 1]) << 16 |
        UInt32(data[offset + 2]) << 8 | UInt32(data[offset + 3])
    }
}
