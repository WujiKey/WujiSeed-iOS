//
//  QRScannerViewController.swift
//  WujiKey
//
//  QR code scanner page
//

import UIKit
import AVFoundation

class QRScannerViewController: UIViewController {

    weak var delegate: QRScannerDelegate?

    // MARK: - UI Components

    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    private let scanFrameView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 8
        view.backgroundColor = .clear
        return view
    }()

    private let instructionLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.textInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        // Text set in updateLocalizedText()
        label.font = Theme.Fonts.bodyMedium
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0  // Support multiline for longer languages
        label.backgroundColor = Theme.Colors.overlayDark
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        // Title set in updateLocalizedText()
        btn.titleLabel?.font = Theme.Fonts.title
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.Colors.overlayDark
        btn.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        return btn
    }()

    private let photoButton: UIButton = {
        let btn = UIButton(type: .system)
        // Title set in updateLocalizedText()
        btn.titleLabel?.font = Theme.Fonts.title
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = Theme.Colors.overlayDark
        btn.layer.cornerRadius = Theme.Layout.mediumCornerRadius
        return btn
    }()

    // MARK: - Capture Session

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        setupUI()
        setupConstraints()
        setupCaptureSession()
        updateLocalizedText()
    }

    // MARK: - Localization

    private func updateLocalizedText() {
        instructionLabel.text = Lang("qrscanner.instruction")
        cancelButton.setTitle(Lang("common.cancel"), for: .normal)

        // Photo button with SF Symbol icon only
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: config)
            photoButton.setImage(image, for: .normal)
            photoButton.tintColor = .white
        }
        photoButton.setTitle(nil, for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hasScanned = false
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(previewView)
        view.addSubview(scanFrameView)
        view.addSubview(instructionLabel)
        view.addSubview(photoButton)
        view.addSubview(cancelButton)

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(photoTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        scanFrameView.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        photoButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Preview fills entire view
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Scan frame (square in center)
            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            scanFrameView.widthAnchor.constraint(equalToConstant: 250),
            scanFrameView.heightAnchor.constraint(equalToConstant: 250),

            // Instruction label - flexible width with max constraint
            instructionLabel.topAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 30),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),

            // Photo button (From Album)
            photoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            photoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            photoButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            photoButton.heightAnchor.constraint(equalToConstant: 50),

            // Cancel button
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showError(Lang("qrscanner.error.camera"))
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showError(Lang("qrscanner.error.camera"))
            return
        }

        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            showError(Lang("qrscanner.error.camera_input"))
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showError(Lang("qrscanner.error.metadata"))
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = previewView.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer!)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.qrScannerDidCancel(self)
    }

    @objc private func photoTapped() {
        // Pause scanning
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }

        // Open photo library picker
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: Lang("common.error"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default) { _ in
            self.delegate?.qrScannerDidCancel(self)
        })
        present(alert, animated: true)
    }

    private func found(code: String) {
        guard !hasScanned else { return }
        hasScanned = true

        // Haptic feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        delegate?.qrScannerDidScan(self, qrString: code)
    }

    private func foundBinaryData(_ data: Data) {
        guard !hasScanned else { return }
        hasScanned = true

        // Haptic feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        delegate?.qrScannerDidScan(self, binaryData: data)
    }

    /// Parse QR code from image (supports binary mode)
    private func parseQRCode(from image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            showAlert(title: Lang("common.error"), message: Lang("qrscanner.error.cannot_read"))
            return
        }

        #if DEBUG
        WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        WujiLogger.info("Starting QR code parsing from image")
        #endif

        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]

        guard let qrFeature = features?.first else {
            #if DEBUG
            WujiLogger.error("❌ No QR code detected in image")
            WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            showAlert(title: Lang("common.error"), message: Lang("qrscanner.error.no_qr"))
            return
        }

        // Prefer binaryValue (extract raw binary data via CIQRCodeDescriptor)
        if let binaryData = qrFeature.binaryValue {
            #if DEBUG
            WujiLogger.info("✅ Using CIQRCodeDescriptor to extract binary data")
            WujiLogger.info("   Data size: \(binaryData.count) bytes")
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
            foundBinaryData(binaryData)
            return
        }

        // Fallback: use messageString + Latin-1 encoding
        if let messageString = qrFeature.messageString {
            #if DEBUG
            WujiLogger.warning("⚠️ CIQRCodeDescriptor unavailable, falling back to Latin-1 parsing")
            WujiLogger.info("   String length: \(messageString.count) chars")
            let preview = String(messageString.prefix(32))
            WujiLogger.info("   String preview: \(preview)...")
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif

            // Try to convert to binary
            if let data = messageString.data(using: .isoLatin1) {
                foundBinaryData(data)
            } else {
                found(code: messageString)
            }
            return
        }

        #if DEBUG
        WujiLogger.error("❌ Unable to extract data from QR code")
        WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
        showAlert(title: Lang("common.error"), message: Lang("qrscanner.error.parse_failed"))
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Lang("common.ok"), style: .default) { _ in
            // Resume scanning
            if self.captureSession?.isRunning == false {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession?.startRunning()
                }
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                #if DEBUG
                WujiLogger.warning("QR code object type error")
                #endif
                return
            }

            #if DEBUG
            WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            WujiLogger.info("Live camera detected QR code")
            #endif

            // Prefer binaryValue (extract raw binary data via CIQRCodeDescriptor)
            if let binaryData = readableObject.binaryValue {
                #if DEBUG
                WujiLogger.info("✅ Using CIQRCodeDescriptor to extract binary data")
                WujiLogger.info("   Data size: \(binaryData.count) bytes")
                WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                #endif
                foundBinaryData(binaryData)
                return
            }

            // Fallback: use stringValue + Latin-1 encoding
            if let stringValue = readableObject.stringValue {
                #if DEBUG
                WujiLogger.warning("⚠️ CIQRCodeDescriptor unavailable, falling back to Latin-1 parsing")
                WujiLogger.info("   String length: \(stringValue.count) chars")
                let preview = String(stringValue.prefix(32))
                WujiLogger.info("   String preview: \(preview)...")
                WujiLogger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                #endif

                // Try to convert to binary
                if let data = stringValue.data(using: .isoLatin1) {
                    foundBinaryData(data)
                } else {
                    found(code: stringValue)
                }
                return
            }

            #if DEBUG
            WujiLogger.error("❌ Unable to extract data from QR code")
            WujiLogger.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            #endif
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension QRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            showAlert(title: Lang("common.error"), message: Lang("qrscanner.error.cannot_read"))
            return
        }

        parseQRCode(from: image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)

        // Resume scanning
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }
    }
}
