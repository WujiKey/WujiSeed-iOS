//
//  AppDelegate.swift
//  WujiSeed
//

import UIKit

/// Custom navigation controller that defers status bar style to its children
class StatusBarDeferringNavigationController: UINavigationController {
    override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var offlineIndicator: UIView?
    private var offlineIndicatorLabel: UILabel?
    private let offlineIndicatorHeight: CGFloat = 18

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Global navigation bar configuration: hide back button text, show only arrow
        // Move back button text off screen (compatible with all iOS versions)
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), for: .default)

        // Set global navigation bar tint color to deep blue
        UINavigationBar.appearance().tintColor = Theme.Colors.elegantBlue

        let window = UIWindow(frame: UIScreen.main.bounds)
        let homeVC = HomeViewController()
        let navVC = StatusBarDeferringNavigationController(rootViewController: homeVC)
        navVC.navigationBar.isHidden = true  // Hide navigation bar on home screen

        // Set additional safe area insets BEFORE view controllers load their views
        if #available(iOS 11.0, *) {
            navVC.additionalSafeAreaInsets.top = offlineIndicatorHeight
        }

        window.rootViewController = navVC
        window.makeKeyAndVisible()
        self.window = window

        // Show launch screen (overlay method, bypasses system cache)
        showLaunchScreen(in: window)

        return true
    }

    // MARK: - Application Lifecycle

    /// Save draft when app enters background
    func applicationDidEnterBackground(_ application: UIApplication) {
        WujiLogger.debug("App entering background, posting save draft notification")
        // Post notification to let active ViewController save progress
        NotificationCenter.default.post(name: .applicationDidEnterBackground, object: nil)
    }

    /// Perform security check when app enters foreground
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Skip if security pre-check page hasn't been completed yet
        let hasSeenSecurityCheck = UserDefaults.standard.bool(forKey: "hasSeenSecurityCheck")
        guard hasSeenSecurityCheck else { return }

        performForegroundSecurityCheck()
    }

    private func performForegroundSecurityCheck() {
        let result = SecurityChecker.shared.performSecurityCheck()

        guard result.hasSecurityIssues else { return }

        // Build issue list
        var issueText = Lang("security.warning.message") + "\n\n"
        for key in result.getIssueKeys() {
            issueText += Lang(key) + "\n"
        }

        let alert = UIAlertController(
            title: Lang("security.warning.title"),
            message: issueText,
            preferredStyle: .alert
        )

        // Dismiss button
        let dismissAction = UIAlertAction(
            title: Lang("common.got_it"),
            style: .default,
            handler: nil
        )
        alert.addAction(dismissAction)

        // Present on top-most view controller
        DispatchQueue.main.async { [weak self] in
            self?.topViewController()?.present(alert, animated: true)
        }
    }

    /// Get the top-most presented view controller
    private func topViewController(from viewController: UIViewController? = nil) -> UIViewController? {
        let vc = viewController ?? window?.rootViewController

        if let nav = vc as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = vc as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        if let presented = vc?.presentedViewController {
            return topViewController(from: presented)
        }
        return vc
    }

    /// Save draft when app is about to terminate
    func applicationWillTerminate(_ application: UIApplication) {
        WujiLogger.debug("App about to terminate, posting save draft notification")
        // Post notification to let active ViewController save progress
        NotificationCenter.default.post(name: .applicationWillTerminate, object: nil)
    }

    private func showLaunchScreen(in window: UIWindow) {
        // Create launch screen view
        let launchView = UIView(frame: window.bounds)
        launchView.backgroundColor = .white

        // App logo (consistent with LaunchScreen.storyboard)
        let logoImageView = UIImageView(image: UIImage(named: "WUJI_logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle (uses system language, consistent with LaunchScreen.storyboard)
        let subtitleLabel = UILabel()
        subtitleLabel.text = Lang("home.enslogan")
        subtitleLabel.font = Theme.Fonts.largeTitleThin
        subtitleLabel.textColor = Theme.Colors.subtitleText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        launchView.addSubview(logoImageView)
        launchView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: launchView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: launchView.topAnchor, constant: launchView.bounds.height * 0.382),  // Golden ratio position
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 50),

            subtitleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: launchView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: launchView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: launchView.trailingAnchor, constant: -20)
        ])

        window.addSubview(launchView)

        // Fade out after 0.8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            UIView.animate(withDuration: 0.3, animations: {
                launchView.alpha = 0
            }, completion: { _ in
                launchView.removeFromSuperview()

                // Show offline indicator
                self.setupOfflineIndicator()

                // Show onboarding if first launch, then security check
                if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                    self.showOnboarding()
                } else {
                    // Show security pre-check if not seen before
                    self.showSecurityPreCheckIfNeeded()
                }
            })
        }
    }

    private func setupOfflineIndicator() {
        guard let window = window else { return }

        // Create container view (using secret tag colors)
        let containerView = UIView()
        containerView.backgroundColor = Theme.Colors.tagSecretBackground
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Content stack (lock + text)
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.spacing = 4
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Lock icon
        let lockLabel = UILabel()
        lockLabel.text = "🔒"
        lockLabel.font = .systemFont(ofSize: 10)

        // Text label
        let textLabel = UILabel()
        textLabel.text = Lang("app.offline_indicator")
        textLabel.font = .systemFont(ofSize: 11, weight: .medium)
        textLabel.textColor = Theme.Colors.tagSecretText

        contentStack.addArrangedSubview(lockLabel)
        contentStack.addArrangedSubview(textLabel)
        containerView.addSubview(contentStack)
        window.addSubview(containerView)

        // Store reference for language updates
        offlineIndicatorLabel = textLabel

        // Register for language change notifications
        NotificationCenter.default.addObserver(self, selector: #selector(languageDidChange), name: .languageDidChange, object: nil)

        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                // Extend from top of window to cover status bar area
                containerView.topAnchor.constraint(equalTo: window.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: offlineIndicatorHeight),

                // Position content just below safe area (status bar)
                contentStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -3),
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: window.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                containerView.heightAnchor.constraint(equalToConstant: 38),

                contentStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -3),
            ])
        }

        offlineIndicator = containerView

        // Fade in animation
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            containerView.alpha = 1
        }
    }

    @objc private func languageDidChange() {
        offlineIndicatorLabel?.text = Lang("app.offline_indicator")
    }

    private func showOnboarding() {
        let onboardingVC = OnboardingViewController()
        onboardingVC.modalPresentationStyle = .fullScreen
        onboardingVC.onComplete = { [weak self] in
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            self?.showSecurityPreCheckIfNeeded()
        }
        window?.rootViewController?.present(onboardingVC, animated: true)
    }

    private func showSecurityPreCheckIfNeeded() {
        let hasSeenSecurityCheck = UserDefaults.standard.bool(forKey: "hasSeenSecurityCheck")
        if !hasSeenSecurityCheck {
            // First time: show security pre-check page (will perform check after completion)
            let securityVC = SecurityPreCheckViewController()
            securityVC.modalPresentationStyle = .fullScreen
            window?.rootViewController?.present(securityVC, animated: true)
        } else {
            // Already seen: perform security check on app launch
            performForegroundSecurityCheck()
        }
    }

}

