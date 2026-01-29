//
//  OnboardingPageView.swift
//  WujiSeed
//
//  Individual page view for onboarding
//

import UIKit

/// A single page view in the onboarding flow
class OnboardingPageView: UIView {

    // MARK: - Properties

    private let pageData: OnboardingPageData
    var onStartButtonTapped: (() -> Void)?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(pageData: OnboardingPageData) {
        self.pageData = pageData
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .white

        addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 32),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -32),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -50),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -64)
        ])

        // Build content based on page type
        switch pageData.pageType {
        case .philosophy:
            buildPhilosophyPage()
        case .comparison:
            buildComparisonPage()
        case .bulletPoints:
            buildBulletPointsPage()
        case .flowDiagram:
            buildFlowDiagramPage()
        case .callToAction:
            buildCallToActionPage()
        }
    }

    // MARK: - Page Builders

    private func buildPhilosophyPage() {
        // Icon
        let iconView = createIconView()
        contentStack.addArrangedSubview(iconView)

        // Spacer
        contentStack.addArrangedSubview(createSpacer(height: 12))

        // Title
        let titleLabel = createTitleLabel(key: pageData.titleKey)
        contentStack.addArrangedSubview(titleLabel)

        // Message
        if let messageKey = pageData.messageKey {
            let messageLabel = createMessageLabel(key: messageKey)
            contentStack.addArrangedSubview(messageLabel)
        }
    }

    private func buildComparisonPage() {
        // Title
        let titleLabel = createTitleLabel(key: pageData.titleKey)
        contentStack.addArrangedSubview(titleLabel)

        contentStack.addArrangedSubview(createSpacer(height: 16))

        // Before card (red background)
        if let beforeTitleKey = pageData.beforeTitleKey,
           let beforeContentKey = pageData.beforeContentKey {
            let beforeCard = createComparisonCard(
                titleKey: beforeTitleKey,
                contentKey: beforeContentKey,
                isNegative: true
            )
            contentStack.addArrangedSubview(beforeCard)
            beforeCard.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }

        // Arrow
        let arrowLabel = UILabel()
        arrowLabel.text = "↓"
        arrowLabel.font = Theme.Fonts.extraLargeTitle
        arrowLabel.textColor = Theme.MinimalTheme.textSecondary
        arrowLabel.textAlignment = .center
        contentStack.addArrangedSubview(arrowLabel)

        // After card (green background)
        if let afterTitleKey = pageData.afterTitleKey,
           let afterContentKey = pageData.afterContentKey {
            let afterCard = createComparisonCard(
                titleKey: afterTitleKey,
                contentKey: afterContentKey,
                isNegative: false
            )
            contentStack.addArrangedSubview(afterCard)
            afterCard.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    private func buildBulletPointsPage() {
        // Icon (if available)
        if pageData.iconName != nil || pageData.iconEmoji != nil {
            let iconView = createIconView()
            contentStack.addArrangedSubview(iconView)
        }

        // Title
        let titleLabel = createTitleLabel(key: pageData.titleKey)
        contentStack.addArrangedSubview(titleLabel)

        contentStack.addArrangedSubview(createSpacer(height: 8))

        // Bullet points card
        if let bulletKeys = pageData.bulletPointKeys {
            let bulletCard = createBulletPointsCard(keys: bulletKeys)
            contentStack.addArrangedSubview(bulletCard)
            bulletCard.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    private func buildFlowDiagramPage() {
        // Title
        let titleLabel = createTitleLabel(key: pageData.titleKey)
        contentStack.addArrangedSubview(titleLabel)

        contentStack.addArrangedSubview(createSpacer(height: 24))

        // Flow diagram
        if let flowKeys = pageData.flowStepKeys {
            let flowView = createFlowDiagram(keys: flowKeys)
            contentStack.addArrangedSubview(flowView)
        }
    }

    private func buildCallToActionPage() {
        // Icon
        let iconView = createIconView()
        contentStack.addArrangedSubview(iconView)

        contentStack.addArrangedSubview(createSpacer(height: 20))

        // Title
        let titleLabel = createTitleLabel(key: pageData.titleKey)
        contentStack.addArrangedSubview(titleLabel)

        // Message
        if let messageKey = pageData.messageKey {
            let messageLabel = createMessageLabel(key: messageKey)
            contentStack.addArrangedSubview(messageLabel)
        }

        contentStack.addArrangedSubview(createSpacer(height: 32))

        // Start button
        if let buttonKey = pageData.buttonKey {
            let button = createStartButton(key: buttonKey)
            contentStack.addArrangedSubview(button)
            button.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    // MARK: - Component Creators

    private func createIconView() -> UIView {
        // Check for custom image first
        if let customImageName = pageData.customImageName,
           let customImage = UIImage(named: customImageName) {
            let imageView = UIImageView()
            imageView.image = customImage
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false

            // Custom image container (larger, no background)
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(imageView)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 200),
                container.heightAnchor.constraint(equalToConstant: 120),
                imageView.topAnchor.constraint(equalTo: container.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            return container
        }

        let containerSize: CGFloat = 80

        if #available(iOS 13.0, *), let iconName = pageData.iconName {
            let imageView = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
            imageView.image = UIImage(systemName: iconName, withConfiguration: config)
            imageView.tintColor = Theme.Colors.elegantBlue
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false

            let container = UIView()
            container.backgroundColor = Theme.Colors.contextCardBackground
            container.layer.cornerRadius = containerSize / 2
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(imageView)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: containerSize),
                container.heightAnchor.constraint(equalToConstant: containerSize),
                imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            return container
        } else {
            // Fallback to emoji for iOS 12
            let label = UILabel()
            label.text = pageData.iconEmoji ?? "🔐"
            label.font = UIFont.systemFont(ofSize: 44)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            let container = UIView()
            container.backgroundColor = Theme.Colors.contextCardBackground
            container.layer.cornerRadius = containerSize / 2
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: containerSize),
                container.heightAnchor.constraint(equalToConstant: containerSize),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            return container
        }
    }

    private func createTitleLabel(key: String) -> UILabel {
        let label = UILabel()
        label.text = Lang(key)
        label.font = Theme.Fonts.extraLargeTitle
        label.textColor = Theme.MinimalTheme.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func createMessageLabel(key: String) -> UILabel {
        let label = UILabel()
        label.text = Lang(key)
        label.font = Theme.Fonts.body
        label.textColor = Theme.MinimalTheme.textSecondary
        label.textAlignment = .left
        label.numberOfLines = 0

        // Add line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .left

        let attributedText = NSAttributedString(
            string: Lang(key),
            attributes: [
                .font: Theme.Fonts.body,
                .foregroundColor: Theme.MinimalTheme.textSecondary,
                .paragraphStyle: paragraphStyle
            ]
        )
        label.attributedText = attributedText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func createComparisonCard(titleKey: String, contentKey: String, isNegative: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = isNegative
            ? UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
            : UIColor(red: 0.93, green: 0.97, blue: 0.93, alpha: 1.0)
        card.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let iconLabel = UILabel()
        iconLabel.text = isNegative ? "✗" : "✓"
        iconLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        iconLabel.textColor = isNegative ? UIColor.systemRed : UIColor.systemGreen
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        // Title
        let titleLabel = UILabel()
        titleLabel.text = Lang(titleKey)
        titleLabel.font = Theme.Fonts.subtitle
        titleLabel.textColor = isNegative
            ? UIColor.systemRed
            : Theme.Colors.elegantBlue
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Content
        let contentLabel = UILabel()
        contentLabel.text = Lang(contentKey)
        contentLabel.font = Theme.Fonts.body
        contentLabel.textColor = Theme.MinimalTheme.textPrimary
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconLabel)
        card.addSubview(titleLabel)
        card.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            iconLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            titleLabel.centerYAnchor.constraint(equalTo: iconLabel.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createBulletPointsCard(keys: [String]) -> UIView {
        let card = UIView()
        card.backgroundColor = Theme.Colors.grayBackground
        card.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, key) in keys.enumerated() {
            let row = createBulletRow(
                text: Lang(key),
                iconName: pageData.bulletPointIcons?[safe: index],
                emoji: pageData.bulletPointEmojis?[safe: index] ?? "•"
            )
            stack.addArrangedSubview(row)

            // Add separator (except for last item)
            if index < keys.count - 1 {
                let separator = UIView()
                separator.backgroundColor = Theme.Colors.separatorLight
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stack.addArrangedSubview(separator)
            }
        }

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])

        return card
    }

    private func createBulletRow(text: String, iconName: String?, emoji: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let iconLabel = UILabel()
        if #available(iOS 13.0, *), let name = iconName {
            let attachment = NSTextAttachment()
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            if let image = UIImage(systemName: name, withConfiguration: config) {
                attachment.image = image.withTintColor(Theme.Colors.elegantBlue, renderingMode: .alwaysOriginal)
            }
            iconLabel.attributedText = NSAttributedString(attachment: attachment)
        } else {
            iconLabel.text = emoji
            iconLabel.font = UIFont.systemFont(ofSize: 16)
        }
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = Theme.Fonts.caption
        textLabel.textColor = Theme.MinimalTheme.textPrimary
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(iconLabel)
        row.addSubview(textLabel)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            iconLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 24),

            textLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            textLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            textLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            textLabel.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12)
        ])

        return row
    }

    private func createFlowDiagram(keys: [String]) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, key) in keys.enumerated() {
            let isLast = index == keys.count - 1

            // Step box
            let stepBox = createFlowStepBox(text: Lang(key), isHighlight: isLast)
            stack.addArrangedSubview(stepBox)

            // Arrow (except after last item)
            if !isLast {
                let arrow = UILabel()
                arrow.text = "↓"
                arrow.font = Theme.Fonts.largeTitle
                arrow.textColor = Theme.MinimalTheme.textSecondary
                arrow.textAlignment = .center
                stack.addArrangedSubview(arrow)
            }
        }

        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createFlowStepBox(text: String, isHighlight: Bool) -> UIView {
        let box = UIView()
        box.backgroundColor = isHighlight
            ? Theme.Colors.elegantBlue
            : Theme.Colors.grayBackground
        box.layer.cornerRadius = Theme.Layout.smallCornerRadius
        box.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = isHighlight ? Theme.Fonts.bodySemibold : Theme.Fonts.body
        label.textColor = isHighlight ? .white : Theme.MinimalTheme.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        box.addSubview(label)

        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            box.heightAnchor.constraint(equalToConstant: isHighlight ? 50 : 44),

            label.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -10)
        ])

        return box
    }

    private func createStartButton(key: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(Lang(key), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Theme.Fonts.bodySemibold
        button.backgroundColor = Theme.Colors.elegantBlue
        button.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        return button
    }

    private func createSpacer(height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    // MARK: - Actions

    @objc private func startButtonTapped() {
        onStartButtonTapped?()
    }

    // MARK: - Animation

    func animateEntrance() {
        contentStack.alpha = 0
        contentStack.transform = CGAffineTransform(translationX: 0, y: 30)

        UIView.animate(withDuration: 0.4, delay: 0.1, options: .curveEaseOut) {
            self.contentStack.alpha = 1
            self.contentStack.transform = .identity
        }
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
