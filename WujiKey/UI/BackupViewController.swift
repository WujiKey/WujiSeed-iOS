//
//  BackupViewController.swift
//  WujiKey
//
//  Encrypted backup display interface
//

import UIKit
import Photos

class BackupViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Data Model

    /// Seed phrase name
    var codeName: String = ""

    /// 24 seed phrase words
    var mnemonics: [String] = []

    /// 5 position codes
    var positionCodes: [Int] = []

    /// 5 keyMaterials (binary Data, for WujiReserve encryption)
    var keyMaterials: [Data] = []

    /// WujiName (for Argon2id salt)
    var wujiName: WujiName?

    /// Whether this is from normal generation flow (Confirm → Backup → Show24)
    /// If true: show "View Seed Phrase" button, auto-save to album
    /// If false: legacy behavior (from Show24 export)
    var isFromGeneration: Bool = false

    /// WujiReserve structured data
    private var reserveData: WujiReserveData?

    /// Whether data has been cleared (for showing "cleared" state)
    private var isCleared: Bool = false

    /// Whether returning to home is in progress (prevent duplicate triggers)
    private var isReturningToHome: Bool = false

    /// Whether auto-save has been triggered
    private var hasAutoSaved: Bool = false

    /// Whether to show no-backup recovery dialog after dismissing save result
    private var shouldShowNoBackupDialogOnDismiss: Bool = false

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Top "publicly storable" hint
    private let publicHintLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.largeTitle
        label.textColor = Theme.Colors.tagPublicText
        label.textAlignment = .center
        return label
    }()

    // QR code image
    private let qrImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.isUserInteractionEnabled = true
        return iv
    }()

    // Recovery hint container (vertical stack, left aligned)
    private let recoveryHintView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()

    // Recovery hint: prefix text (line 1)
    private let recoveryPrefixLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.small
        label.textColor = Theme.Colors.textMedium
        label.textAlignment = .left
        return label
    }()

    // Recovery hint: name row container (line 2)
    private let nameRowView = UIView()

    // Recovery hint: name
    private let nameInfoLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.small
        label.textColor = Theme.Colors.textMedium
        return label
    }()

    // Recovery hint: secret tag
    private let secretTagLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.font = Theme.Fonts.tinySemibold
        label.textColor = Theme.Colors.tagSecretText
        label.backgroundColor = Theme.Colors.tagSecretBackground
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        return label
    }()

    // Recovery hint: location row container (line 3)
    private let locationRowView = UIView()

    // Recovery hint: location notes
    private let locationInfoLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.small
        label.textColor = Theme.Colors.textMedium
        label.textAlignment = .left
        return label
    }()

    // Recovery hint: location secret tag
    private let locationSecretTagLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.font = Theme.Fonts.tinySemibold
        label.textColor = Theme.Colors.tagSecretText
        label.backgroundColor = Theme.Colors.tagSecretBackground
        label.layer.cornerRadius = 3
        label.layer.masksToBounds = true
        return label
    }()

    // Save image button
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.Fonts.bodySemibold
        button.backgroundColor = Theme.Colors.elegantBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        return button
    }()

    // No-backup recovery button (legacy mode only)
    private let geekRecoveryButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.Fonts.small
        button.setTitleColor(Theme.Colors.textMedium, for: .normal)
        return button
    }()

    // Auto-save success indicator
    private let autoSaveLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.captionMedium
        label.textColor = Theme.Colors.tagPublicText  // Green color
        label.textAlignment = .center
        label.numberOfLines = 0  // Support multi-line for long translations
        label.alpha = 0
        return label
    }()

    // Recovery info cards container
    private let recoveryCardsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    // Card 1: With backup recovery
    private let withBackupCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.93, green: 0.97, blue: 0.93, alpha: 1.0) // Light green
        view.layer.cornerRadius = 12
        return view
    }()

    private let withBackupTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0) // Dark green
        return label
    }()

    private let withBackupContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    // Card 2: Without backup recovery
    private let withoutBackupCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0) // Light orange
        view.layer.cornerRadius = 12
        return view
    }()

    private let withoutBackupTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(red: 0.8, green: 0.5, blue: 0.1, alpha: 1.0) // Dark orange
        return label
    }()

    private let withoutBackupContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    // Position code display
    private let positionCodeCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        view.layer.cornerRadius = 8
        return view
    }()

    private let positionCodeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let positionCodeValueLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 13.0, *) {
            label.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        } else {
            label.font = UIFont(name: "Menlo-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        }
        label.textColor = Theme.Colors.elegantBlue
        label.textAlignment = .center
        return label
    }()

    private let positionCodeHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    // View seed phrase button (for generation flow)
    private let viewSeedPhraseButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.Fonts.bodySemibold
        button.backgroundColor = Theme.Colors.elegantBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        return button
    }()

    // No-backup recovery button (for generation flow, shows popup when tapped)
    private let noBackupRecoveryButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0), for: .normal)  // Orange warning color
        return button
    }()

    // No-backup recovery info section (below viewSeedPhraseButton in generation flow)
    private let noBackupInfoCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 1.0) // Light orange
        view.layer.cornerRadius = 12
        return view
    }()

    private let noBackupTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor(red: 0.8, green: 0.5, blue: 0.1, alpha: 1.0) // Dark orange
        return label
    }()

    private let noBackupContentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let noBackupPositionCodeLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 13.0, *) {
            label.font = UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        } else {
            label.font = UIFont(name: "Menlo-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        }
        label.textColor = Theme.Colors.elegantBlue
        label.textAlignment = .center
        return label
    }()

    private let noBackupPositionHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    // Manual save button (shown when auto-save fails)
    private let manualSaveButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.Fonts.captionMedium
        button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        button.isHidden = true
        return button
    }()

    // Dynamic constraint for viewSeedPhraseButton top anchor
    private var viewSeedPhraseButtonTopConstraint: NSLayoutConstraint?

    // Loading container (card style with margins and rounded corners)
    private let loadingContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.isHidden = false
        return view
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .large)
        } else {
            indicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        indicator.color = Theme.Colors.elegantBlue
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.subtitleMedium
        label.textColor = Theme.Colors.textMedium
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = Theme.Colors.elegantBlue
        pv.trackTintColor = Theme.Colors.trackLight
        pv.progress = 0
        return pv
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.small
        label.textColor = Theme.Colors.textLight
        label.textAlignment = .center
        label.text = "0%"
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup "Clear" button in top right
        setupNavigationBar()

        setupUI()
        setupConstraints()
        updateLocalizedText()
        displayInfo()
        setupActions()

        // Start loading animation
        loadingIndicator.startAnimating()

        // Generate encrypted backup async (Argon2id is CPU intensive)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.generateBackupAsync()
        }
    }

    // MARK: - Localization

    private func updateLocalizedText() {
        title = Lang("backup.title")
        publicHintLabel.text = Lang("backup.hint.public_storage")
        recoveryPrefixLabel.text = Lang("backup.recovery_prefix")
        secretTagLabel.text = Lang("tag.secret")
        locationInfoLabel.text = Lang("backup.location_notes")
        locationSecretTagLabel.text = Lang("tag.secret")
        saveButton.setTitle(Lang("backup.button.save_image"), for: .normal)
        geekRecoveryButton.setTitle(Lang("backup.button.geek_recovery"), for: .normal)
        loadingLabel.text = Lang("backup.loading")

        // New generation flow UI
        autoSaveLabel.text = Lang("backup.auto_saved")
        manualSaveButton.setTitle(Lang("backup.button.save_manually"), for: .normal)
        withBackupTitleLabel.text = Lang("backup.recovery.with_backup.title")
        withBackupContentLabel.text = Lang("backup.recovery.with_backup.content")
        withoutBackupTitleLabel.text = Lang("backup.recovery.without_backup.title")
        withoutBackupContentLabel.text = Lang("backup.recovery.without_backup.content")
        positionCodeLabel.text = Lang("backup.position_code")
        viewSeedPhraseButton.setTitle(Lang("backup.button.view_mnemonic"), for: .normal)
        noBackupRecoveryButton.setTitle(Lang("backup.nobackup.button"), for: .normal)

        // Set position code value and hint
        let positionString = positionCodes.map { String($0) }.joined()
        positionCodeValueLabel.text = positionString

        // Generate random 3-digit number for phone disguise example (138 + 3 + 5 = 11 digits)
        let randomMiddle = String(format: "%03d", Int.random(in: 100...999))
        let examplePhone = Lang("backup.position_code.example")
            .replacingOccurrences(of: "{rand}", with: randomMiddle)
            .replacingOccurrences(of: "{code}", with: positionString)

        // Create attributed string with position code highlighted
        let hintText = Lang("backup.position_code.hint") + "\n" + examplePhone
        let attributedHint = NSMutableAttributedString(
            string: hintText,
            attributes: [
                .font: Theme.Fonts.small,
                .foregroundColor: Theme.MinimalTheme.textSecondary
            ]
        )
        if let codeRange = hintText.range(of: positionString) {
            let nsRange = NSRange(codeRange, in: hintText)
            attributedHint.addAttribute(.foregroundColor, value: Theme.Colors.elegantBlue, range: nsRange)
        }
        positionCodeHintLabel.attributedText = attributedHint

        // No-backup recovery info (generation flow)
        noBackupTitleLabel.text = Lang("backup.nobackup.title")
        noBackupContentLabel.text = Lang("backup.nobackup.content")
        noBackupPositionCodeLabel.text = Lang("backup.position_code") + ": " + positionString
        noBackupPositionHintLabel.attributedText = attributedHint
    }

    private func displayInfo() {
        // Set name in recovery hint
        let displayName = isCleared ? "***" : (codeName.isEmpty ? Lang("backup.geek.unnamed") : codeName)
        nameInfoLabel.text = Lang("common.name") + "[\(displayName)]"
    }

    // MARK: - Navigation Bar Setup

    private func setupNavigationBar() {
        // Only show "Clear" button in legacy flow (not from generation flow)
        // In generation flow, user will clear from Show24 page's "Done and Clear" button
        if !isFromGeneration {
            let clearButton = UIBarButtonItem(
                title: Lang("common.clear"),
                style: .plain,
                target: self,
                action: #selector(clearButtonTapped)
            )
            clearButton.tintColor = Theme.Colors.error  // Red indicates destructive action
            navigationItem.rightBarButtonItem = clearButton
        }

        // Use default back button, no customization
        // Back logic is handled by gestureRecognizerShouldBegin based on isCleared state
    }

    private func handleBackAction() {
        // Prevent duplicate triggers
        guard !isReturningToHome else { return }
        isReturningToHome = true

        if isCleared {
            // Cleared: force return to home
            navigationController?.popToRootViewController(animated: true)
        } else {
            // Normal: return to previous page
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func clearButtonTapped() {
        // Show confirmation dialog to prevent accidental operation
        let alert = UIAlertController(
            title: Lang("backup.alert.clear_title"),
            message: Lang("backup.alert.clear_message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))

        alert.addAction(UIAlertAction(title: Lang("backup.alert.confirm_clear"), style: .destructive) { [weak self] _ in
            self?.clearProgress()
        })

        present(alert, animated: true)
    }

    private func clearProgress() {
        // Clear session state
        SessionStateManager.shared.clearAll()

        #if DEBUG
        WujiLogger.success("User cleared all progress records")
        #endif

        // Mark as cleared state
        isCleared = true

        // Clear name, replace with *
        codeName = ""
        displayInfo()

        // Update back button and swipe behavior
        updateBackButton()
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        // Show success toast, stay on current page
        showToast(message: Lang("backup.toast.cleared"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false

        // Decide whether to intercept swipe based on isCleared state
        if isCleared {
            // Cleared: intercept swipe gesture
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = self
        } else {
            // Normal: use default swipe behavior
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }

        // Update back button based on isCleared state
        updateBackButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore swipe gesture delegate
        if !isReturningToHome {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only intercept swipe gesture when in cleared state
        if isCleared && gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            // Intercept swipe, redirect to home
            DispatchQueue.main.async { [weak self] in
                self?.handleBackAction()
            }
            return false
        }
        return true
    }

    // Update back button
    private func updateBackButton() {
        if isCleared {
            // Cleared: customize back button to "Home"
            let backButton = UIBarButtonItem(
                title: Lang("common.home"),
                style: .plain,
                target: self,
                action: #selector(backButtonTapped)
            )
            backButton.tintColor = Theme.Colors.elegantBlue
            navigationItem.leftBarButtonItem = backButton
            navigationItem.hidesBackButton = true
        } else {
            // Normal: use default back button
            navigationItem.leftBarButtonItem = nil
            navigationItem.hidesBackButton = false
        }
    }

    @objc private func backButtonTapped() {
        // Back button tapped
        handleBackAction()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Top "publicly storable" hint (initially hidden, shown after QR code generated)
        contentView.addSubview(publicHintLabel)
        publicHintLabel.alpha = 0

        // QR code image (keep displayed to maintain layout)
        contentView.addSubview(qrImageView)

        // Auto-save label (below QR code)
        contentView.addSubview(autoSaveLabel)
        contentView.addSubview(manualSaveButton)

        // Loading view (overlays QR code area, initially visible)
        contentView.addSubview(loadingContainerView)
        loadingContainerView.addSubview(loadingIndicator)
        loadingContainerView.addSubview(loadingLabel)
        loadingContainerView.addSubview(progressView)
        loadingContainerView.addSubview(progressLabel)

        if isFromGeneration {
            // New generation flow UI
            // View seed phrase button (at top of content below QR)
            contentView.addSubview(viewSeedPhraseButton)
            viewSeedPhraseButton.isEnabled = false
            viewSeedPhraseButton.backgroundColor = Theme.Colors.disabledButtonBackground

            // No-backup recovery button (shows popup when tapped)
            contentView.addSubview(noBackupRecoveryButton)
        } else {
            // Legacy flow UI
            // Recovery hint (3 lines: prefix, name+tag, location+tag)
            contentView.addSubview(recoveryHintView)
            recoveryHintView.addArrangedSubview(recoveryPrefixLabel)

            // Name row (name label + secret tag)
            nameRowView.addSubview(nameInfoLabel)
            nameRowView.addSubview(secretTagLabel)
            recoveryHintView.addArrangedSubview(nameRowView)

            // Location row (location label + secret tag)
            locationRowView.addSubview(locationInfoLabel)
            locationRowView.addSubview(locationSecretTagLabel)
            recoveryHintView.addArrangedSubview(locationRowView)

            // Save button (initially disabled)
            contentView.addSubview(saveButton)
            saveButton.isEnabled = false
            saveButton.backgroundColor = Theme.Colors.disabledButtonBackground

            // Geek recovery mode button
            contentView.addSubview(geekRecoveryButton)
        }
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        publicHintLabel.translatesAutoresizingMaskIntoConstraints = false
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        autoSaveLabel.translatesAutoresizingMaskIntoConstraints = false
        manualSaveButton.translatesAutoresizingMaskIntoConstraints = false
        loadingContainerView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false

        // Common constraints
        NSLayoutConstraint.activate([
            // ScrollView - fills entire screen
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Top "publicly storable" hint
            publicHintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            publicHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            publicHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            // QR Image (composite image aspect ratio ~1.25)
            qrImageView.topAnchor.constraint(equalTo: publicHintLabel.bottomAnchor, constant: 4),
            qrImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            qrImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            qrImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            qrImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 1.25),

            // Auto-save label
            autoSaveLabel.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 8),
            autoSaveLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Manual save button (below auto-save label, hidden by default)
            manualSaveButton.topAnchor.constraint(equalTo: autoSaveLabel.bottomAnchor, constant: 4),
            manualSaveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Loading Container (overlaps QR Image completely, with side margins)
            loadingContainerView.topAnchor.constraint(equalTo: qrImageView.topAnchor),
            loadingContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            loadingContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            loadingContainerView.bottomAnchor.constraint(equalTo: qrImageView.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingContainerView.centerYAnchor, constant: -40),

            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),

            progressView.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: loadingContainerView.leadingAnchor, constant: 60),
            progressView.trailingAnchor.constraint(equalTo: loadingContainerView.trailingAnchor, constant: -60),
            progressView.heightAnchor.constraint(equalToConstant: 6),

            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: loadingContainerView.centerXAnchor),
        ])

        if isFromGeneration {
            setupGenerationFlowConstraints()
        } else {
            setupLegacyFlowConstraints()
        }
    }

    private func setupGenerationFlowConstraints() {
        // Generation flow UI: view seed phrase button, then no-backup recovery button below
        viewSeedPhraseButton.translatesAutoresizingMaskIntoConstraints = false
        noBackupRecoveryButton.translatesAutoresizingMaskIntoConstraints = false

        // Initial constraint: during loading, anchor to qrImageView
        viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 16)
        viewSeedPhraseButtonTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            // View seed phrase button horizontal and height constraints
            viewSeedPhraseButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            viewSeedPhraseButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            viewSeedPhraseButton.heightAnchor.constraint(equalToConstant: 50),

            // No-backup recovery button (small text button, centered below viewSeedPhraseButton)
            noBackupRecoveryButton.topAnchor.constraint(equalTo: viewSeedPhraseButton.bottomAnchor, constant: 12),
            noBackupRecoveryButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            noBackupRecoveryButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])

        // Initially hide no-backup recovery button until loading completes
        noBackupRecoveryButton.alpha = 0
    }

    /// Update viewSeedPhraseButton top constraint based on current UI state
    private func updateViewSeedPhraseButtonConstraint(animated: Bool = true) {
        guard isFromGeneration else { return }

        // Deactivate existing constraint
        viewSeedPhraseButtonTopConstraint?.isActive = false

        // Determine anchor based on visibility
        if !manualSaveButton.isHidden {
            // Save failed, manual save button visible - anchor to manualSaveButton
            viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: manualSaveButton.bottomAnchor, constant: 16)
        } else if !loadingContainerView.isHidden {
            // Loading state - anchor to qrImageView
            viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: qrImageView.bottomAnchor, constant: 16)
        } else {
            // Backup generated, auto-save succeeded - anchor to autoSaveLabel
            viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: autoSaveLabel.bottomAnchor, constant: 16)
        }

        viewSeedPhraseButtonTopConstraint?.isActive = true

        // Apply layout update
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.contentView.layoutIfNeeded()
            }
        } else {
            contentView.layoutIfNeeded()
        }
    }

    private func setupLegacyFlowConstraints() {
        recoveryHintView.translatesAutoresizingMaskIntoConstraints = false
        recoveryPrefixLabel.translatesAutoresizingMaskIntoConstraints = false
        nameRowView.translatesAutoresizingMaskIntoConstraints = false
        nameInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        secretTagLabel.translatesAutoresizingMaskIntoConstraints = false
        locationRowView.translatesAutoresizingMaskIntoConstraints = false
        locationInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        locationSecretTagLabel.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        geekRecoveryButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Recovery hint container (3 lines, right after QR code)
            recoveryHintView.topAnchor.constraint(equalTo: autoSaveLabel.bottomAnchor, constant: 16),
            recoveryHintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            // Name row internal layout (with indent)
            nameInfoLabel.leadingAnchor.constraint(equalTo: nameRowView.leadingAnchor, constant: 16),
            nameInfoLabel.centerYAnchor.constraint(equalTo: nameRowView.centerYAnchor),

            secretTagLabel.leadingAnchor.constraint(equalTo: nameInfoLabel.trailingAnchor, constant: 4),
            secretTagLabel.trailingAnchor.constraint(equalTo: nameRowView.trailingAnchor),
            secretTagLabel.centerYAnchor.constraint(equalTo: nameRowView.centerYAnchor),

            nameRowView.topAnchor.constraint(equalTo: nameInfoLabel.topAnchor),
            nameRowView.bottomAnchor.constraint(equalTo: nameInfoLabel.bottomAnchor),

            // Location row internal layout (with indent)
            locationInfoLabel.leadingAnchor.constraint(equalTo: locationRowView.leadingAnchor, constant: 16),
            locationInfoLabel.centerYAnchor.constraint(equalTo: locationRowView.centerYAnchor),

            locationSecretTagLabel.leadingAnchor.constraint(equalTo: locationInfoLabel.trailingAnchor, constant: 4),
            locationSecretTagLabel.trailingAnchor.constraint(equalTo: locationRowView.trailingAnchor),
            locationSecretTagLabel.centerYAnchor.constraint(equalTo: locationRowView.centerYAnchor),

            locationRowView.topAnchor.constraint(equalTo: locationInfoLabel.topAnchor),
            locationRowView.bottomAnchor.constraint(equalTo: locationInfoLabel.bottomAnchor),

            // Save Button (below recovery hint)
            saveButton.topAnchor.constraint(equalTo: recoveryHintView.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 48),

            // No-backup recovery button (small text button, centered)
            geekRecoveryButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            geekRecoveryButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            geekRecoveryButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        geekRecoveryButton.addTarget(self, action: #selector(geekRecoveryTapped), for: .touchUpInside)
        viewSeedPhraseButton.addTarget(self, action: #selector(viewSeedPhraseTapped), for: .touchUpInside)
        manualSaveButton.addTarget(self, action: #selector(manualSaveTapped), for: .touchUpInside)
        noBackupRecoveryButton.addTarget(self, action: #selector(noBackupRecoveryTapped), for: .touchUpInside)

        // Long press on QR image to save
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(qrImageLongPressed(_:)))
        longPressGesture.minimumPressDuration = 0.5
        qrImageView.addGestureRecognizer(longPressGesture)
    }

    @objc private func qrImageLongPressed(_ gesture: UILongPressGestureRecognizer) {
        // Only trigger on began state to avoid multiple calls
        guard gesture.state == .began else { return }

        // Same logic as manual save button
        guard let image = qrImageView.image else {
            showToast(message: Lang("backup.toast.no_image"))
            return
        }

        checkPhotoLibraryPermissionAndSave(image: image)
    }

    @objc private func geekRecoveryTapped() {
        let positionString = positionCodes.map { String($0) }.joined(separator: "")
        let displayName = isCleared ? "***" : (codeName.isEmpty ? Lang("backup.geek.unnamed") : codeName)

        // Create custom dialog
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = Theme.Colors.overlayDark
        overlayView.tag = 9999

        let dialogView = UIView()
        dialogView.backgroundColor = .white
        dialogView.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        dialogView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = Lang("backup.geek.title")
        titleLabel.font = Theme.Fonts.title
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Description
        let descLabel = UILabel()
        descLabel.text = Lang("backup.geek.description")
        descLabel.font = Theme.Fonts.caption
        descLabel.textColor = Theme.Colors.textMedium
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        // Name row
        let nameRow = createInfoRow(label: Lang("common.name") + ": \(displayName)", tagText: Lang("tag.secret"), isSecret: true)

        // Position code row
        let positionRow = createInfoRow(label: Lang("common.position_code") + ": \(positionString)", tagText: Lang("tag.public"), isSecret: false)

        // Location rows
        let locationRow = createInfoRow(label: Lang("backup.geek.locations"), tagText: Lang("tag.secret"), isSecret: true)

        // OK button
        let okButton = UIButton(type: .system)
        okButton.setTitle(Lang("common.got_it"), for: .normal)
        okButton.titleLabel?.font = Theme.Fonts.titleMedium
        okButton.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.addTarget(self, action: #selector(dismissGeekDialog), for: .touchUpInside)

        // Separator line
        let separator = UIView()
        separator.backgroundColor = Theme.Colors.separatorLight
        separator.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        dialogView.addSubview(titleLabel)
        dialogView.addSubview(descLabel)
        dialogView.addSubview(nameRow)
        dialogView.addSubview(positionRow)
        dialogView.addSubview(locationRow)
        dialogView.addSubview(separator)
        dialogView.addSubview(okButton)

        overlayView.addSubview(dialogView)
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            dialogView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            dialogView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            dialogView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 40),
            dialogView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -40),

            titleLabel.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor, constant: -16),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor, constant: -16),

            nameRow.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            nameRow.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            nameRow.trailingAnchor.constraint(lessThanOrEqualTo: dialogView.trailingAnchor, constant: -16),

            positionRow.topAnchor.constraint(equalTo: nameRow.bottomAnchor, constant: 8),
            positionRow.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            positionRow.trailingAnchor.constraint(lessThanOrEqualTo: dialogView.trailingAnchor, constant: -16),

            locationRow.topAnchor.constraint(equalTo: positionRow.bottomAnchor, constant: 8),
            locationRow.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            locationRow.trailingAnchor.constraint(lessThanOrEqualTo: dialogView.trailingAnchor, constant: -16),

            separator.topAnchor.constraint(equalTo: locationRow.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            okButton.topAnchor.constraint(equalTo: separator.bottomAnchor),
            okButton.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            okButton.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            okButton.heightAnchor.constraint(equalToConstant: 44),
            okButton.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor),
        ])

        // Animate display
        overlayView.alpha = 0
        dialogView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: 0.2) {
            overlayView.alpha = 1
            dialogView.transform = .identity
        }
    }

    private func createInfoRow(label: String, tagText: String, isSecret: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.text = label
        textLabel.font = Theme.Fonts.caption
        textLabel.textColor = Theme.Colors.textDark
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        let tag = PaddedLabel()
        tag.text = tagText
        tag.font = Theme.Fonts.tinySemibold
        tag.textColor = isSecret ? Theme.Colors.tagSecretText : Theme.Colors.tagPublicText
        tag.backgroundColor = isSecret ? Theme.Colors.tagSecretBackground : Theme.Colors.tagPublicBackground
        tag.layer.cornerRadius = 3
        tag.layer.masksToBounds = true
        tag.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(textLabel)
        row.addSubview(tag)

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            textLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            tag.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 6),
            tag.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            tag.trailingAnchor.constraint(equalTo: row.trailingAnchor),

            row.topAnchor.constraint(equalTo: textLabel.topAnchor),
            row.bottomAnchor.constraint(equalTo: textLabel.bottomAnchor),
        ])

        return row
    }

    @objc private func dismissGeekDialog() {
        if let overlayView = view.viewWithTag(9999) {
            UIView.animate(withDuration: 0.15, animations: {
                overlayView.alpha = 0
            }) { _ in
                overlayView.removeFromSuperview()
            }
        }
    }

    @objc private func noBackupRecoveryTapped() {
        showNoBackupRecoveryDialog(saveFailed: false)
    }

    private func showNoBackupRecoveryDialog(saveFailed: Bool) {
        let positionString = positionCodes.map { String($0) }.joined(separator: "")
        let displayName = isCleared ? "***" : (codeName.isEmpty ? Lang("backup.geek.unnamed") : codeName)

        // Generate random 3-digit number for phone disguise example
        let randomMiddle = String(format: "%03d", Int.random(in: 100...999))
        let examplePhone = Lang("backup.position_code.example")
            .replacingOccurrences(of: "{rand}", with: randomMiddle)
            .replacingOccurrences(of: "{code}", with: positionString)

        // Create custom dialog
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = Theme.Colors.overlayDark
        overlayView.tag = 9998

        let dialogView = UIView()
        dialogView.backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0)  // Warm light orange
        dialogView.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        dialogView.translatesAutoresizingMaskIntoConstraints = false

        // Title - use different text based on save status
        let titleLabel = UILabel()
        titleLabel.text = saveFailed ? Lang("backup.nobackup.title_failed") : Lang("backup.nobackup.title")
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.8, green: 0.5, blue: 0.1, alpha: 1.0)  // Dark orange
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Recovery needs label (content at beginning)
        let recoveryNeedsLabel = UILabel()
        recoveryNeedsLabel.text = Lang("backup.nobackup.recovery_needs")
        recoveryNeedsLabel.font = Theme.Fonts.caption
        recoveryNeedsLabel.textColor = Theme.Colors.textDark
        recoveryNeedsLabel.translatesAutoresizingMaskIntoConstraints = false

        // Identifier row
        let nameRow = createInfoRow(label: Lang("backup.nobackup.identifier") + displayName, tagText: Lang("tag.secret"), isSecret: true)

        // Location row
        let locationRow = createInfoRow(label: Lang("backup.geek.locations"), tagText: Lang("tag.secret"), isSecret: true)

        // Position code row (styled like createInfoRow with attributed text)
        let positionCodeRow = UIView()
        positionCodeRow.translatesAutoresizingMaskIntoConstraints = false

        let positionCodeTextLabel = UILabel()
        // Create attributed string: "方位码：" normal + position code bold theme color
        let labelText = Lang("backup.position_code") + ": "
        let attributedPositionText = NSMutableAttributedString(
            string: labelText,
            attributes: [
                .font: Theme.Fonts.caption,
                .foregroundColor: Theme.Colors.textDark
            ]
        )
        let boldPositionCode = NSAttributedString(
            string: positionString,
            attributes: [
                .font: UIFont.systemFont(ofSize: Theme.Fonts.caption.pointSize, weight: .bold),
                .foregroundColor: Theme.Colors.elegantBlue
            ]
        )
        attributedPositionText.append(boldPositionCode)
        positionCodeTextLabel.attributedText = attributedPositionText
        positionCodeTextLabel.translatesAutoresizingMaskIntoConstraints = false

        let positionCodeTag = PaddedLabel()
        positionCodeTag.text = Lang("tag.public")
        positionCodeTag.font = Theme.Fonts.tinySemibold
        positionCodeTag.textColor = Theme.Colors.tagPublicText
        positionCodeTag.backgroundColor = Theme.Colors.tagPublicBackground
        positionCodeTag.layer.cornerRadius = 3
        positionCodeTag.layer.masksToBounds = true
        positionCodeTag.translatesAutoresizingMaskIntoConstraints = false

        positionCodeRow.addSubview(positionCodeTextLabel)
        positionCodeRow.addSubview(positionCodeTag)

        NSLayoutConstraint.activate([
            positionCodeTextLabel.leadingAnchor.constraint(equalTo: positionCodeRow.leadingAnchor),
            positionCodeTextLabel.centerYAnchor.constraint(equalTo: positionCodeRow.centerYAnchor),

            positionCodeTag.leadingAnchor.constraint(equalTo: positionCodeTextLabel.trailingAnchor, constant: 6),
            positionCodeTag.centerYAnchor.constraint(equalTo: positionCodeRow.centerYAnchor),
            positionCodeTag.trailingAnchor.constraint(equalTo: positionCodeRow.trailingAnchor),

            positionCodeRow.topAnchor.constraint(equalTo: positionCodeTextLabel.topAnchor),
            positionCodeRow.bottomAnchor.constraint(equalTo: positionCodeTextLabel.bottomAnchor),
        ])

        // Position code hint (indented)
        let positionHintLabel = UILabel()
        // Create attributed string with position code highlighted
        let hintText = Lang("backup.position_code.hint") + "\n" + examplePhone
        let attributedHint = NSMutableAttributedString(
            string: hintText,
            attributes: [
                .font: Theme.Fonts.small,
                .foregroundColor: Theme.MinimalTheme.textSecondary
            ]
        )
        // Highlight the position code part in the example
        if let codeRange = hintText.range(of: positionString) {
            let nsRange = NSRange(codeRange, in: hintText)
            attributedHint.addAttribute(.foregroundColor, value: Theme.Colors.elegantBlue, range: nsRange)
        }
        positionHintLabel.attributedText = attributedHint
        positionHintLabel.textAlignment = .left
        positionHintLabel.numberOfLines = 0
        positionHintLabel.translatesAutoresizingMaskIntoConstraints = false

        // OK button
        let okButton = UIButton(type: .system)
        okButton.setTitle(Lang("backup.position_code.noted"), for: .normal)
        okButton.titleLabel?.font = Theme.Fonts.titleMedium
        okButton.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.addTarget(self, action: #selector(dismissNoBackupDialog), for: .touchUpInside)

        // Separator line
        let separator = UIView()
        separator.backgroundColor = Theme.Colors.separatorLight
        separator.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        dialogView.addSubview(titleLabel)
        dialogView.addSubview(recoveryNeedsLabel)
        dialogView.addSubview(nameRow)
        dialogView.addSubview(locationRow)
        dialogView.addSubview(positionCodeRow)
        dialogView.addSubview(positionHintLabel)
        dialogView.addSubview(separator)
        dialogView.addSubview(okButton)

        overlayView.addSubview(dialogView)
        view.addSubview(overlayView)

        NSLayoutConstraint.activate([
            dialogView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            dialogView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            dialogView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 32),
            dialogView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -32),

            titleLabel.topAnchor.constraint(equalTo: dialogView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor, constant: -16),

            recoveryNeedsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            recoveryNeedsLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),

            nameRow.topAnchor.constraint(equalTo: recoveryNeedsLabel.bottomAnchor, constant: 8),
            nameRow.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            nameRow.trailingAnchor.constraint(lessThanOrEqualTo: dialogView.trailingAnchor, constant: -16),

            locationRow.topAnchor.constraint(equalTo: nameRow.bottomAnchor, constant: 8),
            locationRow.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            locationRow.trailingAnchor.constraint(lessThanOrEqualTo: dialogView.trailingAnchor, constant: -16),

            positionCodeRow.topAnchor.constraint(equalTo: locationRow.bottomAnchor, constant: 8),
            positionCodeRow.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 16),
            positionCodeRow.trailingAnchor.constraint(lessThanOrEqualTo: dialogView.trailingAnchor, constant: -16),

            positionHintLabel.topAnchor.constraint(equalTo: positionCodeRow.bottomAnchor, constant: 8),
            positionHintLabel.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor, constant: 28),
            positionHintLabel.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor, constant: -16),

            separator.topAnchor.constraint(equalTo: positionHintLabel.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            okButton.topAnchor.constraint(equalTo: separator.bottomAnchor),
            okButton.leadingAnchor.constraint(equalTo: dialogView.leadingAnchor),
            okButton.trailingAnchor.constraint(equalTo: dialogView.trailingAnchor),
            okButton.heightAnchor.constraint(equalToConstant: 50),
            okButton.bottomAnchor.constraint(equalTo: dialogView.bottomAnchor),
        ])
    }

    @objc private func dismissNoBackupDialog() {
        if let overlayView = view.viewWithTag(9998) {
            UIView.animate(withDuration: 0.15, animations: {
                overlayView.alpha = 0
            }) { _ in
                overlayView.removeFromSuperview()
            }
        }
    }

    // MARK: - Backup Generation

    /// Async generate encrypted backup (runs on background thread)
    private func generateBackupAsync() {
        // Validate parameters
        guard mnemonics.count == 24 else {
            DispatchQueue.main.async { [weak self] in
                self?.onBackupError(message: Lang("backup.error.mnemonic_count"))
            }
            return
        }

        guard positionCodes.count == 5 else {
            DispatchQueue.main.async { [weak self] in
                self?.onBackupError(message: Lang("backup.error.position_count"))
            }
            return
        }

        guard keyMaterials.count == 5 else {
            DispatchQueue.main.async { [weak self] in
                self?.onBackupError(message: Lang("backup.error.keymaterial_count"))
            }
            return
        }

        guard let wujiName = wujiName else {
            DispatchQueue.main.async { [weak self] in
                self?.onBackupError(message: Lang("backup.error.name_missing"))
            }
            return
        }

        // Encrypt using WujiReserve (CPU intensive operation)
        let result = WujiReserve.encrypt(
            mnemonics: mnemonics,
            keyMaterials: keyMaterials,
            positionCodes: positionCodes,
            nameSalt: wujiName.salt,
            progressCallback: { [weak self] progress in
                // Update progress UI on main thread
                DispatchQueue.main.async {
                    self?.updateProgress(progress)
                }
            }
        )

        switch result {
        case .success(let output):
            // Generate QR code image (also on background thread)
            #if DEBUG
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            WujiLogger.info("WUJI encrypted backup size: \(output.data.count) bytes")
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            if let qrImage = self.generateQRCodeImage(from: output.data) {
                // Composite QR code with logo
                let compositeImage = self.createCompositeImage(qrImage: qrImage)

                // Switch to main thread to update UI
                DispatchQueue.main.async { [weak self] in
                    self?.onBackupSuccess(output: output, compositeImage: compositeImage)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.onBackupError(message: Lang("backup.error.qr_failed"))
                }
            }

        case .failure(let error):
            DispatchQueue.main.async { [weak self] in
                self?.onBackupError(message: Lang("backup.error.encrypt_failed") + ": \(error.localizedDescription)")
            }
        }
    }

    /// Encryption success callback (main thread)
    private func onBackupSuccess(output: WujiReserve.EncryptedOutput, compositeImage: UIImage) {
        reserveData = output.reserveData

        // Save to SessionStateManager
        SessionStateManager.shared.reserveData = output.reserveData

        // Hide loading view
        loadingIndicator.stopAnimating()
        loadingContainerView.isHidden = true

        // Display QR code (fixed height, scaleAspectFit adapts)
        qrImageView.image = compositeImage

        // Show public hint label with fade-in animation
        UIView.animate(withDuration: 0.3) {
            self.publicHintLabel.alpha = 1
        }

        if isFromGeneration {
            // Auto-save to album in generation flow (with permission check)
            if !hasAutoSaved {
                hasAutoSaved = true
                autoSaveWithPermissionCheck(image: compositeImage)
            }

            // Enable view seed phrase button
            viewSeedPhraseButton.isEnabled = true
            viewSeedPhraseButton.backgroundColor = Theme.Colors.elegantBlue

            // Show no-backup recovery button with animation
            UIView.animate(withDuration: 0.3) {
                self.noBackupRecoveryButton.alpha = 1
            }
        } else {
            // Enable save button (legacy flow)
            saveButton.isEnabled = true
            saveButton.backgroundColor = Theme.Colors.elegantBlue
        }

        #if DEBUG
        WujiLogger.success("Successfully generated WujiReserve backup and QR code")
        #endif
    }

    @objc private func autoSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let success = (error == nil)

        #if DEBUG
        if let error = error {
            WujiLogger.error("Auto-save failed: \(error.localizedDescription)")
        } else {
            WujiLogger.success("Auto-saved to album")
        }
        #endif

        // Update status label
        if success {
            autoSaveLabel.text = Lang("backup.auto_saved")
            autoSaveLabel.textColor = Theme.Colors.tagPublicText
            manualSaveButton.isHidden = true
        } else {
            autoSaveLabel.text = Lang("backup.auto_save_failed")
            autoSaveLabel.textColor = .systemOrange
            manualSaveButton.isHidden = false
        }

        // Update constraint first (without animation), then animate both alpha and layout together
        viewSeedPhraseButtonTopConstraint?.isActive = false
        if !manualSaveButton.isHidden {
            viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: manualSaveButton.bottomAnchor, constant: 16)
        } else {
            viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: autoSaveLabel.bottomAnchor, constant: 16)
        }
        viewSeedPhraseButtonTopConstraint?.isActive = true

        // Animate both alpha and layout together
        UIView.animate(withDuration: 0.3) {
            self.autoSaveLabel.alpha = 1
            self.contentView.layoutIfNeeded()
        }

        // Always show recovery info alert (success or failure)
        showRecoveryInfoAlert(saveSuccess: success)
    }

    private func autoSaveWithPermissionCheck(image: UIImage) {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            // Permission granted, save directly
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(autoSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)

        case .notDetermined:
            // Request permission
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited {
                            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.autoSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
                        } else {
                            self?.handleAutoSavePermissionDenied()
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized {
                            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.autoSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
                        } else {
                            self?.handleAutoSavePermissionDenied()
                        }
                    }
                }
            }

        case .denied, .restricted:
            // Permission denied
            handleAutoSavePermissionDenied()

        @unknown default:
            handleAutoSavePermissionDenied()
        }
    }

    private func handleAutoSavePermissionDenied() {
        // Show failed status and manual save button
        autoSaveLabel.text = Lang("backup.auto_save_failed")
        autoSaveLabel.textColor = .systemOrange
        manualSaveButton.isHidden = false

        // Update constraint first, then animate both alpha and layout together
        viewSeedPhraseButtonTopConstraint?.isActive = false
        viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: manualSaveButton.bottomAnchor, constant: 16)
        viewSeedPhraseButtonTopConstraint?.isActive = true

        UIView.animate(withDuration: 0.3) {
            self.autoSaveLabel.alpha = 1
            self.contentView.layoutIfNeeded()
        }

        // Show permission denied alert with recovery info
        showPermissionDeniedAlertWithRecoveryInfo()
    }

    private func showPermissionDeniedAlertWithRecoveryInfo() {
        let alert = UIAlertController(
            title: Lang("backup.permission.title"),
            message: Lang("backup.permission.message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Lang("backup.permission.settings"), style: .default) { [weak self] _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            // Show no-backup recovery dialog after opening settings
            self?.showNoBackupRecoveryDialog(saveFailed: true)
        })

        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel) { [weak self] _ in
            // Show no-backup recovery dialog after cancel
            self?.showNoBackupRecoveryDialog(saveFailed: true)
        })

        present(alert, animated: true)
    }

    @objc private func manualSaveTapped() {
        guard let image = qrImageView.image else {
            showToast(message: Lang("backup.toast.no_image"))
            return
        }

        // Check photo library permission before saving
        checkPhotoLibraryPermissionAndSave(image: image)
    }

    private func checkPhotoLibraryPermissionAndSave(image: UIImage) {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            // Permission granted, save directly
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(manualSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)

        case .notDetermined:
            // Request permission
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited {
                            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.manualSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
                        } else {
                            self?.showPermissionDeniedAlert()
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized {
                            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.manualSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
                        } else {
                            self?.showPermissionDeniedAlert()
                        }
                    }
                }
            }

        case .denied, .restricted:
            // Permission denied, guide user to Settings
            showPermissionDeniedAlert()

        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: Lang("backup.permission.title"),
            message: Lang("backup.permission.message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: Lang("backup.permission.settings"), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })

        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))

        present(alert, animated: true)
    }

    @objc private func manualSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let success = (error == nil)

        #if DEBUG
        if let error = error {
            WujiLogger.error("Manual save failed: \(error.localizedDescription)")
        }
        #endif
        if error == nil {
            // Update UI to show success
            autoSaveLabel.text = Lang("backup.auto_saved")
            autoSaveLabel.textColor = Theme.Colors.tagPublicText
            manualSaveButton.isHidden = true
            #if DEBUG
            WujiLogger.success("Manually saved to album")
            #endif

            // Update button constraint since manualSaveButton is now hidden
            viewSeedPhraseButtonTopConstraint?.isActive = false
            viewSeedPhraseButtonTopConstraint = viewSeedPhraseButton.topAnchor.constraint(equalTo: autoSaveLabel.bottomAnchor, constant: 16)
            viewSeedPhraseButtonTopConstraint?.isActive = true

            UIView.animate(withDuration: 0.3) {
                self.contentView.layoutIfNeeded()
            }
        }

        // Always show recovery info alert (success or failure)
        showRecoveryInfoAlert(saveSuccess: success)
    }

    /// Update progress (main thread)
    private func updateProgress(_ progress: Float) {
        progressView.setProgress(progress, animated: true)
        progressLabel.text = "\(Int(progress * 100))%"
    }

    /// Encryption failure callback (main thread)
    private func onBackupError(message: String) {
        loadingIndicator.stopAnimating()
        loadingLabel.text = Lang("backup.loading_failed")
        loadingLabel.textColor = .systemRed

        showAlert(title: Lang("common.error"), message: message)
    }

    /// Generate QR code image from binary data
    private func generateQRCodeImage(from data: Data) -> UIImage? {
        #if DEBUG
        WujiLogger.info("Starting QR code generation (binary mode)")
        WujiLogger.info("Data size: \(data.count) bytes")
        #endif

        // Use Core Image to generate QR code
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            #if DEBUG
            WujiLogger.error("CIQRCodeGenerator not available")
            #endif
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")

        // QR code capacity reference (binary/byte mode):
        // H level (30% error correction): ~1852 bytes
        // Q level (25% error correction): ~2132 bytes
        // M level (15% error correction): ~2331 bytes
        // L level (7% error correction): ~2953 bytes
        // 766 bytes can use H level error correction

        // Use H level error correction (30% tolerance, 766 bytes is well under 1852 bytes limit)
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
            #if DEBUG
            WujiLogger.error("QR code generation failed")
            WujiLogger.error("   Data size: \(data.count) bytes")
            #endif
            return nil
        }

        #if DEBUG
        WujiLogger.success("QR code generated (H level, 30% error tolerance)")
        #endif

        // Scale up image (QR code default is very small)
        let scale = 10.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledCIImage = ciImage.transformed(by: transform)

        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            #if DEBUG
            WujiLogger.error("CIImage to CGImage conversion failed")
            #endif
            return nil
        }

        #if DEBUG
        WujiLogger.success("QR code image generated successfully")
        #endif

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Actions

    @objc private func viewSeedPhraseTapped() {
        // Set empty back button title for next page
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Navigate to Show24ViewController
        let show24VC = Show24ViewController()
        show24VC.mnemonics = mnemonics
        show24VC.isFromBackupFlow = true  // Flag to indicate coming from backup flow

        navigationController?.pushViewController(show24VC, animated: true)

        #if DEBUG
        WujiLogger.info("Navigating to Show24 from backup flow")
        #endif
    }

    @objc private func saveTapped() {
        guard let image = qrImageView.image else {
            showToast(message: Lang("backup.toast.no_image"))
            return
        }

        // Save to photo album (already composited image)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    /// Create composite image with logo (vertical logo on each side, rotated 90 degrees)
    private func createCompositeImage(qrImage: UIImage) -> UIImage {
        guard let logo = UIImage(named: "WUJI") else {
            return qrImage
        }

        // Calculate dimensions
        let qrSize = qrImage.size
        let logoOriginalWidth = logo.size.width
        let logoOriginalHeight = logo.size.height

        // Rotated logo dimensions (width/height swapped), scaled up
        let logoDisplayHeight: CGFloat = 480
        let logoDisplayWidth: CGFloat = logoOriginalHeight / logoOriginalWidth * logoDisplayHeight
        let sideSpacing: CGFloat = -20

        // Total canvas size (no margins)
        let canvasWidth = qrSize.width + (logoDisplayWidth + sideSpacing) * 2
        let canvasHeight = qrSize.height

        // Start drawing
        UIGraphicsBeginImageContextWithOptions(CGSize(width: canvasWidth, height: canvasHeight), true, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return qrImage
        }

        // White background
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

        // Calculate QR code position (centered)
        let qrX = (canvasWidth - qrSize.width) / 2
        let qrY: CGFloat = 0

        // Draw QR code
        qrImage.draw(in: CGRect(x: qrX, y: qrY, width: qrSize.width, height: qrSize.height))

        // Left logo (counter-clockwise 90 degrees)
        let leftLogoCenterX = logoDisplayWidth / 2
        let leftLogoCenterY = canvasHeight / 2

        context.saveGState()
        context.translateBy(x: leftLogoCenterX, y: leftLogoCenterY)
        context.rotate(by: -.pi / 2)  // Counter-clockwise 90 degrees
        logo.draw(in: CGRect(x: -logoDisplayHeight / 2, y: -logoDisplayWidth / 2, width: logoDisplayHeight, height: logoDisplayWidth))
        context.restoreGState()

        // Right logo (clockwise 90 degrees)
        let rightLogoCenterX = canvasWidth - logoDisplayWidth / 2
        let rightLogoCenterY = canvasHeight / 2

        context.saveGState()
        context.translateBy(x: rightLogoCenterX, y: rightLogoCenterY)
        context.rotate(by: .pi / 2)  // Clockwise 90 degrees
        logo.draw(in: CGRect(x: -logoDisplayHeight / 2, y: -logoDisplayWidth / 2, width: logoDisplayHeight, height: logoDisplayWidth))
        context.restoreGState()

        let compositeImage = UIGraphicsGetImageFromCurrentImageContext() ?? qrImage
        UIGraphicsEndImageContext()

        return compositeImage
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: Lang("backup.alert.save_failed"), message: error.localizedDescription)
        } else {
            showToast(message: Lang("backup.toast.saved"))
            #if DEBUG
            WujiLogger.success("Saved to album")
            #endif
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default))
        present(alert, animated: true)
    }

    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }

    /// Show recovery info alert (called after save success or failure)
    private func showRecoveryInfoAlert(saveSuccess: Bool) {
        // Show no-backup recovery dialog after dismissing if save was successful
        shouldShowNoBackupDialogOnDismiss = saveSuccess

        let title = saveSuccess
            ? Lang("backup.save_success.title")
            : Lang("backup.save_failed.title")

        // Create overlay
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = Theme.Colors.overlayDark
        overlayView.tag = 7777

        // Create popup container
        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 16
        popupView.translatesAutoresizingMaskIntoConstraints = false

        // Status icon
        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
            if saveSuccess {
                iconView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
                iconView.tintColor = UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0) // Green
            } else {
                iconView.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config)
                iconView.tintColor = UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1.0) // Orange
            }
        }
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = saveSuccess
            ? UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Recovery info card
        let infoCard = UIView()
        infoCard.backgroundColor = saveSuccess
            ? UIColor(red: 0.95, green: 0.97, blue: 0.95, alpha: 1.0) // Light green
            : UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0) // Light orange
        infoCard.layer.cornerRadius = 12
        infoCard.translatesAutoresizingMaskIntoConstraints = false

        // Info content label
        let infoLabel = UILabel()
        infoLabel.text = saveSuccess
            ? Lang("backup.save_success.message")
            : Lang("backup.nobackup.content")
        infoLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = Theme.MinimalTheme.textPrimary
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        // OK button
        let okButton = UIButton(type: .system)
        okButton.setTitle(Lang("common.ok"), for: .normal)
        okButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        okButton.setTitleColor(.white, for: .normal)
        okButton.backgroundColor = Theme.Colors.elegantBlue
        okButton.layer.cornerRadius = 10
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.addTarget(self, action: #selector(dismissRecoveryInfoPopup), for: .touchUpInside)

        // Add subviews
        infoCard.addSubview(infoLabel)
        popupView.addSubview(iconView)
        popupView.addSubview(titleLabel)
        popupView.addSubview(infoCard)
        popupView.addSubview(okButton)
        overlayView.addSubview(popupView)
        view.addSubview(overlayView)

        // Layout
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            popupView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 32),
            popupView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -32),

            iconView.topAnchor.constraint(equalTo: popupView.topAnchor, constant: 24),
            iconView.centerXAnchor.constraint(equalTo: popupView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 50),
            iconView.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -20),

            infoCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            infoCard.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),

            infoLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 14),
            infoLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 14),
            infoLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -14),
            infoLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -14),

            okButton.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 20),
            okButton.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 16),
            okButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            okButton.heightAnchor.constraint(equalToConstant: 48),
            okButton.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -20),
        ])

        // Animate in
        overlayView.alpha = 0
        popupView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: 0.25) {
            overlayView.alpha = 1
            popupView.transform = .identity
        }
    }

    @objc private func dismissRecoveryInfoPopup() {
        if let overlayView = view.viewWithTag(7777) {
            UIView.animate(withDuration: 0.2, animations: {
                overlayView.alpha = 0
            }) { [weak self] _ in
                overlayView.removeFromSuperview()
                // Show no-backup recovery dialog after save success dialog
                if self?.shouldShowNoBackupDialogOnDismiss == true {
                    self?.shouldShowNoBackupDialogOnDismiss = false
                    self?.noBackupRecoveryTapped()
                }
            }
        }
    }
}
