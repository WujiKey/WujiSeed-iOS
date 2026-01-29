//
//  TestConfigViewController.swift
//  WujiSeed
//
//  Test configuration page - accessible via triple-tap on version label
//  Controls debug features and mock locations
//

#if DEBUG

import UIKit
import CoreLocation

class TestConfigViewController: UIViewController {

    // MARK: - Preset Locations

    /// Preset locations for F9Grid testing
    private let presetLocations: [(name: String, coordinate: CLLocationCoordinate2D)] = [
        ("k=3/k=4 边界线", CLLocationCoordinate2D(latitude: 31.34625, longitude: 116.4)),
        ("k=3 区域 (边界北侧)", CLLocationCoordinate2D(latitude: 31.347, longitude: 116.4)),
        ("k=4 区域 (边界南侧)", CLLocationCoordinate2D(latitude: 31.345, longitude: 116.4)),
        ("k=3 NW角 (宫格4)", CLLocationCoordinate2D(latitude: 31.347312, longitude: 116.399875)),
        ("k=4 NW角 (宫格4)", CLLocationCoordinate2D(latitude: 31.345312, longitude: 116.3995)),
        ("北京天安门", CLLocationCoordinate2D(latitude: 39.908823, longitude: 116.397470)),
        ("上海东方明珠", CLLocationCoordinate2D(latitude: 31.239702, longitude: 121.499763)),
        ("纽约时代广场", CLLocationCoordinate2D(latitude: 40.758896, longitude: -73.985130)),
    ]

    // MARK: - Colors (iOS 12 compatible)

    private static var labelColor: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    private static var secondaryLabelColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .gray
        }
    }

    private static var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        } else {
            return UIColor(white: 0.95, alpha: 1.0)
        }
    }

    private static var cardBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }

    private static var separatorColor: UIColor {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return UIColor(white: 0.8, alpha: 1.0)
        }
    }

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "测试配置"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("关闭", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return button
    }()

    // Master switch section
    private let masterSwitchCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        return view
    }()

    private let masterSwitchLabel: UILabel = {
        let label = UILabel()
        label.text = "启用测试模式"
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .systemRed
        return label
    }()

    private let masterSwitchDescLabel: UILabel = {
        let label = UILabel()
        label.text = "开启后首页显示 TEST 标记，各页面进入测试状态"
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    private let masterSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = .systemRed
        return sw
    }()

    // F9 Location section
    private let wujiSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "F9 定位模拟"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let wujiStatusCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.5
        return view
    }()

    private let wujiStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "当前状态"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private let wujiCurrentValueLabel: UILabel = {
        let label = UILabel()
        label.text = "使用真实坐标"
        label.numberOfLines = 0
        return label
    }()

    private let wujiClearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("清除", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    private let presetsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    // Other settings section
    private let otherSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "其他设置"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        return label
    }()

    private let securityCheckCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.5
        return view
    }()

    private let securityCheckLabel: UILabel = {
        let label = UILabel()
        label.text = "安全提示页"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    private let securityCheckStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    private let securityCheckResetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重置", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    // Onboarding section
    private let onboardingCard: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.5
        return view
    }()

    private let onboardingLabel: UILabel = {
        let label = UILabel()
        label.text = "启动引导页"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    private let onboardingStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()

    private let onboardingResetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重置", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        loadCurrentState()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Self.backgroundColor

        // Apply colors
        titleLabel.textColor = Self.labelColor
        wujiSectionLabel.textColor = Self.labelColor
        otherSectionLabel.textColor = Self.labelColor
        masterSwitchDescLabel.textColor = Self.secondaryLabelColor
        wujiStatusLabel.textColor = Self.secondaryLabelColor
        securityCheckLabel.textColor = Self.labelColor
        securityCheckStatusLabel.textColor = Self.secondaryLabelColor
        onboardingLabel.textColor = Self.labelColor
        onboardingStatusLabel.textColor = Self.secondaryLabelColor
        wujiStatusCard.backgroundColor = Self.cardBackgroundColor
        wujiStatusCard.layer.borderColor = Self.separatorColor.cgColor
        securityCheckCard.backgroundColor = Self.cardBackgroundColor
        securityCheckCard.layer.borderColor = Self.separatorColor.cgColor
        onboardingCard.backgroundColor = Self.cardBackgroundColor
        onboardingCard.layer.borderColor = Self.separatorColor.cgColor

        // Set font for wujiCurrentValueLabel
        if #available(iOS 13.0, *) {
            wujiCurrentValueLabel.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .medium)
        } else {
            wujiCurrentValueLabel.font = UIFont(name: "Menlo", size: 15) ?? UIFont.systemFont(ofSize: 15, weight: .medium)
        }
        wujiCurrentValueLabel.textColor = Theme.Colors.elegantBlue

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(masterSwitchCard)
        masterSwitchCard.addSubview(masterSwitchLabel)
        masterSwitchCard.addSubview(masterSwitchDescLabel)
        masterSwitchCard.addSubview(masterSwitch)

        contentView.addSubview(wujiSectionLabel)
        contentView.addSubview(wujiStatusCard)
        wujiStatusCard.addSubview(wujiStatusLabel)
        wujiStatusCard.addSubview(wujiCurrentValueLabel)
        wujiStatusCard.addSubview(wujiClearButton)

        contentView.addSubview(presetsStackView)

        // Other settings section
        contentView.addSubview(otherSectionLabel)
        contentView.addSubview(securityCheckCard)
        securityCheckCard.addSubview(securityCheckLabel)
        securityCheckCard.addSubview(securityCheckStatusLabel)
        securityCheckCard.addSubview(securityCheckResetButton)

        contentView.addSubview(onboardingCard)
        onboardingCard.addSubview(onboardingLabel)
        onboardingCard.addSubview(onboardingStatusLabel)
        onboardingCard.addSubview(onboardingResetButton)

        // Create preset buttons
        for (index, preset) in presetLocations.enumerated() {
            let button = createPresetButton(name: preset.name, index: index)
            presetsStackView.addArrangedSubview(button)
        }
    }

    private func createPresetButton(name: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(name, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        button.backgroundColor = Self.cardBackgroundColor
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 0.5
        button.layer.borderColor = Self.separatorColor.cgColor
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.tag = index
        button.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
        return button
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        masterSwitchCard.translatesAutoresizingMaskIntoConstraints = false
        masterSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        masterSwitchDescLabel.translatesAutoresizingMaskIntoConstraints = false
        masterSwitch.translatesAutoresizingMaskIntoConstraints = false
        wujiSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        wujiStatusCard.translatesAutoresizingMaskIntoConstraints = false
        wujiStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        wujiCurrentValueLabel.translatesAutoresizingMaskIntoConstraints = false
        wujiClearButton.translatesAutoresizingMaskIntoConstraints = false
        presetsStackView.translatesAutoresizingMaskIntoConstraints = false
        otherSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        securityCheckCard.translatesAutoresizingMaskIntoConstraints = false
        securityCheckLabel.translatesAutoresizingMaskIntoConstraints = false
        securityCheckStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        securityCheckResetButton.translatesAutoresizingMaskIntoConstraints = false
        onboardingCard.translatesAutoresizingMaskIntoConstraints = false
        onboardingLabel.translatesAutoresizingMaskIntoConstraints = false
        onboardingStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        onboardingResetButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Title and close button
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Master switch card
            masterSwitchCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            masterSwitchCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            masterSwitchCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            masterSwitchLabel.topAnchor.constraint(equalTo: masterSwitchCard.topAnchor, constant: 16),
            masterSwitchLabel.leadingAnchor.constraint(equalTo: masterSwitchCard.leadingAnchor, constant: 16),

            masterSwitch.centerYAnchor.constraint(equalTo: masterSwitchLabel.centerYAnchor),
            masterSwitch.trailingAnchor.constraint(equalTo: masterSwitchCard.trailingAnchor, constant: -16),

            masterSwitchDescLabel.topAnchor.constraint(equalTo: masterSwitchLabel.bottomAnchor, constant: 8),
            masterSwitchDescLabel.leadingAnchor.constraint(equalTo: masterSwitchCard.leadingAnchor, constant: 16),
            masterSwitchDescLabel.trailingAnchor.constraint(equalTo: masterSwitchCard.trailingAnchor, constant: -16),
            masterSwitchDescLabel.bottomAnchor.constraint(equalTo: masterSwitchCard.bottomAnchor, constant: -16),

            // F9 Section
            wujiSectionLabel.topAnchor.constraint(equalTo: masterSwitchCard.bottomAnchor, constant: 32),
            wujiSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            wujiStatusCard.topAnchor.constraint(equalTo: wujiSectionLabel.bottomAnchor, constant: 12),
            wujiStatusCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            wujiStatusCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            wujiStatusLabel.topAnchor.constraint(equalTo: wujiStatusCard.topAnchor, constant: 12),
            wujiStatusLabel.leadingAnchor.constraint(equalTo: wujiStatusCard.leadingAnchor, constant: 16),

            wujiClearButton.centerYAnchor.constraint(equalTo: wujiStatusLabel.centerYAnchor),
            wujiClearButton.trailingAnchor.constraint(equalTo: wujiStatusCard.trailingAnchor, constant: -12),

            wujiCurrentValueLabel.topAnchor.constraint(equalTo: wujiStatusLabel.bottomAnchor, constant: 8),
            wujiCurrentValueLabel.leadingAnchor.constraint(equalTo: wujiStatusCard.leadingAnchor, constant: 16),
            wujiCurrentValueLabel.trailingAnchor.constraint(equalTo: wujiStatusCard.trailingAnchor, constant: -16),
            wujiCurrentValueLabel.bottomAnchor.constraint(equalTo: wujiStatusCard.bottomAnchor, constant: -12),

            // Presets
            presetsStackView.topAnchor.constraint(equalTo: wujiStatusCard.bottomAnchor, constant: 16),
            presetsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            presetsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Other Section
            otherSectionLabel.topAnchor.constraint(equalTo: presetsStackView.bottomAnchor, constant: 32),
            otherSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            securityCheckCard.topAnchor.constraint(equalTo: otherSectionLabel.bottomAnchor, constant: 12),
            securityCheckCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            securityCheckCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            securityCheckLabel.topAnchor.constraint(equalTo: securityCheckCard.topAnchor, constant: 12),
            securityCheckLabel.leadingAnchor.constraint(equalTo: securityCheckCard.leadingAnchor, constant: 16),

            securityCheckResetButton.centerYAnchor.constraint(equalTo: securityCheckLabel.centerYAnchor),
            securityCheckResetButton.trailingAnchor.constraint(equalTo: securityCheckCard.trailingAnchor, constant: -12),

            securityCheckStatusLabel.topAnchor.constraint(equalTo: securityCheckLabel.bottomAnchor, constant: 6),
            securityCheckStatusLabel.leadingAnchor.constraint(equalTo: securityCheckCard.leadingAnchor, constant: 16),
            securityCheckStatusLabel.trailingAnchor.constraint(equalTo: securityCheckCard.trailingAnchor, constant: -16),
            securityCheckStatusLabel.bottomAnchor.constraint(equalTo: securityCheckCard.bottomAnchor, constant: -12),

            // Onboarding card
            onboardingCard.topAnchor.constraint(equalTo: securityCheckCard.bottomAnchor, constant: 12),
            onboardingCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            onboardingCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            onboardingLabel.topAnchor.constraint(equalTo: onboardingCard.topAnchor, constant: 12),
            onboardingLabel.leadingAnchor.constraint(equalTo: onboardingCard.leadingAnchor, constant: 16),

            onboardingResetButton.centerYAnchor.constraint(equalTo: onboardingLabel.centerYAnchor),
            onboardingResetButton.trailingAnchor.constraint(equalTo: onboardingCard.trailingAnchor, constant: -12),

            onboardingStatusLabel.topAnchor.constraint(equalTo: onboardingLabel.bottomAnchor, constant: 6),
            onboardingStatusLabel.leadingAnchor.constraint(equalTo: onboardingCard.leadingAnchor, constant: 16),
            onboardingStatusLabel.trailingAnchor.constraint(equalTo: onboardingCard.trailingAnchor, constant: -16),
            onboardingStatusLabel.bottomAnchor.constraint(equalTo: onboardingCard.bottomAnchor, constant: -12),

            onboardingCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        masterSwitch.addTarget(self, action: #selector(masterSwitchChanged), for: .valueChanged)
        wujiClearButton.addTarget(self, action: #selector(clearWujiMockLocation), for: .touchUpInside)
        securityCheckResetButton.addTarget(self, action: #selector(resetSecurityCheck), for: .touchUpInside)
        onboardingResetButton.addTarget(self, action: #selector(resetOnboarding), for: .touchUpInside)
    }

    // MARK: - State Management

    private func loadCurrentState() {
        #if DEBUG
        masterSwitch.isOn = DebugModeManager.shared.isEnabled
        #else
        masterSwitch.isOn = false
        masterSwitch.isEnabled = false
        #endif

        updateF9StatusDisplay()
        updateSecurityCheckStatusDisplay()
        updateOnboardingStatusDisplay()
        updateUIForMasterSwitch()
    }

    private func updateF9StatusDisplay() {
        if let coord = TestConfig.shared.wujiMockCoordinate {
            wujiCurrentValueLabel.text = String(format: "模拟: %.6f, %.6f", coord.latitude, coord.longitude)
            wujiCurrentValueLabel.textColor = .systemOrange
            wujiClearButton.isHidden = false
        } else {
            wujiCurrentValueLabel.text = "使用真实坐标"
            wujiCurrentValueLabel.textColor = Theme.Colors.elegantBlue
            wujiClearButton.isHidden = true
        }
    }

    private func updateUIForMasterSwitch() {
        let isEnabled = masterSwitch.isOn
        wujiSectionLabel.alpha = isEnabled ? 1.0 : 0.5
        wujiStatusCard.alpha = isEnabled ? 1.0 : 0.5
        presetsStackView.alpha = isEnabled ? 1.0 : 0.5
        presetsStackView.isUserInteractionEnabled = isEnabled
    }

    private func updateSecurityCheckStatusDisplay() {
        let hasSeenSecurityCheck = UserDefaults.standard.bool(forKey: "hasSeenSecurityCheck")
        if hasSeenSecurityCheck {
            securityCheckStatusLabel.text = "已关闭（用户点击了「下次不再提醒」）"
            securityCheckStatusLabel.textColor = .systemOrange
            securityCheckResetButton.isHidden = false
        } else {
            securityCheckStatusLabel.text = "正常（每次启动都会弹出）"
            securityCheckStatusLabel.textColor = Theme.Colors.elegantBlue
            securityCheckResetButton.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func masterSwitchChanged() {
        #if DEBUG
        DebugModeManager.shared.isEnabled = masterSwitch.isOn
        #endif
        updateUIForMasterSwitch()

        // Clear mock location when turning off
        if !masterSwitch.isOn {
            TestConfig.shared.wujiMockCoordinate = nil
            updateF9StatusDisplay()
        }
    }

    @objc private func presetTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < presetLocations.count else { return }

        let preset = presetLocations[index]
        TestConfig.shared.wujiMockCoordinate = preset.coordinate

        // Auto-enable master switch
        if !masterSwitch.isOn {
            masterSwitch.isOn = true
            masterSwitchChanged()
        }

        updateF9StatusDisplay()

        // Brief feedback
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    @objc private func clearWujiMockLocation() {
        TestConfig.shared.wujiMockCoordinate = nil
        updateF9StatusDisplay()
    }

    @objc private func resetSecurityCheck() {
        UserDefaults.standard.removeObject(forKey: "hasSeenSecurityCheck")
        updateSecurityCheckStatusDisplay()

        // Brief feedback
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    private func updateOnboardingStatusDisplay() {
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        if hasSeenOnboarding {
            onboardingStatusLabel.text = "已跳过（不会再弹出）"
            onboardingStatusLabel.textColor = .systemOrange
            onboardingResetButton.isHidden = false
        } else {
            onboardingStatusLabel.text = "正常（下次启动会弹出）"
            onboardingStatusLabel.textColor = Theme.Colors.elegantBlue
            onboardingResetButton.isHidden = true
        }
    }

    @objc private func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        updateOnboardingStatusDisplay()

        // Brief feedback
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - TestConfig Singleton

/// Global test configuration storage
class TestConfig {
    static let shared = TestConfig()

    private init() {}

    /// Mock coordinate for F9Location
    var wujiMockCoordinate: CLLocationCoordinate2D?
}

#endif
