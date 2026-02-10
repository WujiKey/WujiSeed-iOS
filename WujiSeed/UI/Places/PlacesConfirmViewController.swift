//
//  PlacesConfirmViewController.swift
//  WujiSeed
//
//  Final summary page: Display code name, position sequence, address info, generate intermediate password
//

import UIKit

class PlacesConfirmViewController: UIViewController {

    var locations: [PlacesInputViewController.PlaceData] = []

    /// Whether in import mode (importing existing seed phrase)
    var isImportMode: Bool = false

    /// Whether in recovery mode (recovering encrypted backup)
    var isRecoveryMode: Bool = false

    // MARK: - Properties

    private var positionSequence: String = ""
    private var calculationTime: TimeInterval = 0

    /// Validation error message (nil if no error)
    private var validationError: String? = nil

    /// Store references to memory tag views for error highlighting
    private var memory1Views: [Int: UIView] = [:]
    private var memory2Views: [Int: UIView] = [:]
    private var coordLabels: [Int: UILabel] = [:]

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Top hint text (minimal design)
    private let infoHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.numberOfLines = 0
        return label
    }()

    // Seed phrase name area (light background card style)
    private let codeNameCard: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.grayBackground  // Light gray background, same as input field
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let codeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.Colors.subtitleText
        return label
    }()

    private let codeSecretTag: PaddedLabel = {
        let label = PaddedLabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = Theme.Colors.tagSecretText
        label.backgroundColor = Theme.Colors.tagSecretBackground
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.textInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        return label
    }()

    private let codeValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)  // Adjusted from 20pt to 17pt
        label.textColor = Theme.MinimalTheme.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private let codeEditArrow: UIImageView = {
        if #available(iOS 13.0, *) {
            let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
            imageView.tintColor = Theme.MinimalTheme.textSecondary
            imageView.contentMode = .scaleAspectFit
            return imageView
        } else {
            let imageView = UIImageView()
            let label = UILabel()
            label.text = "›"
            label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            label.textColor = Theme.MinimalTheme.textSecondary
            imageView.addSubview(label)
            return imageView
        }
    }()

    // Location info area (gray background card, same as name card)
    private let locationsCard: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.grayBackground  // Light gray background, same as name card
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let locationsHeaderTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = Theme.Colors.subtitleText
        return label
    }()

    private let locationsPrivateBadge: PaddedLabel = {
        let label = PaddedLabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = Theme.Colors.tagSecretText
        label.backgroundColor = Theme.Colors.tagSecretBackground
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.textInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        return label
    }()

    private let locationsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4  // Reduced spacing for more compact display
        return stack
    }()

    // Confirmation checkbox container
    private let confirmationContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let confirmationCheckbox: UIButton = {
        let button = UIButton(type: .custom)

        if #available(iOS 13.0, *) {
            // Using SF Symbols icons, unified style
            let uncheckedConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            let checkedConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

            let uncheckedImage = UIImage(systemName: "circle", withConfiguration: uncheckedConfig)
            let checkedImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkedConfig)

            button.setImage(uncheckedImage, for: .normal)
            button.setImage(checkedImage, for: .selected)
            button.tintColor = Theme.Colors.elegantBlue
        } else {
            // iOS 12 fallback
            button.setTitle("☐", for: .normal)
            button.setTitle("☑", for: .selected)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
            button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
            button.setTitleColor(Theme.Colors.elegantBlue, for: .selected)
        }

        return button
    }()

    private let confirmationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = Theme.MinimalTheme.textPrimary
        label.numberOfLines = 0
        return label
    }()

    // Validation error label
    private let validationErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // Next button
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.MinimalTheme.buttonFont
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Theme.Colors.disabledButtonBackground
        button.layer.cornerRadius = Theme.MinimalTheme.cornerRadius
        button.isEnabled = false
        Theme.MinimalTheme.applyButtonShadow(to: button)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white  // White background, unified with NameSalt/Places

        // Display page title
        navigationItem.title = Lang("places.confirm.title")

        // Setup localized text
        setupLocalizedText()

        // Setup navigation bar buttons (professional product dual-path exit mechanism)
        setupNavigationButtons()

        // Set back button to show no text (prepare for next step)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        setupUI()
        setupConstraints()
        setupCodeNameTapGesture()
        loadCodeName()

        // Display location info first
        populateLocations()

        // Validate locations immediately (show errors before generation)
        validateLocations()

        // Generate and display position sequence
        startGeneration()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.tintColor = Theme.Colors.elegantBlue

        // Allow swipe back gesture (consistent with back button)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    // MARK: - Localization

    private func setupLocalizedText() {
        infoHintLabel.text = Lang("places.confirm.hint")
        codeTitleLabel.text = Lang("common.name")
        codeSecretTag.text = Lang("tag.secret")
        locationsHeaderTitle.text = Lang("places.confirm.locations_title")
        locationsPrivateBadge.text = Lang("tag.secret")
        confirmationLabel.text = Lang("places.confirm.checkbox_label")
        nextButton.setTitle(Lang("common.confirm"), for: .normal)
    }

    // MARK: - Navigation Setup

    private func setupNavigationButtons() {
        // Left: Use system default back button (with arrow, no text)
        // Don't set leftBarButtonItem, let system show back arrow automatically

        // Right: Cancel button (exit entire wizard flow)
        let cancelButton = UIBarButtonItem(
            title: Lang("common.cancel"),
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.rightBarButtonItem = cancelButton
    }

    @objc private func cancelButtonTapped() {
        // Show confirmation dialog
        let alert = UIAlertController(
            title: Lang("places.confirm.exit_title"),
            message: Lang("places.confirm.exit_message"),
            preferredStyle: .alert
        )

        // "Continue editing" button (default action)
        alert.addAction(UIAlertAction(title: Lang("places.confirm.continue_editing"), style: .cancel, handler: nil))

        // "Exit" button (destructive action)
        alert.addAction(UIAlertAction(title: Lang("common.exit"), style: .destructive) { [weak self] _ in
            // Clear wizard state
            SessionStateManager.shared.clearAll()

            // Return to home (pop to root view controller)
            self?.navigationController?.popToRootViewController(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Top hint text
        contentView.addSubview(infoHintLabel)

        // Seed phrase name card
        contentView.addSubview(codeNameCard)
        codeNameCard.addSubview(codeTitleLabel)
        codeNameCard.addSubview(codeSecretTag)
        codeNameCard.addSubview(codeValueLabel)
        codeNameCard.addSubview(codeEditArrow)

        // Location info card
        contentView.addSubview(locationsCard)
        locationsCard.addSubview(locationsHeaderTitle)
        locationsCard.addSubview(locationsPrivateBadge)
        locationsCard.addSubview(locationsStackView)

        // Confirmation checkbox
        contentView.addSubview(confirmationContainer)
        confirmationContainer.addSubview(confirmationCheckbox)
        confirmationContainer.addSubview(confirmationLabel)

        // Validation error label
        contentView.addSubview(validationErrorLabel)

        // Confirm button
        contentView.addSubview(nextButton)

        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        confirmationCheckbox.addTarget(self, action: #selector(confirmationCheckboxTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        infoHintLabel.translatesAutoresizingMaskIntoConstraints = false
        codeNameCard.translatesAutoresizingMaskIntoConstraints = false
        codeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        codeSecretTag.translatesAutoresizingMaskIntoConstraints = false
        codeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        codeEditArrow.translatesAutoresizingMaskIntoConstraints = false
        locationsCard.translatesAutoresizingMaskIntoConstraints = false
        locationsHeaderTitle.translatesAutoresizingMaskIntoConstraints = false
        locationsPrivateBadge.translatesAutoresizingMaskIntoConstraints = false
        locationsStackView.translatesAutoresizingMaskIntoConstraints = false
        confirmationContainer.translatesAutoresizingMaskIntoConstraints = false
        confirmationCheckbox.translatesAutoresizingMaskIntoConstraints = false
        confirmationLabel.translatesAutoresizingMaskIntoConstraints = false
        validationErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // ScrollView and ContentView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Top hint text (compact left-aligned display)
            infoHintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            infoHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Seed phrase name card
            codeNameCard.topAnchor.constraint(equalTo: infoHintLabel.bottomAnchor, constant: 12),
            codeNameCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            codeNameCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            // Sub-title
            codeTitleLabel.topAnchor.constraint(equalTo: codeNameCard.topAnchor, constant: 12),
            codeTitleLabel.leadingAnchor.constraint(equalTo: codeNameCard.leadingAnchor, constant: 12),

            // "Secret" tag (right of name title)
            codeSecretTag.leadingAnchor.constraint(equalTo: codeTitleLabel.trailingAnchor, constant: 4),
            codeSecretTag.centerYAnchor.constraint(equalTo: codeTitleLabel.centerYAnchor),
            codeSecretTag.trailingAnchor.constraint(lessThanOrEqualTo: codeNameCard.trailingAnchor, constant: -10),

            // Seed phrase name value and arrow
            codeValueLabel.topAnchor.constraint(equalTo: codeTitleLabel.bottomAnchor, constant: 8),
            codeValueLabel.leadingAnchor.constraint(equalTo: codeNameCard.leadingAnchor, constant: 12),
            codeValueLabel.trailingAnchor.constraint(equalTo: codeEditArrow.leadingAnchor, constant: -8),
            codeValueLabel.bottomAnchor.constraint(equalTo: codeNameCard.bottomAnchor, constant: -12),

            codeEditArrow.trailingAnchor.constraint(equalTo: codeNameCard.trailingAnchor, constant: -4),
            codeEditArrow.centerYAnchor.constraint(equalTo: codeValueLabel.centerYAnchor),
            codeEditArrow.widthAnchor.constraint(equalToConstant: 20),
            codeEditArrow.heightAnchor.constraint(equalToConstant: 20),

            // Location info card
            locationsCard.topAnchor.constraint(equalTo: codeNameCard.bottomAnchor, constant: 12),
            locationsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            locationsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            locationsHeaderTitle.topAnchor.constraint(equalTo: locationsCard.topAnchor, constant: 12),
            locationsHeaderTitle.leadingAnchor.constraint(equalTo: locationsCard.leadingAnchor, constant: 12),

            locationsPrivateBadge.centerYAnchor.constraint(equalTo: locationsHeaderTitle.centerYAnchor),
            locationsPrivateBadge.leadingAnchor.constraint(equalTo: locationsHeaderTitle.trailingAnchor, constant: 4),
            locationsPrivateBadge.trailingAnchor.constraint(lessThanOrEqualTo: locationsCard.trailingAnchor, constant: -10),

            locationsStackView.topAnchor.constraint(equalTo: locationsHeaderTitle.bottomAnchor, constant: 12),
            locationsStackView.leadingAnchor.constraint(equalTo: locationsCard.leadingAnchor, constant: 12),
            locationsStackView.trailingAnchor.constraint(equalTo: locationsCard.trailingAnchor, constant: -4),
            locationsStackView.bottomAnchor.constraint(equalTo: locationsCard.bottomAnchor, constant: -12),

            // Confirmation checkbox (reduced margins by 1/3)
            confirmationContainer.topAnchor.constraint(equalTo: locationsCard.bottomAnchor, constant: 10),
            confirmationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            confirmationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            confirmationCheckbox.leadingAnchor.constraint(equalTo: confirmationContainer.leadingAnchor),
            confirmationCheckbox.topAnchor.constraint(equalTo: confirmationContainer.topAnchor),
            confirmationCheckbox.bottomAnchor.constraint(equalTo: confirmationContainer.bottomAnchor),
            confirmationCheckbox.widthAnchor.constraint(equalToConstant: 24),
            confirmationCheckbox.heightAnchor.constraint(equalToConstant: 24),

            confirmationLabel.leadingAnchor.constraint(equalTo: confirmationCheckbox.trailingAnchor, constant: 8),
            confirmationLabel.centerYAnchor.constraint(equalTo: confirmationCheckbox.centerYAnchor),
            confirmationLabel.trailingAnchor.constraint(lessThanOrEqualTo: confirmationContainer.trailingAnchor),

            // Validation error label
            validationErrorLabel.topAnchor.constraint(equalTo: confirmationContainer.bottomAnchor, constant: 8),
            validationErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            validationErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Confirm button
            nextButton.topAnchor.constraint(equalTo: validationErrorLabel.bottomAnchor, constant: 12),
            nextButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupCodeNameTapGesture() {
        // Add tap gesture to entire seed phrase name card
        codeNameCard.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(codeNameTapped))
        codeNameCard.addGestureRecognizer(tapGesture)
    }

    @objc private func codeNameTapped() {
        #if DEBUG
        WujiLogger.debug("User tapped seed phrase name, preparing to edit")
        #endif

        // Create NameSaltViewController and set to edit mode
        let nameSaltVC = NameSaltViewController()
        nameSaltVC.isPresentedForEditing = true
        nameSaltVC.existingInputString = SessionStateManager.shared.name?.normalized ?? ""

        // Set completion callback
        nameSaltVC.onEditingComplete = { [weak self] newCodeName in
            #if DEBUG
            WujiLogger.success("Seed phrase name updated: \(newCodeName)")
            #endif
            self?.loadCodeName()
            // Regenerate position code (code name change may affect generation result)
            self?.startGeneration()
        }

        // Wrap with UINavigationController, present modally
        let navController = UINavigationController(rootViewController: nameSaltVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true, completion: nil)
    }

    private func loadCodeName() {
        // Get code name from SessionStateManager
        let codeName = SessionStateManager.shared.name?.normalized ?? ""
        if codeName.isEmpty {
            codeValueLabel.text = Lang("places.confirm.name_not_set")
            codeValueLabel.textColor = Theme.MinimalTheme.textSecondary
        } else {
            // Use monospace font with letter spacing for code name (same as memory fragments)
            codeValueLabel.attributedText = createMemoryFragmentText(codeName)
        }
    }


    private func populateLocations() {
        for (index, location) in locations.enumerated() {
            // Add location view
            let locationView = createCompactLocationView(index: index + 1, location: location)
            locationsStackView.addArrangedSubview(locationView)

            // Add separator after non-last locations
            if index < locations.count - 1 {
                let separator = createSeparatorView()
                locationsStackView.addArrangedSubview(separator)
            }
        }
    }

    private func createSeparatorView() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let line = UIView()
        line.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.15)
        line.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(line)

        NSLayoutConstraint.activate([
            // Separator height is 1pt
            container.heightAnchor.constraint(equalToConstant: 1.0),

            // Line aligned with content area left and right
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            line.topAnchor.constraint(equalTo: container.topAnchor),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createCompactLocationView(index: Int, location: PlacesInputViewController.PlaceData) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear  // Flat design: transparent background

        // Add tap functionality
        container.isUserInteractionEnabled = true
        container.tag = index - 1  // Store location index (0-4)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(locationItemTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        // Info stack (coordinates with icon first, then two memory fragments)
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 6
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        // First line: Map pin icon + Coordinates (horizontal stack)
        let coordRow = UIStackView()
        coordRow.axis = .horizontal
        coordRow.spacing = 6
        coordRow.alignment = .center

        // Map pin icon (Google Maps style)
        let mapPinIcon: UIImageView
        if #available(iOS 13.0, *) {
            mapPinIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
            mapPinIcon.tintColor = Theme.Colors.subtitleText
        } else {
            mapPinIcon = UIImageView()
            let pinLabel = UILabel()
            pinLabel.text = "📍"
            pinLabel.font = UIFont.systemFont(ofSize: 14)
            mapPinIcon.addSubview(pinLabel)
        }
        mapPinIcon.contentMode = .scaleAspectFit
        mapPinIcon.translatesAutoresizingMaskIntoConstraints = false
        mapPinIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        mapPinIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let coordLabel = UILabel()
        coordLabel.text = location.coordinateString
        coordLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        coordLabel.textColor = Theme.Colors.subtitleText
        coordLabel.numberOfLines = 1

        coordRow.addArrangedSubview(mapPinIcon)
        coordRow.addArrangedSubview(coordLabel)

        // Memory 1 (second line) - display as tag chips
        let memory1Container = createTagContainerView(tags: location.memory1Tags, isError: false)

        // Memory 2 (third line) - display as tag chips
        let memory2Container = createTagContainerView(tags: location.memory2Tags, isError: false)

        // Store references for error highlighting
        coordLabels[index - 1] = coordLabel
        memory1Views[index - 1] = memory1Container
        memory2Views[index - 1] = memory2Container

        infoStack.addArrangedSubview(coordRow)
        infoStack.addArrangedSubview(memory1Container)
        infoStack.addArrangedSubview(memory2Container)

        // Right arrow icon
        let arrowIcon: UIImageView
        if #available(iOS 13.0, *) {
            arrowIcon = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrowIcon.tintColor = Theme.MinimalTheme.textSecondary
        } else {
            let arrow = UILabel()
            arrow.text = "›"
            arrow.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            arrow.textColor = Theme.MinimalTheme.textSecondary
            arrowIcon = UIImageView()
            arrowIcon.addSubview(arrow)
        }
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        arrowIcon.contentMode = .scaleAspectFit

        container.addSubview(infoStack)
        container.addSubview(arrowIcon)

        NSLayoutConstraint.activate([
            // Info: left aligned, before arrow, with compact top/bottom padding
            infoStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            infoStack.trailingAnchor.constraint(equalTo: arrowIcon.leadingAnchor, constant: 0),
            infoStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            infoStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),

            // Arrow: right side, vertically centered
            arrowIcon.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            arrowIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            arrowIcon.widthAnchor.constraint(equalToConstant: 20),
            arrowIcon.heightAnchor.constraint(equalToConstant: 20)
        ])

        return container
    }

    /// Create attributed text for memory fragments with monospace font and letter spacing
    private func createMemoryFragmentText(_ text: String, isError: Bool = false) -> NSAttributedString {
        // Use monospace font (SF Mono or Menlo) for precise character display
        let monoFont: UIFont
        if #available(iOS 13.0, *) {
            monoFont = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        } else {
            monoFont = UIFont(name: "Menlo-Bold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .medium)
        }

        let textColor = isError ? UIColor.systemRed : Theme.Colors.elegantBlue

        let attributes: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: textColor,
            .kern: 1.5  // Letter spacing to emphasize each character
        ]

        return NSAttributedString(string: text, attributes: attributes)
    }

    /// Create a horizontal container view with tag chips
    private func createTagContainerView(tags: [String], isError: Bool) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 6
        container.alignment = .center

        let textColor = isError ? UIColor.systemRed : Theme.Colors.elegantBlue
        let bgColor = isError ? UIColor.systemRed.withAlphaComponent(0.1) : Theme.Colors.elegantBlue.withAlphaComponent(0.1)

        for tag in tags {
            let chipView = UIView()
            chipView.backgroundColor = bgColor
            chipView.layer.cornerRadius = 4
            chipView.layer.masksToBounds = true
            // Prevent chip from stretching
            chipView.setContentHuggingPriority(.required, for: .horizontal)
            chipView.setContentCompressionResistancePriority(.required, for: .horizontal)

            let label = UILabel()
            label.text = tag
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.textColor = textColor
            label.translatesAutoresizingMaskIntoConstraints = false

            chipView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: chipView.topAnchor, constant: 2),
                label.bottomAnchor.constraint(equalTo: chipView.bottomAnchor, constant: -2),
                label.leadingAnchor.constraint(equalTo: chipView.leadingAnchor, constant: 6),
                label.trailingAnchor.constraint(equalTo: chipView.trailingAnchor, constant: -6)
            ])

            container.addArrangedSubview(chipView)
        }

        // Add spacer to absorb extra space (prevents chips from stretching)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        container.addArrangedSubview(spacer)

        return container
    }

    /// Update tag container view with new error state
    private func updateTagContainerView(_ container: UIView, tags: [String], isError: Bool) {
        guard let stackView = container as? UIStackView else { return }

        // Remove all existing subviews
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let textColor = isError ? UIColor.systemRed : Theme.Colors.elegantBlue
        let bgColor = isError ? UIColor.systemRed.withAlphaComponent(0.1) : Theme.Colors.elegantBlue.withAlphaComponent(0.1)

        for tag in tags {
            let chipView = UIView()
            chipView.backgroundColor = bgColor
            chipView.layer.cornerRadius = 4
            chipView.layer.masksToBounds = true
            // Prevent chip from stretching
            chipView.setContentHuggingPriority(.required, for: .horizontal)
            chipView.setContentCompressionResistancePriority(.required, for: .horizontal)

            let label = UILabel()
            label.text = tag
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.textColor = textColor
            label.translatesAutoresizingMaskIntoConstraints = false

            chipView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: chipView.topAnchor, constant: 2),
                label.bottomAnchor.constraint(equalTo: chipView.bottomAnchor, constant: -2),
                label.leadingAnchor.constraint(equalTo: chipView.leadingAnchor, constant: 6),
                label.trailingAnchor.constraint(equalTo: chipView.trailingAnchor, constant: -6)
            ])

            stackView.addArrangedSubview(chipView)
        }

        // Add spacer to absorb extra space (prevents chips from stretching)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(spacer)
    }

    // MARK: - Generation

    private func startGeneration() {
        // Process 5 location data, generate position sequence
        var spots: [WujiSpot] = []
        for location in locations {
            // Use processed (merged, sorted + concatenated) memory string for crypto operations
            guard let spot = WujiSpot(
                coordinates: location.coordinateString,
                memory: location.memoryProcessed
            ) else {
                showError(Lang("places.error.process_failed"))
                return
            }
            spots.append(spot)
        }

        // Use WujiSpot to process
        guard case .success(let processResult) = WujiSpot.process(spots) else {
            showError(Lang("places.error.process_failed"))
            return
        }

        // Extract position sequence
        positionSequence = processResult.positionCodes.map { String($0) }.joined()
    }

    private func displaySuccess() {
        // Display Toast message
        displayToastMessage("✅ Calculation complete (\(String(format: "%.2f", calculationTime))s)", duration: 3.0)

        // Validate locations for duplicates
        validateLocations()
    }

    // MARK: - Validation

    /// Validate locations for duplicate memories and cellIndex
    private func validateLocations() {
        var errors: [String] = []

        // Track which items have errors for highlighting
        var errorMemory1: Set<Int> = []
        var errorMemory2: Set<Int> = []
        var errorCoord: Set<Int> = []

        // Collect all processed memories (merged memory1 + memory2 tags)
        var allProcessedMemories: [(index: Int, value: String)] = []
        // Collect all cellIndex values
        var allCellIndices: [(index: Int, value: Int64)] = []

        for (i, location) in locations.enumerated() {
            // Use tag arrays directly (already normalized)
            let memory1Tags = location.memory1Tags
            let memory2Tags = location.memory2Tags

            // Check minimum tag count (at least 1 keyword, max 3 enforced by UI)
            if memory1Tags.count < 1 {
                errors.append(Lang("places.error.memory_tags_too_few") + " (\(Lang("common.location"))\(i + 1) \(Lang("common.memory1")))")
                errorMemory1.insert(i)
            }
            if memory2Tags.count < 1 {
                errors.append(Lang("places.error.memory_tags_too_few") + " (\(Lang("common.location"))\(i + 1) \(Lang("common.memory2")))")
                errorMemory2.insert(i)
            }

            // Use merged processed string for duplicate checking
            allProcessedMemories.append((i, location.memoryProcessed))

            // Check coordinate precision
            if let precisionError = validateCoordinatePrecision(location.coordinateString, locationIndex: i + 1) {
                errors.append(precisionError)
                errorCoord.insert(i)
            }

            // Get cellIndex
            if let place = WujiPlace(from: location.coordinateString) {
                if let cellIndex = place.cell()?.index {
                    allCellIndices.append((i, cellIndex))
                }
            }
        }

        // Check for duplicate memories (merged memory strings)
        var seenMemories: [String: Int] = [:]
        for memory in allProcessedMemories {
            if let existingIndex = seenMemories[memory.value] {
                let loc1 = existingIndex + 1
                let loc2 = memory.index + 1
                // Different locations have same merged memory
                errors.append(Lang("places.error.duplicate_memory") + " (\(Lang("common.location"))\(loc1) = \(Lang("common.location"))\(loc2))")
                // Mark both locations' memories as error
                errorMemory1.insert(existingIndex)
                errorMemory2.insert(existingIndex)
                errorMemory1.insert(memory.index)
                errorMemory2.insert(memory.index)
            } else {
                seenMemories[memory.value] = memory.index
            }
        }

        // Check for duplicate cellIndex
        var seenCellIndices: [Int64: Int] = [:]
        for cellData in allCellIndices {
            if let existingIndex = seenCellIndices[cellData.value] {
                let loc1 = existingIndex + 1
                let loc2 = cellData.index + 1
                errors.append(Lang("places.error.duplicate_cellindex") + " (\(Lang("common.location"))\(loc1), \(Lang("common.location"))\(loc2))")
                // Mark both duplicate coordinates
                errorCoord.insert(existingIndex)
                errorCoord.insert(cellData.index)
            } else {
                seenCellIndices[cellData.value] = cellData.index
            }
        }

        // Update view colors based on errors
        for i in 0..<locations.count {
            // Reset to normal first, then apply error color if needed
            if let view = memory1Views[i] {
                updateTagContainerView(view, tags: locations[i].memory1Tags, isError: errorMemory1.contains(i))
            }
            if let view = memory2Views[i] {
                updateTagContainerView(view, tags: locations[i].memory2Tags, isError: errorMemory2.contains(i))
            }
            if let label = coordLabels[i] {
                if errorCoord.contains(i) {
                    label.textColor = .systemRed
                } else {
                    label.textColor = Theme.Colors.subtitleText
                }
            }
        }

        // Update UI based on validation result
        if errors.isEmpty {
            validationError = nil
            validationErrorLabel.isHidden = true
            validationErrorLabel.text = nil
            // Enable checkbox interaction
            confirmationCheckbox.isEnabled = true
            confirmationContainer.alpha = 1.0
        } else {
            validationError = errors.joined(separator: "\n")
            validationErrorLabel.text = "⚠️ " + errors.joined(separator: "\n")
            validationErrorLabel.isHidden = false
            // Disable checkbox and button
            confirmationCheckbox.isEnabled = false
            confirmationCheckbox.isSelected = false
            confirmationContainer.alpha = 0.5
            nextButton.isEnabled = false
            nextButton.backgroundColor = Theme.Colors.disabledButtonBackground
        }
    }

    /// Validate coordinate precision (minimum 11.8m accuracy)
    /// - DD format: at least 4 decimal places
    /// - DMS format: seconds must have decimal point
    private func validateCoordinatePrecision(_ coordinateString: String, locationIndex: Int) -> String? {
        let trimmed = coordinateString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if it's DMS format (contains degree symbol)
        if trimmed.contains("°") {
            // DMS format: check if seconds have decimal point
            // Pattern to find seconds values: number followed by " or ″
            let dmsPattern = #"(\d+(?:\.\d+)?)[\"″]"#
            guard let regex = try? NSRegularExpression(pattern: dmsPattern, options: []) else {
                return nil
            }

            let nsString = trimmed as NSString
            let matches = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let secondsStr = nsString.substring(with: match.range(at: 1))
                // Check if seconds have decimal point
                if !secondsStr.contains(".") {
                    return Lang("places.error.dms_precision") + " (\(Lang("common.location"))\(locationIndex))"
                }
            }
        } else {
            // DD format: check decimal places
            // Normalize comma
            let normalized = trimmed.replacingOccurrences(of: "，", with: ",")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "（", with: "")
                .replacingOccurrences(of: "）", with: "")

            let parts = normalized.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { return nil }

            for (index, part) in parts.enumerated() {
                // Find decimal point and count digits after it
                if let dotIndex = part.firstIndex(of: ".") {
                    let decimalPart = part[part.index(after: dotIndex)...]
                    // Filter only digits
                    let digits = decimalPart.filter { $0.isNumber }
                    if digits.count < 4 {
                        let coordName = index == 0 ? Lang("common.latitude") : Lang("common.longitude")
                        return Lang("places.error.dd_precision") + " (\(Lang("common.location"))\(locationIndex) \(coordName))"
                    }
                } else {
                    // No decimal point at all
                    let coordName = index == 0 ? Lang("common.latitude") : Lang("common.longitude")
                    return Lang("places.error.dd_precision") + " (\(Lang("common.location"))\(locationIndex) \(coordName))"
                }
            }
        }

        return nil
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: Lang("common.error"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default))
        present(alert, animated: true)
    }

    private func showArgon2FailureAlert() {
        let alert = UIAlertController(
            title: Lang("places.error.argon2_title"),
            message: Lang("places.error.argon2_message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Lang("common.got_it"), style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func locationItemTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        let locationIndex = tappedView.tag

        // Add professional tap feedback animation (scale + highlight)
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            tappedView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            tappedView.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.05, options: [.curveEaseIn], animations: {
                tappedView.transform = .identity
                tappedView.alpha = 1.0
            }, completion: nil)
        }

        // Delay showing edit page, let animation complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.presentLocationEdit(locationIndex: locationIndex)
        }
    }

    private func presentLocationEdit(locationIndex: Int) {
        guard locationIndex >= 0 && locationIndex < locations.count else { return }
        let location = locations[locationIndex]

        #if DEBUG
        WujiLogger.debug("Editing location \(locationIndex + 1): memo1Tags=\(location.memory1Tags), memo2Tags=\(location.memory2Tags)")
        #endif

        // Create edit page
        let editVC = SingleLocationEditViewController()
        editVC.locationIndex = locationIndex
        editVC.existingLocation = location

        // Set completion callback
        editVC.onEditingComplete = { [weak self] updatedLocation in
            guard let self = self else { return }
            #if DEBUG
            WujiLogger.success("Location \(locationIndex + 1) updated")
            #endif

            // Update data
            self.locations[locationIndex] = updatedLocation

            // Refresh display
            self.refreshLocationsDisplay()

            // Regenerate position code (location change affects generation result)
            self.startGeneration()
        }

        // Wrap with UINavigationController, present modally
        let navController = UINavigationController(rootViewController: editVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true, completion: nil)
    }

    private func refreshLocationsDisplay() {
        // Clear existing views
        locationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Clear label references
        memory1Views.removeAll()
        memory2Views.removeAll()
        coordLabels.removeAll()

        // Refill
        populateLocations()

        // Re-validate immediately to highlight errors
        validateLocations()
    }

    @objc private func confirmationCheckboxTapped() {
        confirmationCheckbox.isSelected.toggle()

        // Enable/disable next button based on checkbox state
        if confirmationCheckbox.isSelected {
            nextButton.isEnabled = true
            nextButton.backgroundColor = Theme.Colors.elegantBlue
        } else {
            nextButton.isEnabled = false
            nextButton.backgroundColor = Theme.Colors.disabledButtonBackground
        }
    }

    @objc private func nextButtonTapped() {
        guard confirmationCheckbox.isSelected else {
            displayToastMessage(Lang("places.confirm.toast_check_first"), duration: 2.0)
            return
        }

        // Disable button to prevent repeated taps
        nextButton.isEnabled = false
        nextButton.backgroundColor = Theme.Colors.disabledButtonBackground

        // Show loading state (with spinning progress)
        showLoadingIndicator(message: Lang("common.loading"))

        // Start Argon2 encryption
        performFinalEncryption()
    }

    private func performFinalEncryption() {
        // Process 5 location data
        #if DEBUG
        WujiLogger.debug("Processing location data...")
        WujiLogger.debug("   Location count: \(locations.count)")
        #endif

        var spots: [WujiSpot] = []
        for (index, location) in locations.enumerated() {
            #if DEBUG
            WujiLogger.debug("   Location \(index + 1):")
            WujiLogger.debug("     Coordinates: \"\(location.coordinateString)\"")
            WujiLogger.debug("     Memo1Tags: \(location.memory1Tags)")
            WujiLogger.debug("     Memo2Tags: \(location.memory2Tags)")
            WujiLogger.debug("     MemoryProcessed: \"\(location.memoryProcessed)\"")
            WujiLogger.debug("     latitude: \"\(location.latitude)\"")
            WujiLogger.debug("     longitude: \"\(location.longitude)\"")
            #endif

            guard let spot = WujiSpot(
                coordinates: location.coordinateString,
                memory: location.memoryProcessed
            ) else {
                #if DEBUG
                WujiLogger.error("WujiSpot creation failed: location \(index + 1)")
                #endif
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoadingIndicator()
                    self?.showError("Location data processing failed, check console logs")
                    self?.nextButton.isEnabled = true
                    self?.nextButton.backgroundColor = Theme.Colors.elegantBlue
                }
                return
            }
            spots.append(spot)
        }

        // Use WujiSpot to process
        #if DEBUG
        WujiLogger.debug("Calling WujiSpot.process...")
        #endif
        guard case .success(let processResult) = WujiSpot.process(spots) else {
            #if DEBUG
            WujiLogger.error("WujiSpot.process returned failure")
            #endif
            DispatchQueue.main.async { [weak self] in
                self?.hideLoadingIndicator()
                self?.showError("Location data processing failed, check console logs")
                self?.nextButton.isEnabled = true
                self?.nextButton.backgroundColor = Theme.Colors.elegantBlue
            }
            return
        }
        #if DEBUG
        WujiLogger.success("WujiSpot.process succeeded")
        #endif

        let passwordData = processResult.combinedData
        guard let wujiName = SessionStateManager.shared.name else {
            #if DEBUG
            WujiLogger.error("Error: WujiName is empty!")
            #endif
            DispatchQueue.main.async { [weak self] in
                self?.hideLoadingIndicator()
                self?.showError("Encryption failed: internal state error (name is empty), please restart the process")
                self?.nextButton.isEnabled = true
                self?.nextButton.backgroundColor = Theme.Colors.elegantBlue
            }
            return
        }
        let salt = wujiName.salt
        let parameters = CryptoUtils.Argon2Parameters.standard

        #if DEBUG
        WujiLogger.debug("Starting final encryption...")
        WujiLogger.debug("   Params: m=\(parameters.memoryKB)KB, t=\(parameters.iterations), p=\(parameters.parallelism)")
        WujiLogger.debug("   Password length: \(passwordData.count) bytes")
        WujiLogger.debug("   Salt length: \(salt.count) bytes")
        #endif

        if passwordData.isEmpty {
            #if DEBUG
            WujiLogger.error("Error: password is empty!")
            #endif
            DispatchQueue.main.async { [weak self] in
                self?.hideLoadingIndicator()
                self?.showError("Encryption failed: location data is empty")
                self?.nextButton.isEnabled = true
                self?.nextButton.backgroundColor = Theme.Colors.elegantBlue
            }
            return
        }

        #if DEBUG
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        WujiLogger.info("🔐 Starting Argon2id calculation")
        WujiLogger.info("   Params: memory=\(CryptoUtils.WujiArgon2idMem / 1024)MB, iterations=\(CryptoUtils.WujiArgon2idTimes), parallelism=\(CryptoUtils.WujiArgon2idParallel)")
        WujiLogger.info("   Estimated time: 20-40s (depends on device performance)")
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        let startTime = Date()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Run Argon2id
            guard let keyData = CryptoUtils.argon2id(
                password: passwordData,
                salt: salt,
                parameters: parameters
            ) else {
                let failedTime = Date().timeIntervalSince(startTime)
                #if DEBUG
                WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                WujiLogger.error("❌ Argon2id calculation failed")
                WujiLogger.error("   Failed at: \(String(format: "%.2f", failedTime))s")
                WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                #endif

                DispatchQueue.main.async {
                    self.hideLoadingIndicator()
                    self.showArgon2FailureAlert()
                    self.nextButton.isEnabled = true
                    self.nextButton.backgroundColor = Theme.Colors.elegantBlue
                }
                return
            }

            let elapsedTime = Date().timeIntervalSince(startTime)

            #if DEBUG
            WujiLogger.success("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            WujiLogger.success("✅ Argon2id calculation complete!")
            WujiLogger.success("   Actual time: \(String(format: "%.2f", elapsedTime))s")
            WujiLogger.success("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            DispatchQueue.main.async {
                self.calculationTime = elapsedTime

                // Clear draft
                UserDefaults.standard.removeObject(forKey: "Places_LocationsDraft")
                UserDefaults.standard.removeObject(forKey: "Places_LocationsDraft_currentIndex")

                // Note: Don't clear progress, user is still in wizard flow
                // Progress will continue to update in subsequent steps

                // Remove loading indicator
                self.hideLoadingIndicator()

                // Save position codes and keyMaterials to SessionStateManager (for backup)
                SessionStateManager.shared.positionCodes = processResult.positionCodes
                SessionStateManager.shared.keyMaterials = processResult.keyMaterials

                // Execute different logic based on mode
                if self.isRecoveryMode {
                    // Recovery mode: Try to decrypt all backup packages
                    self.attemptRecovery(positionCodes: processResult.positionCodes)
                } else if self.isImportMode {
                    // Import mode: Jump directly to backup page
                    self.navigateToBackup()
                } else {
                    // Normal mode: Go to backup page first, then show seed phrase
                    self.navigateToBackupFirst(keyData: keyData)
                }

                // Restore button state
                self.nextButton.isEnabled = true
                self.nextButton.backgroundColor = Theme.Colors.elegantBlue
            }
        }
    }

    // MARK: - Toast Message

    private func displayToastMessage(_ message: String, duration: TimeInterval = 3.0) {
        // Remove old toast (if exists)
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }

        let toastContainer = UIView()
        toastContainer.tag = 9999
        toastContainer.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        toastContainer.layer.cornerRadius = 10
        toastContainer.alpha = 0.0
        toastContainer.isUserInteractionEnabled = false  // Don't block user interaction
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false

        toastContainer.addSubview(toastLabel)
        view.addSubview(toastContainer)

        NSLayoutConstraint.activate([
            toastContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: 12),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -12),
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: 16),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -16)
        ])

        // Animate display
        UIView.animate(withDuration: 0.3, animations: {
            toastContainer.alpha = 1.0
        }) { _ in
            // Auto dismiss
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                toastContainer.alpha = 0.0
            }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }

    /// Show loading indicator with spinning progress
    private func showLoadingIndicator(message: String) {
        // Remove old loading view (if exists)
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }

        let loadingContainer = UIView()
        loadingContainer.tag = 9999
        loadingContainer.backgroundColor = UIColor(white: 0.2, alpha: 0.9)
        loadingContainer.layer.cornerRadius = 12
        loadingContainer.alpha = 0.0
        loadingContainer.isUserInteractionEnabled = false  // Don't block user interaction
        loadingContainer.translatesAutoresizingMaskIntoConstraints = false

        // Spinning progress indicator
        let activityIndicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.color = .white
        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()

        // Message text
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        loadingContainer.addSubview(activityIndicator)
        loadingContainer.addSubview(messageLabel)
        view.addSubview(loadingContainer)

        NSLayoutConstraint.activate([
            loadingContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingContainer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            loadingContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            activityIndicator.topAnchor.constraint(equalTo: loadingContainer.topAnchor, constant: 16),
            activityIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: loadingContainer.bottomAnchor, constant: -16),
            messageLabel.leadingAnchor.constraint(equalTo: loadingContainer.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: loadingContainer.trailingAnchor, constant: -20)
        ])

        // Animate display
        UIView.animate(withDuration: 0.3) {
            loadingContainer.alpha = 1.0
        }
    }

    /// Hide loading indicator
    private func hideLoadingIndicator() {
        view.subviews.filter { $0.tag == 9999 }.forEach { loadingView in
            UIView.animate(withDuration: 0.3, animations: {
                loadingView.alpha = 0.0
            }) { _ in
                loadingView.removeFromSuperview()
            }
        }
    }

    // MARK: - Navigation

    /// Navigate to backup page first (normal generation flow)
    /// New flow: Confirm → Backup → Show24 → Done
    private func navigateToBackupFirst(keyData: Data) {
        // Generate mnemonics first
        guard let mnemonics = BIP39Helper.generate24Words(from: keyData) else {
            showError(Lang("places.error.mnemonic_failed"))
            return
        }

        // Save mnemonics to SessionStateManager
        SessionStateManager.shared.mnemonics = mnemonics

        // Create BackupViewController
        let backupVC = BackupViewController()
        backupVC.codeName = SessionStateManager.shared.name?.normalized ?? ""
        backupVC.mnemonics = mnemonics
        backupVC.positionCodes = SessionStateManager.shared.positionCodes
        backupVC.keyMaterials = SessionStateManager.shared.keyMaterials
        backupVC.wujiName = SessionStateManager.shared.name
        backupVC.isFromGeneration = true  // Flag to indicate this is from normal generation flow

        navigationController?.pushViewController(backupVC, animated: true)

        #if DEBUG
        WujiLogger.info("Normal mode: navigating to backup page first")
        #endif
    }

    /// Navigate to seed phrase display page (legacy, kept for reference)
    private func navigateToShow24(keyData: Data) {
        let show24VC = Show24ViewController()
        show24VC.masterPassword = keyData
        show24VC.positionSequence = Array(self.positionSequence).compactMap { Int(String($0)) }  // Pass position sequence
        show24VC.codeName = SessionStateManager.shared.name?.normalized ?? ""  // Pass code name
        navigationController?.pushViewController(show24VC, animated: true)
    }

    /// Navigate to backup page (import mode)
    private func navigateToBackup() {
        let backupVC = BackupViewController()
        backupVC.mnemonics = SessionStateManager.shared.mnemonics
        backupVC.positionCodes = SessionStateManager.shared.positionCodes
        backupVC.keyMaterials = SessionStateManager.shared.keyMaterials
        navigationController?.pushViewController(backupVC, animated: true)

        #if DEBUG
        WujiLogger.info("Import mode: jumping to backup page")
        #endif
    }

    /// Try to recover backup (recovery mode)
    /// Uses WujiSpot to allow cellIndex correction during decryption
    private func attemptRecovery(positionCodes: [Int]) {
        #if DEBUG
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        WujiLogger.info("🔓 Starting backup decryption (WujiReserve)")
        WujiLogger.info("   Position codes: \(positionCodes)")
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        // Get backup data from SessionStateManager
        guard let reserveData = SessionStateManager.shared.reserveData,
              let capsuleData = reserveData.encode() else {
            #if DEBUG
            WujiLogger.error("Error: backup data not found")
            #endif
            showAlert(title: Lang("common.error"), message: Lang("places.error.no_backup"))
            return
        }

        // Validate locations count
        guard locations.count == 5 else {
            #if DEBUG
            WujiLogger.error("Error: locations count incorrect: \(locations.count)")
            #endif
            showAlert(title: Lang("common.error"), message: Lang("places.error.location_count"))
            return
        }

        // Convert PlaceData to WujiSpot
        var spots: [WujiSpot] = []
        for placeData in locations {
            guard let spot = WujiSpot(
                coordinates: "\(placeData.latitude), \(placeData.longitude)",
                memory: placeData.memoryProcessed
            ) else {
                #if DEBUG
                WujiLogger.error("Error: failed to create WujiSpot")
                #endif
                showAlert(title: Lang("common.error"), message: Lang("places.error.parse_failed"))
                return
            }
            spots.append(spot)
        }

        #if DEBUG
        WujiLogger.info("Backup data found: \(capsuleData.count) bytes")
        WujiLogger.info("Parsed spots count: \(spots.count)")
        #endif

        // Get name salt (generated in NameSalt)
        guard let wujiName = SessionStateManager.shared.name else {
            #if DEBUG
            WujiLogger.error("Error: WujiName not set")
            #endif
            showAlert(title: Lang("common.error"), message: Lang("places.error.name_data"))
            return
        }
        let nameSalt = wujiName.salt

        // Decrypt using WujiReserve (with cellIndex correction support)
        let result = WujiReserve.decrypt(
            data: capsuleData,
            spots: spots,
            positionCodes: positionCodes,
            nameSalt: nameSalt
        )

        switch result {
        case .success(let output):
            #if DEBUG
            WujiLogger.success("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            WujiLogger.success("✅ Decryption successful!")
            WujiLogger.success("   Recovered mnemonic count: \(output.mnemonics.count)")
            WujiLogger.success("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            // Save to SessionStateManager
            SessionStateManager.shared.mnemonics = output.mnemonics

            // Navigate to seed phrase display page (recovery mode)
            let show24VC = Show24ViewController()
            show24VC.mnemonics = output.mnemonics
            show24VC.isFromRecover = true
            navigationController?.pushViewController(show24VC, animated: true)

        case .failure(let error):
            #if DEBUG
            WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            WujiLogger.error("❌ Decryption failed: \(error.localizedDescription)")
            WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            showAlert(
                title: Lang("places.error.decrypt_failed_title"),
                message: Lang("places.error.decrypt_failed_message")
            )
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SingleLocationEditViewController

/// Single location edit controller (for present mode)
class SingleLocationEditViewController: KeyboardAwareViewController {

    // MARK: - Properties

    var locationIndex: Int = 0
    var existingLocation: PlacesInputViewController.PlaceData?
    var onEditingComplete: ((PlacesInputViewController.PlaceData) -> Void)?

    // MARK: - UI Components

    private var locationInputView: PlaceInputRowView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Display edit location title (no number shown, minimize order emphasis)
        navigationItem.title = Lang("places.confirm.edit_location")

        // Left cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Lang("common.cancel"), style: .plain, target: self, action: #selector(cancelTapped))

        setupInputView()
    }

    // MARK: - Setup

    private func setupInputView() {
        locationInputView = PlaceInputRowView()
        locationInputView.locationIndex = locationIndex
        locationInputView.buttonTitle = Lang("common.confirm")  // Change button to "Confirm" in edit mode

        // Pre-fill existing data
        if let location = existingLocation {
            // Parse coordinate string
            let coords = parseCoordinateString(location.coordinateString)
            locationInputView.latitudeText = coords.latitude
            locationInputView.longitudeText = coords.longitude
            locationInputView.memory1Tags = location.memory1Tags
            locationInputView.memory2Tags = location.memory2Tags
        }

        // Set completion callback
        locationInputView.onComplete = { [weak self] lat, lon, memory1Tags, memory2Tags in
            guard let self = self else { return }

            // Create updated data
            var updatedLocation = PlacesInputViewController.PlaceData()
            updatedLocation.latitude = lat
            updatedLocation.longitude = lon
            updatedLocation.memory1Tags = memory1Tags
            updatedLocation.memory2Tags = memory2Tags

            // Call callback
            self.onEditingComplete?(updatedLocation)

            // Dismiss
            self.dismiss(animated: true, completion: nil)
        }

        view.addSubview(locationInputView)
        locationInputView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationInputView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            locationInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            locationInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            locationInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Helper

    /// Parse coordinate string "lat, lon" into separate parts
    private func parseCoordinateString(_ coordinateString: String) -> (latitude: String, longitude: String) {
        let components = coordinateString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if components.count >= 2 {
            return (components[0], components[1])
        }
        return ("", "")
    }
}
