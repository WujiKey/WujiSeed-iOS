//
//  UIViewController+Alerts.swift
//  WujiSeed
//
//  Provides Alert and Toast extension methods for UIViewController
//

import UIKit

extension UIViewController {

    /// Show standard alert dialog
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message content
    ///   - completion: Callback after OK button is tapped
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    /// Show Toast notification (auto-dismisses, doesn't affect keyboard state)
    /// - Parameters:
    ///   - message: Toast message
    ///   - duration: Display duration, default 1.5 seconds
    ///   - anchorView: Optional reference view, Toast will be displayed below it. If nil, displayed at bottom of screen
    func showToast(message: String, duration: TimeInterval = 1.5, anchorView: UIView? = nil) {
        #if DEBUG
        WujiLogger.debug("[showToast] Showing Toast: \(message)")
        #endif

        // Create Toast view
        let toastView = UIView()
        toastView.backgroundColor = Theme.Colors.toastBackground
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = Theme.Fonts.bodySemibold
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        toastView.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Get window (supports iOS 13+ scene-based architecture)
        var window: UIWindow?

        // Prefer current view's window
        if let viewWindow = self.view.window {
            window = viewWindow
        } else if #available(iOS 13.0, *) {
            // iOS 13+ uses scene-based architecture
            window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })
        } else {
            // iOS 12 uses legacy windows API
            window = UIApplication.shared.keyWindow
        }

        guard let targetWindow = window else {
            #if DEBUG
            WujiLogger.warning("[showToast] Unable to get window")
            #endif
            return
        }

        targetWindow.addSubview(toastView)
        toastView.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = [
            messageLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -12),

            toastView.centerXAnchor.constraint(equalTo: targetWindow.centerXAnchor),
            toastView.leadingAnchor.constraint(greaterThanOrEqualTo: targetWindow.leadingAnchor, constant: 40),
            toastView.trailingAnchor.constraint(lessThanOrEqualTo: targetWindow.trailingAnchor, constant: -40)
        ]

        // If anchor view is provided, display Toast below it; otherwise display at bottom of screen
        if let anchor = anchorView {
            // Convert anchor view's bottom coordinate to window coordinate system
            let anchorBottomInWindow = anchor.convert(CGPoint(x: 0, y: anchor.bounds.maxY), to: targetWindow)
            constraints.append(toastView.topAnchor.constraint(equalTo: targetWindow.topAnchor, constant: anchorBottomInWindow.y + 6))
        } else {
            constraints.append(toastView.bottomAnchor.constraint(equalTo: targetWindow.safeAreaLayoutGuide.bottomAnchor, constant: -100))
        }

        NSLayoutConstraint.activate(constraints)

        // Initial state: transparent
        toastView.alpha = 0

        // Animate show
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1.0
        }) { _ in
            // Animate hide after delay
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                toastView.alpha = 0
            }) { _ in
                toastView.removeFromSuperview()
            }
        }
    }
}
