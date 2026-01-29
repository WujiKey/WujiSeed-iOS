//
//  SessionStateManager.swift
//  WujiSeed
//
//

import Foundation

/// Session state manager (Singleton)
/// Used to save and restore user input data across different pages
class SessionStateManager {

    // MARK: - Singleton

    static let shared = SessionStateManager()

    private init() {}

    // MARK: - Name Data

    /// WujiName (normalized name + salt for Argon2id)
    var name: WujiName?

    // MARK: - Generation Data

    /// 5 position codes (1-9 digits, used for backup encryption)
    var positionCodes: [Int] = []

    /// Places: 5 keyMaterials (sorted, binary Data, used for WujiReserve encryption)
    var keyMaterials: [Data] = []

    // MARK: - Backup Data

    /// Generated 24 seed phrase words (for backup)
    var mnemonics: [String] = []

    /// WujiReserve structured data (use .encode() to get binary for storage)
    var reserveData: WujiReserveData?

    // MARK: - Clear All Data

    /// Clear all wizard state (used when completing or canceling the flow)
    func clearAll() {
        // Name
        name = nil

        // Generation
        positionCodes = []
        keyMaterials = []

        // Backup
        mnemonics = []
        reserveData = nil
    }
}
