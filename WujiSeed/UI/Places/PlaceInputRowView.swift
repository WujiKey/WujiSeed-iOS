//
//  PlaceInputRowView.swift
//  WujiSeed
//
//  Places input view - Coordinates + notes on one page
//

import UIKit

class PlaceInputRowView: UIView, UITextFieldDelegate, TagInputViewDelegate {

    var locationIndex = 0 {  // Current location index (0-4)
        didSet {
            updateTitle()
        }
    }
    var latitudeText = "" {
        didSet {
            // Sync to UI when property is set (if UI is initialized)
            if latitudeField.superview != nil {
                latitudeField.text = latitudeText
                validateAllInputs()
            }
        }
    }
    var longitudeText = "" {
        didSet {
            // Sync to UI when property is set (if UI is initialized)
            if longitudeField.superview != nil {
                longitudeField.text = longitudeText
                validateAllInputs()
            }
        }
    }
    var memory1Tags: [String] = [] {
        didSet {
            // Sync to UI when property is set (if UI is initialized)
            if memory1TagInput.superview != nil {
                memory1TagInput.setTags(memory1Tags)
                validateAllInputs()
            }
        }
    }
    var memory2Tags: [String] = [] {
        didSet {
            // Sync to UI when property is set (if UI is initialized)
            if memory2TagInput.superview != nil {
                memory2TagInput.setTags(memory2Tags)
                validateAllInputs()
            }
        }
    }

    /// For backward compatibility - get normalized result from tags
    var memory1Text: String {
        get { WujiMemoryTagProcessor.process(memory1Tags) }
        set { memory1Tags = WujiMemoryTagProcessor.parseTags(from: newValue) }
    }
    var memory2Text: String {
        get { WujiMemoryTagProcessor.process(memory2Tags) }
        set { memory2Tags = WujiMemoryTagProcessor.parseTags(from: newValue) }
    }
    var buttonTitle: String = "" {  // Button text, default from localization
        didSet {
            nextButton.setTitle(buttonTitle.isEmpty ? Lang("common.next") : buttonTitle, for: .normal)
        }
    }
    var onComplete: ((String, String, [String], [String]) -> Void)?  // (lat, lon, memory1Tags, memory2Tags)
    var onShowGuide: (() -> Void)?  // Show coordinate guide
    var onShowExamples: (() -> Void)?  // Show memory examples
    #if DEBUG
    var onFillTestData: (() -> Void)?  // Fill test data
    #endif

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Top title
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = Theme.MinimalTheme.textPrimary
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let secretLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 0.8, green: 0.3, blue: 0.0, alpha: 1.0)  // Deep orange-red text
        label.backgroundColor = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.15)  // Light orange background
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.textInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        return label
    }()

    #if DEBUG
    private let testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        button.isHidden = !DebugModeManager.shared.isEnabled
        return button
    }()
    #endif

    private let hintView: UIView = {
        let view = UIView()
        // Design D: Light blue background + rounded corners
        view.backgroundColor = UIColor(red: 0.0, green: 0.17, blue: 0.36, alpha: 0.05)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private let guideButton: UIButton = {
        let button = UIButton(type: .system)

        // Use icon (iOS 13+) or text
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let icon = UIImage(systemName: "map.fill", withConfiguration: config)
            button.setImage(icon, for: .normal)
            button.setTitle(" How to Get", for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        } else {
            button.setTitle("📍 How to Get", for: .normal)
        }

        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.backgroundColor = Theme.Colors.elegantBlue
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        return button
    }()

    private let examplesButton: UIButton = {
        let button = UIButton(type: .system)

        // Use icon (iOS 13+) or text
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            let icon = UIImage(systemName: "lightbulb.fill", withConfiguration: config)
            button.setImage(icon, for: .normal)
            button.setTitle(" Examples", for: .normal)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        } else {
            button.setTitle("💡 Examples", for: .normal)
        }

        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.backgroundColor = Theme.Colors.elegantBlue
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        return button
    }()

    // Coordinate container (card with border)
    private let coordContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.cardBackground
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.5
        view.layer.borderColor = Theme.MinimalTheme.border.cgColor
        return view
    }()

    // Latitude label
    private let latitudeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // Latitude input field (no border, monospace font)
    private let latitudeField: UITextField = {
        let tf = UITextField()
        // Use SF Mono font for consistent display
        if #available(iOS 13.0, *) {
            tf.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        } else {
            tf.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        }
        tf.textColor = Theme.Colors.elegantBlue
        tf.borderStyle = .none
        tf.keyboardType = .decimalPad
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        return tf
    }()

    // Latitude paste button
    private lazy var latitudePasteButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(pasteCoordinate), for: .touchUpInside)
        return button
    }()

    // Coordinate separator line
    private let coordSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.border
        return view
    }()

    // Longitude label
    private let longitudeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // Longitude input field (no border, monospace font)
    private let longitudeField: UITextField = {
        let tf = UITextField()
        // Use SF Mono font for consistent display
        if #available(iOS 13.0, *) {
            tf.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        } else {
            tf.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        }
        tf.textColor = Theme.Colors.elegantBlue
        tf.borderStyle = .none
        tf.keyboardType = .decimalPad
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        return tf
    }()

    // Longitude paste button
    private lazy var longitudePasteButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(Theme.Colors.elegantBlue, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(pasteCoordinate), for: .touchUpInside)
        return button
    }()

    // Memo input area
    private let noteHintView: UIView = {
        let view = UIView()
        // Design D: Light blue background + rounded corners (consistent with coordinate hint)
        view.backgroundColor = UIColor(red: 0.0, green: 0.17, blue: 0.36, alpha: 0.05)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private let noteHintLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    // Memo container (card with border)
    private let memoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.cardBackground
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.5
        view.layer.borderColor = Theme.MinimalTheme.border.cgColor
        return view
    }()

    // Memory 1 label
    private let memory1Label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // Memory 1 tag input view
    private let memory1TagInput: TagInputView = {
        let view = TagInputView()
        view.minimumTagCount = 1
        view.maximumTagCount = 3
        return view
    }()

    // Separator line
    private let memoSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.MinimalTheme.border
        return view
    }()

    // Memory 2 label
    private let memory2Label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = Theme.Colors.elegantBlue
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // Memory 2 tag input view
    private let memory2TagInput: TagInputView = {
        let view = TagInputView()
        view.minimumTagCount = 1
        view.maximumTagCount = 3
        return view
    }()

    // Coordinate error label
    private let coordErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // Memory error label
    private let memoryErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()


    // Bottom button area (fully transparent container)
    private let nextButtonBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .clear  // Fully transparent
        return view
    }()

    // Bottom button
    private var nextButtonBottomConstraint: NSLayoutConstraint?
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Theme.Colors.disabledButtonBackground  // Initial disabled state
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()

        #if DEBUG
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(debugModeDidChange),
            name: .debugModeDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotModeDidChange),
            name: .screenshotModeDidChange,
            object: nil
        )
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .white

        addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Top title area
        contentView.addSubview(titleLabel)
        contentView.addSubview(secretLabel)
        #if DEBUG
        contentView.addSubview(testButton)
        #endif

        // Top hint area (Design D: top color bar + light background)
        contentView.addSubview(hintView)
        hintView.addSubview(hintLabel)
        hintView.addSubview(guideButton)

        // Add top brand blue bar (2pt height)
        let topAccent = UIView()
        topAccent.tag = 998
        topAccent.backgroundColor = Theme.Colors.elegantBlue
        topAccent.translatesAutoresizingMaskIntoConstraints = false
        hintView.addSubview(topAccent)
        NSLayoutConstraint.activate([
            topAccent.leadingAnchor.constraint(equalTo: hintView.leadingAnchor),
            topAccent.topAnchor.constraint(equalTo: hintView.topAnchor),
            topAccent.trailingAnchor.constraint(equalTo: hintView.trailingAnchor),
            topAccent.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Coordinate area (using container card)
        contentView.addSubview(coordContainerView)
        coordContainerView.addSubview(latitudeLabel)
        coordContainerView.addSubview(latitudeField)
        coordContainerView.addSubview(latitudePasteButton)
        coordContainerView.addSubview(coordSeparatorView)
        coordContainerView.addSubview(longitudeLabel)
        coordContainerView.addSubview(longitudeField)
        coordContainerView.addSubview(longitudePasteButton)
        contentView.addSubview(coordErrorLabel)

        // Memo hint area (Design D: top color bar + light background)
        contentView.addSubview(noteHintView)
        noteHintView.addSubview(noteHintLabel)
        noteHintView.addSubview(examplesButton)

        // Add top blue bar (2pt height, consistent with coordinate hint)
        let noteTopAccent = UIView()
        noteTopAccent.tag = 999
        noteTopAccent.backgroundColor = Theme.Colors.elegantBlue
        noteTopAccent.translatesAutoresizingMaskIntoConstraints = false
        noteHintView.addSubview(noteTopAccent)
        NSLayoutConstraint.activate([
            noteTopAccent.leadingAnchor.constraint(equalTo: noteHintView.leadingAnchor),
            noteTopAccent.topAnchor.constraint(equalTo: noteHintView.topAnchor),
            noteTopAccent.trailingAnchor.constraint(equalTo: noteHintView.trailingAnchor),
            noteTopAccent.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Memo input area (using container card)
        contentView.addSubview(memoContainerView)
        memoContainerView.addSubview(memory1Label)
        memoContainerView.addSubview(memory1TagInput)
        memoContainerView.addSubview(memoSeparatorView)
        memoContainerView.addSubview(memory2Label)
        memoContainerView.addSubview(memory2TagInput)
        contentView.addSubview(memoryErrorLabel)

        // Button (add background first, then button)
        addSubview(nextButtonBackground)
        addSubview(nextButton)

        // Set delegates and events
        latitudeField.delegate = self
        longitudeField.delegate = self
        memory1TagInput.delegate = self
        memory2TagInput.delegate = self

        latitudeField.text = latitudeText
        longitudeField.text = longitudeText

        // Set memo tags
        memory1TagInput.setTags(memory1Tags)
        memory2TagInput.setTags(memory2Tags)

        latitudeField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        longitudeField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)
        #if DEBUG
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        #endif
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        guideButton.addTarget(self, action: #selector(guideButtonTapped), for: .touchUpInside)
        examplesButton.addTarget(self, action: #selector(examplesButtonTapped), for: .touchUpInside)

        setupToolbar()
        setupConstraints()

        // Initial validation
        inputChanged()

        // Update title
        updateTitle()

        // Setup hint text styles (reference NameSalt)
        setupHintTextStyles()

        // Setup localized text
        updateLocalizedText()

        // Setup keyboard observers
        setupKeyboardObservers()

        // Initial test button visibility
        #if DEBUG
        updateTestButtonVisibility()
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    #if DEBUG
    @objc private func debugModeDidChange() {
        updateTestButtonVisibility()
    }

    @objc private func screenshotModeDidChange() {
        updateTestButtonVisibility()
    }

    private func updateTestButtonVisibility() {
        // Hide Test button if debug mode is off
        if !DebugModeManager.shared.isEnabled {
            testButton.isHidden = true
            return
        }

        // In screenshot mode: invisible but still tappable
        testButton.isHidden = false
        testButton.alpha = TestConfig.shared.screenshotMode ? 0 : 1
    }
    #endif

    override func layoutSubviews() {
        super.layoutSubviews()

        // Calculate button area height and set scrollView bottom contentInset
        let buttonAreaHeight = nextButtonBackground.frame.height
        if buttonAreaHeight > 0 && buttonAreaHeight.isFinite {
            scrollView.contentInset.bottom = buttonAreaHeight
            scrollView.scrollIndicatorInsets.bottom = buttonAreaHeight
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height

        UIView.animate(withDuration: duration) {
            // Adjust button position to be above keyboard
            self.nextButtonBottomConstraint?.constant = -keyboardHeight - 16

            // Update scrollView contentInset to adapt to button position
            let buttonAreaHeight = self.nextButtonBackground.frame.height
            if buttonAreaHeight > 0 && buttonAreaHeight.isFinite {
                self.scrollView.contentInset.bottom = buttonAreaHeight
                self.scrollView.scrollIndicatorInsets.bottom = buttonAreaHeight
            }

            // Force layout update
            self.layoutIfNeeded()
        }

        // Delay scroll to ensure layout update completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // Scroll to active input field
            if self.memory1TagInput.isFirstResponder || self.memory1TagInput.containsFirstResponder {
                let rect = self.memory1TagInput.convert(self.memory1TagInput.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            } else if self.memory2TagInput.isFirstResponder || self.memory2TagInput.containsFirstResponder {
                let rect = self.memory2TagInput.convert(self.memory2TagInput.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            } else if self.latitudeField.isFirstResponder {
                let rect = self.latitudeField.convert(self.latitudeField.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            } else if self.longitudeField.isFirstResponder {
                let rect = self.longitudeField.convert(self.longitudeField.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: duration) {
            // Restore button position
            self.nextButtonBottomConstraint?.constant = -16

            // Restore scrollView contentInset
            let buttonAreaHeight = self.nextButtonBackground.frame.height
            if buttonAreaHeight > 0 && buttonAreaHeight.isFinite {
                self.scrollView.contentInset.bottom = buttonAreaHeight
                self.scrollView.scrollIndicatorInsets.bottom = buttonAreaHeight
            }

            // Force layout update
            self.layoutIfNeeded()
        }
    }

    private func updateTitle() {
        titleLabel.text = Lang("places.title.find_places")
    }

    private func updateLocalizedText() {
        // Title and tag
        titleLabel.text = Lang("places.title.find_places")
        secretLabel.text = Lang("tag.secret")

        // Labels
        latitudeLabel.text = Lang("common.latitude")
        longitudeLabel.text = Lang("common.longitude")
        memory1Label.text = Lang("common.memory1")
        memory2Label.text = Lang("common.memory2")

        // Placeholders
        latitudeField.placeholder = Lang("places.placeholder.latitude")
        longitudeField.placeholder = Lang("places.placeholder.longitude")
        memory1TagInput.placeholder = Lang("places.placeholder.memory_tags")
        memory2TagInput.placeholder = Lang("places.placeholder.memory_tags")

        // Buttons
        latitudePasteButton.setTitle(Lang("common.paste"), for: .normal)
        longitudePasteButton.setTitle(Lang("common.paste"), for: .normal)

        // Guide button
        if #available(iOS 13.0, *) {
            guideButton.setTitle(Lang("places.button.how_to_get"), for: .normal)
        } else {
            guideButton.setTitle("📍" + Lang("places.button.how_to_get"), for: .normal)
        }

        // Examples button
        if #available(iOS 13.0, *) {
            examplesButton.setTitle(Lang("places.button.examples"), for: .normal)
        } else {
            examplesButton.setTitle("💡" + Lang("places.button.examples"), for: .normal)
        }

        // Next button (if not custom)
        if buttonTitle.isEmpty {
            nextButton.setTitle(Lang("common.next"), for: .normal)
        }
    }

    private func setupHintTextStyles() {
        // Top hint text (Design 2: Navy blue - professional, trustworthy)
        let hintText = Lang("places.hint.coordinates")
        let hintParagraphStyle = NSMutableParagraphStyle()
        hintParagraphStyle.lineSpacing = 8  // Consistent with NameSalt

        let attributedHint = NSAttributedString(
            string: hintText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                .foregroundColor: UIColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1.0),  // #1E3A5F Navy blue
                .paragraphStyle: hintParagraphStyle
            ]
        )
        hintLabel.attributedText = attributedHint

        // Memo hint text (keep navy blue - consistent with coordinate hint)
        let noteHintText = Lang("places.hint.memos")
        let noteParagraphStyle = NSMutableParagraphStyle()
        noteParagraphStyle.lineSpacing = 8  // Consistent with NameSalt

        let attributedNoteHint = NSAttributedString(
            string: noteHintText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                .foregroundColor: UIColor(red: 0.12, green: 0.23, blue: 0.37, alpha: 1.0),  // Navy blue, consistent with coordinate hint
                .paragraphStyle: noteParagraphStyle
            ]
        )
        noteHintLabel.attributedText = attributedNoteHint
    }

    private func setupToolbar() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let decimalButton = UIBarButtonItem(title: ".", style: .plain, target: self, action: #selector(insertDecimal))
        let negativeButton = UIBarButtonItem(title: "-", style: .plain, target: self, action: #selector(insertNegative))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: Lang("common.done"), style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [negativeButton, decimalButton, flexSpace, doneButton]

        latitudeField.inputAccessoryView = toolbar
        longitudeField.inputAccessoryView = toolbar
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        secretLabel.translatesAutoresizingMaskIntoConstraints = false
        #if DEBUG
        testButton.translatesAutoresizingMaskIntoConstraints = false
        #endif
        hintView.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        guideButton.translatesAutoresizingMaskIntoConstraints = false
        coordContainerView.translatesAutoresizingMaskIntoConstraints = false
        latitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        latitudeField.translatesAutoresizingMaskIntoConstraints = false
        latitudePasteButton.translatesAutoresizingMaskIntoConstraints = false
        coordSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        longitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        longitudeField.translatesAutoresizingMaskIntoConstraints = false
        longitudePasteButton.translatesAutoresizingMaskIntoConstraints = false
        noteHintView.translatesAutoresizingMaskIntoConstraints = false
        noteHintLabel.translatesAutoresizingMaskIntoConstraints = false
        examplesButton.translatesAutoresizingMaskIntoConstraints = false
        memoContainerView.translatesAutoresizingMaskIntoConstraints = false
        memory1Label.translatesAutoresizingMaskIntoConstraints = false
        memory1TagInput.translatesAutoresizingMaskIntoConstraints = false
        memoSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        memory2Label.translatesAutoresizingMaskIntoConstraints = false
        memory2TagInput.translatesAutoresizingMaskIntoConstraints = false
        coordErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        memoryErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        // Helper to create constraints with high (but not required) priority for trailing edges
        // This prevents conflicts with _UITemporaryLayoutWidth during initial layout
        func highPriorityTrailing(_ constraint: NSLayoutConstraint) -> NSLayoutConstraint {
            constraint.priority = UILayoutPriority(999)
            return constraint
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highPriorityTrailing(scrollView.trailingAnchor.constraint(equalTo: trailingAnchor)),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            highPriorityTrailing(contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            highPriorityTrailing(contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)),

            // Top title: Find five memorable places + Secret
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),

            secretLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            secretLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            secretLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            secretLabel.heightAnchor.constraint(equalToConstant: 22),

            // Top hint area (Design D: top color bar + light background)
            hintView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            hintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            highPriorityTrailing(hintView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)),

            hintLabel.topAnchor.constraint(equalTo: hintView.topAnchor, constant: 14),  // 2pt color bar + 12pt padding
            hintLabel.leadingAnchor.constraint(equalTo: hintView.leadingAnchor, constant: 12),
            highPriorityTrailing(hintLabel.trailingAnchor.constraint(equalTo: hintView.trailingAnchor, constant: -12)),

            guideButton.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 2),
            highPriorityTrailing(guideButton.trailingAnchor.constraint(equalTo: hintView.trailingAnchor, constant: -10)),
            guideButton.bottomAnchor.constraint(equalTo: hintView.bottomAnchor, constant: -10),
            guideButton.heightAnchor.constraint(equalToConstant: 30),

            // Coordinate container card
            coordContainerView.topAnchor.constraint(equalTo: hintView.bottomAnchor, constant: 8),
            coordContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            highPriorityTrailing(coordContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)),

            // Latitude row
            latitudeLabel.topAnchor.constraint(equalTo: coordContainerView.topAnchor, constant: 12),
            latitudeLabel.leadingAnchor.constraint(equalTo: coordContainerView.leadingAnchor, constant: 12),
            latitudeLabel.widthAnchor.constraint(equalToConstant: 36),

            latitudeField.leadingAnchor.constraint(equalTo: latitudeLabel.trailingAnchor, constant: 8),
            highPriorityTrailing(latitudeField.trailingAnchor.constraint(equalTo: latitudePasteButton.leadingAnchor, constant: -8)),
            latitudeField.centerYAnchor.constraint(equalTo: latitudeLabel.centerYAnchor),
            latitudeField.heightAnchor.constraint(equalToConstant: 32),

            highPriorityTrailing(latitudePasteButton.trailingAnchor.constraint(equalTo: coordContainerView.trailingAnchor, constant: -12)),
            latitudePasteButton.centerYAnchor.constraint(equalTo: latitudeLabel.centerYAnchor),

            // Coordinate separator line
            coordSeparatorView.topAnchor.constraint(equalTo: latitudeLabel.bottomAnchor, constant: 12),
            coordSeparatorView.leadingAnchor.constraint(equalTo: coordContainerView.leadingAnchor, constant: 12),
            highPriorityTrailing(coordSeparatorView.trailingAnchor.constraint(equalTo: coordContainerView.trailingAnchor, constant: -12)),
            coordSeparatorView.heightAnchor.constraint(equalToConstant: 1),

            // Longitude row
            longitudeLabel.topAnchor.constraint(equalTo: coordSeparatorView.bottomAnchor, constant: 12),
            longitudeLabel.leadingAnchor.constraint(equalTo: coordContainerView.leadingAnchor, constant: 12),
            longitudeLabel.widthAnchor.constraint(equalToConstant: 36),
            longitudeLabel.bottomAnchor.constraint(equalTo: coordContainerView.bottomAnchor, constant: -12),

            longitudeField.leadingAnchor.constraint(equalTo: longitudeLabel.trailingAnchor, constant: 8),
            highPriorityTrailing(longitudeField.trailingAnchor.constraint(equalTo: longitudePasteButton.leadingAnchor, constant: -8)),
            longitudeField.centerYAnchor.constraint(equalTo: longitudeLabel.centerYAnchor),
            longitudeField.heightAnchor.constraint(equalToConstant: 32),

            highPriorityTrailing(longitudePasteButton.trailingAnchor.constraint(equalTo: coordContainerView.trailingAnchor, constant: -12)),
            longitudePasteButton.centerYAnchor.constraint(equalTo: longitudeLabel.centerYAnchor),

            // Coordinate error label
            coordErrorLabel.topAnchor.constraint(equalTo: coordContainerView.bottomAnchor, constant: 4),
            coordErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            highPriorityTrailing(coordErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18)),

            // Memo hint area (Design D: top color bar + light background)
            noteHintView.topAnchor.constraint(equalTo: coordErrorLabel.bottomAnchor, constant: 12),
            noteHintView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            highPriorityTrailing(noteHintView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)),

            noteHintLabel.topAnchor.constraint(equalTo: noteHintView.topAnchor, constant: 14),  // 2pt color bar + 12pt padding
            noteHintLabel.leadingAnchor.constraint(equalTo: noteHintView.leadingAnchor, constant: 12),
            highPriorityTrailing(noteHintLabel.trailingAnchor.constraint(equalTo: noteHintView.trailingAnchor, constant: -12)),

            examplesButton.topAnchor.constraint(equalTo: noteHintLabel.bottomAnchor, constant: 2),
            highPriorityTrailing(examplesButton.trailingAnchor.constraint(equalTo: noteHintView.trailingAnchor, constant: -10)),
            examplesButton.bottomAnchor.constraint(equalTo: noteHintView.bottomAnchor, constant: -10),
            examplesButton.heightAnchor.constraint(equalToConstant: 30),

            // Memo container card
            memoContainerView.topAnchor.constraint(equalTo: noteHintView.bottomAnchor, constant: 8),
            memoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            highPriorityTrailing(memoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)),

            // Memory 1 row
            memory1Label.leadingAnchor.constraint(equalTo: memoContainerView.leadingAnchor, constant: 12),
            memory1Label.centerYAnchor.constraint(equalTo: memory1TagInput.centerYAnchor),

            memory1TagInput.leadingAnchor.constraint(equalTo: memory1Label.trailingAnchor, constant: 8),
            highPriorityTrailing(memory1TagInput.trailingAnchor.constraint(equalTo: memoContainerView.trailingAnchor, constant: -12)),
            memory1TagInput.topAnchor.constraint(equalTo: memoContainerView.topAnchor, constant: 12),
            memory1TagInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            // Separator line
            memoSeparatorView.topAnchor.constraint(equalTo: memory1TagInput.bottomAnchor, constant: 12),
            memoSeparatorView.leadingAnchor.constraint(equalTo: memoContainerView.leadingAnchor, constant: 12),
            highPriorityTrailing(memoSeparatorView.trailingAnchor.constraint(equalTo: memoContainerView.trailingAnchor, constant: -12)),
            memoSeparatorView.heightAnchor.constraint(equalToConstant: 1),

            // Memory 2 row
            memory2Label.leadingAnchor.constraint(equalTo: memoContainerView.leadingAnchor, constant: 12),
            memory2Label.centerYAnchor.constraint(equalTo: memory2TagInput.centerYAnchor),

            memory2TagInput.leadingAnchor.constraint(equalTo: memory2Label.trailingAnchor, constant: 8),
            highPriorityTrailing(memory2TagInput.trailingAnchor.constraint(equalTo: memoContainerView.trailingAnchor, constant: -12)),
            memory2TagInput.topAnchor.constraint(equalTo: memoSeparatorView.bottomAnchor, constant: 12),
            memory2TagInput.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
            memory2TagInput.bottomAnchor.constraint(equalTo: memoContainerView.bottomAnchor, constant: -12),

            // Memory error label
            memoryErrorLabel.topAnchor.constraint(equalTo: memoContainerView.bottomAnchor, constant: 4),
            memoryErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            highPriorityTrailing(memoryErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18)),
            memoryErrorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // Button background (fully transparent container, extends from button top to view bottom)
            nextButtonBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            highPriorityTrailing(nextButtonBackground.trailingAnchor.constraint(equalTo: trailingAnchor)),
            nextButtonBackground.topAnchor.constraint(equalTo: nextButton.topAnchor, constant: -16),
            nextButtonBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Button
            nextButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            highPriorityTrailing(nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)),
            nextButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        #if DEBUG
        NSLayoutConstraint.activate([
            testButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            highPriorityTrailing(testButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16))
        ])
        #endif

        // Save button bottom constraint for keyboard adjustment
        nextButtonBottomConstraint = nextButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
        nextButtonBottomConstraint?.isActive = true
    }

    // MARK: - Actions

    @objc private func inputChanged() {
        validateAllInputs()
    }

    private func validateAllInputs() {
        let latText = latitudeField.text ?? ""
        let lonText = longitudeField.text ?? ""

        // Validate coordinates (format and range)
        let coordResult = validateCoordinates(lat: latText, lon: lonText)

        // Validate coordinate precision (at least 4 decimal places)
        var coordErrors: [String] = []
        if coordResult.isValid {
            if let latError = validateCoordinatePrecision(latText, coordName: Lang("common.latitude")) {
                coordErrors.append(latError)
            }
            if let lonError = validateCoordinatePrecision(lonText, coordName: Lang("common.longitude")) {
                coordErrors.append(lonError)
            }
        }
        let coordPrecisionValid = coordErrors.isEmpty

        // Update coordinate error label
        // Only show red border when there's an actual error message (not when just empty)
        if !coordResult.isValid && !coordResult.message.isEmpty {
            coordErrorLabel.text = coordResult.message
            coordErrorLabel.isHidden = false
            coordContainerView.layer.borderColor = UIColor.systemRed.cgColor
        } else if !coordPrecisionValid {
            coordErrorLabel.text = coordErrors.joined(separator: "\n")
            coordErrorLabel.isHidden = false
            coordContainerView.layer.borderColor = UIColor.systemRed.cgColor
        } else if !latText.isEmpty && !lonText.isEmpty {
            coordErrorLabel.isHidden = true
            coordContainerView.layer.borderColor = Theme.MinimalTheme.stable.cgColor
        } else {
            // Empty fields - use default border, no error
            coordErrorLabel.isHidden = true
            coordContainerView.layer.borderColor = Theme.MinimalTheme.border.cgColor
        }

        // Validate memories (tag count >= 1, max 3, not identical)
        let tags1 = memory1TagInput.tags
        let tags2 = memory2TagInput.tags
        let tag1Count = memory1TagInput.getUniqueTagCount()
        let tag2Count = memory2TagInput.getUniqueTagCount()
        let tags1Empty = tags1.isEmpty
        let tags2Empty = tags2.isEmpty

        let normalized1 = memory1TagInput.getNormalizedResult()
        let normalized2 = memory2TagInput.getNormalizedResult()

        var memoryErrors: [String] = []
        // Note: minimum 1 tag is enforced by checking !tags1Empty below
        // Maximum 3 tags is enforced by TagInputView.maximumTagCount

        // Check if memory1 and memory2 are identical after normalization
        if !tags1Empty && !tags2Empty && normalized1 == normalized2 {
            memoryErrors.append(Lang("places.error.same_memory_in_location_inline"))
        }

        let memoryValid = memoryErrors.isEmpty

        // Update memory error label
        if !memoryErrors.isEmpty {
            memoryErrorLabel.text = memoryErrors.joined(separator: "\n")
            memoryErrorLabel.isHidden = false
            memoContainerView.layer.borderColor = UIColor.systemRed.cgColor
        } else if !tags1Empty && !tags2Empty && tag1Count >= 1 && tag2Count >= 1 {
            memoryErrorLabel.isHidden = true
            memoContainerView.layer.borderColor = Theme.MinimalTheme.stable.cgColor
        } else {
            memoryErrorLabel.isHidden = true
            memoContainerView.layer.borderColor = Theme.MinimalTheme.border.cgColor
        }

        // Update button state (min 1 tag per memory)
        let allValid = coordResult.isValid && coordPrecisionValid && tag1Count >= 1 && tag2Count >= 1 && memoryValid
        nextButton.isEnabled = allValid
        nextButton.backgroundColor = allValid ? Theme.Colors.elegantBlue : Theme.Colors.disabledButtonBackground
    }

    private func validateCoordinates(lat: String, lon: String) -> (isValid: Bool, message: String, color: UIColor) {
        guard !lat.isEmpty && !lon.isEmpty else {
            return (false, "", Theme.MinimalTheme.textSecondary)
        }

        guard let latValue = Double(lat), let lonValue = Double(lon) else {
            return (false, Lang("places.validation.format_error"), .systemRed)
        }

        let latValid = latValue >= -90 && latValue <= 90
        let lonValid = lonValue >= -180 && lonValue <= 180

        if !latValid {
            return (false, Lang("places.validation.lat_range_error"), .systemRed)
        }

        if !lonValid {
            return (false, Lang("places.validation.lon_range_error"), .systemRed)
        }

        return (true, "", Theme.MinimalTheme.stable)
    }

    /// Validate coordinate precision (at least 4 decimal places for ~11m accuracy)
    private func validateCoordinatePrecision(_ value: String, coordName: String) -> String? {
        guard let dotIndex = value.firstIndex(of: ".") else {
            return Lang("places.error.dd_precision_short")
        }

        let decimalPart = value[value.index(after: dotIndex)...]
        let digits = decimalPart.filter { $0.isNumber }
        if digits.count < 4 {
            return Lang("places.error.dd_precision_short")
        }

        return nil
    }

    #if DEBUG
    @objc private func testButtonTapped() {
        onFillTestData?()
    }
    #endif

    // MARK: - Public Methods

    /// Update input field display content (called when restoring data from DataManager)
    /// Note: memory1/memory2 strings are parsed into tags
    func updateFields(latitude: String, longitude: String, memory1: String, memory2: String) {
        // Update coordinate input fields
        latitudeField.text = latitude
        longitudeField.text = longitude

        // Update memo tag inputs (parse string back to tags)
        let tags1 = WujiMemoryTagProcessor.parseTags(from: memory1)
        let tags2 = WujiMemoryTagProcessor.parseTags(from: memory2)
        memory1TagInput.setTags(tags1)
        memory2TagInput.setTags(tags2)

        // Trigger validation logic and update button state
        inputChanged()
    }

    /// Update with tag arrays directly
    func updateFieldsWithTags(latitude: String, longitude: String, memory1Tags: [String], memory2Tags: [String]) {
        latitudeField.text = latitude
        longitudeField.text = longitude
        memory1TagInput.setTags(memory1Tags)
        memory2TagInput.setTags(memory2Tags)
        inputChanged()
    }

    /// Get current input data with normalized tag arrays
    func getCurrentInputWithTags() -> (latitude: String, longitude: String, memory1Tags: [String], memory2Tags: [String]) {
        let lat = latitudeField.text ?? ""
        let lon = longitudeField.text ?? ""
        let tags1 = WujiMemoryTagProcessor.normalizedTags(memory1TagInput.tags)
        let tags2 = WujiMemoryTagProcessor.normalizedTags(memory2TagInput.tags)
        return (lat, lon, tags1, tags2)
    }

    /// Get current tags (raw, before normalization)
    func getCurrentTags() -> (memory1Tags: [String], memory2Tags: [String]) {
        return (memory1TagInput.tags, memory2TagInput.tags)
    }

    @objc private func nextButtonTapped() {
        let lat = latitudeField.text ?? ""
        let lon = longitudeField.text ?? ""
        // Return normalized tag arrays (not sorted/concatenated)
        let tags1 = WujiMemoryTagProcessor.normalizedTags(memory1TagInput.tags)
        let tags2 = WujiMemoryTagProcessor.normalizedTags(memory2TagInput.tags)

        onComplete?(lat, lon, tags1, tags2)
    }

    @objc private func guideButtonTapped() {
        // Prevent rapid repeated taps
        guideButton.isUserInteractionEnabled = false
        onShowGuide?()

        // Re-enable after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.guideButton.isUserInteractionEnabled = true
        }
    }

    @objc private func examplesButtonTapped() {
        // Prevent rapid repeated taps
        examplesButton.isUserInteractionEnabled = false
        onShowExamples?()

        // Re-enable after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.examplesButton.isUserInteractionEnabled = true
        }
    }

    @objc private func pasteCoordinate() {
        #if DEBUG
        // In screenshot mode, paste button triggers test data fill
        if TestConfig.shared.screenshotMode {
            onFillTestData?()
            return
        }
        #endif

        // Check pasteboard content
        guard let pasteboardString = UIPasteboard.general.string else {
            return
        }

        // Use LatLngParser to parse coordinates
        let result = LatLngParser.parse(pasteboardString)
        if result.isValid {
            latitudeField.text = String(format: "%.6f", result.latitude)
            longitudeField.text = String(format: "%.6f", result.longitude)
            inputChanged()
        }
    }

    @objc private func insertDecimal() {
        if let activeField = [latitudeField, longitudeField].first(where: { $0.isFirstResponder }),
           !(activeField.text?.contains(".") ?? false) {
            activeField.insertText(".")
        }
    }

    @objc private func insertNegative() {
        if let activeField = [latitudeField, longitudeField].first(where: { $0.isFirstResponder }) {
            if let text = activeField.text, !text.isEmpty {
                if text.hasPrefix("-") {
                    activeField.text = String(text.dropFirst())
                } else {
                    activeField.text = "-" + text
                }
            } else {
                activeField.insertText("-")
            }
            inputChanged()
        }
    }

    @objc private func dismissKeyboard() {
        endEditing(true)
    }

    // MARK: - UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == latitudeField || textField == longitudeField {
            let allowedCharacters = CharacterSet(charactersIn: "0123456789.-")
            let characterSet = CharacterSet(charactersIn: string)

            if !allowedCharacters.isSuperset(of: characterSet) {
                return false
            }

            if string == "-" && range.location != 0 {
                return false
            }

            if string == "." && (textField.text?.contains(".") ?? false) {
                return false
            }
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == latitudeField {
            longitudeField.becomeFirstResponder()
        } else if textField == longitudeField {
            memory1TagInput.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    // MARK: - TagInputViewDelegate

    func tagInputView(_ view: TagInputView, didChangeTags tags: [String]) {
        validateAllInputs()
    }
}
