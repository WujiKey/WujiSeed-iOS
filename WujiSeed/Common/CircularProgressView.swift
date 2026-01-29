//
//  CircularProgressView.swift
//  WujiSeed
//
//  Circular progress indicator with percentage label
//

import UIKit

/// Circular progress view with percentage display
class CircularProgressView: UIView {

    // MARK: - Properties

    /// Current progress (0.0 - 1.0)
    var progress: Float = 0 {
        didSet {
            updateProgress()
        }
    }

    /// Track color (background circle)
    var trackColor: UIColor = Theme.Colors.trackLight {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }

    /// Progress color (foreground arc)
    var progressColor: UIColor = Theme.Colors.elegantBlue {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }

    /// Line width
    var lineWidth: CGFloat = 6 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }

    // MARK: - Private Properties

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let percentageLabel = UILabel()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    // MARK: - Setup

    private func setupLayers() {
        // Track layer (background circle)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // Progress layer (foreground arc)
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)

        // Percentage label
        percentageLabel.textAlignment = .center
        percentageLabel.font = Theme.Fonts.monospacedLarge
        percentageLabel.textColor = Theme.MinimalTheme.textPrimary
        percentageLabel.text = "0%"
        addSubview(percentageLabel)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2

        // Create circular path (start from top, -90 degrees)
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath

        // Center the label
        percentageLabel.frame = bounds
    }

    // MARK: - Update

    private func updateProgress() {
        // Clamp progress to 0-1
        let clampedProgress = max(0, min(1, progress))

        // Update arc
        progressLayer.strokeEnd = CGFloat(clampedProgress)

        // Update label
        let percentage = Int(clampedProgress * 100)
        percentageLabel.text = "\(percentage)%"
    }

    // MARK: - Animation

    /// Set progress with animation
    func setProgress(_ newProgress: Float, animated: Bool, duration: TimeInterval = 0.3) {
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = CGFloat(newProgress)
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.add(animation, forKey: "progressAnimation")
        }
        progress = newProgress
    }
}
