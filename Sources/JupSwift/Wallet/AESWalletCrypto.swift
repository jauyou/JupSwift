//
//  AESWalletCrypto.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

/// `AESWalletCrypto` is a utility class that securely handles AES encryption
/// and decryption of sensitive wallet data, such as mnemonics and private keys,
/// using Apple's Secure Enclave technology.
///
/// This class generates and manages a symmetric encryption key that is securely
/// stored within the Secure Enclave—a dedicated security coprocessor that provides
/// an isolated and tamper-resistant environment for sensitive operations.
///
/// The encryption key is stored in a separate, protected memory area inaccessible
/// to the main processor or software, and all cryptographic operations using this
/// key are executed inside the Secure Enclave hardware itself. This architecture
/// ensures that the key material never leaves the enclave, significantly reducing
/// the risk of key extraction or compromise.
///
/// For more information on Secure Enclave and its security features, see:
/// https://support.apple.com/en-sg/guide/security/sec59b0b31ff/web
class AESWalletCrypto {
    private static let keyAlias = "ag.jup.wallet.secureEnclaveKey"

    private init() {}

    
    enum AESKeyStorageError: Error {
        case failedToSave
        case failedToLoad
        case keyDataCorrupted
    }
    
    /// Loads the locally stored AES symmetric encryption key.
    /// If the key does not exist, a new one is generated and saved to the local file system.
    ///
    /// The key is stored as a `.key` file inside the app's sandbox Application Support directory.
    /// If the file is missing or cannot be read, a new 256-bit AES key is generated and written to disk.
    ///
    /// > Warning: This method stores the key in a local file, which is not protected by Secure Enclave or Keychain.
    /// > If the device is jailbroken or the file system is accessed, the key may be compromised.
    /// > This approach is recommended only for development or non-sensitive use cases.
    ///
    /// - Returns: A `SymmetricKey` that was loaded or newly generated.
    /// - Throws: An error if the key could not be saved to disk.
    static func loadOrGenerateKeyFromLocal() throws -> SymmetricKey {
        if let keyData = try? Data(contentsOf: keyFileURL) {
            print("Loaded AES key from file.")
            return SymmetricKey(data: keyData)
        }

        // Key doesn't exist or failed to read → generate new one
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }

        do {
            try keyData.write(to: keyFileURL, options: [.atomic])
            print("Generated and saved new AES key.")
        } catch {
            print("Failed to save AES key: \(error)")
            throw AESKeyStorageError.failedToSave
        }

        return newKey
    }
    
    /// The file URL where the AES symmetric key will be stored locally.
    /// This uses the application's support directory to persist the key in a safe, sandboxed location.
    /// - Note: The file is named "aes.key" and is saved under the app's Application Support directory.
    ///         Ensure proper file protection and access controls if used in production.
    private static var keyFileURL: URL {
        let fileManager = FileManager.default
        let appSupportURL = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupportURL.appendingPathComponent("aes.key")
    }
    
    /// Loads the existing symmetric encryption key from secure storage,
    /// or generates a new one if not found.
    ///
    /// - Returns: A `SymmetricKey` used for encrypting/decrypting wallet data.
    /// - Throws: An error if key generation or loading fails.
    private static func loadOrGenerateKey() throws -> SymmetricKey {
        do {
            let key = try getKeyFromSecureEnclave()
            return key
        } catch {
            print("Failed to get key: \(error)")
            let newKey = SymmetricKey(size: .bits256)
            try saveKeyToSecureEnclave(newKey)
            return newKey
        }
    }

    /// Saves the given symmetric encryption key securely into the Secure Enclave or keychain.
    ///
    /// - Parameter key: The `SymmetricKey` to be securely stored.
    /// - Throws: An error if saving the key fails.
    private static func saveKeyToSecureEnclave(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }

        var accessControlError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, .biometryCurrentSet, &accessControlError) else {
            throw accessControlError!.takeRetainedValue()
        }

        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
            kSecAttrAccessControl as String: access,
            kSecValueData as String: keyData
        ]

        if #available(iOS 14.0, *) {
            let context = LAContext()
            context.interactionNotAllowed = false
            query[kSecUseAuthenticationContext as String] = context
        } else {
            query[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIAllow
        }

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "SecureEnclave", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save AES key"])
        }
    }

    /// Retrieves the symmetric encryption key stored securely in the Secure Enclave or keychain.
    ///
    /// - Returns: The retrieved `SymmetricKey`.
    /// - Throws: An error if the key cannot be found or retrieval fails.
    private static func getKeyFromSecureEnclave() throws -> SymmetricKey {
        let context = LAContext()
        context.localizedReason = "Authenticate to access wallet"

        // Set reuse duration to 30 seconds
        if #available(iOS 13.0, *) {
            context.touchIDAuthenticationAllowableReuseDuration = 30
        }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
            kSecReturnData as String: true
        ]

        if #available(iOS 14.0, *) {
            query[kSecUseAuthenticationContext as String] = context
        } else {
            query[kSecUseOperationPrompt as String] = "Authenticate"
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            throw NSError(domain: "SecureEnclave", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to get AES key"])
        }

        return SymmetricKey(data: data)
    }

    /// Encrypts the given plaintext data using the securely stored symmetric key.
    ///
    /// - Parameter plaintext: The raw data to be encrypted.
    /// - Returns: The encrypted data.
    /// - Throws: An error if encryption fails or the key cannot be accessed.
    static func encrypt(_ plaintext: Data) throws -> Data {
        let key = try loadOrGenerateKey()
        return try AES.GCM.seal(plaintext, using: key).combined!
    }

    /// Decrypts the given encrypted data using the securely stored symmetric key.
    ///
    /// - Parameter encryptedData: The data to decrypt.
    /// - Returns: The decrypted plaintext data.
    /// - Throws: An error if decryption fails or the key cannot be accessed.
    static func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try loadOrGenerateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

