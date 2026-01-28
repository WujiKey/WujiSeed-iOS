//
//  DebugModeManager.swift
//  WujiKey
//
//  Global debug mode manager - activated by tapping version label 3 times
//  State is persisted to UserDefaults
//

import Foundation

/// Notification posted when debug mode changes
extension Notification.Name {
    static let debugModeDidChange = Notification.Name("debugModeDidChange")
}

/// Singleton manager for runtime debug mode
/// Only available in DEBUG builds, but can be toggled at runtime
class DebugModeManager {

    static let shared = DebugModeManager()

    private let userDefaultsKey = "wujikey.debugMode"

    private init() {
        #if DEBUG
        // Load saved state from UserDefaults
        _isEnabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
        #endif
    }

    #if DEBUG
    private var _isEnabled: Bool = false

    /// Whether debug mode is currently enabled
    var isEnabled: Bool {
        get { _isEnabled }
        set {
            guard _isEnabled != newValue else { return }
            _isEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
            NotificationCenter.default.post(name: .debugModeDidChange, object: nil)
        }
    }

    /// Toggle debug mode on/off
    func toggle() {
        isEnabled.toggle()
    }

    /// Enable debug mode
    func enable() {
        isEnabled = true
    }

    /// Disable debug mode
    func disable() {
        isEnabled = false
    }
    #else
    /// In release builds, debug mode is always disabled
    var isEnabled: Bool { false }
    func toggle() {}
    func enable() {}
    func disable() {}
    #endif
}
