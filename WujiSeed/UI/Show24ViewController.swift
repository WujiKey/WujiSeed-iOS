//
//  Show24ViewController.swift
//  WujiSeed
//
//  Display 24 seed phrase words (shared by standard mode and expert mode)
//

import UIKit

class Show24ViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Data Model

    /// 256-bit master password (generated from Argon2id)
    var masterPassword: Data?

    /// Generated 24 seed phrase words
    var mnemonics: [String] = []

    /// Whether entered from recover page (hide export backup button)
    var isFromRecover: Bool = false

    /// Whether in no-backup recovery mode (show special warning)
    var isRecoverWithoutBackup: Bool = false

    /// Whether entered from backup flow (new generation flow: Confirm → Backup → Show24)
    /// If true: show "Done" button that returns to home and clears session
    var isFromBackupFlow: Bool = false

    // Data needed for backup
    var positionSequence: [Int] = []
    var codeName: String = ""

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Security warning card
    private let securityWarningView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.warningRedBackground
        view.layer.cornerRadius = Theme.Layout.defaultCornerRadius
        view.layer.borderWidth = Theme.Layout.defaultBorderWidth
        view.layer.borderColor = Theme.Colors.warningRedBorder.cgColor
        return view
    }()

    private let warningLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.captionMedium
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.textAlignment = .natural
        return label
    }()

    // Seed phrase display
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.register(StandardMnemonicCell.self, forCellWithReuseIdentifier: "MnemonicCell")
        cv.isScrollEnabled = false
        return cv
    }()

    // Export backup button
    private let exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = Theme.Fonts.bodySemibold
        button.backgroundColor = Theme.Colors.elegantBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()

    private var collectionViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Display page title
        navigationItem.title = Lang("common.seed_phrase")

        // Set back button to show only arrow (no text)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Generate mnemonic from 256bit
        generateMnemonics()

        setupUI()
        setupConstraints()
        setupActions()
        setupLanguageObserver()

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()

        updateLocalizedText()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false

        // Enable swipe back gesture and set delegate
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    // MARK: - UIGestureRecognizerDelegate

    /// Allow simultaneous recognition of swipe back gesture and scrollView scroll gesture
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    /// Ensure swipe back gesture is always available
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - Seed Phrase Generation

    private func generateMnemonics() {
        // If mnemonics already exist (passed from expert mode), skip generation
        if !mnemonics.isEmpty {
            #if DEBUG
            WujiLogger.success("Expert mode: received 24 seed phrase words")
            #endif
            return
        }

        // Standard mode: generate seed phrase from master password
        guard let password = masterPassword else {
            showAlert(title: Lang("show24.error.title"), message: Lang("show24.error.no_password"))
            return
        }

        guard let words = BIP39Helper.generate24Words(from: password) else {
            showAlert(title: Lang("show24.error.title"), message: Lang("show24.error.generate_failed"))
            return
        }

        mnemonics = words
        #if DEBUG
        WujiLogger.success("Standard mode: successfully generated 24 seed phrase words")
        #endif
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(securityWarningView)
        securityWarningView.addSubview(warningLabel)

        contentView.addSubview(collectionView)
        contentView.addSubview(exportButton)
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        securityWarningView.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        exportButton.translatesAutoresizingMaskIntoConstraints = false

        // Calculate collection view height (24 cells, 4 per row = 6 rows)
        let cellHeight: CGFloat = 50
        let spacing: CGFloat = 8
        let rows: CGFloat = 6
        let totalHeight = (cellHeight * rows) + (spacing * (rows - 1))

        NSLayoutConstraint.activate([
            // ScrollView - fills entire screen
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Security Warning
            securityWarningView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            securityWarningView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            securityWarningView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            warningLabel.topAnchor.constraint(equalTo: securityWarningView.topAnchor, constant: 12),
            warningLabel.leadingAnchor.constraint(equalTo: securityWarningView.leadingAnchor, constant: 12),
            warningLabel.trailingAnchor.constraint(equalTo: securityWarningView.trailingAnchor, constant: -12),
            warningLabel.bottomAnchor.constraint(equalTo: securityWarningView.bottomAnchor, constant: -12),

            // Collection View
            collectionView.topAnchor.constraint(equalTo: securityWarningView.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Export Button - below collectionView
            exportButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 12),
            exportButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            exportButton.heightAnchor.constraint(equalToConstant: 48),

            // Bottom constraint for exportButton
            exportButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])

        // Set collection view height
        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: totalHeight)
        collectionViewHeightConstraint.isActive = true
    }

    // MARK: - Actions

    private func setupActions() {
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
    }

    @objc private func exportTapped() {
        if isFromRecover || isFromBackupFlow {
            // Recovery mode or backup flow: clear session and return to home
            SessionStateManager.shared.clearAll()
            mnemonics = []
            navigationController?.popToRootViewController(animated: true)
            return
        }

        // Legacy mode: Navigate to backup page
        let backupVC = BackupViewController()
        backupVC.codeName = codeName
        backupVC.mnemonics = mnemonics

        // Use own positionSequence, not SessionStateManager
        // This ensures correct export from both standard mode and expert mode
        backupVC.positionCodes = positionSequence

        // keyMaterials from SessionStateManager (saved in PlacesConfirmViewController)
        backupVC.keyMaterials = SessionStateManager.shared.keyMaterials

        // WujiName from SessionStateManager
        backupVC.wujiName = SessionStateManager.shared.name

        navigationController?.pushViewController(backupVC, animated: true)
    }

    // MARK: - Language Support

    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateLocalizedText),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func updateLocalizedText() {
        title = Lang("common.seed_phrase")

        // Set different button text and warning based on entry mode
        if isFromRecover {
            if isRecoverWithoutBackup {
                // No-backup recovery mode: show special warning
                warningLabel.text = Lang("show24.warning.recover_without_backup")
                // Change warning card background to orange
                securityWarningView.backgroundColor = Theme.Colors.warningOrangeBackground
                securityWarningView.layer.borderColor = Theme.Colors.warningOrangeBorder.cgColor
            } else {
                // Recovery with backup mode: normal prompt
                warningLabel.text = Lang("show24.warning.recover_with_backup")
            }
            exportButton.setTitle(Lang("common.done"), for: .normal)
        } else if isFromBackupFlow {
            // New generation flow (came from backup page): show "Done and Clear" button
            warningLabel.text = Lang("show24.warning.from_backup")
            exportButton.setTitle(Lang("show24.button.done_and_clear"), for: .normal)
        } else {
            // Legacy mode: export encrypted backup
            warningLabel.text = Lang("show24.warning.standard")
            exportButton.setTitle(Lang("show24.button.export"), for: .normal)
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension Show24ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mnemonics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MnemonicCell", for: indexPath) as! StandardMnemonicCell
        cell.configure(index: indexPath.item + 1, word: mnemonics[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension Show24ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 8
        let numberOfColumns: CGFloat = 4
        let totalSpacing = spacing * (numberOfColumns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: 50)
    }
}

// MARK: - Seed Phrase Word Cell

class StandardMnemonicCell: UICollectionViewCell {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)  // Very light gray
        view.layer.cornerRadius = 8
        return view
    }()

    // Circular number background
    private let indexBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.elegantBlue
        view.layer.masksToBounds = true
        return view
    }()

    private let indexLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.miniSemibold
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let wordLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.smallSemibold
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(indexBackgroundView)
        indexBackgroundView.addSubview(indexLabel)
        containerView.addSubview(wordLabel)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        indexBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Circular background - centered, 20x20
            indexBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            indexBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            indexBackgroundView.widthAnchor.constraint(equalToConstant: 20),
            indexBackgroundView.heightAnchor.constraint(equalToConstant: 20),

            // Number label
            indexLabel.topAnchor.constraint(equalTo: indexBackgroundView.topAnchor),
            indexLabel.leadingAnchor.constraint(equalTo: indexBackgroundView.leadingAnchor),
            indexLabel.trailingAnchor.constraint(equalTo: indexBackgroundView.trailingAnchor),
            indexLabel.bottomAnchor.constraint(equalTo: indexBackgroundView.bottomAnchor),

            // Word label - centered
            wordLabel.topAnchor.constraint(equalTo: indexBackgroundView.bottomAnchor, constant: 2),
            wordLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            wordLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            wordLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Set circular shape
        indexBackgroundView.layer.cornerRadius = 10
    }

    func configure(index: Int, word: String) {
        indexLabel.text = "\(index)"
        wordLabel.text = word
    }
}
