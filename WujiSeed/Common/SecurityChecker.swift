//
//  SecurityChecker.swift
//  WujiSeed
//
//  Security detection tool - checks device security status
//

import Foundation
import UIKit
import SystemConfiguration
import CoreTelephony
import CoreBluetooth
import MachO

/// Security detection tool
class SecurityChecker: NSObject {

    // MARK: - Singleton

    static let shared = SecurityChecker()

    private override init() {
        super.init()
    }

    // MARK: - Network Detection

    /// Network status
    struct NetworkStatus {
        var isWiFiEnabled: Bool
        var isCellularEnabled: Bool
        var isBluetoothEnabled: Bool

        var hasAnyConnection: Bool {
            return isWiFiEnabled || isCellularEnabled
        }

        var isFullyOffline: Bool {
            return !isWiFiEnabled && !isCellularEnabled && !isBluetoothEnabled
        }
    }

    /// Check network status
    func checkNetworkStatus() -> NetworkStatus {
        return NetworkStatus(
            isWiFiEnabled: isWiFiConnected(),
            isCellularEnabled: isCellularConnected(),
            isBluetoothEnabled: isBluetoothEnabled()
        )
    }

    /// Check Wi-Fi connection
    private func isWiFiConnected() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isWWAN = flags.contains(.isWWAN)

        return isReachable && !needsConnection && !isWWAN
    }

    /// Check cellular connection
    private func isCellularConnected() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)

        return isReachable && isWWAN
    }

    /// Check Bluetooth status
    private func isBluetoothEnabled() -> Bool {
        // Note: Cannot directly check Bluetooth status, requires user authorization
        // Return conservative estimate here
        return false  // Assume disabled unless confirmed enabled
    }

    // MARK: - Jailbreak Detection

    /// Check for jailbreak
    func isJailbroken() -> Bool {
        // Method 1: Check jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Method 2: Check if can write to system directory
        let testPath = "/private/jailbreak.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true  // Can write to system directory = jailbroken
        } catch {
            // Cannot write = normal
        }

        // Method 3: Check URL scheme
        if let url = URL(string: "cydia://package/com.example.package") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        // Method 4: Check dyld
        #if arch(arm64) || arch(x86_64)
        let suspiciousLibraries = [
            "MobileSubstrate",
            "Substrate",
            "FridaGadget"
        ]

        for i in 0..<_dyld_image_count() {
            if let imageName = String(validatingUTF8: _dyld_get_image_name(i)) {
                for lib in suspiciousLibraries {
                    if imageName.lowercased().contains(lib.lowercased()) {
                        return true
                    }
                }
            }
        }
        #endif

        return false
    }

    // MARK: - MDM Detection

    /// Check for MDM management
    func isMDMManaged() -> Bool {
        // Check configuration profile
        if let _ = try? String(contentsOfFile: "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/CloudConfigurationDetails.plist") {
            return true
        }

        // Check enterprise certificate
        #if !targetEnvironment(simulator)
        if let provisioningPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") {
            do {
                let provisioningData = try Data(contentsOf: URL(fileURLWithPath: provisioningPath))
                let provisioningString = String(decoding: provisioningData, as: UTF8.self)

                // Check for MDM-related fields
                if provisioningString.contains("ProvisionsAllDevices") {
                    return true
                }
            } catch {
                // Cannot read
            }
        }
        #endif

        return false
    }

    // MARK: - Screen Capture Detection

    /// Check if screen is being captured (recording or mirroring)
    /// Available on iOS 11+
    func isScreenBeingCaptured() -> Bool {
        if #available(iOS 11.0, *) {
            return UIScreen.main.isCaptured
        }
        return false
    }

    /// Check if screen is being mirrored (external display connected)
    func isScreenMirrored() -> Bool {
        // If there are multiple screens, mirroring or external display is active
        return UIScreen.screens.count > 1
    }

    // MARK: - Comprehensive Security Check

    /// Security check result
    struct SecurityCheckResult {
        var isJailbroken: Bool
        var isScreenCaptured: Bool
        var isScreenMirrored: Bool
        var isMDMManaged: Bool

        var hasSecurityIssues: Bool {
            return isJailbroken || isScreenCaptured || isScreenMirrored || isMDMManaged
        }

        /// Get list of detected issues
        func getIssueKeys() -> [String] {
            var issues: [String] = []
            if isJailbroken {
                issues.append("security.warning.jailbroken")
            }
            if isScreenCaptured {
                issues.append("security.warning.screen_captured")
            }
            if isScreenMirrored {
                issues.append("security.warning.screen_mirrored")
            }
            if isMDMManaged {
                issues.append("security.warning.mdm_managed")
            }
            return issues
        }
    }

    /// Perform comprehensive security check
    func performSecurityCheck() -> SecurityCheckResult {
        return SecurityCheckResult(
            isJailbroken: isJailbroken(),
            isScreenCaptured: isScreenBeingCaptured(),
            isScreenMirrored: isScreenMirrored(),
            isMDMManaged: isMDMManaged()
        )
    }

    // MARK: - Device Info

    /// Get device info
    func getDeviceInfo() -> String {
        var info = ""

        info += "Device Model: \(UIDevice.current.model)\n"
        info += "System Version: iOS \(UIDevice.current.systemVersion)\n"
        info += "Device Name: \(UIDevice.current.name)\n"

        #if targetEnvironment(simulator)
        info += "⚠️ Simulator Environment\n"
        #endif

        return info
    }

    /// Check if running in simulator
    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
