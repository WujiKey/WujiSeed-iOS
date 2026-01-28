//
//  NameSaltViewController.swift
//  WujiKey
//
//  Name input page - first step of wizard
//

import UIKit

class NameSaltViewController: KeyboardAwareViewController {

    // MARK: - Data Model

    /// User input string (42+ characters, used as Argon2id salt)
    var inputString: String = ""

    /// Whether presented in editing mode
    var isPresentedForEditing: Bool = false

    /// Whether in import mode (importing existing mnemonic)
    var isImportMode: Bool = false

    /// Whether in recovery mode (recovering encrypted backup)
    var isRecoveryMode: Bool = false

    /// Existing input for editing mode (for pre-filling)
    var existingInputString: String = ""

    /// Callback when editing completes
    var onEditingComplete: ((String) -> Void)?

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Context card - shows what user is doing
    private let contextCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.contextCardBackground
        view.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        view.layer.borderWidth = Theme.Layout.defaultBorderWidth
        view.layer.borderColor = Theme.Colors.infoBlueBorder.cgColor
        return view
    }()

    private let contextLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.subtitle
        label.textColor = Theme.Colors.titleText
        label.numberOfLines = 0
        return label
    }()

    private let secretTagLabel: PaddedLabel = {
        let label = PaddedLabel()
        // Match PlaceInputRowView style
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1.0)  // Deep orange-red
        label.backgroundColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.15)  // Light orange
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        return label
    }()

    // Security warning view
    private let securityWarningView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 0
        view.layer.borderWidth = 0
        return view
    }()

    private let warningTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.captionBold
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        return label
    }()

    // Example card view
    private let exampleCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.grayBackground
        view.layer.cornerRadius = 6
        return view
    }()

    private let exampleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.caption
        label.textColor = Theme.Colors.subtitleText
        label.numberOfLines = 1
        return label
    }()

    // Input area
    private let manualInputView = UIView()

    private let inputTextView: UITextView = {
        let textView = UITextView()
        // Use SF Mono font for consistent display with PlaceInputRowView
        if #available(iOS 13.0, *) {
            textView.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        } else {
            textView.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        }
        textView.textColor = .black
        textView.backgroundColor = Theme.Colors.grayBackground
        textView.layer.cornerRadius = Theme.Layout.smallCornerRadius

        // Use fixed, safe insets
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.keyboardType = .default
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no

        // Configure text container with safe defaults
        textView.textContainer.lineFragmentPadding = 0  // Remove extra padding, align cursor to left edge
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping

        // Set explicit size to prevent auto-sizing issues
        textView.textContainer.size = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        // Enable scrolling with safe defaults
        textView.isScrollEnabled = true
        textView.bounces = false  // Disable bounce to reduce layout calculations
        textView.alwaysBounceVertical = false
        textView.alwaysBounceHorizontal = false
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false

        // Prevent layer from getting invalid bounds
        textView.clipsToBounds = true
        textView.layer.masksToBounds = true

        return textView
    }()

    private let inputPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.monospacedRegular
        label.textColor = .lightGray
        label.isUserInteractionEnabled = false
        return label
    }()

    // Next button background (fully transparent container for separator line)
    private let nextButtonBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .clear  // Fully transparent
        return view
    }()

    // Next button
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.Fonts.bodySemibold
        button.backgroundColor = Theme.Colors.disabledButtonBackground  // Initial disabled state
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        button.isEnabled = false
        return button
    }()

    // Button bottom constraint for keyboard following
    private var nextButtonBottomConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Adjust navigation bar based on presentation mode
        if isPresentedForEditing {
            // Editing mode: hide back button, add cancel button
            navigationItem.hidesBackButton = true
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Lang("common.cancel"), style: .plain, target: self, action: #selector(cancelTapped))
        } else {
            // Normal mode: show back button
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }

        setupUI()
        setupConstraints()
        setupActions()
        setupLanguageObserver()
        setupKeyboardScrollObserver()

        // Enable keyboard constraint with enhanced validation
        keyboardConstraint = nextButtonBottomConstraint
        inputTextView.delegate = self

        // Editing mode: pre-fill existing content
        if isPresentedForEditing && !existingInputString.isEmpty {
            inputTextView.text = existingInputString
            inputString = existingInputString
            updateInputCount()
        }

        // Force initial layout to ensure all frames are valid before interaction
        view.layoutIfNeeded()

        // Update textContainer width after layout is complete
        if inputTextView.bounds.width > 0 && inputTextView.bounds.width.isFinite {
            let availableWidth = inputTextView.bounds.width - inputTextView.textContainerInset.left - inputTextView.textContainerInset.right
            if availableWidth > 0 && availableWidth.isFinite {
                inputTextView.textContainer.size = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
            }
        }

        // Restore saved state and update localized text
        restoreState()
        updateLocalizedText()

        // Ensure button initial state is correct (disabled if input is empty)
        updateInputCount()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        updateNavigationBarTheme()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.backgroundColor = .white  // Explicitly set scrollView background color
        scrollView.addSubview(contentView)

        contentView.addSubview(contextCardView)
        contextCardView.addSubview(contextLabel)
        contextCardView.addSubview(secretTagLabel)

        contentView.addSubview(securityWarningView)
        securityWarningView.addSubview(warningTitleLabel)

        contentView.addSubview(exampleCardView)
        exampleCardView.addSubview(exampleLabel)

        contentView.addSubview(manualInputView)
        manualInputView.addSubview(inputTextView)
        inputTextView.addSubview(inputPlaceholderLabel)

        view.addSubview(nextButtonBackground)
        view.addSubview(nextButton)

        applyThemeStyles()
        updateNavigationBarTheme()
    }

    /// Apply theme styles
    private func applyThemeStyles() {
        // Background: pure white
        view.backgroundColor = .white

        // Context card: transparent background, allow overflow for secret tag
        contextCardView.backgroundColor = .clear
        contextCardView.layer.cornerRadius = 0
        contextCardView.layer.borderWidth = 0
        contextCardView.clipsToBounds = false

        // Context text: 22pt heavy, black
        contextLabel.textColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        contextLabel.font = Theme.Fonts.largeTitleHeavy

        // Warning box: light blue background + rounded corners (Design D)
        securityWarningView.backgroundColor = UIColor(red: 0.0, green: 0.17, blue: 0.36, alpha: 0.05)  // Brand blue 5% opacity
        securityWarningView.layer.cornerRadius = 8
        securityWarningView.layer.masksToBounds = true

        // Remove old left line and top accent bar
        securityWarningView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

        // Add top accent bar (2pt height)
        let topAccent = UIView()
        topAccent.tag = 999
        topAccent.backgroundColor = Theme.Colors.elegantBlue  // Brand blue
        topAccent.translatesAutoresizingMaskIntoConstraints = false
        securityWarningView.addSubview(topAccent)
        NSLayoutConstraint.activate([
            topAccent.leadingAnchor.constraint(equalTo: securityWarningView.leadingAnchor),
            topAccent.topAnchor.constraint(equalTo: securityWarningView.topAnchor),
            topAccent.trailingAnchor.constraint(equalTo: securityWarningView.trailingAnchor),
            topAccent.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Warning text: navy blue (professional, trustworthy)
        warningTitleLabel.textColor = UIColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1.0)  // #1E3A5F navy blue
        warningTitleLabel.font = Theme.Fonts.title

        // Input field style (match PlaceInputRowView)
        inputTextView.backgroundColor = Theme.MinimalTheme.secondaryBackground
        inputTextView.textColor = Theme.Colors.elegantBlue
        if #available(iOS 13.0, *) {
            inputTextView.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        } else {
            inputTextView.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        }
        inputTextView.layer.cornerRadius = Theme.MinimalTheme.cornerRadius
        inputTextView.layer.borderWidth = Theme.MinimalTheme.borderWidth
        inputTextView.layer.borderColor = Theme.MinimalTheme.border.cgColor

        // Placeholder style
        inputPlaceholderLabel.textColor = Theme.MinimalTheme.textPlaceholder
        inputPlaceholderLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
    }

    /// Update navigation bar theme
    private func updateNavigationBarTheme() {
        guard let navBar = navigationController?.navigationBar else { return }

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Theme.MinimalTheme.cardBackground
            appearance.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont
            ]
            appearance.shadowColor = Theme.MinimalTheme.separator

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Validate frame dimensions to prevent NaN errors
        guard view.bounds.width > 0 && view.bounds.height > 0,
              view.bounds.width.isFinite && view.bounds.height.isFinite,
              scrollView.bounds.width.isFinite && scrollView.bounds.height.isFinite else {
            return
        }

        // Calculate button area height, set scrollView bottom contentInset
        let buttonAreaHeight = nextButtonBackground.frame.height
        if buttonAreaHeight > 0 && buttonAreaHeight.isFinite {
            scrollView.contentInset.bottom = buttonAreaHeight
            scrollView.scrollIndicatorInsets.bottom = buttonAreaHeight
        }

        // Validate scrollView contentSize
        if !scrollView.contentSize.width.isFinite || !scrollView.contentSize.height.isFinite {
            scrollView.contentSize = contentView.bounds.size
        }

        // Validate and update textContainer size to prevent NaN in text layout
        if inputTextView.bounds.width > 0 && inputTextView.bounds.width.isFinite {
            let availableWidth = inputTextView.bounds.width - inputTextView.textContainerInset.left - inputTextView.textContainerInset.right
            if availableWidth > 0 && availableWidth.isFinite {
                let currentSize = inputTextView.textContainer.size
                // Only update if current size is invalid or width changed significantly
                if !currentSize.width.isFinite || !currentSize.height.isFinite || abs(currentSize.width - availableWidth) > 1 {
                    inputTextView.textContainer.size = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
                }
            }
        }

        // Validate inputTextView contentSize to prevent NaN errors during paste menu
        if !inputTextView.contentSize.width.isFinite || !inputTextView.contentSize.height.isFinite {
            // Reset contentSize if invalid
            inputTextView.contentSize = CGSize(width: inputTextView.bounds.width, height: 96)
        }

        // Validate inputTextView frame and apply button style if all frames are valid
        if inputTextView.frame.width.isFinite && inputTextView.frame.height.isFinite &&
           nextButton.frame.width.isFinite && nextButton.frame.height.isFinite &&
           nextButton.frame.width > 0 && nextButton.frame.height > 0 {
            // Set button style (don't set backgroundColor, controlled by updateInputCount() based on state)
            nextButton.layer.cornerRadius = Theme.MinimalTheme.cornerRadius
            nextButton.layer.borderWidth = 0  // Explicitly disable border
            nextButton.layer.borderColor = UIColor.clear.cgColor  // Transparent border color
            nextButton.setTitleColor(.white, for: .normal)
            nextButton.titleLabel?.font = Theme.MinimalTheme.buttonFont
            nextButton.clipsToBounds = true  // Clip bounds, prevent content overflow

            // Only apply shadow if button has valid bounds
            if nextButton.bounds.width.isFinite && nextButton.bounds.height.isFinite {
                Theme.MinimalTheme.applyButtonShadow(to: nextButton)
            }
        }
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contextCardView.translatesAutoresizingMaskIntoConstraints = false
        contextLabel.translatesAutoresizingMaskIntoConstraints = false
        secretTagLabel.translatesAutoresizingMaskIntoConstraints = false
        securityWarningView.translatesAutoresizingMaskIntoConstraints = false
        warningTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        exampleCardView.translatesAutoresizingMaskIntoConstraints = false
        exampleLabel.translatesAutoresizingMaskIntoConstraints = false

        manualInputView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),  // Extend to view bottom

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Context card
            contextCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contextCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contextCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Context label (allow wrapping, leave room for tag)
            contextLabel.topAnchor.constraint(equalTo: contextCardView.topAnchor, constant: 0),
            contextLabel.leadingAnchor.constraint(equalTo: contextCardView.leadingAnchor, constant: 0),
            contextLabel.trailingAnchor.constraint(lessThanOrEqualTo: contextCardView.trailingAnchor, constant: -60),
            contextLabel.bottomAnchor.constraint(equalTo: contextCardView.bottomAnchor, constant: 0),

            // Secret tag - positioned after context label (like PlaceInputRowView)
            secretTagLabel.centerYAnchor.constraint(equalTo: contextLabel.centerYAnchor),
            secretTagLabel.leadingAnchor.constraint(equalTo: contextLabel.trailingAnchor, constant: 8),
            secretTagLabel.heightAnchor.constraint(equalToConstant: 22),

            // Security warning (Design D: top accent bar + background)
            securityWarningView.topAnchor.constraint(equalTo: contextCardView.bottomAnchor, constant: 12),
            securityWarningView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            securityWarningView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            warningTitleLabel.topAnchor.constraint(equalTo: securityWarningView.topAnchor, constant: 14),  // 2pt top accent bar + 12pt padding
            warningTitleLabel.leadingAnchor.constraint(equalTo: securityWarningView.leadingAnchor, constant: 12),
            warningTitleLabel.trailingAnchor.constraint(equalTo: securityWarningView.trailingAnchor, constant: -12),
            warningTitleLabel.bottomAnchor.constraint(equalTo: securityWarningView.bottomAnchor, constant: -12),

            // Example card
            exampleCardView.topAnchor.constraint(equalTo: securityWarningView.bottomAnchor, constant: 10),
            exampleCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exampleCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            exampleLabel.topAnchor.constraint(equalTo: exampleCardView.topAnchor, constant: 8),
            exampleLabel.leadingAnchor.constraint(equalTo: exampleCardView.leadingAnchor, constant: 12),
            exampleLabel.trailingAnchor.constraint(equalTo: exampleCardView.trailingAnchor, constant: -12),
            exampleLabel.bottomAnchor.constraint(equalTo: exampleCardView.bottomAnchor, constant: -8),

            // Input view
            manualInputView.topAnchor.constraint(equalTo: exampleCardView.bottomAnchor, constant: 10),
            manualInputView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            manualInputView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            inputTextView.topAnchor.constraint(equalTo: manualInputView.topAnchor),
            inputTextView.leadingAnchor.constraint(equalTo: manualInputView.leadingAnchor),
            inputTextView.trailingAnchor.constraint(equalTo: manualInputView.trailingAnchor),
            inputTextView.bottomAnchor.constraint(equalTo: manualInputView.bottomAnchor),
            inputTextView.heightAnchor.constraint(equalToConstant: 96),

            // Placeholder label - aligned with textContainerInset
            inputPlaceholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 12),
            inputPlaceholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 12),
            inputPlaceholderLabel.trailingAnchor.constraint(equalTo: inputTextView.trailingAnchor, constant: -12),

            // Manual input view bottom constraint
            manualInputView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // Next button background (white base, extends from button top to view bottom)
            nextButtonBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nextButtonBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextButtonBackground.topAnchor.constraint(equalTo: nextButton.topAnchor, constant: -16),
            nextButtonBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Next button (fixed at view bottom, not in scrollView)
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Save next button bottom constraint for keyboard following
        nextButtonBottomConstraint = nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        nextButtonBottomConstraint?.isActive = true
    }

    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageDidChange() {
        updateLocalizedText()
    }

    private func setupKeyboardScrollObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
    }

    @objc private func keyboardDidShow(_ notification: NSNotification) {
        guard inputTextView.isFirstResponder else { return }

        // Scroll to make input visible after keyboard appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let inputFrame = self.manualInputView.convert(self.manualInputView.bounds, to: self.scrollView)
            // Add some padding at the bottom
            let paddedFrame = CGRect(x: inputFrame.origin.x, y: inputFrame.origin.y, width: inputFrame.width, height: inputFrame.height + 20)
            self.scrollView.scrollRectToVisible(paddedFrame, animated: true)
        }
    }

    private func updateLocalizedText() {
        let lang = LanguageManager.shared

        title = lang.localizedString("wizard.namesalt.title")

        contextLabel.text = lang.localizedString("namesalt.context")
        secretTagLabel.text = Lang("tag.secret")
        secretTagLabel.isHidden = false

        let warningText = lang.localizedString("namesalt.security_warning")
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8  // Increase line spacing for readability

        let attributedWarning = NSAttributedString(
            string: warningText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .medium),  // Match PlaceInputRowView hint style
                .foregroundColor: UIColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1.0),  // #1E3A5F navy blue
                .paragraphStyle: paragraphStyle
            ]
        )
        warningTitleLabel.attributedText = attributedWarning

        exampleLabel.text = lang.localizedString("namesalt.example")

        inputPlaceholderLabel.text = lang.localizedString("namesalt.placeholder")

        // Set button text based on mode
        if isPresentedForEditing {
            nextButton.setTitle(Lang("common.confirm"), for: .normal)
        } else {
            nextButton.setTitle(Lang("common.next"), for: .normal)
        }

        updateInputCount()
    }

    // MARK: - Actions

    @objc private func nextTapped() {
        guard !inputString.isEmpty else { return }

        // Validate name length: at least 2 Chinese characters OR 4 other characters
        if let validationError = validateNameLength(inputString) {
            showAlert(title: Lang("common.error"), message: validationError)
            return
        }

        inputTextView.resignFirstResponder()

        // Create WujiName (normalizes and generates salt)
        guard let wujiName = WujiName(raw: inputString) else {
            showAlert(title: "Error", message: "Failed to process name")
            return
        }

        // Save WujiName to session
        SessionStateManager.shared.name = wujiName

        // Log output
        #if DEBUG
        WujiLogger.success("NameSalt processing complete:")
        WujiLogger.debug("   Original text: \(inputString)")
        WujiLogger.debug("   Normalized text: \(wujiName.normalized)")
        WujiLogger.debug("   Salt (\(wujiName.salt.count) bytes): \(wujiName.salt.map { String(format: "%02x", $0) }.joined())")
        #endif

        // Execute different behavior based on mode
        if isPresentedForEditing {
            // Editing mode: call callback and dismiss
            onEditingComplete?(inputString)
            dismiss(animated: true, completion: nil)
        } else {
            // Normal mode, import mode, or recovery mode: navigate to Locations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self = self else { return }
                let placesVC = PlacesInputViewController()
                placesVC.isImportMode = self.isImportMode  // Pass import mode flag
                placesVC.isRecoveryMode = self.isRecoveryMode  // Pass recovery mode flag
                self.navigationController?.pushViewController(placesVC, animated: true)
            }
        }
    }


    // MARK: - Helper Methods

    /// Validate name length: UTF-8 byte count must be at least 4
    /// Returns error message if invalid, nil if valid
    private func validateNameLength(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Lang("namesalt.error.empty")
        }

        // Check UTF-8 byte count (must be at least 4 bytes)
        let byteCount = trimmed.utf8.count
        if byteCount >= 4 {
            return nil  // Valid
        }

        return Lang("namesalt.error.too_short")
    }

    private func updateInputCount() {
        let text = inputTextView.text ?? ""
        let count = text.count

        // Control placeholder visibility
        inputPlaceholderLabel.isHidden = !text.isEmpty

        // Set text color: all characters use normal color
        // Avoid setting attributedText if the text is being edited (like during paste)
        // to prevent NaN errors during menu display
        if count > 0 && !inputTextView.isFirstResponder {
            // Validate count and range before creating attributed string
            if count <= text.utf16.count {
                let range = NSRange(location: 0, length: count)

                // Validate range before applying attributes
                if range.location != NSNotFound &&
                   range.location >= 0 &&
                   range.length >= 0 &&
                   range.location + range.length <= (text as NSString).length {

                    let attributedString = NSMutableAttributedString(string: text)

                    // All text uses normal color
                    let inputFont: UIFont
                    if #available(iOS 13.0, *) {
                        inputFont = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
                    } else {
                        inputFont = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
                    }
                    attributedString.addAttribute(.foregroundColor,
                                                 value: Theme.Colors.elegantBlue,
                                                 range: range)

                    attributedString.addAttribute(.font,
                                                 value: inputFont,
                                                 range: range)

                    inputTextView.attributedText = attributedString
                } else {
                    // Fallback to simple text if range is invalid
                    if #available(iOS 13.0, *) {
                        inputTextView.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
                    } else {
                        inputTextView.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
                    }
                    inputTextView.textColor = Theme.Colors.elegantBlue
                }
            } else {
                // Fallback to simple text if count is invalid
                if #available(iOS 13.0, *) {
                    inputTextView.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
                } else {
                    inputTextView.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
                }
                inputTextView.textColor = Theme.Colors.elegantBlue
            }
        } else if count > 0 {
            // When editing, just ensure the font is set without triggering layout
            if #available(iOS 13.0, *) {
                inputTextView.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
            } else {
                inputTextView.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
            }
            inputTextView.textColor = Theme.Colors.elegantBlue
        }

        // Save input
        inputString = text

        // Update next button state (any length is valid)
        let isValid = count > 0
        nextButton.isEnabled = isValid
        nextButton.backgroundColor = isValid ? Theme.Colors.elegantBlue : Theme.Colors.disabledButtonBackground
    }

    // MARK: - State Management

    private func restoreState() {
        // Restore from WujiName if available
        if let name = SessionStateManager.shared.name {
            inputTextView.text = name.normalized
            inputString = name.normalized
            updateInputCount()
        }
    }
}

// MARK: - UITextViewDelegate

extension NameSaltViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == inputTextView {
            updateInputCount()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == inputTextView {
            // Scroll input view into visible area
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                let inputFrame = self.manualInputView.convert(self.manualInputView.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(inputFrame, animated: true)
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == inputTextView {
            // Input editing ended
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // Force layout completion before editing to prevent NaN errors
        if textView == inputTextView {
            // Ensure all layout calculations are complete and valid
            textView.layoutIfNeeded()

            // Validate and fix contentSize if needed
            if !textView.contentSize.width.isFinite || !textView.contentSize.height.isFinite {
                textView.contentSize = CGSize(width: textView.bounds.width, height: 96)
            }

            // Ensure frame is valid
            if !textView.frame.width.isFinite || !textView.frame.height.isFinite {
                return false
            }
        }
        return true
    }

    // Override canPerformAction to COMPLETELY disable editing menu
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Completely disable all editing menu actions to prevent keyboard adjustment issues
        if inputTextView.isFirstResponder {
            return false  // This prevents the editing menu from showing at all
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

