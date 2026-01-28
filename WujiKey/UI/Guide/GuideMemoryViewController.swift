//
//  GuideMemoryViewController.swift
//  WujiKey
//
//  Memory tag examples guide page
//  Shows examples of good keyword tags for memory input
//

import UIKit

class GuideMemoryViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fill
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Lang("places.guide.notes.title")

        setupNavigationBar()
        setupUI()
        setupConstraints()
        createContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "xmark"),
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )

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
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "✕",
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped)
            )

            navigationController?.navigationBar.barTintColor = Theme.MinimalTheme.cardBackground
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: Theme.MinimalTheme.textPrimary,
                .font: Theme.MinimalTheme.titleFont
            ]
        }

        navigationController?.navigationBar.tintColor = Theme.Colors.elegantBlue
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

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

            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func createContent() {
        // 1. Introduction card
        let introCard = createIntroCard()
        contentStackView.addArrangedSubview(introCard)

        contentStackView.addArrangedSubview(createSpacer(height: 20))

        // 2. Examples section
        let examplesSection = createExamplesSection()
        contentStackView.addArrangedSubview(examplesSection)

        contentStackView.addArrangedSubview(createSpacer(height: 8))

        // 4. Warning card
        let warningCard = createWarningCard()
        contentStackView.addArrangedSubview(warningCard)
    }

    // MARK: - Create Spacer

    private func createSpacer(height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
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

    // MARK: - Create Introduction Card

    private func createIntroCard() -> UIView {
        let wrapper = UIView()

        let card = UIView()
        card.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1.0)
        card.layer.cornerRadius = 10
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(card)

        let messageLabel = UILabel()
        messageLabel.text = Lang("guide.memory.intro")
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        messageLabel.textColor = UIColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1.0)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .left
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrapper.topAnchor),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            messageLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return wrapper
    }

    // MARK: - Create Examples Section

    private func createExamplesSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let padding: CGFloat = 16

        // Header with icon
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            if let icon = UIImage(systemName: "tag", withConfiguration: config) {
                let iconView = UIImageView(image: icon)
                iconView.tintColor = Theme.Colors.elegantBlue
                iconView.contentMode = .scaleAspectFit
                iconView.translatesAutoresizingMaskIntoConstraints = false
                iconView.widthAnchor.constraint(equalToConstant: 28).isActive = true
                iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true
                headerStack.addArrangedSubview(iconView)
            }
        }

        let titleLabel = UILabel()
        titleLabel.text = Lang("guide.memory.examples.title")
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = Theme.MinimalTheme.textPrimary
        headerStack.addArrangedSubview(titleLabel)

        container.addSubview(headerStack)

        // Examples stack
        let examplesStack = UIStackView()
        examplesStack.axis = .vertical
        examplesStack.spacing = 16
        examplesStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(examplesStack)

        // Example 1
        let example1 = createExampleCard(
            location: Lang("guide.memory.ex1.location"),
            memory1Desc: Lang("guide.memory.ex1.m1.desc"),
            memory1Tags: [Lang("guide.memory.ex1.m1.tag1"), Lang("guide.memory.ex1.m1.tag2")],
            memory2Desc: Lang("guide.memory.ex1.m2.desc"),
            memory2Tags: [Lang("guide.memory.ex1.m2.tag1"), Lang("guide.memory.ex1.m2.tag2")]
        )
        examplesStack.addArrangedSubview(example1)

        // Example 2
        let example2 = createExampleCard(
            location: Lang("guide.memory.ex2.location"),
            memory1Desc: Lang("guide.memory.ex2.m1.desc"),
            memory1Tags: [Lang("guide.memory.ex2.m1.tag1"), Lang("guide.memory.ex2.m1.tag2")],
            memory2Desc: Lang("guide.memory.ex2.m2.desc"),
            memory2Tags: [Lang("guide.memory.ex2.m2.tag1")]
        )
        examplesStack.addArrangedSubview(example2)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            headerStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),

            examplesStack.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            examplesStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding),
            examplesStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding),
            examplesStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }

    private func createExampleCard(
        location: String,
        memory1Desc: String,
        memory1Tags: [String],
        memory2Desc: String,
        memory2Tags: [String]
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
        card.layer.cornerRadius = 10
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.9, green: 0.92, blue: 0.95, alpha: 1.0).cgColor

        // Location label
        let locationLabel = UILabel()
        locationLabel.text = "📍 \(location)"
        locationLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        locationLabel.textColor = Theme.Colors.elegantBlue
        locationLabel.numberOfLines = 0
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(locationLabel)

        // Memory 1
        let memory1View = createMemoryRow(
            label: Lang("guide.memory.memory1"),
            description: memory1Desc,
            tags: memory1Tags
        )
        memory1View.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(memory1View)

        // Memory 2
        let memory2View = createMemoryRow(
            label: Lang("guide.memory.memory2"),
            description: memory2Desc,
            tags: memory2Tags
        )
        memory2View.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(memory2View)

        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            locationLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            locationLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            memory1View.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 12),
            memory1View.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            memory1View.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            memory2View.topAnchor.constraint(equalTo: memory1View.bottomAnchor, constant: 10),
            memory2View.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            memory2View.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            memory2View.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func createMemoryRow(label: String, description: String, tags: [String]) -> UIView {
        let container = UIView()

        // Label (记忆一/记忆二)
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        labelView.textColor = Theme.MinimalTheme.textSecondary
        labelView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(labelView)

        // Description (事件描述)
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descLabel.textColor = Theme.MinimalTheme.textPrimary
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descLabel)

        // Arrow + Tags row
        let tagsRowStack = UIStackView()
        tagsRowStack.axis = .horizontal
        tagsRowStack.spacing = 6
        tagsRowStack.alignment = .center
        tagsRowStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tagsRowStack)

        // Arrow
        let arrowLabel = UILabel()
        arrowLabel.text = "→"
        arrowLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        arrowLabel.textColor = Theme.MinimalTheme.textSecondary
        arrowLabel.setContentHuggingPriority(.required, for: .horizontal)
        tagsRowStack.addArrangedSubview(arrowLabel)

        // Tags
        for tag in tags {
            let tagView = createTagChip(text: tag)
            tagsRowStack.addArrangedSubview(tagView)
        }

        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            descLabel.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            tagsRowStack.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 6),
            tagsRowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tagsRowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func createTagChip(text: String) -> UIView {
        let chip = UIView()
        chip.backgroundColor = Theme.Colors.blueBackground
        chip.layer.cornerRadius = 6
        chip.layer.borderWidth = 0.5
        chip.layer.borderColor = Theme.Colors.borderBlue.cgColor
        chip.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.Colors.elegantBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: chip.topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -5),
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -8)
        ])

        return chip
    }

    // MARK: - Create Warning Card

    private func createWarningCard() -> UIView {
        let wrapper = UIView()

        let card = UIView()
        card.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
        card.layer.cornerRadius = 10
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = Lang("guide.memory.warning.title")
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor.systemRed
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let badExamples = [
            Lang("guide.memory.warning.ex1"),
            Lang("guide.memory.warning.ex2"),
            Lang("guide.memory.warning.ex3"),
            Lang("guide.memory.warning.ex4")
        ]

        let examplesStack = UIStackView()
        examplesStack.axis = .horizontal
        examplesStack.distribution = .fillEqually
        examplesStack.spacing = 8
        examplesStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(examplesStack)

        for example in badExamples {
            let label = PaddedLabel()
            label.text = example
            label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            label.textColor = UIColor.systemRed
            label.textAlignment = .center
            label.backgroundColor = UIColor.white
            label.layer.cornerRadius = 6
            label.layer.masksToBounds = true
            label.layer.borderWidth = 1
            label.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
            label.textInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            examplesStack.addArrangedSubview(label)
        }

        let tipsLabel = UILabel()
        tipsLabel.text = Lang("guide.memory.warning.tips")
        tipsLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        tipsLabel.textColor = UIColor.systemRed.withAlphaComponent(0.8)
        tipsLabel.numberOfLines = 0
        tipsLabel.textAlignment = .left
        tipsLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(tipsLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: wrapper.topAnchor),
            card.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            examplesStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            examplesStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            examplesStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            tipsLabel.topAnchor.constraint(equalTo: examplesStack.bottomAnchor, constant: 10),
            tipsLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            tipsLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            tipsLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return wrapper
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
