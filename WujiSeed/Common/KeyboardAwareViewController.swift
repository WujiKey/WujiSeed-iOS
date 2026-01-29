//
//  KeyboardAwareViewController.swift
//  WujiSeed
//
//  Keyboard-aware base class that automatically handles view adjustment when keyboard appears/hides
//

import UIKit

/// Keyboard-aware view controller base class
///
/// Subclasses inheriting from this class automatically get UI avoidance when keyboard appears/hides.
/// Usage:
/// 1. Inherit from this class
/// 2. Set `keyboardConstraint` to the constraint that needs adjustment (usually bottom button constraint)
/// 3. Set `defaultBottomConstant` to the constraint's default value (default -16)
class KeyboardAwareViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Properties

    /// Constraint to adjust with keyboard (usually bottom button's bottom constraint)
    var keyboardConstraint: NSLayoutConstraint?

    /// Constraint's default value (when keyboard is hidden)
    var defaultBottomConstant: CGFloat = -16

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardObservers()
        setupDismissKeyboardGesture()
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Keyboard Handling

    /// Setup keyboard notification observers
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

    /// Keyboard will show
    @objc private func keyboardWillShow(_ notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let constraint = keyboardConstraint else {
            return
        }

        let keyboardHeight = keyboardFrame.height

        // Validate keyboardHeight to prevent NaN errors
        guard keyboardHeight.isFinite && keyboardHeight > 0 else {
            return
        }

        // Validate view bounds before animating
        guard view.bounds.width.isFinite && view.bounds.height.isFinite,
              view.bounds.width > 0 && view.bounds.height > 0 else {
            return
        }

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.3

        // Calculate new constraint value
        let newConstant = -keyboardHeight - 16

        // Validate new constraint value
        guard newConstant.isFinite else {
            return
        }

        // Only update if the change is significant (more than 1pt difference)
        guard abs(constraint.constant - newConstant) > 1 else {
            return
        }

        // Update constraint to position view above keyboard
        constraint.constant = newConstant

        // Use safer animation approach - disable implicit animations during constraint update
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    /// Keyboard will hide
    @objc private func keyboardWillHide(_ notification: NSNotification) {
        guard let constraint = keyboardConstraint else {
            return
        }

        // Validate view bounds before animating
        guard view.bounds.width.isFinite && view.bounds.height.isFinite,
              view.bounds.width > 0 && view.bounds.height > 0 else {
            return
        }

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.3

        // Validate default constant
        guard defaultBottomConstant.isFinite else {
            return
        }

        // Only update if the change is significant
        guard abs(constraint.constant - defaultBottomConstant) > 1 else {
            return
        }

        // Restore constraint to default position
        constraint.constant = defaultBottomConstant

        // Use safer animation approach
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - Dismiss Keyboard

    /// Setup tap gesture to dismiss keyboard
    private func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    /// Dismiss keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - UIGestureRecognizerDelegate

    /// Allow gesture recognizer and other touch events to be recognized simultaneously
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    /// Allow gesture recognizer to receive touch events even on buttons and other controls
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't intercept touch events if touching a button or other control
        if touch.view is UIControl {
            return false
        }
        return true
    }
}
