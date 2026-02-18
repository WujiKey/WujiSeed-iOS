//
//  CryptoUtils.swift
//  WujiSeed
//
//  Unified cryptography utility class - all crypto operations are centralized here
//  Includes: SHA256, BLAKE2b, Argon2id, XChaCha20-Poly1305
//

import Foundation
import CommonCrypto
import Sodium
import Clibsodium

/// Unified Cryptography Utility Class
/// Contains all cryptographic hash and key derivation operations
class CryptoUtils {
    // MARK: - Constants

    /// Salt generation suffix (protocol version identifier)
    static let WujiBlake2bSaltSuffix = "WUJI-Key-V1:Memory-Based Seed Phrases"

    /// Argon2id parameters
    static let WujiArgon2idSaltLength = 16           // Salt length (bytes) - libsodium standard
    static let WujiArgon2idMem = 256 * 1024          // Memory size (KB) = 256 MB
    static let WujiArgon2idTimes = 7                 // Iteration count
    static let WujiArgon2idParallel = 1              // Parallelism (single thread)

    // MARK: - Singleton

    /// Shared Sodium instance
    private nonisolated(unsafe) static let sodium = Sodium()

    // MARK: - BLAKE2b

    /// Calculate hash using BLAKE2b
    ///
    /// - Parameters:
    ///   - data: Input data
    ///   - outputLength: Output length (bytes, 1-64, default 32 = 256 bits)
    /// - Returns: Hash result, nil on failure
    static func blake2b(data: Data, outputLength: Int = 32) -> Data? {
        guard outputLength >= 1 && outputLength <= 64 else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.blake2b: Output length must be between 1-64 bytes")
            #endif
            return nil
        }

        let bytes = Bytes(data)
        guard let result = sodium.genericHash.hash(message: bytes, outputLength: outputLength) else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.blake2b: genericHash calculation failed")
            #endif
            return nil
        }

        return Data(result)
    }

    /// Calculate hash of string using BLAKE2b
    ///
    /// - Parameters:
    ///   - string: Input string (UTF-8 encoded)
    ///   - outputLength: Output length (bytes, default 32)
    /// - Returns: Hash result, nil on failure
    static func blake2b(string: String, outputLength: Int = 32) -> Data? {
        guard let data = string.data(using: .utf8) else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.blake2b: String UTF-8 encoding failed")
            #endif
            return nil
        }
        return blake2b(data: data, outputLength: outputLength)
    }

    // MARK: - Argon2id

    /// Argon2id parameter configuration
    struct Argon2Parameters {
        let memoryKB: Int          // Memory size (KB)
        let iterations: Int        // Iteration count (time cost)
        let parallelism: Int       // Parallelism (thread count)

        /// Standard parameters: use values defined in Constants
        static let standard = Argon2Parameters(
            memoryKB: WujiArgon2idMem,
            iterations: WujiArgon2idTimes,
            parallelism: WujiArgon2idParallel
        )
    }

    /// Key derivation using Argon2id
    ///
    /// - Parameters:
    ///   - password: Password/key material
    ///   - salt: Salt value (must be exactly 32 bytes)
    ///   - parameters: Argon2 parameters
    ///   - outputLength: Output length (bytes, default 32)
    /// - Returns: Derived key, nil on failure
    static func argon2id(password: Data, salt: Data, parameters: Argon2Parameters = .standard, outputLength: Int = 32) -> Data? {
        // Validate salt length (must be exactly 32 bytes)
        guard salt.count == WujiArgon2idSaltLength else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.argon2id: Salt length must be \(WujiArgon2idSaltLength) bytes, got: \(salt.count) bytes")
            #endif
            return nil
        }

        // Calculate memory limit (bytes)
        let memLimit = parameters.memoryKB * 1024

        // Allocate output buffer
        var output = Data(count: outputLength)

        // Call crypto_pwhash directly (supports arbitrary length salt)
        let result = output.withUnsafeMutableBytes { outputPtr -> Int32 in
            password.withUnsafeBytes { passwordPtr -> Int32 in
                salt.withUnsafeBytes { saltPtr -> Int32 in
                    guard let outputBase = outputPtr.baseAddress,
                          let passwordBase = passwordPtr.baseAddress,
                          let saltBase = saltPtr.baseAddress else {
                        return -1
                    }

                    return crypto_pwhash(
                        outputBase.assumingMemoryBound(to: UInt8.self),
                        UInt64(outputLength),
                        passwordBase.assumingMemoryBound(to: Int8.self),
                        UInt64(password.count),
                        saltBase.assumingMemoryBound(to: UInt8.self),
                        UInt64(parameters.iterations),
                        size_t(memLimit),
                        crypto_pwhash_ALG_ARGON2ID13
                    )
                }
            }
        }

        guard result == 0 else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.argon2id: Key derivation failed, error code: \(result)")
            #endif
            return nil
        }

        #if DEBUG
        WujiLogger.success("CryptoUtils.argon2id: Key derivation successful")
        #endif
        return output
    }

    /// Key derivation using Argon2id (string version)
    ///
    /// - Parameters:
    ///   - password: Password string (UTF-8 encoded)
    ///   - salt: Salt data
    ///   - parameters: Argon2 parameters
    ///   - outputLength: Output length
    /// - Returns: Derived key, nil on failure
    static func argon2id(password: String, salt: Data, parameters: Argon2Parameters = .standard, outputLength: Int = 32) -> Data? {
        guard let passwordData = password.data(using: .utf8) else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.argon2id: Password UTF-8 encoding failed")
            #endif
            return nil
        }
        return argon2id(password: passwordData, salt: salt, parameters: parameters, outputLength: outputLength)
    }

    // MARK: - Random Bytes

    /// Generate cryptographically secure random bytes
    ///
    /// - Parameter count: Number of bytes
    /// - Returns: Random data, nil on failure
    static func randomBytes(count: Int) -> Data? {
        guard let bytes = sodium.randomBytes.buf(length: count) else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.randomBytes: Random number generation failed")
            #endif
            return nil
        }
        return Data(bytes)
    }

    // MARK: - Utility Methods

    /// Check if libsodium is available
    static func isAvailable() -> Bool {
        // Sodium initialization is done automatically when creating instance
        // If genericHash works, libsodium is available
        return sodium.genericHash.hash(message: Bytes([0]), outputLength: 32) != nil
    }

    /// Get libsodium version info
    static func version() -> String {
        return String(cString: sodium_version_string())
    }

    /// Print debug information
    static func printDebugInfo() {
        #if DEBUG
        WujiLogger.debugBlock(title: "CryptoUtils Debug Info") {
            WujiLogger.info("Protocol version: \(WujiBlake2bSaltSuffix)")
            WujiLogger.info("libsodium version: \(version())")
            WujiLogger.info("BLAKE2b available: \(isAvailable())")
            WujiLogger.info("Standard Argon2 params: \(WujiArgon2idMem / 1024)MB memory, \(WujiArgon2idTimes) iterations")
        }
        #endif
    }

    // MARK: - SHA256

    /// Calculate SHA256 hash of data
    /// - Parameter data: Data to hash
    /// - Returns: 32-byte SHA256 hash
    static func sha256(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }

    // MARK: - XChaCha20-Poly1305 Constants

    /// XChaCha20-Poly1305 nonce length (24 bytes)
    static let xChaCha20NonceLength = 24

    /// XChaCha20-Poly1305 tag length (16 bytes)
    static let xChaCha20TagLength = 16

    /// XChaCha20-Poly1305 key length (32 bytes)
    static let xChaCha20KeyLength = 32

    // MARK: - XChaCha20-Poly1305 Encryption

    /// Encryption result
    struct EncryptionResult {
        let ciphertext: Data   // Ciphertext (without tag)
        let tag: Data          // Authentication tag (16 bytes)
        let nonce: Data        // Nonce used (24 bytes)
    }

    /// Encrypt data using XChaCha20-Poly1305
    ///
    /// - Parameters:
    ///   - plaintext: Plaintext data
    ///   - key: 32-byte key
    ///   - aad: Additional authenticated data (optional)
    /// - Returns: Encryption result (includes auto-generated nonce), nil on failure
    static func xChaCha20Poly1305Encrypt(plaintext: Data, key: Data, aad: Data? = nil) -> EncryptionResult? {
        guard key.count == xChaCha20KeyLength else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.xChaCha20Poly1305Encrypt: key must be \(xChaCha20KeyLength) bytes")
            #endif
            return nil
        }

        // Generate random nonce
        var nonce = Data(count: xChaCha20NonceLength)
        nonce.withUnsafeMutableBytes { ptr in
            guard let base = ptr.baseAddress else { return }
            randombytes_buf(base, xChaCha20NonceLength)
        }

        // Output buffer (ciphertext + tag)
        let outputLen = plaintext.count + xChaCha20TagLength
        var output = Data(count: outputLen)
        var actualLen: UInt64 = 0

        let aadData = aad ?? Data()

        let result = output.withUnsafeMutableBytes { outputPtr -> Int32 in
            plaintext.withUnsafeBytes { plaintextPtr -> Int32 in
                key.withUnsafeBytes { keyPtr -> Int32 in
                    nonce.withUnsafeBytes { noncePtr -> Int32 in
                        aadData.withUnsafeBytes { aadPtr -> Int32 in
                            guard let oBase = outputPtr.baseAddress,
                                  let pBase = plaintextPtr.baseAddress,
                                  let kBase = keyPtr.baseAddress,
                                  let nBase = noncePtr.baseAddress else {
                                return -1
                            }

                            let aBase = aadData.isEmpty ? nil : aadPtr.baseAddress

                            return crypto_aead_xchacha20poly1305_ietf_encrypt(
                                oBase.assumingMemoryBound(to: UInt8.self),
                                &actualLen,
                                pBase.assumingMemoryBound(to: UInt8.self),
                                UInt64(plaintext.count),
                                aBase?.assumingMemoryBound(to: UInt8.self),
                                UInt64(aadData.count),
                                nil,
                                nBase.assumingMemoryBound(to: UInt8.self),
                                kBase.assumingMemoryBound(to: UInt8.self)
                            )
                        }
                    }
                }
            }
        }

        guard result == 0 else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.xChaCha20Poly1305Encrypt: Encryption failed, error code: \(result)")
            #endif
            return nil
        }

        // Separate ciphertext and tag
        let ciphertextLen = Int(actualLen) - xChaCha20TagLength
        let ciphertext = output.prefix(ciphertextLen)
        let tag = output.subdata(in: ciphertextLen..<Int(actualLen))

        return EncryptionResult(ciphertext: Data(ciphertext), tag: tag, nonce: nonce)
    }

    // MARK: - XChaCha20-Poly1305 Decryption

    /// Decrypt data using XChaCha20-Poly1305
    ///
    /// - Parameters:
    ///   - ciphertext: Ciphertext data (without tag)
    ///   - tag: Authentication tag (16 bytes)
    ///   - key: 32-byte key
    ///   - nonce: 24-byte nonce
    ///   - aad: Additional authenticated data (optional, must match encryption)
    /// - Returns: Decrypted plaintext, nil on failure
    static func xChaCha20Poly1305Decrypt(ciphertext: Data, tag: Data, key: Data, nonce: Data, aad: Data? = nil) -> Data? {
        guard key.count == xChaCha20KeyLength else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.xChaCha20Poly1305Decrypt: key must be \(xChaCha20KeyLength) bytes")
            #endif
            return nil
        }

        guard nonce.count == xChaCha20NonceLength else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.xChaCha20Poly1305Decrypt: nonce must be \(xChaCha20NonceLength) bytes")
            #endif
            return nil
        }

        guard tag.count == xChaCha20TagLength else {
            #if DEBUG
            WujiLogger.error("CryptoUtils.xChaCha20Poly1305Decrypt: tag must be \(xChaCha20TagLength) bytes")
            #endif
            return nil
        }

        // Combine ciphertext + tag
        var fullCiphertext = Data(ciphertext)
        fullCiphertext.append(tag)

        var plaintext = Data(count: ciphertext.count)
        var plaintextLen: UInt64 = 0

        let aadData = aad ?? Data()

        let result = fullCiphertext.withUnsafeBytes { ciphertextPtr -> Int32 in
            key.withUnsafeBytes { keyPtr -> Int32 in
                nonce.withUnsafeBytes { noncePtr -> Int32 in
                    aadData.withUnsafeBytes { aadPtr -> Int32 in
                        plaintext.withUnsafeMutableBytes { plaintextPtr -> Int32 in
                            guard let cBase = ciphertextPtr.baseAddress,
                                  let kBase = keyPtr.baseAddress,
                                  let nBase = noncePtr.baseAddress,
                                  let pBase = plaintextPtr.baseAddress else {
                                return -1
                            }

                            let aBase = aadData.isEmpty ? nil : aadPtr.baseAddress

                            return crypto_aead_xchacha20poly1305_ietf_decrypt(
                                pBase.assumingMemoryBound(to: UInt8.self),
                                &plaintextLen,
                                nil,
                                cBase.assumingMemoryBound(to: UInt8.self),
                                UInt64(fullCiphertext.count),
                                aBase?.assumingMemoryBound(to: UInt8.self),
                                UInt64(aadData.count),
                                nBase.assumingMemoryBound(to: UInt8.self),
                                kBase.assumingMemoryBound(to: UInt8.self)
                            )
                        }
                    }
                }
            }
        }

        guard result == 0 else {
            // Don't log decryption failure (may be trying wrong key)
            return nil
        }

        return Data(plaintext.prefix(Int(plaintextLen)))
    }

}
