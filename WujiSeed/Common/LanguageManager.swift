//
//  LanguageManager.swift
//  WujiSeed
//
//  Language manager using iOS native .strings files
//

import Foundation
import UIKit

/// Shorthand function for localization
func Lang(_ key: String) -> String {
    return LanguageManager.shared.localizedString(key)
}

/// Supported language types
enum AppLanguage: String, CaseIterable {
    case english = "en"              // English
    case chineseSimplified = "zh-Hans"   // Simplified Chinese
    case chineseTraditional = "zh-Hant"  // Traditional Chinese
    case japanese = "ja"             // Japanese
    case spanish = "es"              // Spanish

    /// Display name
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .japanese: return "日本語"
        case .spanish: return "Español"
        }
    }

    /// Whether this language uses RTL (right-to-left) layout
    var isRTL: Bool {
        return false
    }
}

/// Language manager
class LanguageManager {
    static let shared = LanguageManager()

    private let languageKey = "app_language"

    /// Cached bundle for current language
    private var localizedBundle: Bundle?

    private init() {
        // On first launch, set default based on system language to match LaunchScreen
        if UserDefaults.standard.string(forKey: languageKey) == nil {
            let systemLanguage = detectSystemLanguage()
            UserDefaults.standard.set(systemLanguage.rawValue, forKey: languageKey)
            #if DEBUG
            WujiLogger.info("First launch, saving system language: \(systemLanguage.rawValue)")
            #endif
        } else {
            #if DEBUG
            let savedLanguage = UserDefaults.standard.string(forKey: languageKey) ?? "unknown"
            WujiLogger.info("Existing language setting: \(savedLanguage)")
            #endif
        }

        // Load bundle for current language
        updateLocalizedBundle()

        // Apply RTL direction on init
        updateLayoutDirection()
    }

    /// Detect system language
    private func detectSystemLanguage() -> AppLanguage {
        let systemLanguage = Locale.preferredLanguages.first ?? ""
        #if DEBUG
        WujiLogger.info("Detecting system language: \(systemLanguage)")
        #endif

        // Traditional Chinese detection
        if systemLanguage.hasPrefix("zh-Hant") ||  // Traditional Chinese
           systemLanguage.hasPrefix("zh-TW") ||    // Taiwan
           systemLanguage.hasPrefix("zh-HK") ||    // Hong Kong
           systemLanguage.hasPrefix("zh-MO") {     // Macau
            #if DEBUG
            WujiLogger.info("Detected Traditional Chinese")
            #endif
            return .chineseTraditional
        }

        // Simplified Chinese detection
        if systemLanguage.hasPrefix("zh-Hans") ||  // Simplified Chinese
           systemLanguage.hasPrefix("zh-CN") ||    // Mainland China
           systemLanguage.hasPrefix("zh-SG") ||    // Singapore
           systemLanguage.hasPrefix("zh") {        // Other Chinese
            #if DEBUG
            WujiLogger.info("Detected Simplified Chinese")
            #endif
            return .chineseSimplified
        }

        // Japanese detection
        if systemLanguage.hasPrefix("ja") {
            #if DEBUG
            WujiLogger.info("Detected Japanese")
            #endif
            return .japanese
        }

        // Spanish detection
        if systemLanguage.hasPrefix("es") {
            #if DEBUG
            WujiLogger.info("Detected Spanish")
            #endif
            return .spanish
        }

        // English or other
        #if DEBUG
        WujiLogger.info("Detected English or other language, defaulting to English")
        #endif
        return .english
    }

    /// Current language
    var currentLanguage: AppLanguage {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: languageKey),
               let language = AppLanguage(rawValue: rawValue) {
                return language
            }
            return .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            updateLocalizedBundle()
            updateLayoutDirection()
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
            #if DEBUG
            WujiLogger.info("Language changed to: \(newValue.rawValue)")
            #endif
        }
    }

    /// Update the cached localized bundle based on current language
    private func updateLocalizedBundle() {
        let languageCode = currentLanguage.rawValue

        // Try to find the .lproj bundle for the selected language
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            localizedBundle = bundle
            #if DEBUG
            WujiLogger.info("Loaded localization bundle for: \(languageCode)")
            #endif
        } else {
            // Fallback to main bundle (will use Base or device language)
            localizedBundle = Bundle.main
            #if DEBUG
            WujiLogger.warning("Could not find bundle for \(languageCode), using main bundle")
            #endif
        }
    }

    /// Get localized string for key
    func localizedString(_ key: String) -> String {
        guard let bundle = localizedBundle else {
            return NSLocalizedString(key, comment: "")
        }

        let localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)

        // If the key is returned as-is, it means translation was not found
        if localizedString == key {
            // Try main bundle as fallback
            let fallback = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
            if fallback != key {
                return fallback
            }
            // Return key itself if no translation found (helps identify missing translations)
            #if DEBUG
            WujiLogger.warning("Missing translation for key: \(key)")
            #endif
            return key
        }

        return localizedString
    }

    /// Update layout direction for RTL languages
    func updateLayoutDirection() {
        let direction: UISemanticContentAttribute = currentLanguage.isRTL ? .forceRightToLeft : .forceLeftToRight

        // Set appearance for new views
        UIView.appearance().semanticContentAttribute = direction
        UINavigationBar.appearance().semanticContentAttribute = direction
        UITabBar.appearance().semanticContentAttribute = direction
        UISearchBar.appearance().semanticContentAttribute = direction
        UITextField.appearance().semanticContentAttribute = direction
        UITextView.appearance().semanticContentAttribute = direction

        // Update existing windows
        DispatchQueue.main.async {
            for window in UIApplication.shared.windows {
                window.semanticContentAttribute = direction
                self.updateSemanticContentAttribute(for: window, direction: direction)
                window.setNeedsLayout()
                window.layoutIfNeeded()
            }
        }

        #if DEBUG
        WujiLogger.info("Layout direction updated: \(currentLanguage.isRTL ? "RTL" : "LTR")")
        #endif
    }

    /// Recursively update semantic content attribute for all subviews
    private func updateSemanticContentAttribute(for view: UIView, direction: UISemanticContentAttribute) {
        view.semanticContentAttribute = direction
        for subview in view.subviews {
            updateSemanticContentAttribute(for: subview, direction: direction)
        }
    }
}

/// Language change notification
extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
    static let applicationDidEnterBackground = Notification.Name("applicationDidEnterBackground")
    static let applicationWillTerminate = Notification.Name("applicationWillTerminate")
}
