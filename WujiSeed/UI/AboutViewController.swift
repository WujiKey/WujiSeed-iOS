//
//  AboutViewController.swift
//  WujiSeed
//
//  About page with version info and open source link
//

import UIKit

class AboutViewController: UIViewController {

    // MARK: - Constants

    private let githubURL = "https://github.com/WujiKey/WujiSeed"

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let appIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "WUJI_logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private let versionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = Theme.Colors.elegantBlue
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // Open source section
    private let openSourceCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        view.layer.cornerRadius = 12
        return view
    }()

    private let openSourceTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.MinimalTheme.textSecondary
        label.textAlignment = .natural
        return label
    }()

    private let githubLinkLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 13.0, *) {
            label.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        } else {
            label.font = UIFont(name: "Menlo", size: 12) ?? UIFont.systemFont(ofSize: 12)
        }
        label.textColor = Theme.MinimalTheme.textSecondary
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()

    private let feedbackButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(Theme.MinimalTheme.textSecondary, for: .normal)
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let image = UIImage(systemName: "xmark", withConfiguration: config)
            button.setImage(image, for: .normal)
            button.tintColor = Theme.MinimalTheme.textSecondary
        } else {
            button.setTitle("✕", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setTitleColor(Theme.MinimalTheme.textSecondary, for: .normal)
        }
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        setupConstraints()
        updateLocalizedText()
        updateAppIconTint()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(closeButton)
        view.addSubview(appIconView)  // Title bar area
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(versionLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(openSourceCard)
        openSourceCard.addSubview(openSourceTitleLabel)
        openSourceCard.addSubview(githubLinkLabel)
        contentView.addSubview(feedbackButton)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // App icon tap for debug toggle (only in DEBUG)
        #if DEBUG
        let iconTap = UITapGestureRecognizer(target: self, action: #selector(appIconTapped))
        appIconView.addGestureRecognizer(iconTap)
        #endif
    }

    private func setupConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        openSourceCard.translatesAutoresizingMaskIntoConstraints = false
        openSourceTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        githubLinkLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Close button (top right)
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            // App icon (title bar, with top margin)
            appIconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            appIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appIconView.heightAnchor.constraint(equalToConstant: 50),

            // ScrollView
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Version label
            versionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            versionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Description
            descriptionLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Open source card
            openSourceCard.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            openSourceCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            openSourceCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            openSourceTitleLabel.topAnchor.constraint(equalTo: openSourceCard.topAnchor, constant: 12),
            openSourceTitleLabel.leadingAnchor.constraint(equalTo: openSourceCard.leadingAnchor, constant: 12),
            openSourceTitleLabel.trailingAnchor.constraint(equalTo: openSourceCard.trailingAnchor, constant: -12),

            githubLinkLabel.topAnchor.constraint(equalTo: openSourceTitleLabel.bottomAnchor, constant: 6),
            githubLinkLabel.leadingAnchor.constraint(equalTo: openSourceCard.leadingAnchor, constant: 12),
            githubLinkLabel.trailingAnchor.constraint(equalTo: openSourceCard.trailingAnchor, constant: -12),
            githubLinkLabel.bottomAnchor.constraint(equalTo: openSourceCard.bottomAnchor, constant: -12),

            // Feedback button (simple text link style)
            feedbackButton.topAnchor.constraint(equalTo: openSourceCard.bottomAnchor, constant: 4),
            feedbackButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            feedbackButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func updateLocalizedText() {
        // Set version info
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        versionLabel.text = "\(Lang("about.current_version")) \(version) (\(build))"

        // Set description with increased line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center
        let descriptionAttr = NSAttributedString(
            string: Lang("about.description"),
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                .foregroundColor: Theme.Colors.elegantBlue
            ]
        )
        descriptionLabel.attributedText = descriptionAttr
        openSourceTitleLabel.text = Lang("about.open_source_title")
        githubLinkLabel.text = githubURL

        // Build attributed string for feedback with channel name in bold deep blue
        let feedbackText = Lang("about.feedback")
        let channelName = Lang("about.feedback_channel")
        let fullText = "\(feedbackText)\n\(channelName)"

        let feedbackParagraphStyle = NSMutableParagraphStyle()
        feedbackParagraphStyle.alignment = .center
        feedbackParagraphStyle.lineSpacing = 4

        let attributedFeedback = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: Theme.MinimalTheme.textSecondary,
                .paragraphStyle: feedbackParagraphStyle
            ]
        )

        // Style the channel name (bold and deep blue)
        if let channelRange = fullText.range(of: channelName) {
            let nsRange = NSRange(channelRange, in: fullText)
            attributedFeedback.addAttributes([
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: Theme.Colors.elegantBlue
            ], range: nsRange)
        }

        feedbackButton.setAttributedTitle(attributedFeedback, for: .normal)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func appIconTapped() {
        #if DEBUG
        // Toggle debug mode (enables TEST badge on home screen)
        DebugModeManager.shared.toggle()
        updateAppIconTint()
        #endif
    }

    private func updateAppIconTint() {
        #if DEBUG
        if DebugModeManager.shared.isEnabled {
            appIconView.tintColor = .systemRed
            appIconView.image = UIImage(named: "WUJI_logo")?.withRenderingMode(.alwaysTemplate)
        } else {
            appIconView.image = UIImage(named: "WUJI_logo")?.withRenderingMode(.alwaysOriginal)
        }
        #endif
    }
}
