//
//  PlacesInputViewController.swift
//  WujiKey
//
//  Step-by-step location input controller - Dual device scenario design
//  Completely offline, no paste functionality, user needs to manually input coordinates from another device
//

import UIKit

/// Places: Step-by-step location input controller
/// One page per location: coordinates + memos combined input
class PlacesInputViewController: KeyboardAwareViewController {

    // MARK: - Types

    typealias PlaceData = PlacesDataManager.PlaceData

    // MARK: - Properties

    private let dataManager = PlacesDataManager()

    /// Location index to jump to after returning from Summary page
    var jumpToLocationAfterReturn: Int?

    /// Whether editing from Confirm page (controls behavior after clicking "Next")
    private var isEditingFromConfirm = false

    /// Whether in import mode (importing existing mnemonic)
    var isImportMode: Bool = false

    /// Whether in recovery mode (recovering encrypted backup)
    var isRecoveryMode: Bool = false

    // MARK: - UI Components

    private let contentContainerView = UIView()

    // Currently displayed location input view
    private var currentInputView: PlaceInputRowView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Set back button to show no text (prepare for PlacesConfirm)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // If not returning from Confirm, start from first location
        if jumpToLocationAfterReturn == nil {
            dataManager.goToLocation(at: 0)
        }

        setupUI()
        setupConstraints()
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false

        updateNavigationBar()

        // Enable swipe gesture and set delegate for custom behavior
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        // Handle jump after returning from Summary page
        if let targetIndex = jumpToLocationAfterReturn {
            jumpToLocationAfterReturn = nil  // Clear flag
            isEditingFromConfirm = true  // Mark as editing from Confirm

            // Hide back button
            navigationItem.hidesBackButton = true

            dataManager.goToLocation(at: targetIndex)
            updateUI()
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        // Content container
        view.addSubview(contentContainerView)
    }

    private func setupConstraints() {
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Content container
            contentContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func updateNavigationBar() {
        // Display current location title
        navigationItem.title = String(format: Lang("places.nav.location_x_of_5"), dataManager.currentLocation + 1)

        // Hide menu button when editing from Last page
        if isEditingFromConfirm {
            navigationItem.rightBarButtonItem = nil
        } else {
            // Normal flow, show menu button in top-right
            let menuButton: UIBarButtonItem
            if #available(iOS 13.0, *) {
                menuButton = UIBarButtonItem(
                    image: UIImage(systemName: "line.3.horizontal"),
                    style: .plain,
                    target: self,
                    action: #selector(showQuickNavigation)
                )
            } else {
                menuButton = UIBarButtonItem(
                    title: "≡",
                    style: .plain,
                    target: self,
                    action: #selector(showQuickNavigation)
                )
            }
            navigationItem.rightBarButtonItem = menuButton
        }

        // Unified navigation bar color
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Theme.MinimalTheme.cardBackground
            appearance.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont
            ]
            appearance.shadowColor = Theme.MinimalTheme.separator

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.barTintColor = Theme.MinimalTheme.cardBackground
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont
            ]
        }

        navigationController?.navigationBar.tintColor = Theme.Colors.elegantBlue
    }

    // MARK: - UI Update

    private func saveCurrentInput() {
        // Save current input field data to dataManager
        // Use view's locationIndex instead of dataManager.currentLocation
        // Avoid data contamination when switching locations
        if let currentView = currentInputView {
            let input = currentView.getCurrentInputWithTags()
            dataManager.updateLocation(
                at: currentView.locationIndex,
                latitude: input.latitude,
                longitude: input.longitude,
                memory1Tags: input.memory1Tags,
                memory2Tags: input.memory2Tags
            )
        }
    }

    private func updateUI() {
        updateNavigationBar()

        // Save current input data first
        saveCurrentInput()

        // Remove old view
        currentInputView?.removeFromSuperview()

        // Create new input view
        let newView = PlaceInputRowView()
        newView.locationIndex = dataManager.currentLocation

        // Change button text to "Confirm" when editing from Last page
        if isEditingFromConfirm {
            newView.buttonTitle = Lang("common.confirm")
        }

        // Restore saved data from DataManager
        let currentLoc = dataManager.getCurrentLocation()
        newView.updateFieldsWithTags(
            latitude: currentLoc.latitude,
            longitude: currentLoc.longitude,
            memory1Tags: currentLoc.memory1Tags,
            memory2Tags: currentLoc.memory2Tags
        )

        newView.onComplete = { [weak self] lat, lon, memory1Tags, memory2Tags in
            guard let self = self else { return }

            // Save current location data (normalized tags)
            self.dataManager.updateCurrentLocation(latitude: lat, longitude: lon, memory1Tags: memory1Tags, memory2Tags: memory2Tags)

            // Go to next location
            self.nextLocation()
        }

        newView.onShowGuide = { [weak self] in
            guard let self = self else { return }
            self.showCoordinateGuide()
        }

        newView.onShowExamples = { [weak self] in
            guard let self = self else { return }
            self.showMemoryExamples()
        }

        #if DEBUG
        newView.onFillTestData = { [weak self] in
            guard let self = self else { return }
            self.fillTestData()
        }
        #endif

        currentInputView = newView
        contentContainerView.addSubview(newView)

        newView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            newView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            newView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            newView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
    }

    // MARK: - Navigation

    @objc private func backButtonTapped() {
        // Linear navigation: 5→4→3→2→1→NameSalt
        previousLocation()
    }

    private func nextLocation() {
        // If editing from Confirm, return to Confirm page after clicking "Next"
        if isEditingFromConfirm {
            isEditingFromConfirm = false  // Clear flag
            showFinalSummary()
            return
        }

        let transition = CATransition()
        transition.duration = 0.3
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        contentContainerView.layer.add(transition, forKey: nil)

        // Can only enter Confirm page when at last location (5th)
        if dataManager.isLastLocation {
            // At last location, check if all locations are completed
            // Find first incomplete location
            if let firstIncompleteIndex = dataManager.locations.firstIndex(where: { !$0.isValid }) {
                // Has incomplete location, jump to first incomplete
                #if DEBUG
                WujiLogger.warning("Incomplete location exists, jumping to location \(firstIncompleteIndex + 1)")
                #endif
                dataManager.jumpTo(firstIncompleteIndex)
                updateUI()

                // Show alert
                showIncompleteLocationAlert(firstIncompleteIndex + 1)
            } else {
                // All locations completed, can enter summary page
                showFinalSummary()
            }
        } else {
            // Not at last location, go to next location
            dataManager.goToNext()
            updateUI()
        }
    }

    private func previousLocation() {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = .push
        transition.subtype = .fromLeft
        contentContainerView.layer.add(transition, forKey: nil)

        if dataManager.canGoPrevious {
            dataManager.goToPrevious()
            updateUI()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Quick Navigation

    @objc private func showQuickNavigation() {
        let alert = UIAlertController(title: Lang("places.menu.quick_nav"), message: nil, preferredStyle: .actionSheet)

        for i in 0..<5 {
            let location = dataManager.locations[i]
            let title: String

            if location.isValid {
                // Show first few tags as preview
                let allTags = location.memory1Tags + location.memory2Tags
                let preview = allTags.prefix(4).joined(separator: " ")
                title = String(format: Lang("places.menu.location_completed"), i + 1, String(preview.prefix(15)))
            } else if i == dataManager.currentLocation {
                title = String(format: Lang("places.menu.location_current"), i + 1)
            } else {
                title = String(format: Lang("places.menu.location_empty"), i + 1)
            }

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.jumpToLocation(i)
            })
        }

        alert.addAction(UIAlertAction(title: Lang("places.menu.clear_all"), style: .destructive) { [weak self] _ in
            self?.confirmClearAllData()
        })

        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }

        present(alert, animated: true)
    }

    private func jumpToLocation(_ index: Int) {
        dataManager.goToLocation(at: index)
        updateUI()
    }

    private func confirmClearAllData() {
        let alert = UIAlertController(
            title: Lang("places.alert.confirm_clear_title"),
            message: Lang("places.alert.confirm_clear_message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Lang("common.clear"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // Remove current input view first, avoid saving current input in updateUI
            self.currentInputView?.removeFromSuperview()
            self.currentInputView = nil

            // Clear all data and drafts
            self.dataManager.reset()

            // Refresh UI to first location
            self.updateUI()
        })

        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - Guide and Examples

    private func showCoordinateGuide() {
        // Prevent duplicate present
        guard presentedViewController == nil else { return }

        let guideVC = GuideLatLngViewController()
        let navVC = UINavigationController(rootViewController: guideVC)
        if #available(iOS 13.0, *) {
            navVC.modalPresentationStyle = .pageSheet
        } else {
            navVC.modalPresentationStyle = .fullScreen
        }

        // Ensure execution on main thread
        DispatchQueue.main.async {
            self.present(navVC, animated: true)
        }
    }

    private func showMemoryExamples() {
        // Prevent duplicate present
        guard presentedViewController == nil else { return }

        let examplesVC = GuideMemoryViewController()
        let navVC = UINavigationController(rootViewController: examplesVC)
        if #available(iOS 13.0, *) {
            navVC.modalPresentationStyle = .pageSheet
        } else {
            navVC.modalPresentationStyle = .fullScreen
        }

        // Ensure execution on main thread
        DispatchQueue.main.async {
            self.present(navVC, animated: true)
        }
    }

    // MARK: - Final Summary

    private func showFinalSummary() {
        // Go directly to PlacesConfirm page, validation happens there
        let confirmVC = PlacesConfirmViewController()
        confirmVC.locations = dataManager.locations
        confirmVC.isImportMode = self.isImportMode  // Pass import mode flag
        confirmVC.isRecoveryMode = self.isRecoveryMode  // Pass recovery mode flag
        navigationController?.pushViewController(confirmVC, animated: true)
    }

    /// Show alert for incomplete location
    private func showIncompleteLocationAlert(_ locationNumber: Int) {
        let alert = UIAlertController(
            title: Lang("places.alert.incomplete_title"),
            message: String(format: Lang("places.alert.incomplete_message"), locationNumber),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default))
        present(alert, animated: true)
    }

    #if DEBUG
    // MARK: - Test Data

    private func fillTestData() {
        dataManager.fillTestDataForCurrentLocation()
        let currentLoc = dataManager.getCurrentLocation()
        currentInputView?.updateFieldsWithTags(
            latitude: currentLoc.latitude,
            longitude: currentLoc.longitude,
            memory1Tags: currentLoc.memory1Tags,
            memory2Tags: currentLoc.memory2Tags
        )
    }
    #endif

}

// MARK: - Progress Dots View

class ProgressDotsView: UIView {

    var totalDots = 5 {
        didSet {
            setupDots()
        }
    }

    var currentDot = 0 {
        didSet {
            updateDots()
        }
    }

    private var dotViews: [UIView] = []
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .equalSpacing
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        setupDots()
    }

    private func setupDots() {
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        for _ in 0..<totalDots {
            let dot = UIView()
            dot.layer.cornerRadius = 5
            dot.backgroundColor = .lightGray
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

            stackView.addArrangedSubview(dot)
            dotViews.append(dot)
        }

        updateDots()
    }

    private func updateDots() {
        for (index, dot) in dotViews.enumerated() {
            if index == currentDot {
                dot.backgroundColor = Theme.Colors.elegantBlue
                dot.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            } else {
                dot.backgroundColor = .lightGray
                dot.transform = .identity
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PlacesInputViewController {
    /// Handle swipe gesture for linear navigation
    /// Linear navigation: Location 5→4→3→2→1→NameSalt
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only handle the interactive pop gesture
        guard gestureRecognizer == navigationController?.interactivePopGestureRecognizer else {
            return true
        }

        // In editing mode, allow normal pop
        if isEditingFromConfirm {
            return true
        }

        // If we can go to previous location, handle it ourselves
        if dataManager.canGoPrevious {
            previousLocation()
            return false // Prevent default pop behavior
        }

        // Already at first location, allow normal pop to NameSalt
        return true
    }
}
