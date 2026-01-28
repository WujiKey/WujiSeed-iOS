//
//  TagInputView.swift
//  WujiKey
//
//  Tag-based input view for memory fragments
//  Users input keywords that form tags, which are normalized and sorted
//

import UIKit

/// Delegate protocol for TagInputView
protocol TagInputViewDelegate: AnyObject {
    /// Called when tags change (added or removed)
    func tagInputView(_ view: TagInputView, didChangeTags tags: [String])
}

// MARK: - BackspaceDetectingTextField

/// Custom UITextField that detects backspace on empty field
private class BackspaceDetectingTextField: UITextField {

    var onBackspaceWhenEmpty: (() -> Void)?

    override func deleteBackward() {
        // Check if text is empty before calling super
        let wasEmpty = text?.isEmpty ?? true
        super.deleteBackward()

        // If was empty, notify parent to delete last tag
        if wasEmpty {
            onBackspaceWhenEmpty?()
        }
    }
}

/// A view that allows users to input tags (keywords) for memory fragments
/// Supports automatic splitting by space, comma, semicolon (full/half-width)
class TagInputView: UIView, UITextFieldDelegate {

    // MARK: - Properties

    weak var delegate: TagInputViewDelegate?

    /// Callback when tags change (alternative to delegate)
    var onTagsChanged: (() -> Void)?

    /// Current raw tags (before normalization)
    private(set) var tags: [String] = []

    /// Minimum number of tags required
    var minimumTagCount: Int = 1

    /// Maximum number of tags allowed (0 = unlimited)
    var maximumTagCount: Int = 3

    /// Placeholder text for input field
    var placeholder: String = "" {
        didSet {
            updatePlaceholderVisibility()
        }
    }

    /// Get separator characters based on input content
    /// Space is only a separator when input contains CJK characters
    private func getSeparators(for text: String) -> CharacterSet {
        var chars = ",;，；、"
        if WujiMemoryTagProcessor.containsCJKCharacters(text) {
            chars += " "
        }
        return CharacterSet(charactersIn: chars)
    }

    // MARK: - UI Components

    private let inputField: BackspaceDetectingTextField = {
        let tf = BackspaceDetectingTextField()
        tf.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        tf.textColor = Theme.Colors.elegantBlue
        tf.tintColor = Theme.Colors.elegantBlue
        tf.borderStyle = .none
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.returnKeyType = .continue
        return tf
    }()

    private var tagViews: [TagItemView] = []

    // MARK: - Layout Constants

    private let tagSpacing: CGFloat = 6
    private let tagHeight: CGFloat = 28
    private let minInputWidth: CGFloat = 60

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        addSubview(inputField)

        inputField.delegate = self
        inputField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // Handle backspace on empty field - delete last tag
        inputField.onBackspaceWhenEmpty = { [weak self] in
            guard let self = self, !self.tags.isEmpty else { return }
            self.removeTag(at: self.tags.count - 1)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTagsAndInput()
    }

    // MARK: - Tag Layout

    private func layoutTagsAndInput() {
        let availableWidth = bounds.width
        guard availableWidth > 0 else { return }

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let lineHeight = tagHeight + tagSpacing

        // Layout existing tags
        for tagView in tagViews {
            let tagWidth = tagView.intrinsicContentSize.width

            // Check if need to wrap to next line
            if currentX + tagWidth > availableWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight
            }

            tagView.frame = CGRect(x: currentX, y: currentY, width: tagWidth, height: tagHeight)
            currentX += tagWidth + tagSpacing
        }

        // Layout input field
        let remainingWidth = availableWidth - currentX
        if remainingWidth < minInputWidth && currentX > 0 {
            // Move input to next line
            currentX = 0
            currentY += lineHeight
        }

        let inputWidth = max(minInputWidth, availableWidth - currentX)
        inputField.frame = CGRect(x: currentX, y: currentY, width: inputWidth, height: tagHeight)

        // Update placeholder visibility
        updatePlaceholderVisibility()

        // Notify layout change
        invalidateIntrinsicContentSize()
    }

    /// Update placeholder visibility based on tag count
    private func updatePlaceholderVisibility() {
        inputField.placeholder = tags.isEmpty ? placeholder : nil
        // Hide input field when maximum tags reached
        inputField.isHidden = maximumTagCount > 0 && tags.count >= maximumTagCount
    }

    override var intrinsicContentSize: CGSize {
        // Calculate based on actual layout
        let availableWidth = bounds.width > 0 ? bounds.width : 200
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let lineHeight = tagHeight + tagSpacing

        for tagView in tagViews {
            let tagWidth = tagView.intrinsicContentSize.width
            if currentX + tagWidth > availableWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight
            }
            currentX += tagWidth + tagSpacing
        }

        // Account for input field
        if availableWidth - currentX < minInputWidth && currentX > 0 {
            currentY += lineHeight
        }

        let totalHeight = currentY + tagHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
    }

    // MARK: - Tag Management

    /// Add a new tag
    func addTag(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Check maximum tag count
        if maximumTagCount > 0 && tags.count >= maximumTagCount {
            return
        }

        // Check for duplicates (case-insensitive after normalization)
        let normalized = WujiMemoryTagProcessor.normalizeTag(trimmed)
        let existingNormalized = tags.map { WujiMemoryTagProcessor.normalizeTag($0) }
        guard !existingNormalized.contains(normalized) else { return }

        tags.append(trimmed)

        let tagView = createTagView(for: trimmed)
        tagViews.append(tagView)
        addSubview(tagView)

        setNeedsLayout()
        layoutIfNeeded()
        delegate?.tagInputView(self, didChangeTags: tags)
        onTagsChanged?()
    }

    /// Remove a tag at index
    func removeTag(at index: Int) {
        guard index >= 0 && index < tags.count else { return }

        tags.remove(at: index)
        let tagView = tagViews.remove(at: index)
        tagView.removeFromSuperview()

        setNeedsLayout()
        layoutIfNeeded()
        delegate?.tagInputView(self, didChangeTags: tags)
        onTagsChanged?()
    }

    /// Clear all tags
    func clearTags() {
        tags.removeAll()
        tagViews.forEach { $0.removeFromSuperview() }
        tagViews.removeAll()

        setNeedsLayout()
        layoutIfNeeded()
        delegate?.tagInputView(self, didChangeTags: tags)
        onTagsChanged?()
    }

    /// Set tags programmatically
    func setTags(_ newTags: [String]) {
        // Clear existing
        tagViews.forEach { $0.removeFromSuperview() }
        tagViews.removeAll()
        tags.removeAll()

        // Add new tags (respecting maximum limit)
        for tag in newTags {
            if maximumTagCount > 0 && tags.count >= maximumTagCount {
                break
            }

            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            tags.append(trimmed)
            let tagView = createTagView(for: trimmed)
            tagViews.append(tagView)
            addSubview(tagView)
        }

        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()

        delegate?.tagInputView(self, didChangeTags: tags)
        onTagsChanged?()
    }

    /// Get normalized and sorted result string
    func getNormalizedResult() -> String {
        return WujiMemoryTagProcessor.process(tags)
    }

    /// Get count of unique normalized tags
    func getUniqueTagCount() -> Int {
        return WujiMemoryTagProcessor.uniqueCount(tags)
    }

    // MARK: - Tag View Creation

    private func createTagView(for text: String) -> TagItemView {
        let tagView = TagItemView(text: text)
        tagView.onDelete = { [weak self] in
            guard let self = self,
                  let index = self.tagViews.firstIndex(of: tagView) else { return }
            self.removeTag(at: index)
        }
        return tagView
    }

    // MARK: - UITextFieldDelegate

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else { return }

        // Check for separator characters (space only for CJK input)
        let components = text.components(separatedBy: getSeparators(for: text))

        if components.count > 1 {
            // Has separators - process all complete tags
            for i in 0..<(components.count - 1) {
                let tag = components[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if !tag.isEmpty {
                    addTag(tag)
                }
            }
            // Keep the last part in input field
            textField.text = components.last?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Add current input as tag on Return
        if let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addTag(text)
            textField.text = ""
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Auto-convert remaining text to tag when losing focus
        if let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addTag(text)
            textField.text = ""
        }
    }

    // MARK: - First Responder

    override var canBecomeFirstResponder: Bool {
        return true
    }

    /// Check if any subview is currently first responder
    var containsFirstResponder: Bool {
        return inputField.isFirstResponder
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return inputField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        // Add any remaining text as tag before resigning
        if let text = inputField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addTag(text)
            inputField.text = ""
        }
        return inputField.resignFirstResponder()
    }

    // MARK: - Touch Handling

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // First check if we hit a tag view's delete button
        for tagView in tagViews {
            let tagPoint = tagView.convert(point, from: self)
            if let hitView = tagView.hitTest(tagPoint, with: event) {
                return hitView
            }
        }

        // Check if we hit the input field
        let inputPoint = inputField.convert(point, from: self)
        if inputField.bounds.contains(inputPoint) {
            return inputField
        }

        // If we hit anywhere else in our bounds, return self (will focus input)
        if bounds.contains(point) {
            return inputField  // Redirect to input field
        }

        return nil
    }
}

// MARK: - TagItemView

/// Individual tag item view with delete button (uses frame-based layout)
private class TagItemView: UIView {

    var onDelete: (() -> Void)?

    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.Colors.elegantBlue
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("×", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.setTitleColor(Theme.MinimalTheme.textSecondary, for: .normal)
        button.setTitleColor(Theme.Colors.elegantBlue, for: .highlighted)
        return button
    }()

    init(text: String) {
        super.init(frame: .zero)
        label.text = text
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Theme.Colors.blueBackground
        layer.cornerRadius = 6
        layer.borderWidth = 0.5
        layer.borderColor = Theme.Colors.borderBlue.cgColor

        addSubview(label)
        addSubview(deleteButton)

        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Frame-based layout for label and delete button
        let labelSize = label.intrinsicContentSize
        let buttonWidth: CGFloat = 24
        let height = bounds.height

        label.frame = CGRect(
            x: 8,
            y: (height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )

        deleteButton.frame = CGRect(
            x: 8 + labelSize.width + 2,
            y: 0,
            width: buttonWidth,
            height: height
        )
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    override var intrinsicContentSize: CGSize {
        let labelSize = label.intrinsicContentSize
        return CGSize(width: labelSize.width + 36, height: 28)  // 8 + label + 2 + 24 + 2
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Check delete button first with expanded hit area
        let buttonFrame = deleteButton.frame.insetBy(dx: -8, dy: -8)
        if buttonFrame.contains(point) {
            return deleteButton
        }
        return super.hitTest(point, with: event)
    }
}
