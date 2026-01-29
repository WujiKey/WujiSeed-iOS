//
//  Utils.swift
//  WujiSeed
//
//  Utilities - big integer conversion, binary string conversion, etc.
//

import Foundation
import UIKit

/// Utility class
/// Provides unified utility API, including big integer conversion, binary string conversion, etc.
class Utils {

    // MARK: - Big Integer Conversion

    /// Convert hexadecimal string to decimal string
    /// - Parameter hex: Hexadecimal string (case-insensitive)
    /// - Returns: Decimal string representation
    static func hexToDecimal(_ hex: String) -> String {
        var result = "0"

        for char in hex.lowercased() {
            guard let digit = Int(String(char), radix: 16) else { continue }
            // result = result * 16 + digit
            result = multiplyAndAdd(result, multiplier: 16, addend: digit)
        }

        return result
    }

    /// Convert Data (byte array) to decimal string
    /// Used to convert 256-bit hash to ~77-digit decimal string
    /// - Parameter data: Byte data (e.g., hash value)
    /// - Returns: Decimal string representation
    static func dataToDecimal(_ data: Data) -> String {
        var result = "0"

        for byte in data {
            // result = result * 256 + byte
            result = multiplyAndAdd(result, multiplier: 256, addend: Int(byte))
        }

        return result
    }

    // MARK: - Binary String Conversion

    /// Convert binary string to Data
    /// - Parameter binary: Binary string (length must be multiple of 8)
    /// - Returns: Converted Data, nil if input is invalid
    static func binaryStringToData(_ binary: String) -> Data? {
        guard binary.count % 8 == 0 else { return nil }

        var data = Data()
        for i in stride(from: 0, to: binary.count, by: 8) {
            let startIndex = binary.index(binary.startIndex, offsetBy: i)
            let endIndex = binary.index(startIndex, offsetBy: 8)
            let byte = String(binary[startIndex..<endIndex])

            if let byteValue = UInt8(byte, radix: 2) {
                data.append(byteValue)
            } else {
                return nil
            }
        }

        return data
    }

    /// Convert Data to binary string
    /// - Parameter data: Data to convert
    /// - Returns: Binary string representation (8 bits per byte, zero-padded)
    static func dataToBinaryString(_ data: Data) -> String {
        return data.map { byte in
            padLeft(String(byte, radix: 2), toLength: 8, withPad: "0")
        }.joined()
    }

    // MARK: - Private Helper Methods

    /// Perform (num * multiplier + addend) operation on big integer string
    ///
    /// Uses digit-by-digit calculation to avoid integer overflow, works for any length numbers
    ///
    /// - Parameters:
    ///   - numStr: Number string (decimal)
    ///   - multiplier: Multiplier
    ///   - addend: Addend
    /// - Returns: String representation of the result
    private static func multiplyAndAdd(_ numStr: String, multiplier: Int, addend: Int) -> String {
        var result = [Int]()
        var carry = addend

        // Start from units digit, multiply each digit by multiplier and add carry
        for char in numStr.reversed() {
            let digit = Int(String(char))!
            let product = digit * multiplier + carry
            result.insert(product % 10, at: 0)
            carry = product / 10
        }

        // Handle remaining carry
        while carry > 0 {
            result.insert(carry % 10, at: 0)
            carry /= 10
        }

        return result.map { String($0) }.joined()
    }

    /// Left-pad string to specified length
    /// - Parameters:
    ///   - string: Original string
    ///   - length: Target length
    ///   - pad: Padding character
    /// - Returns: Padded string
    static func padLeft(_ string: String, toLength length: Int, withPad pad: String) -> String {
        let padLength = length - string.count
        if padLength <= 0 {
            return string
        }
        return String(repeating: pad, count: padLength) + string
    }
}

// MARK: - String Extensions

extension String {
    /// Left-pad string to specified length
    /// - Parameters:
    ///   - toLength: Target length
    ///   - character: Padding character
    /// - Returns: Padded string
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return self
        }
    }

    /// Convert emoji string to UIImage
    /// - Parameter size: Target image size
    /// - Returns: UIImage rendered from emoji
    func emojiToImage(size: CGSize) -> UIImage? {
        let nsString = (self as NSString)
        let font = UIFont.systemFont(ofSize: min(size.width, size.height))
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = nsString.size(withAttributes: attributes)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let origin = CGPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        )
        nsString.draw(at: origin, withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
