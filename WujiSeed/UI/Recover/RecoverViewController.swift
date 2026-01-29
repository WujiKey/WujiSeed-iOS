//
//  RecoverViewController.swift
//  WujiSeed
//
//  Seed phrase recovery page
//

import UIKit
import AVFoundation
import Photos

class RecoverViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - State

    /// Whether encrypted backup has been imported
    private var hasBackup: Bool = false

    /// Position code parsed from backup
    private var parsedPositionCode: String?

    /// Imported WujiReserveData (for decryption)
    private var importedCapsule: WujiReserveData?

    /// Imported raw binary data
    private var importedCapsuleData: Data?

    /// 5 location input status
    private var locationsFilled: [Bool] = [false, false, false, false, false]

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Top info text (displayed directly without card)
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = Theme.Colors.textMedium
        label.numberOfLines = 0
        label.textAlignment = .natural
        return label
    }()

    // Name card container
    private let nameCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.cardBackground
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.MinimalTheme.border.cgColor
        return view
    }()

    private let nameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        return tf
    }()

    // Encrypted backup card container
    private let backupCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.cardBackground
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.MinimalTheme.border.cgColor
        return view
    }()

    private let backupIconView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            imageView.image = UIImage(systemName: "qrcode", withConfiguration: config)
        }
        imageView.tintColor = Theme.Colors.elegantBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let backupTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private let scanButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.7
        btn.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        btn.backgroundColor = Theme.Colors.contextCardBackground
        btn.layer.cornerRadius = 6
        btn.layer.borderWidth = 1
        btn.layer.borderColor = Theme.Colors.borderBlue.cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        return btn
    }()

    private let clearBackupButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.isHidden = true
        return btn
    }()

    // Position code hint label
    private let positionHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = Theme.Colors.textMedium
        return label
    }()

    // Position code card container
    private let positionCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.cardBackground
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.MinimalTheme.border.cgColor
        return view
    }()

    private let positionTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private let positionTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.keyboardType = .numberPad
        return tf
    }()

    // Backup success hint (shown below card)
    private let backupSuccessView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.Colors.successBackground
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.Colors.borderGreen.cgColor
        view.isHidden = true
        return view
    }()

    private let backupSuccessLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.Colors.tagPublicText
        label.numberOfLines = 0
        return label
    }()

    // Position code hint label top constraint (dynamically adjusted)
    private var positionHintTopConstraint: NSLayoutConstraint?

    // 5 location input groups
    private var locationInputViews: [LocationInputView] = []

    // Bottom recover button
    private let recoverButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = Theme.Colors.disabledButtonBackground
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.isEnabled = false
        return btn
    }()

    private let validationHintLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = Theme.Colors.textLight
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Hide back button text (show arrow only)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Ensure swipe-back gesture is available
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        setupUI()
        setupConstraints()
        setupActions()
        updateLocalizedText()
        updateValidation()
    }

    // MARK: - Localization

    private func updateLocalizedText() {
        title = Lang("recover.title")
        infoLabel.text = Lang("recover.info")
        nameTitleLabel.text = Lang("common.personal_id") + " *"
        nameTextField.placeholder = Lang("recover.name_placeholder")
        backupTitleLabel.text = Lang("recover.backup_title")
        scanButton.setTitle(Lang("common.import_qrcode"), for: .normal)
        clearBackupButton.setTitle(Lang("common.clear"), for: .normal)
        positionHintLabel.text = Lang("recover.position_hint")
        positionTitleLabel.text = Lang("common.position_code") + " *"
        positionTextField.placeholder = Lang("recover.position_placeholder")
        backupSuccessLabel.text = Lang("recover.backup_success") + "\n" + Lang("recover.backup_success_hint")
        recoverButton.setTitle(Lang("recover.button.recover"), for: .normal)

        // Update localized text for location input groups
        for locationView in locationInputViews {
            locationView.updateLocalizedText()
        }
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Top info text
        contentView.addSubview(infoLabel)

        // Name card
        contentView.addSubview(nameCardView)
        nameCardView.addSubview(nameTitleLabel)
        nameCardView.addSubview(nameTextField)

        // Encrypted backup card
        contentView.addSubview(backupCardView)
        backupCardView.addSubview(backupIconView)
        backupCardView.addSubview(backupTitleLabel)
        backupCardView.addSubview(scanButton)
        backupCardView.addSubview(clearBackupButton)

        // Backup success hint (between backup card and position code)
        contentView.addSubview(backupSuccessView)
        backupSuccessView.addSubview(backupSuccessLabel)

        // Position code hint and card
        contentView.addSubview(positionHintLabel)
        contentView.addSubview(positionCardView)
        positionCardView.addSubview(positionTitleLabel)
        positionCardView.addSubview(positionTextField)

        // Create 5 location input groups
        for i in 1...5 {
            let locationView = LocationInputView()
            locationView.configure(index: i)
            locationView.delegate = self
            locationInputViews.append(locationView)
            contentView.addSubview(locationView)
        }

        // Bottom button
        contentView.addSubview(recoverButton)
        contentView.addSubview(validationHintLabel)
    }

    private func setupConstraints() {
        // Set translatesAutoresizingMaskIntoConstraints for all views
        let allViews: [UIView] = [
            scrollView, contentView, infoLabel,
            nameCardView, nameTitleLabel, nameTextField,
            backupCardView, backupIconView, backupTitleLabel, scanButton, clearBackupButton,
            positionHintLabel, positionCardView, positionTitleLabel, positionTextField,
            backupSuccessView, backupSuccessLabel,
            recoverButton, validationHintLabel
        ]
        allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        locationInputViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let horizontalPadding: CGFloat = 10

        var constraints: [NSLayoutConstraint] = [
            // ScrollView
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

            // Info text (at top)
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            // Encrypted backup card
            backupCardView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 12),
            backupCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            backupCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            backupIconView.leadingAnchor.constraint(equalTo: backupCardView.leadingAnchor, constant: 12),
            backupIconView.centerYAnchor.constraint(equalTo: backupCardView.centerYAnchor),
            backupIconView.widthAnchor.constraint(equalToConstant: 20),
            backupIconView.heightAnchor.constraint(equalToConstant: 20),

            backupTitleLabel.topAnchor.constraint(equalTo: backupCardView.topAnchor, constant: 14),
            backupTitleLabel.leadingAnchor.constraint(equalTo: backupIconView.trailingAnchor, constant: 0),
            backupTitleLabel.bottomAnchor.constraint(equalTo: backupCardView.bottomAnchor, constant: -14),

            scanButton.leadingAnchor.constraint(equalTo: backupTitleLabel.trailingAnchor, constant: 8),
            scanButton.centerYAnchor.constraint(equalTo: backupTitleLabel.centerYAnchor),

            clearBackupButton.trailingAnchor.constraint(equalTo: backupCardView.trailingAnchor, constant: -16),
            clearBackupButton.centerYAnchor.constraint(equalTo: backupTitleLabel.centerYAnchor),

            // Backup success hint (between backup card and position code)
            backupSuccessView.topAnchor.constraint(equalTo: backupCardView.bottomAnchor, constant: 8),
            backupSuccessView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            backupSuccessView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            backupSuccessLabel.topAnchor.constraint(equalTo: backupSuccessView.topAnchor, constant: 12),
            backupSuccessLabel.leadingAnchor.constraint(equalTo: backupSuccessView.leadingAnchor, constant: 12),
            backupSuccessLabel.trailingAnchor.constraint(equalTo: backupSuccessView.trailingAnchor, constant: -12),
            backupSuccessLabel.bottomAnchor.constraint(equalTo: backupSuccessView.bottomAnchor, constant: -12),

            // Position code hint label (top constraint set dynamically)
            positionHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            positionHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            // Position code card
            positionCardView.topAnchor.constraint(equalTo: positionHintLabel.bottomAnchor, constant: 8),
            positionCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            positionCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            positionTitleLabel.topAnchor.constraint(equalTo: positionCardView.topAnchor, constant: 14),
            positionTitleLabel.leadingAnchor.constraint(equalTo: positionCardView.leadingAnchor, constant: 12),
            positionTitleLabel.bottomAnchor.constraint(equalTo: positionCardView.bottomAnchor, constant: -14),

            positionTextField.leadingAnchor.constraint(equalTo: positionTitleLabel.trailingAnchor, constant: 8),
            positionTextField.trailingAnchor.constraint(equalTo: positionCardView.trailingAnchor, constant: -16),
            positionTextField.centerYAnchor.constraint(equalTo: positionTitleLabel.centerYAnchor),
            positionTextField.heightAnchor.constraint(equalToConstant: 32),

            // Name card (below position code)
            nameCardView.topAnchor.constraint(equalTo: positionCardView.bottomAnchor, constant: 16),
            nameCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            nameCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),

            nameTitleLabel.topAnchor.constraint(equalTo: nameCardView.topAnchor, constant: 14),
            nameTitleLabel.leadingAnchor.constraint(equalTo: nameCardView.leadingAnchor, constant: 12),
            nameTitleLabel.bottomAnchor.constraint(equalTo: nameCardView.bottomAnchor, constant: -14),

            nameTextField.leadingAnchor.constraint(equalTo: nameTitleLabel.trailingAnchor, constant: 8),
            nameTextField.trailingAnchor.constraint(equalTo: nameCardView.trailingAnchor, constant: -16),
            nameTextField.centerYAnchor.constraint(equalTo: nameTitleLabel.centerYAnchor),
            nameTextField.heightAnchor.constraint(equalToConstant: 32),
        ]

        // 5 location input groups
        var previousAnchor = nameCardView.bottomAnchor
        for (index, locationView) in locationInputViews.enumerated() {
            constraints.append(contentsOf: [
                locationView.topAnchor.constraint(equalTo: previousAnchor, constant: index == 0 ? 20 : 16),
                locationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
                locationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            ])
            previousAnchor = locationView.bottomAnchor
        }

        // Bottom button
        constraints.append(contentsOf: [
            recoverButton.topAnchor.constraint(equalTo: previousAnchor, constant: 16),
            recoverButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            recoverButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            recoverButton.heightAnchor.constraint(equalToConstant: 50),

            validationHintLabel.topAnchor.constraint(equalTo: recoverButton.bottomAnchor, constant: 12),
            validationHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            validationHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            validationHintLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])

        NSLayoutConstraint.activate(constraints)

        // Initially, position hint label constrained below backup card (no backup imported)
        positionHintTopConstraint = positionHintLabel.topAnchor.constraint(equalTo: backupCardView.bottomAnchor, constant: 16)
        positionHintTopConstraint?.isActive = true
    }

    private func updatePositionCardConstraint(hasBackup: Bool) {
        positionHintTopConstraint?.isActive = false
        if hasBackup {
            // With backup: position hint label constrained below success hint
            positionHintTopConstraint = positionHintLabel.topAnchor.constraint(equalTo: backupSuccessView.bottomAnchor, constant: 16)
        } else {
            // Without backup: position hint label constrained below backup card
            positionHintTopConstraint = positionHintLabel.topAnchor.constraint(equalTo: backupCardView.bottomAnchor, constant: 16)
        }
        positionHintTopConstraint?.isActive = true

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func setupActions() {
        scanButton.addTarget(self, action: #selector(scanQRCode), for: .touchUpInside)
        clearBackupButton.addTarget(self, action: #selector(clearBackup), for: .touchUpInside)
        recoverButton.addTarget(self, action: #selector(performRecover), for: .touchUpInside)

        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        positionTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func scanQRCode() {
        // Show action sheet with two options
        let actionSheet = UIAlertController(
            title: Lang("recover.import.title"),
            message: nil,
            preferredStyle: .actionSheet
        )

        // Option 1: Import from photo album
        actionSheet.addAction(UIAlertAction(title: Lang("recover.import.photo_album"), style: .default) { [weak self] _ in
            self?.checkPhotoLibraryPermissionAndOpen()
        })

        // Option 2: Scan QR code with camera
        actionSheet.addAction(UIAlertAction(title: Lang("recover.import.scan_qrcode"), style: .default) { [weak self] _ in
            self?.openCameraScanner()
        })

        // Cancel button
        actionSheet.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))

        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = scanButton
            popover.sourceRect = scanButton.bounds
        }

        present(actionSheet, animated: true)
    }

    // MARK: - Import Functions

    /// Check photo library permission and open picker
    private func checkPhotoLibraryPermissionAndOpen() {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            openPhotoLibrary()
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized || newStatus == .limited {
                            self?.openPhotoLibrary()
                        } else {
                            self?.showPhotoPermissionDeniedAlert()
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                    DispatchQueue.main.async {
                        if newStatus == .authorized {
                            self?.openPhotoLibrary()
                        } else {
                            self?.showPhotoPermissionDeniedAlert()
                        }
                    }
                }
            }
        case .denied, .restricted:
            showPhotoPermissionDeniedAlert()
        @unknown default:
            showPhotoPermissionDeniedAlert()
        }
    }

    /// Show photo library permission denied alert with settings redirect
    private func showPhotoPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: Lang("recover.permission.photo_title"),
            message: Lang("recover.permission.photo_message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Lang("recover.permission.settings"), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))
        present(alert, animated: true)
    }

    /// Open photo library picker
    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let image = info[.originalImage] as? UIImage else {
                self?.showAlert(title: Lang("common.error"), message: Lang("recover.error.image_load_failed"))
                return
            }
            self?.detectQRCodeFromImage(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    /// Detect QR code from image
    private func detectQRCodeFromImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.image_process_failed"))
            return
        }

        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options) else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.qr_detector_failed"))
            return
        }

        let features = detector.features(in: ciImage)

        guard let qrFeature = features.first as? CIQRCodeFeature else {
            #if DEBUG
            WujiLogger.error("❌ No QR code detected in image")
            #endif
            showAlert(title: Lang("recover.error.no_qrcode"), message: Lang("recover.error.no_qrcode_message"))
            return
        }

        // Prefer binaryValue (extract raw binary data via CIQRCodeDescriptor)
        if let binaryData = qrFeature.binaryValue {
            #if DEBUG
            WujiLogger.info("✅ Using CIQRCodeDescriptor to extract binary data from image")
            WujiLogger.info("   Data size: \(binaryData.count) bytes")
            #endif
            processBinaryQRData(binaryData)
            return
        }

        // Fallback: use messageString + Latin-1 encoding
        if let messageString = qrFeature.messageString {
            #if DEBUG
            WujiLogger.warning("⚠️ CIQRCodeDescriptor unavailable, falling back to Latin-1 parsing")
            WujiLogger.info("   String length: \(messageString.count) chars")
            #endif
            processQRData(messageString)
            return
        }

        #if DEBUG
        WujiLogger.error("❌ Unable to extract data from QR code in image")
        #endif
        showAlert(title: Lang("recover.error.no_qrcode"), message: Lang("recover.error.no_qrcode_message"))
    }

    /// Open camera scanner
    private func openCameraScanner() {
        // Check camera permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authStatus {
        case .authorized:
            showQRScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.showQRScanner()
                    } else {
                        self?.showCameraPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionDeniedAlert()
        @unknown default:
            showCameraPermissionDeniedAlert()
        }
    }

    /// Show camera permission denied alert with settings redirect
    private func showCameraPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: Lang("recover.permission.camera_title"),
            message: Lang("recover.permission.camera_message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Lang("recover.permission.settings"), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: Lang("common.cancel"), style: .cancel))
        present(alert, animated: true)
    }

    /// Show QR code scanner
    private func showQRScanner() {
        let scanner = QRScannerViewController()
        scanner.delegate = self
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
    }

    /// Process QR code data (string mode, fallback compatibility)
    private func processQRData(_ qrString: String) {
        #if DEBUG
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        WujiLogger.info("Processing scanned QR code data (string mode)")
        #endif

        // Convert Latin-1 string to binary data
        guard let data = qrString.data(using: .isoLatin1), !data.isEmpty else {
            #if DEBUG
            WujiLogger.error("❌ Cannot convert QR code content to binary data")
            WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            showAlert(title: Lang("common.error"), message: Lang("recover.error.qr_format"))
            return
        }

        // Use unified binary processing method
        processBinaryQRData(data)
    }

    /// Process QR code data (binary mode)
    private func processBinaryQRData(_ data: Data) {
        #if DEBUG
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        WujiLogger.info("Processing scanned QR code data (binary mode)")
        WujiLogger.info("Data size: \(data.count) bytes")

        // Print hex representation of first 16 bytes
        let preview = data.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
        WujiLogger.info("Data preview: \(preview)")
        #endif

        // Try to parse WujiReserveData
        let result = WujiReserveData.decode(data)
        switch result {
        case .success(let capsule):
            // Extract position code
            let positionCodeString = capsule.positionCodes.map { String($0) }.joined()

            #if DEBUG
            WujiLogger.success("✅ Successfully parsed WujiReserve backup")
            WujiLogger.info("   Position code: \(positionCodeString)")
            WujiLogger.info("   Encrypted blocks: \(capsule.encryptedBlocks.count)")
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            // Save data (for later decryption)
            importedCapsule = capsule
            importedCapsuleData = data

            // Update UI (no popup on success, UI already shows status)
            onBackupImported(positionCode: positionCodeString)

        case .failure(let error):
            #if DEBUG
            WujiLogger.error("❌ WujiReserveData parse failed")
            WujiLogger.error("   Error: \(error.localizedDescription)")
            WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            // Show more specific error message based on error type
            let errorMessage: String
            switch error {
            case .crc32Mismatch:
                errorMessage = Lang("recover.error.checksum_failed")
            case .invalidMagic:
                errorMessage = Lang("recover.error.invalid_format")
            case .insufficientData:
                errorMessage = Lang("recover.error.incomplete_data")
            default:
                errorMessage = Lang("recover.error.parse_failed") + "\n\(error.localizedDescription)"
            }
            showAlert(title: Lang("common.import_failed"), message: errorMessage)
        }
    }

    @objc private func clearBackup() {
        hasBackup = false
        parsedPositionCode = nil
        importedCapsule = nil
        importedCapsuleData = nil
        backupSuccessView.isHidden = true
        clearBackupButton.isHidden = true
        positionTextField.isEnabled = true
        positionTextField.text = ""
        positionTextField.textColor = .black
        positionTextField.font = UIFont.systemFont(ofSize: 16)
        positionTextField.backgroundColor = nil

        // Update position code card position
        updatePositionCardConstraint(hasBackup: false)
        updateValidation()
    }

    @objc private func textFieldDidChange() {
        updateValidation()
    }

    @objc private func performRecover() {
        // Collect location data filled by user
        var locationDataList: [(coord: String, memory: String)] = []
        for locationView in locationInputViews {
            let coordText = locationView.coordinateTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            // Use merged processed (sorted + concatenated) memory string
            let memoryText = locationView.memoryProcessed

            if !coordText.isEmpty && !memoryText.isEmpty {
                locationDataList.append((coordText, memoryText))
            }
        }

        // With encrypted backup: only need 3 locations, without backup: need all 5 + position code
        let requiredCount = hasBackup ? 3 : 5
        guard locationDataList.count >= requiredCount else {
            showAlert(title: Lang("common.error"), message: String(format: Lang("recover.error.need_locations"), requiredCount, locationDataList.count))
            return
        }

        // Get name
        let nameInput = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !nameInput.isEmpty else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.enter_name"))
            return
        }

        // Create WujiName (normalize name and generate salt)
        guard let wujiName = WujiName(raw: nameInput) else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.name_salt_failed"))
            return
        }

        if hasBackup {
            // With encrypted backup: use decryption flow
            performRecoverWithBackup(locationDataList: locationDataList, nameSalt: wujiName.salt)
        } else {
            // Without encrypted backup: need position code, use generation flow
            performRecoverWithoutBackup(locationDataList: locationDataList, nameSalt: wujiName.salt)
        }
    }

    /// Recovery flow with encrypted backup
    ///
    /// Decryption logic:
    /// - User provides N places (3-5)
    /// - Select 3 from N places: C(N,3) place combinations
    /// - Select 3 from 5 position codes: C(5,3)=10 position code combinations
    /// - Each place combination × each position code combination = total Argon2id attempts
    ///   - 3 places: 1 × 10 = 10 attempts
    ///   - 4 places: 4 × 10 = 40 attempts
    ///   - 5 places: 10 × 10 = 100 attempts
    ///
    /// Uses pipeline processing for acceleration: Argon2id and AEAD decryption run in parallel
    private func performRecoverWithBackup(locationDataList: [(coord: String, memory: String)], nameSalt: Data) {
        guard let capsule = importedCapsule, let capsuleData = importedCapsuleData else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.backup_lost"))
            return
        }

        // Get all 5 position codes from backup
        let allPositionCodes = capsule.positionCodes
        guard allPositionCodes.count == 5 else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.invalid_backup"))
            return
        }

        // Convert to WujiSpot array
        var spots: [WujiSpot] = []
        for data in locationDataList {
            guard let spot = WujiSpot(coordinates: data.coord, memory: data.memory) else {
                showAlert(title: Lang("common.error"), message: Lang("recover.error.coord_parse_failed"))
                return
            }
            spots.append(spot)
        }

        // Calculate total attempts: C(N,3) × 10
        let spotCombinationCount: Int
        switch spots.count {
        case 3: spotCombinationCount = 1
        case 4: spotCombinationCount = 4
        default: spotCombinationCount = 10
        }
        let totalAttempts = spotCombinationCount * 10

        #if DEBUG
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        WujiLogger.info("🔐 Starting mnemonic recovery (with backup)")
        WujiLogger.info("   User provided \(spots.count) spots")
        WujiLogger.info("   Backup position codes: \(allPositionCodes)")
        WujiLogger.info("   Total attempts: \(totalAttempts) Argon2id calls")
        WujiLogger.info("   Using pipeline acceleration")
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        // Show loading alert with circular progress
        let loadingAlert = UIAlertController(
            title: Lang("recover.loading.decrypt"),
            message: nil,
            preferredStyle: .alert
        )

        // Add circular progress view
        let circularProgress = CircularProgressView()
        circularProgress.translatesAutoresizingMaskIntoConstraints = false
        circularProgress.progress = 0
        loadingAlert.view.addSubview(circularProgress)

        NSLayoutConstraint.activate([
            circularProgress.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            circularProgress.topAnchor.constraint(equalTo: loadingAlert.view.topAnchor, constant: 60),
            circularProgress.widthAnchor.constraint(equalToConstant: 80),
            circularProgress.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Adjust alert height to accommodate circular progress
        if let alertView = loadingAlert.view {
            let height = NSLayoutConstraint(item: alertView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 160)
            alertView.addConstraint(height)
        }

        present(loadingAlert, animated: true)

        // Async processing - use WujiReserve.decryptWithRecovery pipeline method
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let input = WujiReserve.RecoveryInput(
                spots: spots,
                allPositionCodes: allPositionCodes,
                nameSalt: nameSalt,
                capsuleData: capsuleData
            )

            let result = WujiReserve.decryptWithRecovery(input: input) { progress in
                DispatchQueue.main.async {
                    circularProgress.progress = progress
                }
            }

            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    switch result {
                    case .success(let output):
                        // Log statistics (if available) and navigate directly
                        #if DEBUG
                        if let stats = output.statistics {
                            WujiLogger.info("Recovery stats: \(stats.argon2idCalls) Argon2id calls, \(stats.cacheHits) cache hits, \(String(format: "%.1f", stats.totalArgon2idTime))s total")
                        }
                        #endif
                        self.navigateToShow24(mnemonics: output.mnemonics, isWithoutBackup: false)
                    case .failure:
                        self.showAlert(
                            title: Lang("recover.error.cannot_recover"),
                            message: Lang("recover.error.cannot_recover_message")
                        )
                    }
                }
            }
        }
    }

    /// Recovery flow without encrypted backup (requires position codes + 5 places)
    /// Uses WujiSpot.process for unified processing logic
    private func performRecoverWithoutBackup(locationDataList: [(coord: String, memory: String)], nameSalt: Data) {
        // Validate position codes
        let positionCodeText = positionTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard positionCodeText.count == 5,
              positionCodeText.allSatisfy({ $0.isNumber && $0 != "0" }) else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.need_position_code"))
            return
        }

        // Parse position codes
        let positionCodes = positionCodeText.compactMap { Int(String($0)) }
        guard positionCodes.count == 5 else {
            showAlert(title: Lang("common.error"), message: Lang("recover.error.position_parse_failed"))
            return
        }

        // Convert to WujiSpot array
        var spots: [WujiSpot] = []
        for data in locationDataList {
            guard let spot = WujiSpot(coordinates: data.coord, memory: data.memory) else {
                showAlert(title: Lang("common.error"), message: Lang("recover.error.coord_parse_failed"))
                return
            }
            spots.append(spot)
        }

        // Show loading alert (Argon2id is slow)
        let loadingAlert = UIAlertController(title: Lang("recover.loading.generate"), message: Lang("recover.loading.generate_message"), preferredStyle: .alert)
        present(loadingAlert, animated: true)

        // Async processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            #if DEBUG
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            WujiLogger.info("🔐 Starting mnemonic recovery (without backup)")
            WujiLogger.info("   User provided \(spots.count) spots")
            WujiLogger.info("   User input position codes: \(positionCodes)")
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            // Use WujiSpot unified processing (with position code correction)
            let processResult = WujiSpot.process(spots, positionCodes: positionCodes)

            switch processResult {
            case .success(let result):
                let passwordData = result.combinedData

                #if DEBUG
                WujiLogger.info("Places processed successfully, password length=\(passwordData.count) bytes")
                WujiLogger.info("Starting Argon2id computation...")
                #endif
                let startTime = Date()

                // Run Argon2id
                let parameters = CryptoUtils.Argon2Parameters.standard
                guard let keyData = CryptoUtils.argon2id(
                    password: passwordData,
                    salt: nameSalt,
                    parameters: parameters
                ) else {
                    #if DEBUG
                    WujiLogger.error("Argon2id computation failed")
                    #endif
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            self.showAlert(title: Lang("recover.error.argon2_failed"), message: Lang("recover.error.argon2_failed_message"))
                        }
                    }
                    return
                }

                let elapsedTime = Date().timeIntervalSince(startTime)
                #if DEBUG
                WujiLogger.success("Argon2id completed in \(String(format: "%.2f", elapsedTime)) seconds")
                #endif

                // Generate mnemonic from master key
                guard let mnemonics = BIP39Helper.generate24Words(from: keyData) else {
                    #if DEBUG
                    WujiLogger.error("Mnemonic generation failed")
                    #endif
                    DispatchQueue.main.async {
                        loadingAlert.dismiss(animated: true) {
                            self.showAlert(title: Lang("common.error"), message: Lang("recover.error.mnemonic_failed"))
                        }
                    }
                    return
                }

                #if DEBUG
                WujiLogger.success("✅ Generated \(mnemonics.count) mnemonic words")
                #endif

                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self.navigateToShow24(mnemonics: mnemonics, isWithoutBackup: true)
                    }
                }

            case .failure(let error):
                #if DEBUG
                WujiLogger.error("Place processing failed: \(error.localizedDescription)")
                #endif
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        self.showAlert(title: Lang("common.error"), message: error.localizedDescription)
                    }
                }
            }
        }
    }

    /// Navigate to Show24ViewController to display recovered mnemonic
    /// - Parameters:
    ///   - mnemonics: Array of mnemonic words
    ///   - isWithoutBackup: Whether this is recovery without backup mode (needs warning display)
    private func navigateToShow24(mnemonics: [String], isWithoutBackup: Bool = false) {
        let show24VC = Show24ViewController()
        show24VC.mnemonics = mnemonics
        show24VC.isFromRecover = true  // From recovery page
        show24VC.isRecoverWithoutBackup = isWithoutBackup  // Whether recovery without backup

        // Push to navigation stack
        navigationController?.pushViewController(show24VC, animated: true)
    }

    // MARK: - Validation

    private func updateValidation() {
        // Validate recovery conditions
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)

        // Count filled location entries
        let filledLocationsCount = locationInputViews.filter { $0.isComplete }.count

        var missingItems: [String] = []

        if !hasName {
            missingItems.append(Lang("common.name").lowercased())
        }

        // Position code validation (auto-filled with backup, manual input without backup)
        let hasValidPosition: Bool
        if hasBackup {
            hasValidPosition = parsedPositionCode != nil
        } else {
            hasValidPosition = positionTextField.text?.count == 5
            if !hasValidPosition {
                missingItems.append(Lang("common.position_code").lowercased())
            }
        }

        // Location validation:
        // - With backup: only need 3 locations (C(5,3)=10, need at least 3 to match)
        // - Without backup: need all 5 locations
        let requiredLocationCount = hasBackup ? 3 : 5
        let hasEnoughLocations = filledLocationsCount >= requiredLocationCount

        // Update location required status
        for (index, locationView) in locationInputViews.enumerated() {
            if hasBackup {
                // With backup, first 3 marked as required
                locationView.isRequired = index < 3
            } else {
                // Without backup, all locations are required
                locationView.isRequired = true
            }
        }

        // Add missing locations to hints
        if !hasEnoughLocations {
            let neededCount = requiredLocationCount - filledLocationsCount
            missingItems.append(String(format: Lang("recover.validation.locations"), neededCount))
        }

        // Recovery conditions: name + position code (auto or manual) + enough locations
        let canRecover = hasName && hasValidPosition && hasEnoughLocations
        recoverButton.isEnabled = canRecover
        recoverButton.backgroundColor = canRecover ? Theme.Colors.elegantBlue : Theme.Colors.disabledButtonBackground

        // Update hint text
        if missingItems.isEmpty {
            if hasBackup {
                validationHintLabel.text = String(format: Lang("recover.validation.ready_with_count"), filledLocationsCount)
            } else {
                validationHintLabel.text = Lang("recover.validation.ready")
            }
            validationHintLabel.textColor = Theme.Colors.tagPublicText
        } else {
            let separator = LanguageManager.shared.currentLanguage == .english ? ", " : "、"
            let missing = missingItems.prefix(3).joined(separator: separator)
            let etc = missingItems.count > 3 ? (LanguageManager.shared.currentLanguage == .english ? " etc." : " etc.") : ""
            validationHintLabel.text = String(format: Lang("recover.validation.still_need"), missing + etc)
            validationHintLabel.textColor = Theme.Colors.textLight
        }
    }

    // Handle successful backup import
    private func onBackupImported(positionCode: String) {
        hasBackup = true
        parsedPositionCode = positionCode

        // Show success hint and clear button
        backupSuccessView.isHidden = false
        backupSuccessLabel.text = "✓ " + Lang("recover.backup_imported")
        clearBackupButton.isHidden = false

        // Auto-fill position code and disable editing
        positionTextField.text = positionCode
        positionTextField.isEnabled = false
        positionTextField.textColor = Theme.Colors.tagPublicText
        positionTextField.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        positionTextField.backgroundColor = Theme.Colors.successBackground

        // Update position code card position (push down)
        updatePositionCardConstraint(hasBackup: true)
        updateValidation()
    }

    // MARK: - Helper

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - LocationInputViewDelegate

extension RecoverViewController: LocationInputViewDelegate {
    func locationInputDidChange(_ view: LocationInputView) {
        updateValidation()
    }

    #if DEBUG
    func locationInputDidTapTest(_ view: LocationInputView, index: Int) {
        // Fill test data from PlacesDataManager
        guard index >= 0 && index < PlacesDataManager.testCoordinates.count else { return }

        let coord = PlacesDataManager.testCoordinates[index]
        let memory1Tags = PlacesDataManager.testMemos1Tags[index]
        let memory2Tags = PlacesDataManager.testMemos2Tags[index]

        // Fill coordinates and tags
        view.coordinateTextField.text = "\(coord.lat), \(coord.lon)"
        view.memory1TagInput.setTags(memory1Tags)
        view.memory2TagInput.setTags(memory2Tags)

        // Update validation status
        updateValidation()
    }
    #endif
}

// MARK: - QRScannerDelegate

protocol QRScannerDelegate: AnyObject {
    func qrScannerDidScan(_ scanner: QRScannerViewController, qrString: String)
    func qrScannerDidScan(_ scanner: QRScannerViewController, binaryData: Data)
    func qrScannerDidCancel(_ scanner: QRScannerViewController)
}

extension RecoverViewController: QRScannerDelegate {
    func qrScannerDidScan(_ scanner: QRScannerViewController, qrString: String) {
        scanner.dismiss(animated: true) {
            self.processQRData(qrString)
        }
    }

    func qrScannerDidScan(_ scanner: QRScannerViewController, binaryData: Data) {
        scanner.dismiss(animated: true) {
            self.processBinaryQRData(binaryData)
        }
    }

    func qrScannerDidCancel(_ scanner: QRScannerViewController) {
        scanner.dismiss(animated: true)
    }
}

// MARK: - LocationInputView

protocol LocationInputViewDelegate: AnyObject {
    func locationInputDidChange(_ view: LocationInputView)
    #if DEBUG
    func locationInputDidTapTest(_ view: LocationInputView, index: Int)
    #endif
}

class LocationInputView: UIView {

    weak var delegate: LocationInputViewDelegate?
    var isRequired: Bool = true
    var locationIndex: Int = 0  // Location index (0-4)

    // Label width (memory1/memory2)
    private let labelWidth: CGFloat = 52

    // Container card (contains location, memory1, memory2)
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.cardBackground
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.MinimalTheme.border.cgColor
        return view
    }()

    // Location icon (SF Symbol mappin.and.ellipse - Google Maps style)
    private let locationIconView: UIImageView = {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            imageView.image = UIImage(systemName: "mappin.and.ellipse", withConfiguration: config)
        }
        imageView.tintColor = Theme.Colors.elegantBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // Coordinate text field (borderless)
    let coordinateTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        tf.placeholder = "39.9042°N, 116.4074°E"
        tf.borderStyle = .none
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        return tf
    }()

    #if DEBUG
    // Test button (right side of coordinate field) - only visible in debug mode
    let testButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Test", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        btn.backgroundColor = Theme.Colors.contextCardBackground
        btn.layer.cornerRadius = 4
        btn.layer.borderWidth = 1
        btn.layer.borderColor = Theme.Colors.borderBlue.cgColor
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        btn.isHidden = !DebugModeManager.shared.isEnabled
        return btn
    }()
    #endif

    // First separator (between location and memory1)
    private let separator1View: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.border
        return view
    }()

    // Memory1 label (dark blue)
    private let memory1Label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    // Memory1 tag input view
    let memory1TagInput: TagInputView = {
        let view = TagInputView()
        view.minimumTagCount = 1
        view.maximumTagCount = 3
        return view
    }()

    // Second separator (between memory1 and memory2)
    private let separator2View: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.border
        return view
    }()

    // Memory2 label (dark blue)
    private let memory2Label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    // Memory2 tag input view
    let memory2TagInput: TagInputView = {
        let view = TagInputView()
        view.minimumTagCount = 1
        view.maximumTagCount = 3
        return view
    }()

    func updateLocalizedText() {
        memory1Label.text = Lang("common.memory1")
        memory2Label.text = Lang("common.memory2")
        memory1TagInput.placeholder = Lang("places.placeholder.memory_tags")
        memory2TagInput.placeholder = Lang("places.placeholder.memory_tags")
        coordinateTextField.placeholder = Lang("recover.coord_placeholder")
        #if DEBUG
        testButton.setTitle(Lang("common.test"), for: .normal)
        #endif
    }

    var isComplete: Bool {
        let hasCoord = !(coordinateTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let hasNote1 = memory1TagInput.tags.count >= 1
        let hasNote2 = memory2TagInput.tags.count >= 1
        return hasCoord && hasNote1 && hasNote2
    }

    /// Get memory1 tags (normalized)
    var memory1Tags: [String] {
        return WujiMemoryTagProcessor.normalizedTags(memory1TagInput.tags)
    }

    /// Get memory2 tags (normalized)
    var memory2Tags: [String] {
        return WujiMemoryTagProcessor.normalizedTags(memory2TagInput.tags)
    }

    /// Get processed memory string (all tags merged, sorted + concatenated)
    /// Combines memory1 and memory2 tags for better fault tolerance during recovery
    var memoryProcessed: String {
        let allTags = memory1TagInput.tags + memory2TagInput.tags
        return WujiMemoryTagProcessor.process(allTags)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        updateLocalizedText()

        #if DEBUG
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(debugModeDidChange),
            name: .debugModeDidChange,
            object: nil
        )
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    #if DEBUG
    @objc private func debugModeDidChange() {
        testButton.isHidden = !DebugModeManager.shared.isEnabled
    }
    #endif

    func configure(index: Int) {
        locationIndex = index - 1
    }

    private func setupUI() {
        // Container (three rows)
        addSubview(containerView)
        containerView.addSubview(locationIconView)
        containerView.addSubview(coordinateTextField)
        #if DEBUG
        containerView.addSubview(testButton)
        #endif
        containerView.addSubview(separator1View)
        containerView.addSubview(memory1Label)
        containerView.addSubview(memory1TagInput)
        containerView.addSubview(separator2View)
        containerView.addSubview(memory2Label)
        containerView.addSubview(memory2TagInput)

        let allViews: [UIView] = [
            containerView, locationIconView, coordinateTextField,
            separator1View, memory1Label, memory1TagInput, separator2View, memory2Label, memory2TagInput
        ]
        allViews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        #if DEBUG
        testButton.translatesAutoresizingMaskIntoConstraints = false
        #endif

        NSLayoutConstraint.activate([
            // Container card
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Location row: icon + coordinate field
            locationIconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            locationIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            locationIconView.widthAnchor.constraint(equalToConstant: 20),
            locationIconView.heightAnchor.constraint(equalToConstant: 20),

            coordinateTextField.leadingAnchor.constraint(equalTo: locationIconView.trailingAnchor, constant: 8),
            coordinateTextField.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            coordinateTextField.heightAnchor.constraint(equalToConstant: 32),

            // First separator
            separator1View.topAnchor.constraint(equalTo: locationIconView.bottomAnchor, constant: 12),
            separator1View.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            separator1View.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separator1View.heightAnchor.constraint(equalToConstant: 1),

            // Memory1 row
            memory1Label.topAnchor.constraint(equalTo: separator1View.bottomAnchor, constant: 12),
            memory1Label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            memory1Label.centerYAnchor.constraint(equalTo: memory1TagInput.centerYAnchor),

            memory1TagInput.leadingAnchor.constraint(equalTo: memory1Label.trailingAnchor, constant: 8),
            memory1TagInput.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            memory1TagInput.topAnchor.constraint(equalTo: separator1View.bottomAnchor, constant: 8),
            memory1TagInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            // Second separator
            separator2View.topAnchor.constraint(equalTo: memory1TagInput.bottomAnchor, constant: 8),
            separator2View.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            separator2View.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separator2View.heightAnchor.constraint(equalToConstant: 1),

            // Memory2 row
            memory2Label.topAnchor.constraint(equalTo: separator2View.bottomAnchor, constant: 12),
            memory2Label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            memory2Label.centerYAnchor.constraint(equalTo: memory2TagInput.centerYAnchor),

            memory2TagInput.leadingAnchor.constraint(equalTo: memory2Label.trailingAnchor, constant: 8),
            memory2TagInput.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            memory2TagInput.topAnchor.constraint(equalTo: separator2View.bottomAnchor, constant: 8),
            memory2TagInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
            memory2TagInput.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
        ])

        // Coordinate text field trailing constraint (conditional based on DEBUG)
        #if DEBUG
        NSLayoutConstraint.activate([
            testButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            testButton.centerYAnchor.constraint(equalTo: locationIconView.centerYAnchor),
            coordinateTextField.trailingAnchor.constraint(equalTo: testButton.leadingAnchor, constant: -8)
        ])
        #else
        coordinateTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16).isActive = true
        #endif

        // Add event listeners
        coordinateTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        memory1TagInput.onTagsChanged = { [weak self] in
            self?.delegate?.locationInputDidChange(self!)
        }
        memory2TagInput.onTagsChanged = { [weak self] in
            self?.delegate?.locationInputDidChange(self!)
        }
        #if DEBUG
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        #endif
    }

    @objc private func textFieldDidChange() {
        delegate?.locationInputDidChange(self)
    }

    #if DEBUG
    @objc private func testButtonTapped() {
        delegate?.locationInputDidTapTest(self, index: locationIndex)
    }
    #endif
}
