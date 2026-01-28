//
//  SecurityPreCheckViewController.swift
//  WujiKey
//
//  Security pre-check page shown on app launch
//

import UIKit

class SecurityPreCheckViewController: UIViewController {

    // MARK: - Properties

    /// When true, shows checkbox for "don't show again" option (used on app launch)
    /// When false, just shows simple "OK" button (used when manually opened)
    var showDontShowAgainOption: Bool = true

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 14.2, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
            imageView.image = UIImage(systemName: "checkerboard.shield", withConfiguration: config)
        } else if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
            imageView.image = UIImage(systemName: "checkmark.shield", withConfiguration: config)
        } else {
            // iOS 12 fallback - render emoji as image
            imageView.image = "🛡️".emojiToImage(size: CGSize(width: 60, height: 60))
        }
        imageView.tintColor = Theme.Colors.elegantBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = Theme.MinimalTheme.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let cardsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.distribution = .fill
        return stack
    }()

    // Checkbox container
    private let checkboxContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let dontShowCheckbox: UIButton = {
        let button = UIButton(type: .custom)

        if #available(iOS 13.0, *) {
            let uncheckedConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            let checkedConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

            let uncheckedImage = UIImage(systemName: "circle", withConfiguration: uncheckedConfig)
            let checkedImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkedConfig)

            button.setImage(uncheckedImage, for: .normal)
            button.setImage(checkedImage, for: .selected)
            button.tintColor = Theme.Colors.elegantBlue
        } else {
            button.setTitle("☐", for: .normal)
            button.setTitle("☑", for: .selected)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
            button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
            button.setTitleColor(Theme.Colors.elegantBlue, for: .selected)
        }

        return button
    }()

    private let checkboxLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = Theme.MinimalTheme.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    // Constraint that changes based on mode
    private var continueButtonTopConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        setupConstraints()
        updateLocalizedText()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(cardsStackView)

        if showDontShowAgainOption {
            // Show checkbox for "don't show again" option
            contentView.addSubview(checkboxContainer)
            checkboxContainer.addSubview(dontShowCheckbox)
            checkboxContainer.addSubview(checkboxLabel)

            dontShowCheckbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)

            // Make label tappable too
            let labelTap = UITapGestureRecognizer(target: self, action: #selector(checkboxTapped))
            checkboxLabel.isUserInteractionEnabled = true
            checkboxLabel.addGestureRecognizer(labelTap)

            // Button starts disabled
            continueButton.isEnabled = false
            continueButton.backgroundColor = Theme.Colors.disabledButtonBackground
        } else {
            // Simple mode - button is always enabled
            continueButton.isEnabled = true
            continueButton.backgroundColor = Theme.Colors.elegantBlue
        }

        contentView.addSubview(continueButton)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardsStackView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        // Base constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            cardsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            cardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            continueButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        if showDontShowAgainOption {
            // Checkbox mode - button below checkbox
            checkboxContainer.translatesAutoresizingMaskIntoConstraints = false
            dontShowCheckbox.translatesAutoresizingMaskIntoConstraints = false
            checkboxLabel.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                checkboxContainer.topAnchor.constraint(equalTo: cardsStackView.bottomAnchor, constant: 24),
                checkboxContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                checkboxContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

                dontShowCheckbox.leadingAnchor.constraint(equalTo: checkboxContainer.leadingAnchor),
                dontShowCheckbox.topAnchor.constraint(equalTo: checkboxContainer.topAnchor),
                dontShowCheckbox.bottomAnchor.constraint(equalTo: checkboxContainer.bottomAnchor),
                dontShowCheckbox.widthAnchor.constraint(equalToConstant: 24),
                dontShowCheckbox.heightAnchor.constraint(equalToConstant: 24),

                checkboxLabel.leadingAnchor.constraint(equalTo: dontShowCheckbox.trailingAnchor, constant: 8),
                checkboxLabel.centerYAnchor.constraint(equalTo: dontShowCheckbox.centerYAnchor),
                checkboxLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkboxContainer.trailingAnchor)
            ])

            continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: checkboxContainer.bottomAnchor, constant: 24)
        } else {
            // Simple mode - button directly below cards (smaller spacing)
            continueButtonTopConstraint = continueButton.topAnchor.constraint(equalTo: cardsStackView.bottomAnchor, constant: 16)
        }

        continueButtonTopConstraint?.isActive = true
    }

    private func updateLocalizedText() {
        titleLabel.text = Lang("security.title")

        if showDontShowAgainOption {
            checkboxLabel.text = Lang("security.checkbox_dontshow")
            continueButton.setTitle(Lang("security.continue"), for: .normal)
        } else {
            continueButton.setTitle(Lang("common.ok"), for: .normal)
        }

        // Clear existing cards
        cardsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Card 1: Use dedicated phone
        let card1 = createCheckCard(
            icon: "iphone",
            title: Lang("security.phone.title"),
            content: Lang("security.phone.content")
        )
        cardsStackView.addArrangedSubview(card1)

        // Card 2: Privacy settings check
        let card2 = createCheckCard(
            icon: "eye.slash",
            title: Lang("security.privacy.title"),
            content: Lang("security.privacy.content")
        )
        cardsStackView.addArrangedSubview(card2)

        // Card 3: Airplane mode
        let card3 = createCheckCard(
            icon: "airplane",
            title: Lang("security.airplane.title"),
            content: Lang("security.airplane.content")
        )
        cardsStackView.addArrangedSubview(card3)

        // Card 4: Offline guarantee
        let card4 = createCheckCard(
            icon: "wifi.slash",
            title: Lang("security.offline.title"),
            content: Lang("security.offline.content"),
            isHighlight: true
        )
        cardsStackView.addArrangedSubview(card4)
    }

    private func createCheckCard(icon: String, title: String, content: String, isHighlight: Bool = false) -> UIView {
        let card = UIView()
        card.backgroundColor = isHighlight
            ? UIColor(red: 0.93, green: 0.97, blue: 0.93, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        card.layer.cornerRadius = 12

        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
            iconView.image = UIImage(systemName: icon, withConfiguration: config)
        }
        iconView.tintColor = isHighlight ? UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0) : Theme.Colors.elegantBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        contentLabel.textColor = Theme.MinimalTheme.textSecondary
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            contentLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    // MARK: - Actions

    @objc private func checkboxTapped() {
        dontShowCheckbox.isSelected.toggle()

        // Enable/disable continue button based on checkbox state
        if dontShowCheckbox.isSelected {
            continueButton.isEnabled = true
            continueButton.backgroundColor = Theme.Colors.elegantBlue
        } else {
            continueButton.isEnabled = false
            continueButton.backgroundColor = Theme.Colors.disabledButtonBackground
        }
    }

    @objc private func continueTapped() {
        if showDontShowAgainOption {
            // Checkbox mode - must be checked
            guard dontShowCheckbox.isSelected else { return }
        }

        // Perform security check
        let result = SecurityChecker.shared.performSecurityCheck()

        if result.hasSecurityIssues {
            // Show warning alert
            showSecurityWarningAlert(result: result)
        } else {
            // No issues, proceed
            proceedAfterSecurityCheck()
        }
    }

    private func showSecurityWarningAlert(result: SecurityChecker.SecurityCheckResult) {
        // Build issue list
        var issueText = Lang("security.warning.message") + "\n\n"
        for key in result.getIssueKeys() {
            issueText += Lang(key) + "\n"
        }

        let alert = UIAlertController(
            title: Lang("security.warning.title"),
            message: issueText,
            preferredStyle: .alert
        )

        // Go back button (preferred action)
        let goBackAction = UIAlertAction(
            title: Lang("security.warning.go_back"),
            style: .cancel,
            handler: nil
        )
        alert.addAction(goBackAction)

        // Continue anyway button (destructive)
        let continueAction = UIAlertAction(
            title: Lang("security.warning.continue_anyway"),
            style: .destructive
        ) { [weak self] _ in
            self?.proceedAfterSecurityCheck()
        }
        alert.addAction(continueAction)

        alert.preferredAction = goBackAction
        present(alert, animated: true)
    }

    private func proceedAfterSecurityCheck() {
        if showDontShowAgainOption {
            // Mark as "don't show again"
            UserDefaults.standard.set(true, forKey: "hasSeenSecurityCheck")
        }

        // Dismiss
        dismiss(animated: true)
    }
}
