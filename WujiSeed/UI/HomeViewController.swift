//
//  HomeViewController.swift
//  WujiSeed
//
//  Main home screen with navigation to all features
//

import UIKit

class HomeViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Security check button (top left)
    private let securityButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 14.2, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            let image = UIImage(systemName: "checkerboard.shield", withConfiguration: config)
            button.setImage(image, for: .normal)
        } else if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            let image = UIImage(systemName: "checkmark.shield", withConfiguration: config)
            button.setImage(image, for: .normal)
        } else {
            button.setTitle("🛡️", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        }
        button.tintColor = Theme.MinimalTheme.stable
        return button
    }()

    // Language switch button (top right)
    private let languageButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            let image = UIImage(systemName: "globe", withConfiguration: config)
            button.setImage(image, for: .normal)
        } else {
            button.setTitle("🌐", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        }
        button.tintColor = Theme.MinimalTheme.stable  // Deep blue
        return button
    }()

    // Top branding area
    private let logoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textAlignment = .center
        label.textColor = Theme.MinimalTheme.stable  // Deep blue #002B5B, matches input field valid text color
        return label
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "WUJI_logo"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let logoContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let sloganLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 2
        return label
    }()

    // Button 1: Seed phrase generation wizard
    private let wizardButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = Theme.Colors.elegantBlue
        button.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        return button
    }()

    // Button 2: User manual
    private let manualButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = Theme.Colors.grayBackground
        button.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()

    // Button: Encrypt existing seed phrase (temporarily removed, for future release)
    // private let importMnemonicButton: UIButton = { ... }()

    // Button 4: Recover seed phrase
    private let recoveryMnemonicButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = Theme.Colors.grayBackground
        button.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()

    // Button 5: F9 Location
    private let wujiLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = Theme.Colors.grayBackground
        button.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return button
    }()

    // Container for version label (centered, tappable)
    private let versionContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()


    // Bottom version label
    private let versionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .gray
        return label
    }()

    // Debug mode indicator
    private let debugIndicator: UILabel = {
        let label = UILabel()
        label.text = "TEST"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.isHidden = true
        label.isUserInteractionEnabled = true
        return label
    }()


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide back button text, show only arrow
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Check libsodium status (only on first launch)
        CryptoUtils.printDebugInfo()

        setupUI()
        setupConstraints()
        setupActions()
        setupLanguageObserver()
        setupDebugModeObserver()
        updateLocalizedText()
        updateDebugIndicator()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide navigation bar on home screen
        navigationController?.navigationBar.isHidden = true

        // Ensure corner buttons are visible (fix for view hierarchy issue after modal dismiss)
        ensureCornerButtonsVisible()

        // IMPORTANT: Do NOT clear state here!
        // User might return from wizard to view other content, clearing would cause data loss
        // State should be cleared at these times:
        // 1. When user taps "Generate Seed Phrase" button to start new flow
        // 2. When user explicitly taps "Exit" button
        // 3. After completing the entire flow
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Defensive: ensure corner buttons are always visible and on top
        // This covers cases where viewWillAppear might not fire (e.g., pageSheet dismiss on iOS 13+)
        ensureCornerButtonsVisible()
    }

    /// Ensure security and language buttons are visible and on top of the view hierarchy
    private func ensureCornerButtonsVisible() {
        securityButton.isHidden = false
        languageButton.isHidden = false
        view.bringSubviewToFront(securityButton)
        view.bringSubviewToFront(languageButton)

        // Clean up any stale dimView (pre-generation notice) that might block interaction
        if let dimView = view.viewWithTag(8888) {
            dimView.removeFromSuperview()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Show navigation bar (needed when leaving home screen for other pages)
        navigationController?.navigationBar.isHidden = false

        // Restore default navigation bar appearance (including separator)
        guard let navBar = navigationController?.navigationBar else { return }

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Theme.MinimalTheme.cardBackground
            appearance.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont
            ]
            appearance.shadowColor = Theme.MinimalTheme.separator  // Show separator line

            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
        } else {
            navBar.barTintColor = Theme.MinimalTheme.cardBackground
            navBar.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont
            ]
            navBar.isTranslucent = false
        }
        navBar.tintColor = Theme.MinimalTheme.stable
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .white

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Top buttons float on top
        view.addSubview(securityButton)
        view.addSubview(languageButton)

        contentView.addSubview(logoContainer)
        logoContainer.addSubview(logoLabel)
        logoContainer.addSubview(logoImageView)
        logoContainer.addSubview(debugIndicator)  // TEST badge after logo
        contentView.addSubview(sloganLabel)
        contentView.addSubview(wizardButton)
        contentView.addSubview(manualButton)
        // importMnemonicButton temporarily removed, for future release
        contentView.addSubview(recoveryMnemonicButton)
        contentView.addSubview(wujiLocationButton)
        contentView.addSubview(versionContainer)
        versionContainer.addSubview(versionLabel)

        // Version text will be set in updateLocalizedText()

        // Version container tap opens about page
        let containerTap = UITapGestureRecognizer(target: self, action: #selector(aboutBtnTapped))
        versionContainer.addGestureRecognizer(containerTap)

        // Setup TEST indicator tap gesture for test config (DEBUG only)
        #if DEBUG
        let debugTap = UITapGestureRecognizer(target: self, action: #selector(testBtnTapped))
        debugIndicator.addGestureRecognizer(debugTap)
        #endif

        // Configure button content
        configureWizardButton()
        configureManualButton()
        // configureRestoreMnemonicButton() temporarily removed
        configureRecoveryMnemonicButton()
        configureF9LocationButton()
    }

    private func configureWizardButton() {
        let iconLabel = UILabel()
        iconLabel.text = "✨"
        iconLabel.font = UIFont.systemFont(ofSize: 28)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)
        iconLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Spacer to push title to the right
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = Lang("home.wizard")
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let mainStack = UIStackView(arrangedSubviews: [iconLabel, spacer, titleLabel])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.isUserInteractionEnabled = false

        wizardButton.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: wizardButton.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: wizardButton.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: wizardButton.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: wizardButton.bottomAnchor, constant: -16)
        ])
    }

    private func configureManualButton() {
        // Use SF Symbol book icon for Manual
        if #available(iOS 13.0, *) {
            configureSecondaryButtonWithSFSymbol(manualButton, symbolName: "book", title: Lang("home.manual"))
        } else {
            configureSecondaryButton(manualButton, icon: "📖", title: Lang("home.manual"))
        }
    }

    // configureRestoreMnemonicButton temporarily removed

    private func configureRecoveryMnemonicButton() {
        // Use SF Symbol qrcode.viewfinder icon for Recovery
        if #available(iOS 13.0, *) {
            configureSecondaryButtonWithSFSymbol(recoveryMnemonicButton, symbolName: "qrcode.viewfinder", title: Lang("home.restore"))
        } else {
            configureSecondaryButtonWithoutIcon(recoveryMnemonicButton, title: Lang("home.restore"))
        }
    }

    private func configureF9LocationButton() {
        // Use SF Symbol grid icon for F9 Location
        if #available(iOS 13.0, *) {
            configureSecondaryButtonWithSFSymbol(wujiLocationButton, symbolName: "grid", title: Lang("home.f9location"))
        } else {
            configureSecondaryButton(wujiLocationButton, icon: "⊞", title: Lang("home.f9location"))
        }
    }

    @available(iOS 13.0, *)
    private func configureSecondaryButtonWithSFSymbol(_ button: UIButton, symbolName: String, title: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: config))
        iconView.tintColor = Theme.Colors.elegantBlue
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let mainStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.isUserInteractionEnabled = false

        button.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])
    }

    private func configureSecondaryButton(_ button: UIButton, icon: String, title: String) {
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 24)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)
        iconLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let mainStack = UIStackView(arrangedSubviews: [iconLabel, titleLabel])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.isUserInteractionEnabled = false

        button.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])
    }

    private func configureSecondaryButtonWithoutIcon(_ button: UIButton, title: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7

        button.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Setup Constraints

    private func setupConstraints() {
        securityButton.translatesAutoresizingMaskIntoConstraints = false
        languageButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        sloganLabel.translatesAutoresizingMaskIntoConstraints = false
        wizardButton.translatesAutoresizingMaskIntoConstraints = false
        manualButton.translatesAutoresizingMaskIntoConstraints = false
        recoveryMnemonicButton.translatesAutoresizingMaskIntoConstraints = false
        wujiLocationButton.translatesAutoresizingMaskIntoConstraints = false
        versionContainer.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        debugIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Security button (top left corner)
            securityButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            securityButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            securityButton.widthAnchor.constraint(equalToConstant: 44),
            securityButton.heightAnchor.constraint(equalToConstant: 44),

            // Language button (top right corner)
            languageButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            languageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            languageButton.widthAnchor.constraint(equalToConstant: 44),
            languageButton.heightAnchor.constraint(equalToConstant: 44),

            // ScrollView (starts from safe area top)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Logo Container (moved up to give more space below)
            logoContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant:70),
            logoContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 200),
            logoContainer.heightAnchor.constraint(equalToConstant: 55),

            // Logo (text, for Chinese) - bottom aligned, reduced spacing to slogan
            logoLabel.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoLabel.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),

            // Logo (image, for English)
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 55),

            // Slogan
            sloganLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 0),
            sloganLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sloganLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Button 1: Mnemonic generation wizard
            wizardButton.topAnchor.constraint(equalTo: sloganLabel.bottomAnchor, constant: 70),
            wizardButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            wizardButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            wizardButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            // Button 2: Recover mnemonic (encrypt existing mnemonic temporarily removed)
            recoveryMnemonicButton.topAnchor.constraint(equalTo: wizardButton.bottomAnchor, constant: 12),
            recoveryMnemonicButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recoveryMnemonicButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recoveryMnemonicButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Button 3: User manual
            manualButton.topAnchor.constraint(equalTo: recoveryMnemonicButton.bottomAnchor, constant: 12),
            manualButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            manualButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            manualButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Button 4: F9 Location
            wujiLocationButton.topAnchor.constraint(equalTo: manualButton.bottomAnchor, constant: 12),
            wujiLocationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            wujiLocationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            wujiLocationButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Debug indicator (top-right corner of "无迹")
            debugIndicator.leadingAnchor.constraint(equalTo: logoLabel.trailingAnchor, constant: 0),
            debugIndicator.bottomAnchor.constraint(equalTo: logoLabel.topAnchor, constant: 12),
            debugIndicator.widthAnchor.constraint(equalToConstant: 36),
            debugIndicator.heightAnchor.constraint(equalToConstant: 16),

            // Version container (centered)
            versionContainer.topAnchor.constraint(equalTo: wujiLocationButton.bottomAnchor, constant: 12),
            versionContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            versionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            // Version label (inside container, with padding for larger tap area)
            versionLabel.leadingAnchor.constraint(equalTo: versionContainer.leadingAnchor, constant: 16),
            versionLabel.trailingAnchor.constraint(equalTo: versionContainer.trailingAnchor, constant: -16),
            versionLabel.topAnchor.constraint(equalTo: versionContainer.topAnchor, constant: 8),
            versionLabel.bottomAnchor.constraint(equalTo: versionContainer.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Setup Actions

    private func setupActions() {
        securityButton.addTarget(self, action: #selector(securityButtonTapped), for: .touchUpInside)
        languageButton.addTarget(self, action: #selector(languageButtonTapped), for: .touchUpInside)
        wizardButton.addTarget(self, action: #selector(wizardButtonTapped), for: .touchUpInside)
        manualButton.addTarget(self, action: #selector(manualButtonTapped), for: .touchUpInside)
        // importMnemonicButton temporarily removed
        recoveryMnemonicButton.addTarget(self, action: #selector(recoveryMnemonicButtonTapped), for: .touchUpInside)
        wujiLocationButton.addTarget(self, action: #selector(wujiLocationButtonTapped), for: .touchUpInside)
    }

    @objc private func securityButtonTapped() {
        let securityVC = SecurityPreCheckViewController()
        securityVC.showDontShowAgainOption = false  // Simple mode - no checkbox
        securityVC.modalPresentationStyle = .fullScreen
        present(securityVC, animated: true)
    }

    @objc private func aboutBtnTapped() {
        let aboutVC = AboutViewController()
        aboutVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = aboutVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        // Set delegate to handle dismiss (viewWillAppear not called for pageSheet on iOS 13+)
        aboutVC.presentationController?.delegate = self
        present(aboutVC, animated: true)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Called when pageSheet is dismissed by swipe — viewWillAppear is not called in this case
        ensureCornerButtonsVisible()
    }

    // MARK: - Button Actions

    @objc private func wizardButtonTapped() {
        // Check if user has dismissed the notice before
        let hasSeenNotice = UserDefaults.standard.bool(forKey: "hasSeenPreGenerationNotice")

        if hasSeenNotice {
            startGenerationWizard()
        } else {
            showPreGenerationNotice()
        }
    }

    private func startGenerationWizard() {
        // Clear previous wizard state and start fresh
        SessionStateManager.shared.clearAll()

        let nameSaltVC = NameSaltViewController()
        navigationController?.pushViewController(nameSaltVC, animated: true)
    }

    // MARK: - Pre-Generation Notice

    private func showPreGenerationNotice() {
        // Dimmed background
        let dimView = UIView(frame: view.bounds)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimView.alpha = 0
        dimView.tag = 8888

        // Card container
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Header icon and title
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        iconLabel.text = "📝"
        iconLabel.font = UIFont.systemFont(ofSize: 24)

        let titleLabel = UILabel()
        titleLabel.text = Lang("notice.pre_generation.title")
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary

        headerStack.addArrangedSubview(iconLabel)
        headerStack.addArrangedSubview(titleLabel)

        // Content stack
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Point 1: Data not saved
        let point1 = createNoticePoint(
            icon: "⚡",
            text: Lang("notice.pre_generation.point1")
        )

        // Point 2: No sensitive data stored
        let point2 = createNoticePoint(
            icon: "🔒",
            text: Lang("notice.pre_generation.point2")
        )

        // Tip section
        let tipContainer = UIView()
        tipContainer.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
        tipContainer.layer.cornerRadius = 12
        tipContainer.translatesAutoresizingMaskIntoConstraints = false

        let tipStack = UIStackView()
        tipStack.axis = .vertical
        tipStack.spacing = 8
        tipStack.translatesAutoresizingMaskIntoConstraints = false

        let tipTitle = UILabel()
        tipTitle.text = "💡 " + Lang("notice.pre_generation.tip_title")
        tipTitle.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        tipTitle.textColor = Theme.Colors.elegantBlue

        let tipContent = UILabel()
        tipContent.text = Lang("notice.pre_generation.tip_content")
        tipContent.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tipContent.textColor = Theme.MinimalTheme.textSecondary
        tipContent.numberOfLines = 0

        tipStack.addArrangedSubview(tipTitle)
        tipStack.addArrangedSubview(tipContent)

        tipContainer.addSubview(tipStack)

        // Don't show again checkbox (left aligned)
        let checkboxContainer = UIView()
        checkboxContainer.translatesAutoresizingMaskIntoConstraints = false

        let checkbox = UIButton(type: .custom)
        checkbox.tag = 7777
        if #available(iOS 13.0, *) {
            let uncheckedConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            let checkedConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            checkbox.setImage(UIImage(systemName: "circle", withConfiguration: uncheckedConfig), for: .normal)
            checkbox.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkedConfig), for: .selected)
        } else {
            checkbox.setTitle("○", for: .normal)
            checkbox.setTitle("●", for: .selected)
        }
        checkbox.tintColor = Theme.Colors.elegantBlue
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.addTarget(self, action: #selector(noticeCheckboxTapped(_:)), for: .touchUpInside)

        let checkboxLabel = UILabel()
        checkboxLabel.text = Lang("notice.pre_generation.dont_show_again")
        checkboxLabel.font = UIFont.systemFont(ofSize: 14)
        checkboxLabel.textColor = Theme.MinimalTheme.textSecondary
        checkboxLabel.translatesAutoresizingMaskIntoConstraints = false

        checkboxContainer.addSubview(checkbox)
        checkboxContainer.addSubview(checkboxLabel)

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: checkboxContainer.leadingAnchor),
            checkbox.topAnchor.constraint(equalTo: checkboxContainer.topAnchor),
            checkbox.bottomAnchor.constraint(equalTo: checkboxContainer.bottomAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 24),
            checkbox.heightAnchor.constraint(equalToConstant: 24),

            checkboxLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 8),
            checkboxLabel.centerYAnchor.constraint(equalTo: checkbox.centerYAnchor),
            checkboxLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkboxContainer.trailingAnchor)
        ])

        // Start button
        let startButton = UIButton(type: .system)
        startButton.setTitle(Lang("notice.pre_generation.start_button"), for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = Theme.Colors.elegantBlue
        startButton.layer.cornerRadius = 12
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(noticeStartButtonTapped), for: .touchUpInside)

        // Assemble card
        contentStack.addArrangedSubview(point1)
        contentStack.addArrangedSubview(point2)
        contentStack.addArrangedSubview(tipContainer)
        contentStack.addArrangedSubview(checkboxContainer)

        cardView.addSubview(headerStack)
        cardView.addSubview(contentStack)
        cardView.addSubview(startButton)

        dimView.addSubview(cardView)
        view.addSubview(dimView)

        // Constraints
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: dimView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: dimView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: dimView.bottomAnchor),

            headerStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            headerStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),

            contentStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            tipStack.topAnchor.constraint(equalTo: tipContainer.topAnchor, constant: 12),
            tipStack.leadingAnchor.constraint(equalTo: tipContainer.leadingAnchor, constant: 12),
            tipStack.trailingAnchor.constraint(equalTo: tipContainer.trailingAnchor, constant: -12),
            tipStack.bottomAnchor.constraint(equalTo: tipContainer.bottomAnchor, constant: -12),

            startButton.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 24),
            startButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            startButton.bottomAnchor.constraint(equalTo: cardView.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        // Animate in
        cardView.transform = CGAffineTransform(translationX: 0, y: 400)
        UIView.animate(withDuration: 0.3) {
            dimView.alpha = 1
            cardView.transform = .identity
        }

        // Tap to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissNoticeCard))
        dimView.addGestureRecognizer(tapGesture)
    }

    private func createNoticePoint(icon: String, text: String) -> UIView {
        let container = UIView()

        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = UIFont.systemFont(ofSize: 15)
        textLabel.textColor = Theme.MinimalTheme.textPrimary
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconLabel)
        container.addSubview(textLabel)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconLabel.topAnchor.constraint(equalTo: container.topAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 24),

            textLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            textLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textLabel.topAnchor.constraint(equalTo: container.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    @objc private func noticeCheckboxTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
    }

    @objc private func noticeStartButtonTapped() {
        // Save preference if checkbox is selected
        if let dimView = view.viewWithTag(8888),
           let checkbox = dimView.viewWithTag(7777) as? UIButton,
           checkbox.isSelected {
            UserDefaults.standard.set(true, forKey: "hasSeenPreGenerationNotice")
        }

        dismissNoticeCard()
        startGenerationWizard()
    }

    @objc private func dismissNoticeCard() {
        guard let dimView = view.viewWithTag(8888) else { return }

        UIView.animate(withDuration: 0.25, animations: {
            dimView.alpha = 0
        }) { _ in
            dimView.removeFromSuperview()
        }
    }

    @objc private func manualButtonTapped() {
        let manualVC = ManualViewController()
        navigationController?.pushViewController(manualVC, animated: true)
    }

    // importMnemonicButtonTapped temporarily removed, for future release

    @objc private func recoveryMnemonicButtonTapped() {
        // Clear previous session state
        SessionStateManager.shared.clearAll()

        // Navigate to recover mnemonic page
        let recoveryVC = RecoverViewController()
        navigationController?.pushViewController(recoveryVC, animated: true)

        #if DEBUG
        WujiLogger.info("User tapped 'Recover Mnemonic'")
        #endif
    }

    @objc private func wujiLocationButtonTapped() {
        let locationVC = F9LocationViewController()

        #if DEBUG
        // Apply mock coordinate from test config if debug mode is enabled
        if DebugModeManager.shared.isEnabled {
            locationVC.mockCoordinate = TestConfig.shared.wujiMockCoordinate
        }
        #endif

        navigationController?.pushViewController(locationVC, animated: true)
    }

    // MARK: - Language Support

    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageButtonTapped() {
        let alert = UIAlertController(title: Lang("language.select.title"), message: nil, preferredStyle: .actionSheet)

        // Add all language options
        for language in AppLanguage.allCases {
            let action = UIAlertAction(title: language.displayName, style: .default) { _ in
                LanguageManager.shared.currentLanguage = language
            }

            // Show checkmark for currently selected language
            if language == LanguageManager.shared.currentLanguage {
                action.setValue(true, forKey: "checked")
            }

            alert.addAction(action)
        }

        // Add cancel button
        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))

        // iPad requires popover position
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = languageButton
            popoverController.sourceRect = languageButton.bounds
        }

        present(alert, animated: true)
    }

    @objc private func languageDidChange() {
        updateLocalizedText()
    }

    private func updateLocalizedText() {
        // Update Logo: show text for Chinese (WuJi), show WUJI_logo image for all other languages
        let lang = LanguageManager.shared.currentLanguage
        let isChinese = (lang == .chineseSimplified || lang == .chineseTraditional)
        logoImageView.isHidden = isChinese
        logoLabel.isHidden = !isChinese
        logoLabel.text = Lang("home.app.name")

        // Update Slogan (single line only)
        sloganLabel.text = Lang("home.slogan")

        // Update button text
        updateButtonText(wizardButton, title: Lang("home.wizard"))
        updateButtonText(manualButton, title: Lang("home.manual"))
        // updateButtonText(importMnemonicButton, ...) temporarily removed
        updateButtonText(recoveryMnemonicButton, title: Lang("home.restore"))
        updateButtonText(wujiLocationButton, title: Lang("home.f9location"))

        // Update version text with localized "Open Source" label
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let versionText = NSMutableAttributedString(
            string: "v\(version) · ",
            attributes: [.foregroundColor: UIColor.gray]
        )
        versionText.append(NSAttributedString(
            string: Lang("home.open_source"),
            attributes: [.foregroundColor: UIColor.gray]
        ))
        versionLabel.attributedText = versionText
    }

    private func updateButtonText(_ button: UIButton, title: String) {
        // Find UIStackView or UILabel in button
        for subview in button.subviews {
            if let stackView = subview as? UIStackView {
                // Find the last UILabel in the stack (title is always last)
                for arrangedSubview in stackView.arrangedSubviews.reversed() {
                    if let titleLabel = arrangedSubview as? UILabel {
                        titleLabel.text = title
                        break
                    }
                }
            } else if let titleLabel = subview as? UILabel {
                // Button without icon: directly UILabel
                titleLabel.text = title
            }
        }
    }

    // MARK: - Debug Mode

    private func setupDebugModeObserver() {
        #if DEBUG
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(debugModeDidChange),
            name: .debugModeDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotModeDidChange),
            name: .screenshotModeDidChange,
            object: nil
        )
        #endif
    }

    @objc private func debugModeDidChange() {
        updateDebugIndicator()
    }

    @objc private func screenshotModeDidChange() {
        updateDebugIndicator()
    }

    private func updateDebugIndicator() {
        #if DEBUG
        // Only hide TEST indicator if debug mode is off (screenshot mode does NOT hide it)
        debugIndicator.isHidden = !DebugModeManager.shared.isEnabled
        #else
        debugIndicator.isHidden = true
        #endif
    }

    @objc private func testBtnTapped() {
        #if DEBUG
        // Show test configuration page
        let testConfigVC = TestConfigViewController()
        testConfigVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = testConfigVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(testConfigVC, animated: true)
        #endif
    }

}
