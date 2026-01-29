//
//  QRCodeBinaryExtension.swift
//  WujiSeed
//
//  Extract raw data from binary QR codes
//  Based on https://gist.github.com/PetrusM/267e2ee8c1d8b5dca17eac085afa7d7c
//  Reference https://www.thonky.com/qr-code-tutorial/data-encoding
//

import Foundation
import AVKit

// MARK: - AVMetadataMachineReadableCodeObject Extension

extension AVMetadataMachineReadableCodeObject {

    /// Extract raw binary data from QR code (remove QR protocol header)
    /// - Note: Only supports iOS 11+, and only for 100% binary mode QR codes
    var binaryValue: Data? {
        switch type {
        case .qr:
            guard let rawData = binaryValueWithProtocol else { return nil }
            return removeQrProtocolData(rawData)
        case .aztec:
            guard let string = stringValue else { return nil }
            return string.data(using: .isoLatin1)
        default:
            return nil
        }
    }

    /// Get raw payload including QR protocol data
    var binaryValueWithProtocol: Data? {
        guard let descriptor = descriptor else { return nil }
        switch type {
        case .qr:
            return (descriptor as? CIQRCodeDescriptor)?.errorCorrectedPayload
        case .aztec:
            return (descriptor as? CIAztecCodeDescriptor)?.errorCorrectedPayload
        case .pdf417:
            return (descriptor as? CIPDF417CodeDescriptor)?.errorCorrectedPayload
        case .dataMatrix:
            return (descriptor as? CIDataMatrixCodeDescriptor)?.errorCorrectedPayload
        default:
            return nil
        }
    }

    /// Remove QR protocol data, extract pure binary content
    private func removeQrProtocolData(_ input: Data) -> Data? {
        var halves = input.qr_halfBytes()
        var batch = takeBatch(&halves)
        var output = batch
        while !batch.isEmpty {
            batch = takeBatch(&halves)
            output.append(contentsOf: batch)
        }
        return Data(output)
    }

    /// Extract a batch of data from half-byte array
    private func takeBatch(_ input: inout [QRHalfByte]) -> [UInt8] {
        guard !input.isEmpty else { return [] }

        guard let qrDescriptor = descriptor as? CIQRCodeDescriptor else { return [] }
        let version = qrDescriptor.symbolVersion
        let characterCountLength = version > 9 ? 16 : 8

        let mode = input.remove(at: 0)
        var output = [UInt8]()

        switch mode.value {
        case 0x04: // Binary mode (byte mode)
            let charactersCount: UInt16
            if characterCountLength == 8 {
                charactersCount = UInt16(input.qr_takeUInt8())
            } else {
                charactersCount = input.qr_takeUInt16()
            }
            for _ in 0..<charactersCount {
                output.append(input.qr_takeUInt8())
            }
            return output
        case 0x00: // End of data
            return []
        default:
            // Other modes (numeric, alphanumeric, etc.) not supported
            return []
        }
    }
}

// MARK: - CIQRCodeFeature Extension

extension CIQRCodeFeature {

    /// Extract raw binary data from CIQRCodeFeature
    /// - Note: Only supports iOS 11+
    var binaryValue: Data? {
        guard let qrDescriptor = symbolDescriptor else {
            return nil
        }
        return removeQrProtocolData(qrDescriptor.errorCorrectedPayload, version: qrDescriptor.symbolVersion)
    }

    /// Remove QR protocol data, extract pure binary content
    private func removeQrProtocolData(_ input: Data, version: Int) -> Data? {
        var halves = input.qr_halfBytes()
        var batch = takeBatch(&halves, version: version)
        var output = batch
        while !batch.isEmpty {
            batch = takeBatch(&halves, version: version)
            output.append(contentsOf: batch)
        }
        return Data(output)
    }

    /// Extract a batch of data from half-byte array
    private func takeBatch(_ input: inout [QRHalfByte], version: Int) -> [UInt8] {
        guard !input.isEmpty else { return [] }

        let characterCountLength = version > 9 ? 16 : 8

        let mode = input.remove(at: 0)
        var output = [UInt8]()

        switch mode.value {
        case 0x04: // Binary mode (byte mode)
            let charactersCount: UInt16
            if characterCountLength == 8 {
                charactersCount = UInt16(input.qr_takeUInt8())
            } else {
                charactersCount = input.qr_takeUInt16()
            }
            for _ in 0..<charactersCount {
                output.append(input.qr_takeUInt8())
            }
            return output
        case 0x00: // End of data
            return []
        default:
            return []
        }
    }
}

// MARK: - Helper Types

/// QR code half-byte structure
fileprivate struct QRHalfByte {
    let value: UInt8
}

// MARK: - Array<QRHalfByte> Extension

fileprivate extension Array where Element == QRHalfByte {

    mutating func qr_takeUInt8() -> UInt8 {
        guard count >= 2 else { return 0 }
        let left = self.remove(at: 0)
        let right = self.remove(at: 0)
        return (left.value << 4) + (right.value & 0x0F)
    }

    mutating func qr_takeUInt16() -> UInt16 {
        guard count >= 4 else { return 0 }
        let first = self.remove(at: 0)
        let second = self.remove(at: 0)
        let third = self.remove(at: 0)
        let fourth = self.remove(at: 0)
        return (UInt16(first.value) << 12) +
               (UInt16(second.value) << 8) +
               (UInt16(third.value) << 4) +
               UInt16(fourth.value & 0x0F)
    }
}

// MARK: - Data Extension

fileprivate extension Data {

    /// Convert Data to half-byte array
    func qr_halfBytes() -> [QRHalfByte] {
        var result = [QRHalfByte]()
        for byte in self {
            result.append(QRHalfByte(value: byte >> 4))
            result.append(QRHalfByte(value: byte & 0x0F))
        }
        return result
    }
}
