//
//  LatLngParser.swift
//  WujiKey
//
//

import Foundation

/// Geographic coordinate parser - supports multiple latitude/longitude formats
class LatLngParser {

    /// Parse result
    struct ParseResult {
        let latitude: Double
        let longitude: Double
        let isValid: Bool
        let errorMessage: String?

        /// Format as standard string "latitude, longitude"
        var formattedString: String {
            guard isValid else { return "" }
            return String(format: "%.7f, %.7f", latitude, longitude)
        }
    }

    /// Convert decimal coordinates to DMS format (integer seconds, no decimal point)
    /// - Parameters:
    ///   - latitude: Latitude in decimal degrees
    ///   - longitude: Longitude in decimal degrees
    /// - Returns: DMS format string like "18°41'57"N 98°55'21"E"
    static func toDMSFormat(latitude: Double, longitude: Double) -> String {
        let latDMS = decimalToDMS(latitude, isLatitude: true)
        let lonDMS = decimalToDMS(longitude, isLatitude: false)
        return "\(latDMS) \(lonDMS)"
    }

    /// Convert decimal to DMS (degrees, minutes, seconds)
    private static func decimalToDMS(_ decimal: Double, isLatitude: Bool) -> String {
        let absValue = abs(decimal)
        let degrees = Int(absValue)
        let minutesDecimal = (absValue - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = Int((minutesDecimal - Double(minutes)) * 60)  // Integer seconds, no decimals

        let direction: String
        if isLatitude {
            direction = decimal >= 0 ? "N" : "S"
        } else {
            direction = decimal >= 0 ? "E" : "W"
        }

        return "\(degrees)°\(minutes)'\(seconds)\"\(direction)"
    }

    /// Parse coordinate string
    /// - Parameter input: User input coordinate string
    /// - Returns: Parse result
    static func parse(_ input: String) -> ParseResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return ParseResult(latitude: 0, longitude: 0, isValid: false, errorMessage: nil)
        }

        // 1. Try standard format: 18.6992452, 98.9227733
        if let result = parseDecimalFormat(trimmed) {
            return result
        }

        // 2. Try parentheses format: (18.6992452, 98.9227733)
        if let result = parseParenthesesFormat(trimmed) {
            return result
        }

        // 3. Try DMS format: 18°41'57"N 98°55'21"E
        if let result = parseDMSFormat(trimmed) {
            return result
        }

        // 4. Try Chinese direction format
        if let result = parseChineseFormat(trimmed) {
            return result
        }

        // 5. Try Plus Code format: 7MCWMWXF+M4
        if let result = parsePlusCodeFormat(trimmed) {
            return result
        }

        // Unrecognized format
        return ParseResult(latitude: 0, longitude: 0, isValid: false, errorMessage: Lang("places.coord_format_error"))
    }

    // MARK: - Format parsing methods

    /// Parse standard decimal format: 18.6992452, 98.9227733
    private static func parseDecimalFormat(_ input: String) -> ParseResult? {
        // Normalize comma (full-width to half-width)
        let normalized = input.replacingOccurrences(of: "，", with: ",")

        // Split coordinates
        let parts = normalized.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }

        // Parse as numbers
        guard let lat = Double(parts[0]), let lon = Double(parts[1]) else {
            return nil
        }

        // Validate range
        return validateCoordinates(latitude: lat, longitude: lon)
    }

    /// Parse parentheses format: (18.6992452, 98.9227733)
    private static func parseParenthesesFormat(_ input: String) -> ParseResult? {
        // Remove parentheses
        let cleaned = input.replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "（", with: "")
            .replacingOccurrences(of: "）", with: "")

        return parseDecimalFormat(cleaned)
    }

    /// Parse DMS format: 18°41'57"N 98°55'21"E
    private static func parseDMSFormat(_ input: String) -> ParseResult? {
        // Regex pattern for DMS format
        let pattern = #"(\d+)[°](\d+)['′](\d+(?:\.\d+)?)[\"″]?\s*([NnSs北南])\s+(\d+)[°](\d+)['′](\d+(?:\.\d+)?)[\"″]?\s*([EeWw东西])"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = input as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            return nil
        }

        // Extract DMS values
        guard match.numberOfRanges == 9 else { return nil }

        let latDeg = Double(nsString.substring(with: match.range(at: 1))) ?? 0
        let latMin = Double(nsString.substring(with: match.range(at: 2))) ?? 0
        let latSec = Double(nsString.substring(with: match.range(at: 3))) ?? 0
        let latDir = nsString.substring(with: match.range(at: 4))

        let lonDeg = Double(nsString.substring(with: match.range(at: 5))) ?? 0
        let lonMin = Double(nsString.substring(with: match.range(at: 6))) ?? 0
        let lonSec = Double(nsString.substring(with: match.range(at: 7))) ?? 0
        let lonDir = nsString.substring(with: match.range(at: 8))

        // Convert to decimal
        var lat = latDeg + latMin / 60.0 + latSec / 3600.0
        var lon = lonDeg + lonMin / 60.0 + lonSec / 3600.0

        // Handle direction
        if latDir.uppercased() == "S" || latDir == "南" {
            lat = -lat
        }
        if lonDir.uppercased() == "W" || lonDir == "西" {
            lon = -lon
        }

        return validateCoordinates(latitude: lat, longitude: lon)
    }

    /// Parse Chinese direction format
    private static func parseChineseFormat(_ input: String) -> ParseResult? {
        // Normalize comma
        let normalized = input.replacingOccurrences(of: "，", with: ",")

        // Regex pattern for Chinese format
        let pattern = #"([北南])\s*(\d+(?:\.\d+)?)[°]?\s*[,，]\s*([东西])\s*(\d+(?:\.\d+)?)[°]?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = normalized as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: normalized, options: [], range: range) else {
            return nil
        }

        guard match.numberOfRanges == 5 else { return nil }

        let latDir = nsString.substring(with: match.range(at: 1))
        var lat = Double(nsString.substring(with: match.range(at: 2))) ?? 0
        let lonDir = nsString.substring(with: match.range(at: 3))
        var lon = Double(nsString.substring(with: match.range(at: 4))) ?? 0

        // Handle direction
        if latDir == "南" {
            lat = -lat
        }
        if lonDir == "西" {
            lon = -lon
        }

        return validateCoordinates(latitude: lat, longitude: lon)
    }

    /// Parse Plus Code format: 7MCWMWXF+M4 (10-digit full code)
    /// Decodes to the center of the Plus Code grid cell
    private static func parsePlusCodeFormat(_ input: String) -> ParseResult? {
        // Plus Code alphabet (20 characters)
        let alphabet = "23456789CFGHJMPQRVWX"

        // Normalize input: uppercase and remove spaces
        let code = input.uppercased().trimmingCharacters(in: .whitespaces)

        // Validate format: 8 chars + '+' + 2 chars = 11 characters for 10-digit code
        // Pattern: XXXXXXXX+XX where X is from alphabet
        let pattern = #"^[23456789CFGHJMPQRVWX]{8}\+[23456789CFGHJMPQRVWX]{2}$"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(location: 0, length: code.utf16.count)
        guard regex.firstMatch(in: code, options: [], range: range) != nil else {
            return nil
        }

        // Remove '+' for decoding
        let codeWithoutPlus = code.replacingOccurrences(of: "+", with: "")

        // Decode Plus Code to lat/lng
        // Plus Code uses base-20 encoding with specific character set
        // First 10 digits: pairs of (lat, lng) at decreasing resolutions
        // Resolution: 20° → 1° → 0.05° → 0.0025° → 0.000125°

        var latValue: Double = 0
        var lngValue: Double = 0

        // Pair resolutions in degrees
        let pairResolutions: [Double] = [20.0, 1.0, 0.05, 0.0025, 0.000125]

        // Decode pairs (characters 0-1, 2-3, 4-5, 6-7, 8-9)
        for pairIndex in 0..<5 {
            let latCharIndex = pairIndex * 2
            let lngCharIndex = pairIndex * 2 + 1

            let latCharStr = String(codeWithoutPlus[codeWithoutPlus.index(codeWithoutPlus.startIndex, offsetBy: latCharIndex)])
            let lngCharStr = String(codeWithoutPlus[codeWithoutPlus.index(codeWithoutPlus.startIndex, offsetBy: lngCharIndex)])

            guard let latDigit = alphabet.firstIndex(of: Character(latCharStr)),
                  let lngDigit = alphabet.firstIndex(of: Character(lngCharStr)) else {
                return nil
            }

            let latDigitValue = Double(alphabet.distance(from: alphabet.startIndex, to: latDigit))
            let lngDigitValue = Double(alphabet.distance(from: alphabet.startIndex, to: lngDigit))

            latValue += latDigitValue * pairResolutions[pairIndex]
            lngValue += lngDigitValue * pairResolutions[pairIndex]
        }

        // Add half of the smallest resolution to get center of cell
        let halfResolution = pairResolutions[4] / 2.0
        latValue += halfResolution
        lngValue += halfResolution

        // Adjust for global offset (Plus Code origin is at -90, -180)
        let latitude = latValue - 90.0
        let longitude = lngValue - 180.0

        return validateCoordinates(latitude: latitude, longitude: longitude)
    }

    // MARK: - Validation methods

    /// Validate coordinate range
    private static func validateCoordinates(latitude: Double, longitude: Double) -> ParseResult {
        // Latitude range: -90 to 90
        // Longitude range: -180 to 180
        let latValid = latitude >= -90 && latitude <= 90
        let lonValid = longitude >= -180 && longitude <= 180

        if !latValid || !lonValid {
            return ParseResult(latitude: latitude, longitude: longitude, isValid: false, errorMessage: Lang("places.coord_range_error"))
        }

        return ParseResult(latitude: latitude, longitude: longitude, isValid: true, errorMessage: nil)
    }
}
