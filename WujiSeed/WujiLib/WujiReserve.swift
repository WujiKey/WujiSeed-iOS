//
//  WujiReserve.swift
//  WujiSeed
//
//  F9 Reserve - encryption and decryption operations for mnemonic backup
//

import Foundation

/// F9 Reserve - Encryption/decryption for 24 BIP39 mnemonics
enum WujiReserve {

    // MARK: - Constants

    /// Current version number
    static let currentVersion: UInt8 = 0x01

    /// Required mnemonic word count
    static let mnemonicCount = 24

    /// Required location count
    static let locationCount = 5

    /// Number of locations used per encryption block
    static let locationsPerBlock = 3

    /// C(5,3)=10 combinations (pre-computed)
    private static let combinations: [[Int]] = [
        [0, 1, 2], [0, 1, 3], [0, 1, 4], [0, 2, 3], [0, 2, 4],
        [0, 3, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [2, 3, 4]
    ]

    /// Calculate optimal Argon2id concurrency based on device performance
    /// - Returns: Optimal number of concurrent Argon2id operations (1-4)
    private static func optimalArgon2idConcurrency() -> Int {
        let cpuCount = ProcessInfo.processInfo.activeProcessorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory

        // Argon2id uses 256MB per operation (CryptoUtils.WujiArgon2idMem = 256 * 1024 KB)
        // Reserve at least 1GB for system and app
        let argon2idMemoryMB = CryptoUtils.WujiArgon2idMem / 1024  // 256 MB
        let memoryForArgon2id = max(0, Int64(physicalMemory) - 1024 * 1024 * 1024)
        let maxByMemory = Int(memoryForArgon2id / Int64(argon2idMemoryMB * 1024 * 1024))

        // CPU-based limit: use half of available cores (leave room for AEAD and UI)
        let maxByCPU = max(1, cpuCount / 2)

        // Final concurrency: min of memory and CPU limits, capped at 1-4
        let concurrency = min(min(maxByMemory, maxByCPU), 4)

        #if DEBUG
        WujiLogger.info("WujiReserve: Device has \(cpuCount) cores, \(physicalMemory / 1024 / 1024)MB RAM, Argon2id uses \(argon2idMemoryMB)MB → concurrency: \(max(1, concurrency))")
        #endif

        return max(1, concurrency)
    }

    // MARK: - Data Sizes

    /// Seed phrase data size in bytes (264 bits = 33 bytes)
    /// 24 words × 11 bits = 264 bits = 256 bits entropy + 8 bits checksum
    static let mnemonicDataSize = 33

    /// Random padding size in bytes (16 bytes = 128 bits)
    /// Each block gets unique random padding to ensure different ciphertexts
    private static let paddingSize = 16

    /// Total plaintext size per block (seed phrase + padding)
    private static let plaintextSize = mnemonicDataSize + paddingSize  // 49 bytes

    // MARK: - Errors

    /// Errors that can occur during WujiReserve operations
    enum Error: Swift.Error, LocalizedError {
        case invalidMnemonicCount(Int)
        case invalidLocationCount(Int)
        case invalidPositionCode(Int)
        case invalidNameSalt
        case mnemonicToEntropyFailed
        case entropyToMnemonicFailed
        case positionCodeEncodingFailed
        case keyDerivationFailed(Int)
        case encryptionFailed(Int)
        case serializationFailed
        case libsodiumInitFailed
        case libsodiumNotAvailable
        case positionCodeMismatch(input: [Int], stored: [Int])
        case aadConstructionFailed
        case decryptionFailed
        case parseError(WujiReserveData.Error)

        var errorDescription: String? {
            switch self {
            case .invalidMnemonicCount(let count):
                return "Seed phrase word count must be \(mnemonicCount), got: \(count)"
            case .invalidLocationCount(let count):
                return "Location count must be \(locationCount), got: \(count)"
            case .invalidPositionCode(let code):
                return "Position code out of range (1-9): \(code)"
            case .invalidNameSalt:
                return "Name salt must be \(CryptoUtils.WujiArgon2idSaltLength) bytes"
            case .mnemonicToEntropyFailed:
                return "Failed to convert seed phrase to 256-bit entropy"
            case .entropyToMnemonicFailed:
                return "Failed to convert entropy to 24 seed phrase words"
            case .positionCodeEncodingFailed:
                return "Position code encoding failed"
            case .keyDerivationFailed(let index):
                return "Combination \(index) key derivation failed"
            case .encryptionFailed(let index):
                return "Combination \(index) encryption failed"
            case .serializationFailed:
                return "Serialization failed"
            case .libsodiumInitFailed:
                return "libsodium initialization failed"
            case .libsodiumNotAvailable:
                return "Clibsodium not available"
            case .positionCodeMismatch(let input, let stored):
                return "Position code mismatch: input \(input) vs stored \(stored)"
            case .aadConstructionFailed:
                return "AAD construction failed"
            case .decryptionFailed:
                return "Unable to decrypt with current location info"
            case .parseError(let error):
                return error.errorDescription
            }
        }
    }

    // MARK: - Types

    /// Successful encryption output
    struct EncryptedOutput {
        let data: Data
        let reserveData: WujiReserveData
    }

    /// Recovery statistics for UI display
    struct RecoveryStatistics {
        let totalAttempts: Int          // Total combination attempts
        let argon2idCalls: Int          // Actual Argon2id computations
        let cacheHits: Int              // Cache hits (saved Argon2id calls)
        let totalArgon2idTime: TimeInterval  // Total time spent on Argon2id
        let concurrency: Int            // Number of parallel Argon2id

        /// Average time per Argon2id call
        var averageArgon2idTime: TimeInterval {
            argon2idCalls > 0 ? totalArgon2idTime / Double(argon2idCalls) : 0
        }

        /// Cache hit rate as percentage
        var cacheHitRate: Double {
            totalAttempts > 0 ? Double(cacheHits) / Double(totalAttempts) * 100 : 0
        }

        /// Estimated time saved by caching (in seconds)
        var estimatedTimeSaved: TimeInterval {
            Double(cacheHits) * averageArgon2idTime
        }
    }

    /// Successful decryption output
    struct DecryptedOutput {
        let mnemonics: [String]
        let reserveData: WujiReserveData
        let statistics: RecoveryStatistics?  // nil for direct decryption (non-recovery)
    }

    /// Result type aliases for cleaner API
    typealias EncryptResult = Result<EncryptedOutput, Error>
    typealias DecryptResult = Result<DecryptedOutput, Error>

    // MARK: - Encrypt

    /// Progress callback type for encryption
    /// - Parameter progress: Current progress (0.0 to 1.0)
    typealias ProgressCallback = (Float) -> Void

    /// Encrypt seed phrase to WujiReserve binary format
    ///
    /// - Parameters:
    ///   - mnemonics: 24 BIP39 seed phrase words
    ///   - keyMaterials: 5 pre-processed key materials (sorted, binary Data)
    ///   - positionCodes: 5 position codes (1-9, matching keyMaterials order)
    ///   - nameSalt: 32-byte name salt derived from user's name (used as Argon2id salt)
    ///   - progressCallback: Optional callback for progress updates (called on current thread)
    /// - Returns: Result containing encrypted data or error
    static func encrypt(mnemonics: [String], keyMaterials: [Data], positionCodes: [Int], nameSalt: Data, progressCallback: ProgressCallback? = nil) -> EncryptResult {
        // Validate input
        guard mnemonics.count == mnemonicCount else {
            return .failure(.invalidMnemonicCount(mnemonics.count))
        }

        guard keyMaterials.count == locationCount else {
            return .failure(.invalidLocationCount(keyMaterials.count))
        }

        guard positionCodes.count == locationCount else {
            return .failure(.invalidLocationCount(positionCodes.count))
        }

        guard nameSalt.count == CryptoUtils.WujiArgon2idSaltLength else {
            return .failure(.invalidNameSalt)
        }

        // Validate position code range
        for code in positionCodes {
            guard code >= 1 && code <= 9 else {
                return .failure(.invalidPositionCode(code))
            }
        }

        // Sort keyMaterials lexicographically to ensure consistent order
        let sortedKeyMaterials = keyMaterials.sorted { $0.lexicographicallyPrecedes($1) }

        // Convert 24 seed phrase words to 264-bit (33 bytes) data
        guard let mnemonicData = BIP39Helper.wordsToData(mnemonics) else {
            return .failure(.mnemonicToEntropyFailed)
        }

        guard CryptoUtils.isAvailable() else {
            return .failure(.libsodiumInitFailed)
        }

        var encryptedBlocks: [WujiEncryptedBlock] = []

        // Build temporary capsule for AAD generation
        let tempCapsule = WujiReserveData(
            version: currentVersion,
            positionCodes: positionCodes,
            encryptedBlocks: []
        )
        guard let aad = tempCapsule.buildAAD() else {
            return .failure(.positionCodeEncodingFailed)
        }

        for (index, combo) in combinations.enumerated() {
            // Select 3 keyMaterials for this combination (already sorted), concatenate as binary
            let selectedKeyMaterials = combo.map { sortedKeyMaterials[$0] }
            var password = Data()
            for km in selectedKeyMaterials {
                password.append(km)
            }

            guard let key = CryptoUtils.argon2id(password: password, salt: nameSalt) else {
                return .failure(.keyDerivationFailed(index + 1))
            }

            // Generate random padding (8 bytes) - ensures each block has unique plaintext
            guard let padding = CryptoUtils.randomBytes(count: paddingSize) else {
                return .failure(.encryptionFailed(index + 1))
            }

            // Combine seed phrase data + random padding as plaintext
            var plaintext = Data(mnemonicData)
            plaintext.append(padding)

            // Encrypt using CryptoUtils (nonce auto-generated internally)
            guard let encResult = CryptoUtils.xChaCha20Poly1305Encrypt(
                plaintext: plaintext,
                key: key,
                aad: aad
            ) else {
                return .failure(.encryptionFailed(index + 1))
            }

            let block = WujiEncryptedBlock(
                nonce: encResult.nonce,
                ciphertext: encResult.ciphertext,
                tag: encResult.tag
            )
            encryptedBlocks.append(block)

            // Report progress (each block = 10%)
            let progress = Float(index + 1) / Float(combinations.count)
            progressCallback?(progress)

            #if DEBUG
            WujiLogger.debug("Combination \(index + 1)/\(combinations.count) encryption successful")
            #endif
        }

        // Deterministically shuffle encrypted blocks to hide combination-to-block mapping
        let shuffledBlocks = deterministicShuffleBlocks(encryptedBlocks, keyMaterials: sortedKeyMaterials)

        let reserveData = WujiReserveData(
            version: currentVersion,
            positionCodes: positionCodes,
            encryptedBlocks: shuffledBlocks
        )

        guard let binaryData = reserveData.encode() else {
            return .failure(.serializationFailed)
        }

        // Log: detailed size information
        #if DEBUG
        WujiLogger.success("WujiReserve encryption complete:")
        WujiLogger.info("  - \(encryptedBlocks.count) encrypted blocks")
        WujiLogger.info("  - Binary size: \(binaryData.count) bytes")
        WujiLogger.info("  - Each block: 91 bytes (24 nonce + 49 ciphertext + 16 tag + 2 length)")
        WujiLogger.info("  - Plaintext per block: 49 bytes (33 seed phrase + 16 random padding)")
        #endif

        return .success(EncryptedOutput(data: binaryData, reserveData: reserveData))
    }

    // MARK: - Decrypt

    /// Decrypt WujiReserve binary data to seed phrase
    ///
    /// This method takes parsed spots and processes them with position code correction,
    /// then attempts decryption. Using WujiSpot avoids redundant coordinate parsing
    /// and memory normalization.
    ///
    /// - Parameters:
    ///   - data: WujiReserve binary data
    ///   - spots: 5 parsed spot entries (place + memory)
    ///   - positionCodes: 5 position codes (1-9, from original generation or backup)
    ///   - nameSalt: 32-byte name salt derived from user's name (used as Argon2id salt)
    ///   - progressCallback: Optional callback for progress updates (called on current thread)
    /// - Returns: Result containing decrypted seed phrase or error
    static func decrypt(data: Data, spots: [WujiSpot], positionCodes: [Int], nameSalt: Data, progressCallback: ProgressCallback? = nil) -> DecryptResult {
        // Validate input count (must be exactly 5 spots for full verification)
        guard spots.count == locationCount else {
            return .failure(.invalidLocationCount(spots.count))
        }

        guard positionCodes.count == locationCount else {
            return .failure(.invalidLocationCount(positionCodes.count))
        }

        guard nameSalt.count == CryptoUtils.WujiArgon2idSaltLength else {
            return .failure(.invalidNameSalt)
        }

        // Process spots with position code correction to generate keyMaterials
        let processResult = WujiSpot.process(spots, positionCodes: positionCodes)

        let keyMaterials: [Data]
        switch processResult {
        case .success(let result):
            keyMaterials = result.keyMaterials
            #if DEBUG
            WujiLogger.info("WujiReserve decrypt: spots processed successfully, \(keyMaterials.count) keyMaterials")
            #endif
        case .failure(let error):
            #if DEBUG
            WujiLogger.error("WujiReserve decrypt: spot processing failed - \(error.localizedDescription)")
            #endif
            return .failure(.decryptionFailed)
        }

        // Sort keyMaterials lexicographically to ensure consistent order
        let sortedKeyMaterials = keyMaterials.sorted { $0.lexicographicallyPrecedes($1) }

        // Parse binary data
        let reserveData: WujiReserveData
        switch WujiReserveData.decode(data) {
        case .success(let decoded):
            reserveData = decoded
        case .failure(let error):
            return .failure(.parseError(error))
        }

        // Build AAD from reserveData
        guard let aad = reserveData.buildAAD() else {
            return .failure(.aadConstructionFailed)
        }

        guard CryptoUtils.isAvailable() else {
            return .failure(.libsodiumInitFailed)
        }

        // Use all 10 combinations for 5 keyMaterials
        let totalCombinations = combinations.count

        for (comboIndex, combo) in combinations.enumerated() {
            // Report progress at the start of each combination (Argon2id is the slow part)
            let progress = Float(comboIndex) / Float(totalCombinations)
            progressCallback?(progress)

            // Select 3 keyMaterials for this combination (already sorted), concatenate as binary
            let selectedKeyMaterials = combo.map { sortedKeyMaterials[$0] }
            var password = Data()
            for km in selectedKeyMaterials {
                password.append(km)
            }

            guard let key = CryptoUtils.argon2id(password: password, salt: nameSalt) else { continue }

            // Try this key against all encrypted blocks
            for block in reserveData.encryptedBlocks {
                // Decrypt using CryptoUtils
                guard let plaintext = CryptoUtils.xChaCha20Poly1305Decrypt(
                    ciphertext: block.ciphertext,
                    tag: block.tag,
                    key: key,
                    nonce: block.nonce,
                    aad: aad
                ) else { continue }

                // Verify decrypted data size (should be 49 bytes = 33 seed phrase + 16 padding)
                guard plaintext.count == plaintextSize else { continue }

                // Extract seed phrase data (first 33 bytes), discard random padding (last 16 bytes)
                let mnemonicData = Data(plaintext.prefix(mnemonicDataSize))

                // Convert 264-bit data back to 24 seed phrase words
                guard let words = BIP39Helper.dataToWords(mnemonicData) else { continue }

                // Report 100% progress on success
                progressCallback?(1.0)
                #if DEBUG
                WujiLogger.success("WujiReserve decryption successful, using combination \(comboIndex + 1)")
                #endif
                return .success(DecryptedOutput(mnemonics: words, reserveData: reserveData, statistics: nil))
            }
        }

        // Report 100% progress even on failure
        progressCallback?(1.0)
        return .failure(.decryptionFailed)
    }

    // MARK: - Recovery Mode Decrypt (Pipeline)

    /// Recovery mode decryption input
    struct RecoveryInput {
        let spots: [WujiSpot]                      // User input spots (3-5), already parsed
        let allPositionCodes: [Int]              // All 5 position codes from backup
        let nameSalt: Data                       // Name salt
        let capsuleData: Data                    // Encrypted capsule data
    }

    /// Decrypt WujiReserve with recovery mode - tries all position code combinations
    ///
    /// This method implements the correct recovery logic:
    /// - User provides N parsed spots (3-5)
    /// - Generate C(N,3) spot combinations
    /// - For each spot combination, try all C(5,3)=10 position code combinations
    /// - Total Argon2id attempts: C(N,3) × 10
    ///   - 3 spots: 1 × 10 = 10
    ///   - 4 spots: 4 × 10 = 40
    ///   - 5 spots: 10 × 10 = 100
    ///
    /// Uses pipeline processing: while AEAD decryption is running on one key,
    /// the next Argon2id is being computed in parallel.
    ///
    /// - Parameters:
    ///   - input: Recovery input containing parsed spots, position codes, salt, and capsule data
    ///   - progressCallback: Optional callback for progress updates
    /// - Returns: Result containing decrypted seed phrase or error
    static func decryptWithRecovery(input: RecoveryInput, progressCallback: ProgressCallback? = nil) -> DecryptResult {
        let spots = input.spots
        let allPositionCodes = input.allPositionCodes
        let nameSalt = input.nameSalt
        let capsuleData = input.capsuleData

        // Validate inputs
        guard spots.count >= locationsPerBlock && spots.count <= locationCount else {
            return .failure(.invalidLocationCount(spots.count))
        }

        guard allPositionCodes.count == locationCount else {
            return .failure(.invalidLocationCount(allPositionCodes.count))
        }

        guard nameSalt.count == CryptoUtils.WujiArgon2idSaltLength else {
            return .failure(.invalidNameSalt)
        }

        guard CryptoUtils.isAvailable() else {
            return .failure(.libsodiumInitFailed)
        }

        // Parse reserve data
        let reserveData: WujiReserveData
        switch WujiReserveData.decode(capsuleData) {
        case .success(let decoded):
            reserveData = decoded
        case .failure(let error):
            return .failure(.parseError(error))
        }

        // Build AAD from reserveData
        guard let aad = reserveData.buildAAD() else {
            return .failure(.aadConstructionFailed)
        }

        let encryptedBlocks = reserveData.encryptedBlocks

        // Generate spot combinations: C(N, 3)
        let spotIndices = Array(0..<spots.count)
        let spotCombinations = generateCombinations(from: spotIndices, choose: locationsPerBlock)

        // Position code combinations: C(5, 3) = 10 (use predefined)
        let positionCodeCombinations = combinations

        // Total Argon2id attempts
        let totalAttempts = spotCombinations.count * positionCodeCombinations.count

        #if DEBUG
        WujiLogger.info("WujiReserve Recovery: \(spots.count) spots -> \(spotCombinations.count) spot combos × \(positionCodeCombinations.count) position code combos = \(totalAttempts) Argon2id attempts")
        #endif

        // Use OperationQueue for pipeline processing
        let argon2Queue = DispatchQueue(label: "WujiSeed.argon2", qos: .userInitiated)
        let aeadQueue = DispatchQueue(label: "WujiSeed.aead", qos: .userInitiated)

        // Shared state protected by lock
        let lock = NSLock()
        var decryptedMnemonics: [String]?  // Store mnemonics only, create full result at end
        var currentAttempt = 0
        var shouldStop = false

        // Password cache for deduplication (key = password Data, value = Argon2id result)
        var passwordCache: [Data: Data] = [:]
        let cacheLock = NSLock()

        // Statistics
        var argon2idCount = 0
        var cacheHitCount = 0
        var totalArgon2idTime: TimeInterval = 0
        let statsLock = NSLock()

        // Generate all tasks upfront with priority scheduling
        // Priority: position codes closer to 5 (center) are more likely correct due to GPS drift
        var allTasks: [(spotCombo: [Int], posCodeCombo: [Int], priority: Int)] = []
        for spotCombo in spotCombinations {
            for posCodeCombo in positionCodeCombinations {
                // Calculate priority: count how many position codes are 5 (center)
                // Position 5 means GPS stayed in the same cell - most likely scenario
                let centerCount = posCodeCombo.filter { allPositionCodes[$0] == 5 }.count
                allTasks.append((spotCombo, posCodeCombo, centerCount))
            }
        }

        // Sort by priority (descending): try combinations with more center positions first
        allTasks.sort { $0.priority > $1.priority }

        // Semaphore to limit concurrent Argon2id (adaptive based on device)
        let concurrency = optimalArgon2idConcurrency()
        let semaphore = DispatchSemaphore(value: concurrency)

        // Use a dispatch group to wait for all tasks
        let group = DispatchGroup()

        // Key-verification queue for AEAD
        var pendingKeys: [(key: Data, taskIndex: Int)] = []
        let pendingKeysLock = NSLock()

        // Function to process pending keys
        func processPendingKey() {
            pendingKeysLock.lock()
            guard !pendingKeys.isEmpty else {
                pendingKeysLock.unlock()
                return
            }
            let (key, _) = pendingKeys.removeFirst()
            pendingKeysLock.unlock()

            // Try this key against all encrypted blocks
            for block in encryptedBlocks {
                lock.lock()
                if shouldStop {
                    lock.unlock()
                    return
                }
                lock.unlock()

                guard let plaintext = CryptoUtils.xChaCha20Poly1305Decrypt(
                    ciphertext: block.ciphertext,
                    tag: block.tag,
                    key: key,
                    nonce: block.nonce,
                    aad: aad
                ) else { continue }

                guard plaintext.count == plaintextSize else { continue }

                let mnemonicData = Data(plaintext.prefix(mnemonicDataSize))
                guard let words = BIP39Helper.dataToWords(mnemonicData) else { continue }

                // Success!
                lock.lock()
                if decryptedMnemonics == nil {
                    decryptedMnemonics = words
                    shouldStop = true
                }
                lock.unlock()
                return
            }

            // Process next pending key if any
            processPendingKey()
        }

        // Process all tasks
        for (taskIndex, task) in allTasks.enumerated() {
            lock.lock()
            if shouldStop {
                lock.unlock()
                break
            }
            lock.unlock()

            group.enter()
            semaphore.wait()

            argon2Queue.async {
                defer {
                    semaphore.signal()
                    group.leave()
                }

                lock.lock()
                if shouldStop {
                    lock.unlock()
                    return
                }
                lock.unlock()

                // Select spots and position codes
                let selectedSpots = task.spotCombo.map { spots[$0] }
                let selectedPositionCodes = task.posCodeCombo.map { allPositionCodes[$0] }

                // Process spots with position code correction
                let processResult = WujiSpot.process(selectedSpots, positionCodes: selectedPositionCodes)

                guard case .success(let batchResult) = processResult else {
                    // Update progress even on failure
                    lock.lock()
                    currentAttempt += 1
                    let progress = Float(currentAttempt) / Float(totalAttempts)
                    lock.unlock()
                    DispatchQueue.main.async { progressCallback?(progress) }
                    return
                }

                // Sort and concatenate keyMaterials as binary
                let sortedKeyMaterials = batchResult.keyMaterials.sorted { $0.lexicographicallyPrecedes($1) }
                var password = Data()
                for km in sortedKeyMaterials {
                    password.append(km)
                }

                // Check cache first
                cacheLock.lock()
                if let cachedKey = passwordCache[password] {
                    cacheLock.unlock()

                    // Cache hit - skip Argon2id
                    statsLock.lock()
                    cacheHitCount += 1
                    statsLock.unlock()

                    // Update progress
                    lock.lock()
                    currentAttempt += 1
                    let progress = Float(currentAttempt) / Float(totalAttempts)
                    lock.unlock()
                    DispatchQueue.main.async { progressCallback?(progress) }

                    // Add cached key to pending queue
                    pendingKeysLock.lock()
                    pendingKeys.append((cachedKey, taskIndex))
                    pendingKeysLock.unlock()

                    aeadQueue.async { processPendingKey() }
                    return
                }
                cacheLock.unlock()

                // Compute Argon2id (the slow operation)
                let argon2Start = Date()
                guard let key = CryptoUtils.argon2id(password: password, salt: nameSalt) else {
                    lock.lock()
                    currentAttempt += 1
                    let progress = Float(currentAttempt) / Float(totalAttempts)
                    lock.unlock()
                    DispatchQueue.main.async { progressCallback?(progress) }
                    return
                }
                let argon2Time = Date().timeIntervalSince(argon2Start)

                // Update statistics
                statsLock.lock()
                argon2idCount += 1
                totalArgon2idTime += argon2Time
                statsLock.unlock()

                // Cache the result
                cacheLock.lock()
                passwordCache[password] = key
                cacheLock.unlock()

                // Update progress after Argon2id
                lock.lock()
                currentAttempt += 1
                let progress = Float(currentAttempt) / Float(totalAttempts)
                lock.unlock()
                DispatchQueue.main.async { progressCallback?(progress) }

                // Add key to pending queue for AEAD verification
                pendingKeysLock.lock()
                pendingKeys.append((key, taskIndex))
                pendingKeysLock.unlock()

                // Start AEAD processing if not already running
                aeadQueue.async {
                    processPendingKey()
                }
            }
        }

        // Wait for all Argon2id tasks to complete
        group.wait()

        // Wait for remaining AEAD processing
        aeadQueue.sync {}

        progressCallback?(1.0)

        // Build statistics
        let statistics = RecoveryStatistics(
            totalAttempts: totalAttempts,
            argon2idCalls: argon2idCount,
            cacheHits: cacheHitCount,
            totalArgon2idTime: totalArgon2idTime,
            concurrency: concurrency
        )

        // Log statistics
        #if DEBUG
        WujiLogger.info("WujiReserve Recovery Statistics:")
        WujiLogger.info("   Total attempts: \(statistics.totalAttempts)")
        WujiLogger.info("   Argon2id calls: \(statistics.argon2idCalls) (avg \(String(format: "%.2f", statistics.averageArgon2idTime))s each)")
        WujiLogger.info("   Cache hits: \(statistics.cacheHits) (\(String(format: "%.1f", statistics.cacheHitRate))% saved)")
        WujiLogger.info("   Total Argon2id time: \(String(format: "%.2f", statistics.totalArgon2idTime))s")
        WujiLogger.info("   Concurrency: \(statistics.concurrency)")
        #endif

        // Build final result
        lock.lock()
        let mnemonics = decryptedMnemonics
        lock.unlock()

        if let words = mnemonics {
            #if DEBUG
            WujiLogger.success("WujiReserve Recovery: Decryption successful after \(currentAttempt) attempts")
            #endif
            return .success(DecryptedOutput(mnemonics: words, reserveData: reserveData, statistics: statistics))
        } else {
            #if DEBUG
            WujiLogger.error("WujiReserve Recovery: Decryption failed after \(totalAttempts) attempts")
            #endif
            return .failure(.decryptionFailed)
        }
    }

    /// Generate combinations: choose k from n elements
    private static func generateCombinations<T>(from elements: [T], choose k: Int) -> [[T]] {
        guard k > 0 && k <= elements.count else {
            return k == 0 ? [[]] : []
        }

        if k == elements.count {
            return [elements]
        }

        var result: [[T]] = []

        func combine(_ start: Int, _ current: [T]) {
            if current.count == k {
                result.append(current)
                return
            }

            for i in start..<elements.count {
                combine(i + 1, current + [elements[i]])
            }
        }

        combine(0, [])
        return result
    }

    // MARK: - Deterministic Shuffle

    /// Deterministically shuffle encrypted blocks to hide combination-to-block mapping
    /// This prevents attackers from knowing which block corresponds to which key combination
    /// Uses keyMaterials content as random seed to ensure reproducibility
    private static func deterministicShuffleBlocks(_ blocks: [WujiEncryptedBlock], keyMaterials: [Data]) -> [WujiEncryptedBlock] {
        guard blocks.count == combinations.count else {
            return blocks
        }

        // Generate deterministic seed from all keyMaterials (concatenate with separator and suffix)
        var seedInput = Data()
        for (index, km) in keyMaterials.enumerated() {
            if index > 0 {
                seedInput.append(Data("|".utf8))
            }
            seedInput.append(km)
        }
        seedInput.append(Data("|block-shuffle-seed".utf8))
        guard let hash = CryptoUtils.blake2b(data: seedInput, outputLength: 32) else {
            return blocks
        }

        // Create mutable copy for shuffling
        var shuffled = blocks

        // Fisher-Yates shuffle using hash bytes as random source
        let count = shuffled.count
        for i in stride(from: count - 1, through: 1, by: -1) {
            // Use hash bytes to generate random index
            let hashByte = hash[i % hash.count]
            let j = Int(hashByte) % (i + 1)
            shuffled.swapAt(i, j)
        }

        #if DEBUG
        WujiLogger.debug("Deterministic shuffle applied to encrypted blocks")
        #endif

        return shuffled
    }
}
