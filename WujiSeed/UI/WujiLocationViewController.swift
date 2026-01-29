//
//  WujiLocationViewController.swift
//  WujiSeed
//
//  F9 Location - displays current GPS location with F9Grid visualization
//

import UIKit
import CoreLocation
import F9Grid

class WujiLocationViewController: UIViewController {

    // MARK: - Constants

    /// Maximum acceptable accuracy in meters for F9Grid usage
    private let maxAcceptableAccuracy: Double = 11.8

    // MARK: - Mock Location Support

    /// Mock base coordinate - when set, display will show this location offset by real GPS movement
    /// Set this before view appears to enable mock mode
    var mockCoordinate: CLLocationCoordinate2D?

    /// Initial real GPS location (recorded when mock mode is active)
    private var initialRealLocation: CLLocation?

    /// Whether mock mode is active
    private var isMockMode: Bool {
        return mockCoordinate != nil
    }

    // MARK: - Properties

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    // MARK: - UI Components

    // F9Grid map visualization (fills entire screen)
    private let gridMapView = F9GridMapView()

    // MARK: - Theme Colors

    /// Cyan accent color matching grid
    private static let accentColor = UIColor(red: 0.0, green: 0.81, blue: 0.82, alpha: 1.0)  // #00CFD1

    /// Card background (dark semi-transparent)
    private static let cardBackground = UIColor(red: 0.08, green: 0.15, blue: 0.22, alpha: 0.95)  // #142638

    // Circular back button
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = cardBackground
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = accentColor.withAlphaComponent(0.3).cgColor
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        } else {
            button.setTitle("←", for: .normal)
        }
        button.tintColor = accentColor
        return button
    }()

    // Floating coordinates card (tappable to copy)
    private let coordinatesCard: UIView = {
        let view = UIView()
        view.backgroundColor = cardBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = accentColor.withAlphaComponent(0.2).cgColor
        return view
    }()

    private let coordinatesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = Lang("f9location.coordinates")
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        return label
    }()

    private let coordinatesValueLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        if #available(iOS 13.0, *) {
            label.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
        } else {
            label.font = UIFont(name: "Menlo", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .semibold)
        }
        label.textColor = accentColor
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()

    private let accuracyStatusLabel: UILabel = {
        let label = UILabel()
        label.text = Lang("f9location.waiting")
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        return label
    }()

    // MARK: - Status Bar

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupConstraints()
        setupGestures()
        setupLocationManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setNeedsStatusBarAppearanceUpdate()
        startLocationUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Restore status bar style
        if let nav = navigationController {
            nav.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showLocationTips()
    }

    private func showLocationTips() {
        let alert = UIAlertController(
            title: Lang("f9location.tips_title"),
            message: nil,
            preferredStyle: .alert
        )

        // Create left-aligned attributed message
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let messageText = Lang("f9location.tips_message")
        let attributedMessage = NSAttributedString(
            string: messageText,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.darkGray
            ]
        )
        alert.setValue(attributedMessage, forKey: "attributedMessage")

        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default))
        present(alert, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGridMapContentInsets()
    }

    private func updateGridMapContentInsets() {
        // Top inset: safe area top (no navigation bar)
        let topInset = view.safeAreaInsets.top
        // Bottom inset: floating card height
        let cardHeight = coordinatesCard.frame.height
        let bottomInset = cardHeight + 16 // 16 is the margin from safe area bottom

        gridMapView.contentInsets = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = F9GridMapView.backgroundColor

        view.addSubview(gridMapView)
        view.addSubview(backButton)
        view.addSubview(coordinatesCard)

        coordinatesCard.addSubview(coordinatesTitleLabel)
        coordinatesCard.addSubview(coordinatesValueLabel)
        coordinatesCard.addSubview(accuracyStatusLabel)

        gridMapView.maxAcceptableAccuracy = maxAcceptableAccuracy

        // Show debug info (k values) only when using mock location
        gridMapView.showDebugInfo = (mockCoordinate != nil)
    }

    private func setupConstraints() {
        gridMapView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        coordinatesCard.translatesAutoresizingMaskIntoConstraints = false
        coordinatesTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        coordinatesValueLabel.translatesAutoresizingMaskIntoConstraints = false
        accuracyStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Grid map fills entire screen
            gridMapView.topAnchor.constraint(equalTo: view.topAnchor),
            gridMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Back button at top left
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            // Floating coordinates card at bottom
            coordinatesCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            coordinatesCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Card content
            coordinatesTitleLabel.topAnchor.constraint(equalTo: coordinatesCard.topAnchor, constant: 16),
            coordinatesTitleLabel.leadingAnchor.constraint(equalTo: coordinatesCard.leadingAnchor, constant: 20),

            coordinatesValueLabel.topAnchor.constraint(equalTo: coordinatesTitleLabel.bottomAnchor, constant: 8),
            coordinatesValueLabel.leadingAnchor.constraint(equalTo: coordinatesCard.leadingAnchor, constant: 20),
            coordinatesValueLabel.trailingAnchor.constraint(equalTo: coordinatesCard.trailingAnchor, constant: -20),

            accuracyStatusLabel.topAnchor.constraint(equalTo: coordinatesValueLabel.bottomAnchor, constant: 12),
            accuracyStatusLabel.leadingAnchor.constraint(equalTo: coordinatesCard.leadingAnchor, constant: 20),
            accuracyStatusLabel.trailingAnchor.constraint(equalTo: coordinatesCard.trailingAnchor, constant: -20),
            accuracyStatusLabel.bottomAnchor.constraint(equalTo: coordinatesCard.bottomAnchor, constant: -16),

            // Card bottom position
            coordinatesCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func setupGestures() {
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        // Long press to copy coordinates
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        coordinatesValueLabel.addGestureRecognizer(longPress)
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        guard currentLocation != nil else { return }

        coordinatesValueLabel.becomeFirstResponder()

        let menuController = UIMenuController.shared
        let copyItem = UIMenuItem(title: Lang("f9location.copy"), action: #selector(copyCoordinates))
        menuController.menuItems = [copyItem]

        if #available(iOS 13.0, *) {
            menuController.showMenu(from: coordinatesValueLabel, rect: coordinatesValueLabel.bounds)
        } else {
            menuController.setTargetRect(coordinatesValueLabel.bounds, in: coordinatesValueLabel)
            menuController.setMenuVisible(true, animated: true)
        }
    }

    // MARK: - Location Manager

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.headingFilter = 1  // Update every 1 degree change
    }

    private func startLocationUpdates() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
        case .denied, .restricted:
            showLocationDeniedAlert()
        @unknown default:
            break
        }
    }

    private func showLocationDeniedAlert() {
        let alert = UIAlertController(
            title: Lang("f9location.permission_denied_title"),
            message: Lang("f9location.permission_denied_message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Lang("common.settings"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Mock Location Calculation

    /// Calculate display location based on mock mode
    /// - Parameter realLocation: Current real GPS location
    /// - Returns: Location to display (mock + offset, or real location if not in mock mode)
    private func calculateDisplayLocation(from realLocation: CLLocation) -> CLLocation {
        guard let mockCoord = mockCoordinate else {
            // Not in mock mode, use real location
            return realLocation
        }

        // Record initial real location on first update
        if initialRealLocation == nil {
            initialRealLocation = realLocation
        }

        guard let initialReal = initialRealLocation else {
            return realLocation
        }

        // Calculate offset from initial position
        let latOffset = realLocation.coordinate.latitude - initialReal.coordinate.latitude
        let lngOffset = realLocation.coordinate.longitude - initialReal.coordinate.longitude

        // Apply offset to mock coordinate
        let displayLat = mockCoord.latitude + latOffset
        let displayLng = mockCoord.longitude + lngOffset

        // Create new location with mock coordinates but real accuracy/heading
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: displayLat, longitude: displayLng),
            altitude: realLocation.altitude,
            horizontalAccuracy: realLocation.horizontalAccuracy,
            verticalAccuracy: realLocation.verticalAccuracy,
            timestamp: realLocation.timestamp
        )
    }

    // MARK: - UI Updates

    private func updateUI(with location: CLLocation) {
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        let accuracy = location.horizontalAccuracy
        let isAcceptable = accuracy <= maxAcceptableAccuracy

        // Update grid map view
        gridMapView.location = location

        // Update coordinates with color based on accuracy
        coordinatesValueLabel.text = String(format: "%.6f, %.6f", lat, lng)
        let coordColor = isAcceptable ? Self.accentColor : UIColor.systemRed
        coordinatesValueLabel.textColor = coordColor

        // Update accuracy and status on same line
        let prefix = Lang("f9location.accuracy")
        let unit = Lang("f9location.meters")
        let status = isAcceptable ? Lang("f9location.status_available") : Lang("f9location.status_unavailable")
        accuracyStatusLabel.text = "\(prefix) \(String(format: "%.1f", accuracy)) \(unit)  \(status)"
        accuracyStatusLabel.textColor = isAcceptable ? UIColor.white.withAlphaComponent(0.7) : UIColor.systemRed.withAlphaComponent(0.8)
    }

    // MARK: - Actions

    @objc private func copyCoordinates() {
        guard let location = currentLocation else { return }

        let coordString = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
        UIPasteboard.general.string = coordString
    }
}

// MARK: - UILabel Extension for Copy Menu

extension WujiLocationViewController {
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copyCoordinates) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

// MARK: - CLLocationManagerDelegate

extension WujiLocationViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let realLocation = locations.last else { return }

        // Calculate display location (applies mock offset if in mock mode)
        let displayLocation = calculateDisplayLocation(from: realLocation)
        currentLocation = displayLocation
        updateUI(with: displayLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        WujiLogger.error("Location error: \(error.localizedDescription)")
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use true heading if available, otherwise use magnetic heading
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        gridMapView.heading = heading
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startLocationUpdates()
    }

    // iOS 13 and earlier
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startLocationUpdates()
    }
}
