//
//  PlacesDataManager.swift
//  WujiSeed
//
//  Geographic location data manager - Manages data and business logic for 5 places
//

import Foundation

class PlacesDataManager {

    // MARK: - Types

    /// Place data model
    struct PlaceData: Codable {
        var latitude: String = ""
        var longitude: String = ""
        var memory1Tags: [String] = []  // First memory tags (normalized, not sorted)
        var memory2Tags: [String] = []  // Second memory tags (normalized, not sorted)

        var isValid: Bool {
            return isCoordinateValid && isMemosValid
        }

        var isCoordinateValid: Bool {
            guard let lat = parseCoordinate(latitude),
                  let lon = parseCoordinate(longitude),
                  lat >= -90 && lat <= 90,
                  lon >= -180 && lon <= 180 else {
                return false
            }
            return true
        }

        /// Parse coordinate string (supports decimal and DMS formats)
        private func parseCoordinate(_ value: String) -> Double? {
            // Try decimal first
            if let v = Double(value) { return v }
            // Try DMS format: e.g. 18°41'57"N
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let pattern = #"^(-?\d+)[°]\s*(\d+)['''′]\s*(\d+(?:\.\d+)?)[""\"″]?\s*([NSEWnsew北南东西])?$"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
            let nsString = trimmed as NSString
            let range = NSRange(location: 0, length: nsString.length)
            guard let match = regex.firstMatch(in: trimmed, options: [], range: range) else { return nil }
            let degrees = Double(nsString.substring(with: match.range(at: 1))) ?? 0
            let minutes = Double(nsString.substring(with: match.range(at: 2))) ?? 0
            let seconds = Double(nsString.substring(with: match.range(at: 3))) ?? 0
            var result = abs(degrees) + minutes / 60.0 + seconds / 3600.0
            if degrees < 0 { result = -result }
            if match.range(at: 4).location != NSNotFound {
                let dir = nsString.substring(with: match.range(at: 4)).uppercased()
                if dir == "S" || dir == "W" || dir == "南" || dir == "西" { result = -abs(result) }
            }
            return result
        }

        var isMemosValid: Bool {
            let count1 = memory1Tags.count
            let count2 = memory2Tags.count
            return count1 >= 1 && count1 <= 3 && count2 >= 1 && count2 <= 3
        }

        var coordinateString: String {
            return "\(latitude), \(longitude)"
        }

        /// Get final processed memory (all tags merged, sorted + concatenated) for crypto operations
        /// Combines memory1Tags and memory2Tags, then sorts and concatenates for better fault tolerance
        var memoryProcessed: String {
            let allTags = memory1Tags + memory2Tags
            return WujiMemoryTagProcessor.process(allTags)
        }
    }

    // MARK: - Properties

    private(set) var locations: [PlaceData] = Array(repeating: PlaceData(), count: 5)
    private(set) var currentLocation: Int = 0  // Current location index (0-4)

    private let totalLocations = 5

    #if DEBUG
    // MARK: - Test Data (Static, shared with RecoverViewController)

    static let testCoordinates: [(lat: String, lon: String)] = [
        ("34.617090", "119.191840"),
        ("35.066260", "107.614560"),
        ("11.373300", "142.591700"),
        ("29.976330", "122.389360"),
        ("24.695100", "84.991300")
    ]

    // Test memory1 and memory2 (keyword tag arrays)
    static let testMemos1Tags: [[String]] = [
        ["女娲补天石"],
        ["七十二变", "筋斗云"],
        ["齐天大圣"],
        ["西海龙王三太子", "白龙马"],
        ["九九八十一难"]
    ]

    static let testMemos2Tags: [[String]] = [
        ["水帘洞", "称王"],
        ["孙悟空"],
        ["如意金箍棒", "一万三千五百斤"],
        ["西天取经"],
        ["通天河老鼋"]
    ]
    #endif

    // MARK: - Initialization

    init() {
        // Can load draft here
    }

    // MARK: - Data Management

    /// Update current location data with tag arrays
    func updateCurrentLocation(latitude: String, longitude: String, memory1Tags: [String], memory2Tags: [String]) {
        locations[currentLocation].latitude = latitude
        locations[currentLocation].longitude = longitude
        locations[currentLocation].memory1Tags = memory1Tags
        locations[currentLocation].memory2Tags = memory2Tags
    }

    /// Update location data at specified index (for saving data before switching)
    func updateLocation(at index: Int, latitude: String, longitude: String, memory1Tags: [String], memory2Tags: [String]) {
        guard index >= 0 && index < totalLocations else { return }
        locations[index].latitude = latitude
        locations[index].longitude = longitude
        locations[index].memory1Tags = memory1Tags
        locations[index].memory2Tags = memory2Tags
    }

    /// Get current location data
    func getCurrentLocation() -> PlaceData {
        return locations[currentLocation]
    }

    /// Whether current location is valid
    var isCurrentLocationValid: Bool {
        return locations[currentLocation].isValid
    }

    /// Whether all locations are completed
    var isAllLocationsCompleted: Bool {
        return locations.allSatisfy { $0.isValid }
    }

    /// Number of completed locations
    var completedCount: Int {
        return locations.filter { $0.isValid }.count
    }

    // MARK: - Navigation

    /// Whether can go to next location
    var canGoNext: Bool {
        return currentLocation < totalLocations - 1 && isCurrentLocationValid
    }

    /// Whether can go to previous location
    var canGoPrevious: Bool {
        return currentLocation > 0
    }

    /// Whether is first location
    var isFirstLocation: Bool {
        return currentLocation == 0
    }

    /// Whether is last location
    var isLastLocation: Bool {
        return currentLocation == totalLocations - 1
    }

    /// Go to next location
    @discardableResult
    func goToNext() -> Bool {
        guard canGoNext else { return false }
        currentLocation += 1
        return true
    }

    /// Go to previous location
    @discardableResult
    func goToPrevious() -> Bool {
        guard canGoPrevious else { return false }
        currentLocation -= 1
        return true
    }

    /// Jump to specified location
    @discardableResult
    func jumpTo(_ index: Int) -> Bool {
        guard index >= 0 && index < totalLocations else { return false }
        currentLocation = index
        return true
    }

    /// Jump to specified location
    func goToLocation(at index: Int) {
        guard index >= 0 && index < totalLocations else { return }
        currentLocation = index
    }

    /// Find the first incomplete location index
    /// - Returns: Index of first incomplete location, or nil if all completed
    func findFirstIncompleteLocation() -> Int? {
        for i in 0..<totalLocations {
            if !locations[i].isValid {
                return i
            }
        }
        return nil
    }

    /// Reset all data
    func reset() {
        locations = Array(repeating: PlaceData(), count: 5)
        currentLocation = 0
    }

    #if DEBUG
    // MARK: - Test Data Management

    /// Fill test data for current location
    func fillTestDataForCurrentLocation() {
        let index = min(currentLocation, Self.testCoordinates.count - 1)
        let coord = Self.testCoordinates[index]
        let memory1Tags = Self.testMemos1Tags[index]
        let memory2Tags = Self.testMemos2Tags[index]

        locations[currentLocation].latitude = coord.lat
        locations[currentLocation].longitude = coord.lon
        locations[currentLocation].memory1Tags = memory1Tags
        locations[currentLocation].memory2Tags = memory2Tags
    }

    /// Fill test data for all locations
    func fillAllTestData() {
        for i in 0..<min(totalLocations, Self.testCoordinates.count) {
            locations[i].latitude = Self.testCoordinates[i].lat
            locations[i].longitude = Self.testCoordinates[i].lon
            locations[i].memory1Tags = Self.testMemos1Tags[i]
            locations[i].memory2Tags = Self.testMemos2Tags[i]
        }
    }
    #endif
}
