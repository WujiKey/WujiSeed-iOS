//
//  F9GridMapView.swift
//  WujiSeed
//
//  Custom view that visualizes F9Grid cells with position and accuracy
//

import UIKit
import CoreLocation
import F9Grid

class F9GridMapView: UIView {

    // MARK: - Properties

    /// Current location to display
    var location: CLLocation? {
        didSet { setNeedsDisplay() }
    }

    /// Current device heading in degrees (0-360, 0 = North)
    var heading: Double = 0 {
        didSet { setNeedsDisplay() }
    }

    /// Maximum acceptable accuracy (11.8m for F9Grid)
    var maxAcceptableAccuracy: Double = 11.8

    /// Content insets for calculating visible center (top: nav bar, bottom: floating card)
    var contentInsets: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }

    /// Show debug info (k values) - only when using mock location
    var showDebugInfo: Bool = false {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Computed Properties

    /// Grid cell size - calculated so 3 cells fit horizontally
    private var cellSize: CGFloat {
        return bounds.width / 3
    }

    // MARK: - Colors (Dark Tech Theme)

    /// Deep blue-black background color
    static let backgroundColor = UIColor(red: 0.05, green: 0.11, blue: 0.16, alpha: 1.0)  // #0D1B2A

    /// Cyan/teal color for grid lines
    private let gridLineColor = UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 0.5)  // #00CFD1

    /// Highlight color for current cell/position overlay
    private let highlightColor = UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 0.12)

    /// Center dot color (bright green with glow effect)
    private let centerDotColor = UIColor(red: 0.0, green: 1.0, blue: 0.53, alpha: 1.0)  // #00FF88

    /// Accuracy circle color (cyan)
    private let accuracyCircleColor = UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 1.0)

    /// Position code layout (row, col) -> code
    /// 4(NW)  9(N)   2(NE)
    /// 3(W)   5(C)   7(E)
    /// 8(SW)  1(S)   6(SE)
    private let positionCodeLayout: [[Int]] = [
        [4, 9, 2],
        [3, 5, 7],
        [8, 1, 6]
    ]

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = F9GridMapView.backgroundColor
        clipsToBounds = true
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard cellSize > 0 else { return }
        guard let location = location else { return }

        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude

        guard let centerPlace = WujiPlace(latitude: lat, longitude: lng),
              let centerCell = centerPlace.cell() else { return }

        // Screen center point
        let centerX = bounds.width / 2
        let visibleHeight = bounds.height - contentInsets.top - contentInsets.bottom
        let centerY = contentInsets.top + visibleHeight / 2

        // Calculate pixels per degree based on current cell's latitude height
        // Cell height in latitude = 3 steps * 0.000375° = 0.001125°
        // We want 1 cell height = cellSize pixels in latitude direction
        let cellLatHeight = centerCell.latRange.north - centerCell.latRange.south
        let pixelsPerDegreeLat = cellSize / CGFloat(cellLatHeight)

        // Save context state before rotation
        context.saveGState()

        // Apply rotation around the center point
        let rotationAngle = CGFloat(-heading * .pi / 180)
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: rotationAngle)
        context.translateBy(x: -centerX, y: -centerY)

        // Calculate visible geographic range (diagonal covers rotation, small buffer for edge)
        let diagonal = sqrt(bounds.width * bounds.width + bounds.height * bounds.height)
        let latRange = Double(diagonal / pixelsPerDegreeLat) * 1.1  // 10% buffer
        let lngRange = latRange * 1.2  // Slightly wider for varying cell widths

        let minLat = lat - latRange / 2
        let maxLat = lat + latRange / 2
        let minLng = lng - lngRange / 2
        let maxLng = lng + lngRange / 2

        // Collect all cells using BFS from center cell (more efficient than sampling)
        var cellsToDraw: [F9Grid.F9Cell] = []
        var visitedIndices = Set<Int64>()
        var queue: [F9Grid.F9Cell] = [centerCell]
        visitedIndices.insert(centerCell.index)

        while !queue.isEmpty {
            let cell = queue.removeFirst()

            // Check if cell is within visible range
            let cellCenterLat = cell.centerLat
            var cellCenterLng = cell.centerLng
            if cellCenterLng > 180 { cellCenterLng -= 360 }

            // Skip cells too far from visible area
            if cellCenterLat < minLat - cellLatHeight || cellCenterLat > maxLat + cellLatHeight {
                continue
            }
            if cellCenterLng < minLng - 0.01 || cellCenterLng > maxLng + 0.01 {
                continue
            }

            cellsToDraw.append(cell)

            // Add neighbors to queue
            for (_, neighbor) in cell.neighbors() {
                if !visitedIndices.contains(neighbor.index) {
                    visitedIndices.insert(neighbor.index)
                    queue.append(neighbor)
                }
            }
        }

        // Draw all cells based on their actual geographic bounds
        for cell in cellsToDraw {
            let cellRect = cellRectForGeoBounds(
                cell: cell,
                centerLat: lat, centerLng: lng,
                centerX: centerX, centerY: centerY,
                pixelsPerDegreeLat: pixelsPerDegreeLat
            )

            // Draw cell border
            context.setStrokeColor(gridLineColor.cgColor)
            context.setLineWidth(1.0)
            context.stroke(cellRect)

            // Draw 9-grid
            draw9Grid(context: context, cellRect: cellRect)

            // Draw cell ID and k value
            drawWatermarkWithK(context: context, cellRect: cellRect, cell: cell)
        }

        // Draw highlight for current position and adjacent 9 cells
        let isAcceptable = location.horizontalAccuracy <= maxAcceptableAccuracy
        if isAcceptable {
            drawAdjacentPositionsGeo(
                context: context,
                centerLat: lat, centerLng: lng,
                centerX: centerX, centerY: centerY,
                pixelsPerDegreeLat: pixelsPerDegreeLat,
                currentCell: centerCell,
                currentPosCode: centerPlace.positionCode() ?? 5
            )
        }

        // Restore context state
        context.restoreGState()

        // Draw location dot (not rotated)
        drawLocationDot(context: context, location: location)
    }

    /// Convert cell's geographic bounds to screen rect
    private func cellRectForGeoBounds(cell: F9Grid.F9Cell,
                                       centerLat: Double, centerLng: Double,
                                       centerX: CGFloat, centerY: CGFloat,
                                       pixelsPerDegreeLat: CGFloat) -> CGRect {
        let latRange = cell.latRange
        let lngRange = cell.lngRange

        // Normalize longitude
        var cellWest = lngRange.west
        var cellEast = lngRange.east
        if cellWest > 180 { cellWest -= 360 }
        if cellEast > 180 { cellEast -= 360 }

        // Calculate screen coordinates
        // Y increases downward, latitude increases upward
        let top = centerY - CGFloat(latRange.north - centerLat) * pixelsPerDegreeLat
        let bottom = centerY - CGFloat(latRange.south - centerLat) * pixelsPerDegreeLat
        let left = centerX + CGFloat(cellWest - centerLng) * pixelsPerDegreeLat
        let right = centerX + CGFloat(cellEast - centerLng) * pixelsPerDegreeLat

        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    /// Draw watermark (k value only shown when showDebugInfo is true)
    private func drawWatermarkWithK(context: CGContext, cellRect: CGRect, cell: F9Grid.F9Cell) {
        // Show last 6 digits to distinguish cells at different latitudes
        let lastDigits = abs(cell.index) % 1000000  // 6 digits

        // Show k value only when using mock location (showDebugInfo = true)
        // Always display 6 digits with leading zeros
        let idText: String
        if showDebugInfo {
            idText = String(format: "%06d k%d", lastDigits, cell.k)
        } else {
            idText = String(format: "%06d", lastDigits)
        }

        let watermarkAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
            .foregroundColor: gridLineColor.withAlphaComponent(0.6)
        ]

        let idSize = idText.size(withAttributes: watermarkAttributes)
        let idPoint = CGPoint(
            x: cellRect.midX - idSize.width / 2,
            y: cellRect.minY + 3
        )
        idText.draw(at: idPoint, withAttributes: watermarkAttributes)
    }

    /// Draw adjacent 9 positions using F9Grid 1.1.0 API
    private func drawAdjacentPositionsGeo(context: CGContext,
                                           centerLat: Double, centerLng: Double,
                                           centerX: CGFloat, centerY: CGFloat,
                                           pixelsPerDegreeLat: CGFloat,
                                           currentCell: F9Grid.F9Cell,
                                           currentPosCode: Int) {
        context.saveGState()

        // Draw current position (brighter)
        drawSubCell(context: context, cell: currentCell, positionCode: currentPosCode,
                    centerLat: centerLat, centerLng: centerLng,
                    centerX: centerX, centerY: centerY,
                    pixelsPerDegreeLat: pixelsPerDegreeLat,
                    alpha: 0.35)

        // Get adjacent position codes using 9-grid layout
        let adjacentPositions = getAdjacentPositionCodes(currentPosCode: currentPosCode)

        for (direction, targetPosCode) in adjacentPositions {
            // Determine which cell contains this adjacent position
            let targetCell: F9Grid.F9Cell?
            if let cellDirection = direction {
                targetCell = currentCell.neighbor(cellDirection)
            } else {
                targetCell = currentCell  // Same cell
            }

            guard let cell = targetCell else { continue }

            drawSubCell(context: context, cell: cell, positionCode: targetPosCode,
                        centerLat: centerLat, centerLng: centerLng,
                        centerX: centerX, centerY: centerY,
                        pixelsPerDegreeLat: pixelsPerDegreeLat,
                        alpha: 0.12)
        }

        context.restoreGState()
    }

    /// Draw a single sub-cell using F9Grid's subCellBounds API
    private func drawSubCell(context: CGContext, cell: F9Grid.F9Cell, positionCode: Int,
                              centerLat: Double, centerLng: Double,
                              centerX: CGFloat, centerY: CGFloat,
                              pixelsPerDegreeLat: CGFloat, alpha: CGFloat) {
        guard let bounds = cell.subCellBounds(positionCode: positionCode) else { return }

        var subCellWest = bounds.lngRange.west
        var subCellEast = bounds.lngRange.east
        if subCellWest > 180 { subCellWest -= 360 }
        if subCellEast > 180 { subCellEast -= 360 }

        let top = centerY - CGFloat(bounds.latRange.north - centerLat) * pixelsPerDegreeLat
        let bottom = centerY - CGFloat(bounds.latRange.south - centerLat) * pixelsPerDegreeLat
        let left = centerX + CGFloat(subCellWest - centerLng) * pixelsPerDegreeLat
        let right = centerX + CGFloat(subCellEast - centerLng) * pixelsPerDegreeLat

        let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        context.setFillColor(highlightColor.withAlphaComponent(alpha).cgColor)
        context.fill(rect)
    }

    /// Get adjacent position codes with their cell direction (nil = same cell)
    /// Position layout:
    ///   4(NW) 9(N)  2(NE)
    ///   3(W)  5(C)  7(E)
    ///   8(SW) 1(S)  6(SE)
    private func getAdjacentPositionCodes(currentPosCode: Int) -> [(direction: F9Grid.F9Cell.Direction?, positionCode: Int)] {
        // Map position code to (row, col) in 3x3 grid
        let posToRowCol: [Int: (row: Int, col: Int)] = [
            4: (0, 0), 9: (0, 1), 2: (0, 2),
            3: (1, 0), 5: (1, 1), 7: (1, 2),
            8: (2, 0), 1: (2, 1), 6: (2, 2)
        ]
        let rowColToPos: [[Int]] = [
            [4, 9, 2],
            [3, 5, 7],
            [8, 1, 6]
        ]

        guard let (row, col) = posToRowCol[currentPosCode] else { return [] }

        var result: [(F9Grid.F9Cell.Direction?, Int)] = []

        // 8 adjacent directions: (-1,-1), (-1,0), (-1,1), (0,-1), (0,1), (1,-1), (1,0), (1,1)
        let deltas = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]

        for (dRow, dCol) in deltas {
            var newRow = row + dRow
            var newCol = col + dCol
            var cellDir: F9Grid.F9Cell.Direction? = nil

            // Determine cell direction if crossing boundary
            var dirRow: Int? = nil
            var dirCol: Int? = nil

            if newRow < 0 {
                dirRow = -1  // North
                newRow = 2
            } else if newRow > 2 {
                dirRow = 1   // South
                newRow = 0
            }

            if newCol < 0 {
                dirCol = -1  // West
                newCol = 2
            } else if newCol > 2 {
                dirCol = 1   // East
                newCol = 0
            }

            // Convert to F9Cell.Direction
            if let dr = dirRow, let dc = dirCol {
                if dr == -1 && dc == -1 { cellDir = .nw }
                else if dr == -1 && dc == 1 { cellDir = .ne }
                else if dr == 1 && dc == -1 { cellDir = .sw }
                else if dr == 1 && dc == 1 { cellDir = .se }
            } else if let dr = dirRow {
                cellDir = dr == -1 ? .n : .s
            } else if let dc = dirCol {
                cellDir = dc == -1 ? .w : .e
            }

            let targetPosCode = rowColToPos[newRow][newCol]
            result.append((cellDir, targetPosCode))
        }

        return result
    }

    private func draw9Grid(context: CGContext, cellRect: CGRect) {
        // 9-grid fills the entire cell
        let innerRect = cellRect

        let subCellWidth = innerRect.width / 3
        let subCellHeight = innerRect.height / 3

        // Draw dashed lines with modern tech color
        context.saveGState()
        context.setStrokeColor(gridLineColor.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [2, 2])

        // Vertical dashed lines
        for i in 1..<3 {
            let x = innerRect.minX + CGFloat(i) * subCellWidth
            context.move(to: CGPoint(x: x, y: innerRect.minY))
            context.addLine(to: CGPoint(x: x, y: innerRect.maxY))
        }

        // Horizontal dashed lines
        for i in 1..<3 {
            let y = innerRect.minY + CGFloat(i) * subCellHeight
            context.move(to: CGPoint(x: innerRect.minX, y: y))
            context.addLine(to: CGPoint(x: innerRect.maxX, y: y))
        }

        context.strokePath()
        context.restoreGState()

        // Draw position codes
        let codeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            .foregroundColor: gridLineColor.withAlphaComponent(0.6)
        ]

        for row in 0..<3 {
            for col in 0..<3 {
                let code = positionCodeLayout[row][col]
                let codeText = "\(code)"
                let codeSize = codeText.size(withAttributes: codeAttributes)

                let subCellCenterX = innerRect.minX + CGFloat(col) * subCellWidth + subCellWidth / 2
                let subCellCenterY = innerRect.minY + CGFloat(row) * subCellHeight + subCellHeight / 2

                let codePoint = CGPoint(
                    x: subCellCenterX - codeSize.width / 2,
                    y: subCellCenterY - codeSize.height / 2
                )
                codeText.draw(at: codePoint, withAttributes: codeAttributes)
            }
        }
    }

    private func drawLocationDot(context: CGContext, location: CLLocation) {
        // Location dot is always at the visible center (between nav bar and card)
        let dotX = bounds.width / 2
        let visibleHeight = bounds.height - contentInsets.top - contentInsets.bottom
        let dotY = contentInsets.top + visibleHeight / 2

        let accuracy = location.horizontalAccuracy
        let isAcceptable = accuracy <= maxAcceptableAccuracy

        // Calculate cell height in meters using WGS84 ellipsoid at current latitude
        let cellHeightInMeters = getCellHeightInMeters(location: location)
        let pixelsPerMeter = cellSize / CGFloat(cellHeightInMeters)
        let circleRadius = CGFloat(accuracy) * pixelsPerMeter

        // Range circle color based on availability
        let rangeColor = isAcceptable
            ? accuracyCircleColor  // Cyan when available
            : UIColor.systemRed    // Red when unavailable

        // Draw accuracy range circle
        context.saveGState()
        context.setFillColor(rangeColor.withAlphaComponent(0.08).cgColor)
        context.fillEllipse(in: CGRect(
            x: dotX - circleRadius,
            y: dotY - circleRadius,
            width: circleRadius * 2,
            height: circleRadius * 2
        ))
        context.setStrokeColor(rangeColor.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.0)
        context.strokeEllipse(in: CGRect(
            x: dotX - circleRadius,
            y: dotY - circleRadius,
            width: circleRadius * 2,
            height: circleRadius * 2
        ))
        context.restoreGState()

        // Draw center dot with soft glow (using gradient)
        let dotRadius: CGFloat = 5

        // Draw soft radial glow from center
        let glowRadius: CGFloat = 35
        let colors = [
            UIColor.white.withAlphaComponent(0.25).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors as CFArray,
                                      locations: locations) {
            context.saveGState()
            context.drawRadialGradient(gradient,
                                       startCenter: CGPoint(x: dotX, y: dotY),
                                       startRadius: 0,
                                       endCenter: CGPoint(x: dotX, y: dotY),
                                       endRadius: glowRadius,
                                       options: [])
            context.restoreGState()
        }

        // Draw white center dot
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(
            x: dotX - dotRadius,
            y: dotY - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))
    }

    // MARK: - WGS84 Calculations

    /// Calculate cell height in meters using WGS84 ellipsoid parameters
    /// - Parameter location: Current location for latitude reference
    /// - Returns: Cell height in meters at the current latitude
    private func getCellHeightInMeters(location: CLLocation) -> Double {
        guard let place = WujiPlace(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
              let cell = place.cell() else {
            // Fallback to approximate value if cell info unavailable
            return 35.4
        }

        // Get cell latitude range
        let latRange = cell.latRange
        let deltaLat = latRange.north - latRange.south  // degrees

        // Calculate center latitude for more accurate calculation
        let centerLat = (latRange.north + latRange.south) / 2.0

        // WGS84 ellipsoid parameters
        let a: Double = 6378137.0  // Semi-major axis (equatorial radius) in meters
        let e2: Double = 0.00669437999014  // First eccentricity squared

        // Convert latitude to radians
        let latRad = centerLat * .pi / 180.0

        // Calculate meridional radius of curvature (M)
        // M = a * (1 - e²) / (1 - e² * sin²(lat))^(3/2)
        let sinLat = sin(latRad)
        let sinLatSq = sinLat * sinLat
        let denominator = pow(1.0 - e2 * sinLatSq, 1.5)
        let M = a * (1.0 - e2) / denominator

        // Convert delta latitude to radians and calculate distance
        let deltaLatRad = deltaLat * .pi / 180.0
        let cellHeightMeters = M * deltaLatRad

        return cellHeightMeters
    }
}
