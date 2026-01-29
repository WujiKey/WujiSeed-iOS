//
//  GuideLatLngViewController.swift
//  WujiSeed
//
//  Coordinate acquisition guide page
//

import UIKit

class GuideLatLngViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Method cards container
    private let methodsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0  // No spacing, dividers handle separation
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Lang("places.guide.coords.title")

        // Setup navigation bar style (using unified 20pt font)
        setupNavigationBar()

        setupUI()
        setupConstraints()
        createMethodCards()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        // Add close button in top-right corner (using icon)
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )

            // Set navigation bar appearance (20pt font)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont  // 20pt Semibold
            ]
            appearance.shadowColor = Theme.MinimalTheme.separator

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "✕",
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )

            // iOS 12 and below
            navigationController?.navigationBar.barTintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont  // 20pt Semibold
            ]
        }

        navigationController?.navigationBar.tintColor = Theme.Colors.elegantBlue
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(methodsStackView)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        methodsStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // scrollView extends directly to bottom, no longer blocked by button
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            methodsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            methodsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            methodsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            methodsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func createMethodCards() {
        // 1. Add notes card (keep card style for emphasis)
        let notesCard = createCombinedNotesCard()
        methodsStackView.addArrangedSubview(notesCard)

        // Add spacing after notes card
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        methodsStackView.addArrangedSubview(spacer)

        // 2. Main method sections (sorted by usage frequency)
        let examplePrefix = Lang("guide.coords.example")

        let methods: [(iconName: String?, emoji: String, title: String, steps: [String], tips: String)] = [
            (
                iconName: "gmap",
                emoji: "",
                title: Lang("guide.coords.gmap.title"),
                steps: [
                    Lang("guide.coords.gmap.step1"),
                    Lang("guide.coords.gmap.step2"),
                    "\(examplePrefix)(31.122407, 121.294663)"
                ],
                tips: Lang("guide.coords.gmap.tips")
            ),
            (
                iconName: "gearth",
                emoji: "",
                title: Lang("guide.coords.gearth.title"),
                steps: [
                    Lang("guide.coords.gearth.desktop"),
                    Lang("guide.coords.gearth.desktop.step1"),
                    Lang("guide.coords.gearth.desktop.step2"),
                    "",
                    Lang("guide.coords.gearth.mobile"),
                    Lang("guide.coords.gearth.mobile.step1"),
                    Lang("guide.coords.gearth.mobile.step2"),
                    Lang("guide.coords.gearth.mobile.step3"),
                    "",
                    "\(examplePrefix)31.122407°N 121.294663°E",
                    "\(examplePrefix)31°14.2407'N 121°29.4663'E",
                    "\(examplePrefix)31°14'38.54\"N 121°29'46.63\"W"
                ],
                tips: Lang("guide.coords.gearth.tips")
            ),
            (
                iconName: "amap",
                emoji: "",
                title: Lang("guide.coords.amap.title"),
                steps: [
                    Lang("guide.coords.amap.step1"),
                    Lang("guide.coords.amap.step2"),
                    "",
                    Lang("guide.coords.amap.note")
                ],
                tips: ""
            ),
            (
                iconName: "sf:grid",
                emoji: "",
                title: Lang("guide.coords.f9.title"),
                steps: [
                    Lang("guide.coords.f9.step1"),
                    Lang("guide.coords.f9.step2"),
                    Lang("guide.coords.f9.step3"),
                    "\(examplePrefix)31.122407, 121.294663",
                ],
                tips: Lang("guide.coords.f9.tips")
            )
        ]

        for (index, method) in methods.enumerated() {
            let section = createMethodSection(
                iconName: method.iconName,
                emoji: method.emoji,
                title: method.title,
                steps: method.steps,
                tips: method.tips
            )
            methodsStackView.addArrangedSubview(section)

            // Add divider after each section (except the last one)
            if index < methods.count - 1 {
                methodsStackView.addArrangedSubview(createDivider())
            }
        }
    }

    // MARK: - Create Divider

    private func createDivider() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let line = UIView()
        line.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        line.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(line)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 25),
            line.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])

        return container
    }

    // MARK: - Create Method Section (Clean Style)

    private func createMethodSection(iconName: String?, emoji: String, title: String, steps: [String], tips: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let iconPadding: CGFloat = 16       // Icon/title margin from edge (outer)
        let contentPadding: CGFloat = 16    // Content margin from edge (outer)

        // Header: icon + title
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        if let iconName = iconName, !iconName.isEmpty {
            if iconName.hasPrefix("sf:") {
                let sfSymbolName = String(iconName.dropFirst(3))
                if #available(iOS 13.0, *) {
                    let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
                    if let sfImage = UIImage(systemName: sfSymbolName, withConfiguration: config) {
                        let iconView = UIImageView(image: sfImage)
                        iconView.tintColor = Theme.Colors.elegantBlue
                        iconView.contentMode = .scaleAspectFit
                        iconView.translatesAutoresizingMaskIntoConstraints = false
                        iconView.widthAnchor.constraint(equalToConstant: 28).isActive = true
                        iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true
                        headerStack.addArrangedSubview(iconView)
                    }
                } else {
                    let emojiLabel = UILabel()
                    emojiLabel.text = "⊞"
                    emojiLabel.font = UIFont.systemFont(ofSize: 24)
                    headerStack.addArrangedSubview(emojiLabel)
                }
            } else if let icon = UIImage(named: iconName) {
                let iconView = UIImageView(image: icon)
                iconView.contentMode = .scaleAspectFit
                iconView.translatesAutoresizingMaskIntoConstraints = false
                iconView.widthAnchor.constraint(equalToConstant: 28).isActive = true
                iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true
                headerStack.addArrangedSubview(iconView)
            }
        } else if !emoji.isEmpty {
            let emojiLabel = UILabel()
            emojiLabel.text = emoji
            emojiLabel.font = UIFont.systemFont(ofSize: 26)
            headerStack.addArrangedSubview(emojiLabel)
        }

        // Title
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
        headerStack.addArrangedSubview(titleLabel)

        container.addSubview(headerStack)

        // Steps content
        let stepsStack = UIStackView()
        stepsStack.axis = .vertical
        stepsStack.spacing = 6
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        let examplePrefix = Lang("guide.coords.example")
        let notePrefix = Lang("guide.coords.amap.note").components(separatedBy: "：").first ?? "Note"

        for step in steps {
            if step.isEmpty {
                // Empty line for spacing
                let spacer = UIView()
                spacer.heightAnchor.constraint(equalToConstant: 4).isActive = true
                stepsStack.addArrangedSubview(spacer)
            } else if step.hasPrefix(examplePrefix) || step.hasPrefix("Example") {
                // Example: normal text before colon, italic after colon
                let stepLabel = UILabel()
                stepLabel.numberOfLines = 0

                let colonRange = step.range(of: "：") ?? step.range(of: ":")
                if let range = colonRange {
                    let prefix = String(step[..<range.upperBound])
                    let suffix = String(step[range.upperBound...])

                    let attributedString = NSMutableAttributedString()

                    let prefixAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                        .foregroundColor: Theme.MinimalTheme.textPrimary
                    ]
                    attributedString.append(NSAttributedString(string: prefix, attributes: prefixAttrs))

                    let italicFont = UIFont.italicSystemFont(ofSize: 14)
                    let suffixAttrs: [NSAttributedString.Key: Any] = [
                        .font: italicFont,
                        .foregroundColor: Theme.MinimalTheme.textSecondary
                    ]
                    attributedString.append(NSAttributedString(string: suffix, attributes: suffixAttrs))

                    stepLabel.attributedText = attributedString
                } else {
                    stepLabel.text = step
                    stepLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                    stepLabel.textColor = Theme.MinimalTheme.textPrimary
                }
                stepsStack.addArrangedSubview(stepLabel)
            } else if step.hasPrefix(notePrefix) || step.hasPrefix("Note") {
                // Note line: bold
                let stepLabel = UILabel()
                stepLabel.text = step
                stepLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                stepLabel.textColor = Theme.Colors.softAmber
                stepLabel.numberOfLines = 0
                stepsStack.addArrangedSubview(stepLabel)
            } else if step.contains("*") {
                // Line with *italic* markers
                let stepLabel = UILabel()
                stepLabel.numberOfLines = 0
                stepLabel.attributedText = parseItalicMarkers(step)
                stepsStack.addArrangedSubview(stepLabel)
            } else {
                // Normal line
                let stepLabel = UILabel()
                stepLabel.text = step
                stepLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
                stepLabel.textColor = Theme.MinimalTheme.textPrimary
                stepLabel.numberOfLines = 0
                stepsStack.addArrangedSubview(stepLabel)
            }
        }

        container.addSubview(stepsStack)

        // Tips (if not empty)
        var tipsLabel: UILabel?
        if !tips.isEmpty {
            let label = UILabel()
            label.text = tips
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            label.textColor = Theme.Colors.elegantBlue
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            tipsLabel = label
        }

        // Constraints
        var constraints: [NSLayoutConstraint] = [
            headerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: iconPadding),
            headerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -iconPadding),

            stepsStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            stepsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: contentPadding),
            stepsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -contentPadding)
        ]

        if let label = tipsLabel {
            constraints.append(contentsOf: [
                label.topAnchor.constraint(equalTo: stepsStack.bottomAnchor, constant: 8),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: contentPadding),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -contentPadding),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
            ])
        } else {
            constraints.append(stepsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8))
        }

        NSLayoutConstraint.activate(constraints)

        return container
    }

    // MARK: - Parse Italic Markers

    /// Parse *text* markers and return attributed string with italic formatting
    private func parseItalicMarkers(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: Theme.MinimalTheme.textPrimary
        ]
        let italicAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: Theme.Colors.elegantBlue
        ]

        var currentIndex = text.startIndex
        while currentIndex < text.endIndex {
            // Find next *
            if let starStart = text[currentIndex...].firstIndex(of: "*") {
                // Add text before the *
                if starStart > currentIndex {
                    let normalText = String(text[currentIndex..<starStart])
                    result.append(NSAttributedString(string: normalText, attributes: normalAttrs))
                }

                // Find closing *
                let afterStar = text.index(after: starStart)
                if afterStar < text.endIndex, let starEnd = text[afterStar...].firstIndex(of: "*") {
                    // Extract italic text (between the two *)
                    let italicText = String(text[afterStar..<starEnd])
                    result.append(NSAttributedString(string: italicText, attributes: italicAttrs))
                    currentIndex = text.index(after: starEnd)
                } else {
                    // No closing *, treat as normal text
                    let remaining = String(text[starStart...])
                    result.append(NSAttributedString(string: remaining, attributes: normalAttrs))
                    break
                }
            } else {
                // No more *, add remaining text
                let remaining = String(text[currentIndex...])
                result.append(NSAttributedString(string: remaining, attributes: normalAttrs))
                break
            }
        }

        return result
    }

    // MARK: - Create Combined Notes Card (Keep Card Style)

    private func createCombinedNotesCard() -> UIView {
        // Wrapper to add horizontal padding
        let wrapper = UIView()

        let card = UIView()
        card.backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0)  // Light orange background
        card.layer.cornerRadius = 10
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrapper.topAnchor),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])

        // Content container
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Important notice section (warning)
        let noticeSection = createNoteSection(
            title: Lang("guide.coords.notice.title"),
            content: Lang("guide.coords.notice.content"),
            textColor: UIColor.systemRed
        )
        contentStack.addArrangedSubview(noticeSection)

        // China region coordinate explanation
        let chinaSection = createNoteSection(
            title: Lang("guide.coords.china.title"),
            content: Lang("guide.coords.china.content"),
            textColor: UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0)
        )
        contentStack.addArrangedSubview(chinaSection)

        // Satellite image selection tips
        let satelliteSection = createNoteSection(
            title: Lang("guide.coords.satellite.title"),
            content: Lang("guide.coords.satellite.content"),
            textColor: UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0)
        )
        contentStack.addArrangedSubview(satelliteSection)

        // Illustration images
        let imagesStack = UIStackView()
        imagesStack.axis = .horizontal
        imagesStack.spacing = 8
        imagesStack.distribution = .fill
        imagesStack.alignment = .fill
        imagesStack.translatesAutoresizingMaskIntoConstraints = false

        var map001ImageView: UIImageView?

        for (index, imageName) in ["map001", "map002"].enumerated() {
            if let image = UIImage(named: imageName) {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.layer.cornerRadius = 6
                imageView.layer.borderWidth = 1
                imageView.layer.borderColor = Theme.MinimalTheme.border.cgColor
                imageView.clipsToBounds = true
                imageView.translatesAutoresizingMaskIntoConstraints = false

                if index == 0 {
                    map001ImageView = imageView
                }

                imagesStack.addArrangedSubview(imageView)
            }
        }
        contentStack.addArrangedSubview(imagesStack)

        card.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),

            imagesStack.heightAnchor.constraint(equalToConstant: 130)
        ])

        if let map001 = map001ImageView {
            NSLayoutConstraint.activate([
                map001.widthAnchor.constraint(equalTo: imagesStack.widthAnchor, multiplier: 0.35)
            ])
        }

        return wrapper
    }

    // Helper method: create note section
    private func createNoteSection(title: String, content: String, textColor: UIColor) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = textColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        contentLabel.textColor = textColor
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            contentLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
