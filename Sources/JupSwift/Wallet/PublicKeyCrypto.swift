//
//  PublicKeyCrypto.swift
//  JupSwift
//
//  Created by Claude on 16/4/26.
//

import Foundation
import Clibsodium

/// Error types for public key encryption/decryption operations.
public enum PublicKeyCryptoError: Error, LocalizedError {
    case invalidPublicKey
    case invalidPrivateKey
    case keyConversionFailed
    case encryptionFailed
    case decryptionFailed
    case libsodiumInitFailed

    public var errorDescription: String? {
        switch self {
        case .invalidPublicKey:
            return "Invalid public key: expected 32 bytes"
        case .invalidPrivateKey:
            return "Invalid private key: expected 64 bytes"
        case .keyConversionFailed:
            return "Failed to convert Ed25519 key to X25519"
        case .encryptionFailed:
            return "Sealed box encryption failed"
        case .decryptionFailed:
            return "Sealed box decryption failed"
        case .libsodiumInitFailed:
            return "Failed to initialize libsodium"
        }
    }
}

/// Public key encryption and private key decryption using X25519 Sealed Box.
///
/// Solana uses Ed25519 keys for signing. This actor converts Ed25519 keys to
/// X25519 (Curve25519) keys and uses libsodium's Sealed Box for anonymous
/// public key encryption.
///
/// - Encrypt: anyone can encrypt a message using a recipient's Solana public key (address).
/// - Decrypt: only the holder of the corresponding private key can decrypt.
///
/// Example:
/// ```swift
/// let crypto = PublicKeyCrypto.shared
///
/// // Encrypt with a Solana address
/// let message = "Hello Solana".data(using: .utf8)!
/// let encrypted = try crypto.encrypt(message,
///     recipientPublicKey: "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU")
///
/// // Decrypt with the corresponding private key
/// let decrypted = try crypto.decrypt(encrypted, privateKey: base58PrivateKey)
/// ```
public actor PublicKeyCrypto {

    public static let shared = PublicKeyCrypto()

    private let sodiumInitialized: Bool

    private init() {
        self.sodiumInitialized = sodium_init() >= 0
    }

    private func ensureInitialized() throws {
        guard sodiumInitialized else {
            throw PublicKeyCryptoError.libsodiumInitFailed
        }
    }

    // MARK: - Encrypt

    /// Encrypt data using a Base58-encoded Solana public key (address).
    ///
    /// - Parameters:
    ///   - plaintext: The data to encrypt.
    ///   - recipientPublicKey: The recipient's Base58-encoded Solana public key.
    /// - Returns: The encrypted data (sealed box ciphertext).
    public func encrypt(_ plaintext: Data, recipientPublicKey: String) throws -> Data {
        guard let publicKeyBytes = Base58.decode(recipientPublicKey),
              publicKeyBytes.count == 32 else {
            throw PublicKeyCryptoError.invalidPublicKey
        }
        return try encrypt(plaintext, recipientPublicKeyBytes: publicKeyBytes)
    }

    /// Encrypt data using a `PublicKey` struct.
    ///
    /// - Parameters:
    ///   - plaintext: The data to encrypt.
    ///   - recipientPublicKey: The recipient's `PublicKey`.
    /// - Returns: The encrypted data (sealed box ciphertext).
    public func encrypt(_ plaintext: Data, recipientPublicKey: PublicKey) throws -> Data {
        guard recipientPublicKey.bytes.count == 32 else {
            throw PublicKeyCryptoError.invalidPublicKey
        }
        return try encrypt(plaintext, recipientPublicKeyBytes: recipientPublicKey.bytes)
    }

    // MARK: - Decrypt

    /// Decrypt data using a Base58-encoded private key.
    ///
    /// - Parameters:
    ///   - ciphertext: The sealed box ciphertext to decrypt.
    ///   - privateKey: The Base58-encoded 64-byte Ed25519 private key.
    /// - Returns: The decrypted plaintext data.
    public func decrypt(_ ciphertext: Data, privateKey: String) throws -> Data {
        guard let privateKeyBytes = Base58.decode(privateKey),
              privateKeyBytes.count == 64 else {
            throw PublicKeyCryptoError.invalidPrivateKey
        }
        return try decrypt(ciphertext, privateKeyBytes: privateKeyBytes)
    }

    /// Decrypt data using a `[UInt8]` private key.
    ///
    /// - Parameters:
    ///   - ciphertext: The sealed box ciphertext to decrypt.
    ///   - privateKey: The 64-byte Ed25519 private key.
    /// - Returns: The decrypted plaintext data.
    public func decrypt(_ ciphertext: Data, privateKey: [UInt8]) throws -> Data {
        guard privateKey.count == 64 else {
            throw PublicKeyCryptoError.invalidPrivateKey
        }
        return try decrypt(ciphertext, privateKeyBytes: privateKey)
    }

    /// Decrypt data using the current wallet's private key from `WalletManager`.
    ///
    /// - Parameter ciphertext: The sealed box ciphertext to decrypt.
    /// - Returns: The decrypted plaintext data.
    public func decryptWithCurrentWallet(_ ciphertext: Data) async throws -> Data {
        let base58PrivateKey = try await WalletManager.shared.getCurrentPrivateKey()
        return try decrypt(ciphertext, privateKey: base58PrivateKey)
    }

    // MARK: - Key Conversion

    /// Convert an Ed25519 public key to an X25519 public key.
    ///
    /// - Parameter ed25519PK: 32-byte Ed25519 public key.
    /// - Returns: 32-byte X25519 public key.
    func ed25519PublicKeyToX25519(_ ed25519PK: [UInt8]) throws -> [UInt8] {
        try ensureInitialized()
        guard ed25519PK.count == 32 else {
            throw PublicKeyCryptoError.invalidPublicKey
        }
        var x25519PK = [UInt8](repeating: 0, count: 32)
        guard crypto_sign_ed25519_pk_to_curve25519(&x25519PK, ed25519PK) == 0 else {
            throw PublicKeyCryptoError.keyConversionFailed
        }
        return x25519PK
    }

    /// Convert an Ed25519 secret key to an X25519 secret key.
    ///
    /// - Parameter ed25519SK: 64-byte Ed25519 secret key.
    /// - Returns: 32-byte X25519 secret key.
    func ed25519SecretKeyToX25519(_ ed25519SK: [UInt8]) throws -> [UInt8] {
        try ensureInitialized()
        guard ed25519SK.count == 64 else {
            throw PublicKeyCryptoError.invalidPrivateKey
        }
        var x25519SK = [UInt8](repeating: 0, count: 32)
        guard crypto_sign_ed25519_sk_to_curve25519(&x25519SK, ed25519SK) == 0 else {
            throw PublicKeyCryptoError.keyConversionFailed
        }
        return x25519SK
    }

    // MARK: - Private Implementation

    private func encrypt(_ plaintext: Data, recipientPublicKeyBytes: [UInt8]) throws -> Data {
        try ensureInitialized()

        let x25519PK = try ed25519PublicKeyToX25519(recipientPublicKeyBytes)

        let plaintextBytes = [UInt8](plaintext)
        let ciphertextLen = crypto_box_sealbytes() + plaintextBytes.count
        var ciphertext = [UInt8](repeating: 0, count: ciphertextLen)

        guard crypto_box_seal(&ciphertext, plaintextBytes, UInt64(plaintextBytes.count), x25519PK) == 0 else {
            throw PublicKeyCryptoError.encryptionFailed
        }

        return Data(ciphertext)
    }

    private func decrypt(_ ciphertext: Data, privateKeyBytes: [UInt8]) throws -> Data {
        try ensureInitialized()

        // Extract the 32-byte public key from the 64-byte private key (last 32 bytes)
        let ed25519PK = Array(privateKeyBytes[32..<64])

        let x25519PK = try ed25519PublicKeyToX25519(ed25519PK)
        let x25519SK = try ed25519SecretKeyToX25519(privateKeyBytes)

        let ciphertextBytes = [UInt8](ciphertext)
        let sealBytes = crypto_box_sealbytes()
        guard ciphertextBytes.count >= sealBytes else {
            throw PublicKeyCryptoError.decryptionFailed
        }

        let plaintextLen = ciphertextBytes.count - sealBytes
        var plaintext = [UInt8](repeating: 0, count: max(plaintextLen, 1))

        guard crypto_box_seal_open(&plaintext, ciphertextBytes, UInt64(ciphertextBytes.count), x25519PK, x25519SK) == 0 else {
            throw PublicKeyCryptoError.decryptionFailed
        }

        return Data(plaintext.prefix(plaintextLen))
    }
}
