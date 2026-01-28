//
//  ManualViewController.swift
//  WujiKey
//
//  User manual - explains the complete app workflow in plain language
//

import UIKit

class ManualViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let sectionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupUI()
        setupConstraints()
        setupLanguageObserver()
        updateLocalizedText()
        buildContent()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(sectionsStackView)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        sectionsStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            sectionsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            sectionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sectionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            sectionsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
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
        buildContent()
    }

    private func updateLocalizedText() {
        title = Lang("manual.title")
    }

    // MARK: - Build Content

    private func buildContent() {
        // Clear existing content
        sectionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Section 1: What is WujiKey (simple text, no card frame)
        let introSection = createIntroSection(
            title: Lang("manual.intro.title"),
            content: Lang("manual.intro.content")
        )
        sectionsStackView.addArrangedSubview(introSection)
        sectionsStackView.setCustomSpacing(6, after: introSection)

        // Core principle diagram
        let principleCard = createPrincipleCard()
        sectionsStackView.addArrangedSubview(principleCard)

        // Section 2: Core Concepts
        let conceptsTitle = createSectionTitle(Lang("manual.concepts.title"))
        sectionsStackView.addArrangedSubview(conceptsTitle)

        // Concept 1: Personal Identifier
        let identifierCard = createConceptCard(
            title: Lang("manual.concepts.identifier.title"),
            content: Lang("manual.concepts.identifier.content"),
            icon: "person.text.rectangle"
        )
        sectionsStackView.addArrangedSubview(identifierCard)

        // Concept 2: 5 Places
        let placesCard = createConceptCard(
            title: Lang("manual.concepts.places.title"),
            content: Lang("manual.concepts.places.content"),
            icon: "mappin.and.ellipse"
        )
        sectionsStackView.addArrangedSubview(placesCard)

        // Concept 3: Encrypted Backup
        let backupCard = createConceptCard(
            title: Lang("manual.concepts.backup.title"),
            content: Lang("manual.concepts.backup.content"),
            icon: "qrcode"
        )
        sectionsStackView.addArrangedSubview(backupCard)

        // Concept 4: Position Code
        let positionCodeCard = createConceptCard(
            title: Lang("manual.concepts.positioncode.title"),
            content: Lang("manual.concepts.positioncode.content"),
            icon: "square.grid.3x3"
        )
        sectionsStackView.addArrangedSubview(positionCodeCard)

        // Section 3: Guides (before recovery flow - follows user's usage order)
        let guidesTitle = createSectionTitle(Lang("manual.guides.title"))
        sectionsStackView.addArrangedSubview(guidesTitle)

        // Guide 1: How to get coordinates
        let coordsGuideCard = createGuideCard(
            title: Lang("manual.guides.coords.title"),
            icon: "map",
            action: #selector(openCoordsGuide)
        )
        sectionsStackView.addArrangedSubview(coordsGuideCard)

        // Guide 2: How to write memories
        let memoryGuideCard = createGuideCard(
            title: Lang("manual.guides.memory.title"),
            icon: "text.quote",
            action: #selector(openMemoryGuide)
        )
        sectionsStackView.addArrangedSubview(memoryGuideCard)

        // Section 4: Recovery Flow (after guides - for post-generation reference)
        let flowTitle = createSectionTitle(Lang("manual.flow.title"))
        sectionsStackView.addArrangedSubview(flowTitle)

        // Recovery method 1: with backup
        let generateCard = createFlowCard(
            title: Lang("manual.flow.generate.title"),
            steps: Lang("manual.flow.generate.steps"),
            icon: "arrow.counterclockwise.circle"
        )
        sectionsStackView.addArrangedSubview(generateCard)

        // Recovery method 2: without backup
        let recoverCard = createFlowCard(
            title: Lang("manual.flow.recover.title"),
            steps: Lang("manual.flow.recover.steps"),
            icon: "arrow.counterclockwise.circle"
        )
        sectionsStackView.addArrangedSubview(recoverCard)

        // Section 5: Usage Tips
        let tipsTitle = createSectionTitle(Lang("manual.tips.title"))
        sectionsStackView.addArrangedSubview(tipsTitle)

        // Tip 1: No data persistence
        let noSaveCard = createConceptCard(
            title: Lang("manual.tips.no_save.title"),
            content: Lang("manual.tips.no_save.content"),
            icon: "lock.shield"
        )
        sectionsStackView.addArrangedSubview(noSaveCard)

        // Tip 2: Paper preparation
        let paperCard = createConceptCard(
            title: Lang("manual.tips.paper.title"),
            content: Lang("manual.tips.paper.content"),
            icon: "doc.text"
        )
        sectionsStackView.addArrangedSubview(paperCard)

        // Tip 3: Memory verification
        let verifyCard = createConceptCard(
            title: Lang("manual.tips.verify.title"),
            content: Lang("manual.tips.verify.content"),
            icon: "checkmark.circle"
        )
        sectionsStackView.addArrangedSubview(verifyCard)

        // Spacer before onboarding link
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
        sectionsStackView.addArrangedSubview(spacer)

        // Onboarding guide link
        let onboardingCard = createGuideCard(
            title: Lang("manual.onboarding.title"),
            icon: "sparkles",
            action: #selector(openOnboarding)
        )
        sectionsStackView.addArrangedSubview(onboardingCard)

        // About link
        let aboutCard = createGuideCard(
            title: Lang("manual.about.title"),
            icon: "info.circle",
            action: #selector(openAbout)
        )
        sectionsStackView.addArrangedSubview(aboutCard)
    }

    // MARK: - Guide Actions

    @objc private func openCoordsGuide() {
        let vc = GuideLatLngViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    @objc private func openMemoryGuide() {
        let vc = GuideMemoryViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }

    @objc private func openOnboarding() {
        let vc = OnboardingViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    @objc private func openAbout() {
        let aboutVC = AboutViewController()
        aboutVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = aboutVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(aboutVC, animated: true)
    }

    // MARK: - Card Builders

    private func createSectionTitle(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = Theme.MinimalTheme.textPrimary
        return label
    }

    private func createIntroSection(title: String, content: String) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attributedContent = NSAttributedString(
            string: content,
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                .foregroundColor: Theme.Colors.elegantBlue,
                .paragraphStyle: paragraphStyle
            ]
        )
        contentLabel.attributedText = attributedContent
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    private func createHighlightCard(title: String, content: String, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.99, alpha: 1.0)
        card.layer.cornerRadius = 12

        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            iconView.image = UIImage(systemName: icon, withConfiguration: config)
        }
        iconView.tintColor = Theme.Colors.elegantBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.Colors.elegantBlue
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let contentLabel = UILabel()
        contentLabel.text = content
        contentLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        contentLabel.textColor = Theme.MinimalTheme.textPrimary
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

            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            contentLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            contentLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func createPrincipleCard() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        // Gradient background (deep blue to elegant blue)
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.0, green: 0.15, blue: 0.35, alpha: 1.0).cgColor,  // Deep navy
            UIColor(red: 0.0, green: 0.17, blue: 0.36, alpha: 1.0).cgColor   // Elegant blue
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        // We need to set the frame later, so use a container
        let gradientView = GradientView()
        gradientView.gradientLayer.colors = gradientLayer.colors
        gradientView.gradientLayer.locations = gradientLayer.locations
        gradientView.gradientLayer.startPoint = gradientLayer.startPoint
        gradientView.gradientLayer.endPoint = gradientLayer.endPoint
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(gradientView)

        // Key icon
        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .medium)
            iconView.image = UIImage(systemName: "key.fill", withConfiguration: config)
        }
        iconView.tintColor = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)  // Golden yellow
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Parse principle text into two lines
        let principleText = Lang("manual.principle")
        let lines = principleText.components(separatedBy: "\n")

        // First line: inputs (larger, bold)
        let inputLabel = UILabel()
        inputLabel.text = lines.first ?? ""
        inputLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        inputLabel.textColor = .white
        inputLabel.textAlignment = .center
        inputLabel.numberOfLines = 0
        inputLabel.translatesAutoresizingMaskIntoConstraints = false

        // Arrow indicator
        let arrowLabel = UILabel()
        arrowLabel.text = "↓"
        arrowLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        arrowLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)  // Golden yellow
        arrowLabel.textAlignment = .center
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false

        // Second line: output (highlighted)
        let outputLabel = UILabel()
        outputLabel.text = lines.count > 1 ? lines[1].replacingOccurrences(of: "→ ", with: "") : ""
        outputLabel.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        outputLabel.textColor = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)  // Golden yellow
        outputLabel.textAlignment = .center
        outputLabel.numberOfLines = 0
        outputLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconView)
        card.addSubview(inputLabel)
        card.addSubview(arrowLabel)
        card.addSubview(outputLabel)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: card.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            inputLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            inputLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            inputLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            arrowLabel.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: 8),
            arrowLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            outputLabel.topAnchor.constraint(equalTo: arrowLabel.bottomAnchor, constant: 8),
            outputLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            outputLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            outputLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])

        return card
    }

    private func createConceptCard(title: String, content: String, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor

        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            iconView.image = UIImage(systemName: icon, withConfiguration: config)
        }
        iconView.tintColor = Theme.Colors.elegantBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
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
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            contentLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            contentLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            contentLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            contentLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    private func createFlowCard(title: String, steps: String, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor

        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            iconView.image = UIImage(systemName: icon, withConfiguration: config)
        }
        iconView.tintColor = Theme.Colors.elegantBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stepsLabel = UILabel()
        stepsLabel.text = steps
        stepsLabel.font = UIFont(name: "Menlo", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .regular)
        stepsLabel.textColor = Theme.MinimalTheme.textSecondary
        stepsLabel.numberOfLines = 0
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(stepsLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            stepsLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            stepsLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stepsLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stepsLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func createGuideCard(title: String, icon: String, action: Selector) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor

        let iconView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            iconView.image = UIImage(systemName: icon, withConfiguration: config)
        }
        iconView.tintColor = Theme.Colors.elegantBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let arrowView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            arrowView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        }
        arrowView.tintColor = Theme.MinimalTheme.textSecondary
        arrowView.contentMode = .scaleAspectFit
        arrowView.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(arrowView)

        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: arrowView.leadingAnchor, constant: -10),

            arrowView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            arrowView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            arrowView.widthAnchor.constraint(equalToConstant: 14),
            arrowView.heightAnchor.constraint(equalToConstant: 14),

            card.heightAnchor.constraint(equalToConstant: 52)
        ])

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true

        return card
    }
}

// MARK: - GradientView Helper

/// A UIView subclass that displays a gradient background
private class GradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
}
