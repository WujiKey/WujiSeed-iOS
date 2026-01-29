//
//  WujiPlace.swift
//  WujiSeed
//
//  Geographic coordinate - encapsulates coordinate parsing, F9Grid operations, and position code calculation
//

import Foundation
import F9Grid

/// Geographic coordinate - handles parsing, validation, and F9Grid operations
/// Coordinates are stored as Strings to avoid Double precision issues at cell boundaries
struct WujiPlace {

    // MARK: - Properties

    /// Latitude (String format to preserve precision)
    let latitude: String

    /// Longitude (String format to preserve precision)
    let longitude: String

    // MARK: - Initialization

    /// Create from coordinate string (supports DD, DMS, Chinese formats, etc.)
    /// - Parameter coordinateString: Raw coordinate string input
    /// - Returns: WujiPlace if parsing succeeds, nil otherwise
    init?(from coordinateString: String) {
        let result = LatLngParser.parse(coordinateString)
        guard result.isValid else { return nil }
        self.latitude = String(result.latitude)
        self.longitude = String(result.longitude)
    }

    /// Create from numeric values
    /// - Parameters:
    ///   - latitude: Latitude in decimal degrees (-90 to 90)
    ///   - longitude: Longitude in decimal degrees (-180 to 180)
    /// - Returns: WujiPlace if coordinates are valid, nil otherwise
    init?(latitude: Double, longitude: Double) {
        guard latitude >= -90, latitude <= 90,
              longitude >= -180, longitude <= 180 else {
            return nil
        }
        self.latitude = String(latitude)
        self.longitude = String(longitude)
    }

    /// Create from pre-parsed string values (internal use)
    /// - Parameters:
    ///   - latitudeString: Latitude as string
    ///   - longitudeString: Longitude as string
    init(latitudeString: String, longitudeString: String) {
        self.latitude = latitudeString
        self.longitude = longitudeString
    }

    // MARK: - F9Grid Operations

    /// Get the F9Grid cell for current coordinates
    /// - Returns: F9Cell or nil if conversion fails
    func cell() -> F9Grid.F9Cell? {
        F9Grid.cell(lat: latitude, lng: longitude)
    }

    /// Get cell index, optionally corrected by position code
    ///
    /// - Parameter positionCode: Optional position code for correction (1-9).
    ///   If provided, finds the neighboring cell that matches the position code.
    ///   If nil, returns the current cell's index.
    /// - Returns: Cell index or nil if conversion/correction fails
    func cellIndex(correctedBy positionCode: Int? = nil) -> Int64? {
        if let code = positionCode {
            // Recovery mode: find original cell using position code
            return F9Grid.findOriginalCell(lat: latitude, lng: longitude, originalPositionCode: code)
        } else {
            // Generation mode: use current cell
            return cell()?.index
        }
    }

    /// Calculate position code for current coordinates within current cell
    /// - Returns: Position code (1-9) or nil if calculation fails
    ///
    /// Position code layout (9-grid):
    /// ```
    /// 4(NW)  9(N)   2(NE)
    /// 3(W)   5(C)   7(E)
    /// 8(SW)  1(S)   6(SE)
    /// ```
    func positionCode() -> Int? {
        guard let cell = cell(),
              let latDecimal = Decimal(string: latitude),
              let lngDecimal = Decimal(string: longitude) else {
            return nil
        }
        return cell.positionCode(lat: latDecimal, lng: lngDecimal)
    }

    // MARK: - Formatting

    /// Decimal format string: "18.699245, 98.922773"
    var decimalString: String {
        "\(latitude), \(longitude)"
    }

    /// DMS format string: "18°41'57"N 98°55'21"E"
    var dmsString: String {
        guard let lat = Double(latitude), let lng = Double(longitude) else {
            return decimalString
        }
        return LatLngParser.toDMSFormat(latitude: lat, longitude: lng)
    }

    // MARK: - Validation

    /// Whether coordinates are within valid range
    var isValid: Bool {
        guard let lat = Double(latitude), let lng = Double(longitude) else {
            return false
        }
        return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180
    }
}

// MARK: - Equatable

extension WujiPlace: Equatable {
    static func == (lhs: WujiPlace, rhs: WujiPlace) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - CustomStringConvertible

extension WujiPlace: CustomStringConvertible {
    var description: String {
        "WujiPlace(\(decimalString))"
    }
}
