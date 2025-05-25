//
//  WalletManager.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation

/// `WalletManager` is an actor responsible for managing wallet data securely and concurrently-safe.
///
/// It handles loading, saving, and managing mnemonic phrases and private keys,
/// ensuring thread-safe access to wallet data by leveraging Swift's concurrency model.
///
/// Key responsibilities include:
/// - Persisting wallet data to and from disk asynchronously.
/// - Encrypting and decrypting sensitive data such as mnemonics and private keys.
/// - Providing safe, concurrent access to add, retrieve, and derive keys.
///
/// Usage of `WalletManager` guarantees that all mutations and accesses to wallet data
/// are serialized and safe from data races in concurrent environments.
///
/// This actor encapsulates the wallet's state and related cryptographic operations,
/// making it the central point for wallet management in the app.
public actor WalletManager {
    public static let shared = WalletManager()

    private(set) var wallet: WalletData

    /// Initializes a new instance of `WalletManager`.
    ///
    /// This initializer attempts to load existing wallet data from persistent storage.
    /// If loading fails, it initializes with empty wallet data and logs the error.
    ///
    /// - Note: This is a public initializer to allow creating instances outside the actor
    public init() {
        do {
            self.wallet = try Self.loadWalletData()
        } catch {
            print("⚠️ Failed to load wallet data: \(error)")
            self.wallet = WalletData(mnemonics: [], privateKeys: [])
        }
    }

    /// Returns the file URL for storing the wallet data JSON file.
    ///
    /// This method locates the application's Application Support directory,
    /// creating it if necessary, and appends the wallet data filename.
    ///
    /// - Throws: An error if the Application Support directory cannot be accessed or created.
    /// - Returns: The full file URL where wallet data is stored.
    private static func walletFileURL() throws -> URL {
        let appSupport = try FileManager.default.url(for: .applicationSupportDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true)
        return appSupport.appendingPathComponent("walletData.json")
    }

    /// Loads the wallet data from persistent storage.
    ///
    /// This method attempts to read the wallet data JSON file from disk,
    /// decode it into a `WalletData` instance, and return it. If the file does not exist,
    /// it returns an empty `WalletData` instance.
    ///
    /// - Throws: An error if reading the file or decoding the data fails.
    /// - Returns: The decoded `WalletData` object or an empty wallet if no file is found.
    private static func loadWalletData() throws -> WalletData {
        let url = try walletFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            return WalletData(mnemonics: [], privateKeys: [])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(WalletData.self, from: data)
    }

    /// Saves the current wallet data to persistent storage asynchronously.
    ///
    /// This method encodes the wallet data to JSON format and writes it atomically
    /// to the designated file URL on a background thread to ensure thread safety.
    ///
    /// - Throws: An error if encoding or file writing fails.
    private func save() async throws {
        let data = try JSONEncoder().encode(wallet)
        let url = try Self.walletFileURL()

        // Thread-safe background write
        try await Task.detached(priority: .utility) {
            try data.write(to: url, options: [.atomic])
        }.value
    }

    /// Adds a new mnemonic phrase to the wallet, encrypting it before storage.
    ///
    /// This method encrypts the provided mnemonic string and appends it as a new `MnemonicEntry`
    /// in the wallet's mnemonic list. It also initializes the `derivedAddressCount` to 1,
    /// representing the first derived address from this mnemonic. The wallet data is saved asynchronously.
    /// To simplify the logic, only a single mnemonic is supported at the moment.
    ///
    /// - Parameter mnemonic: The mnemonic phrase string to add.
    /// - Returns: The newly created `MnemonicEntry`.
    /// - Throws: Any error encountered during encryption or saving the wallet data.
    public func addMnemonic(_ mnemonic: String) async throws -> MnemonicEntry {
        if (wallet.mnemonics.count != 0) {
            return wallet.mnemonics.first!
        }
        let encrypted = try AESWalletCrypto.encrypt(Data(mnemonic.utf8))
        var entry = MnemonicEntry(id: UUID(), encryptedData: encrypted, createdAt: Date(), generatedAddressCount: 0)
        wallet.mnemonics.append(entry)
        
        _ = try await deriveAndAddPrivateKey(from: entry, index: 0)
        
        entry.generatedAddressCount += 1
        if let idx = wallet.mnemonics.firstIndex(where: { $0.id == entry.id }) {
            wallet.mnemonics[idx] = entry
        }
        try await save()
        return entry
    }

    /// Retrieves the decrypted mnemonic phrase associated with the specified UUID.
    ///
    /// This method looks up the mnemonic entry by its unique identifier, decrypts the stored encrypted data,
    /// and returns the mnemonic phrase as a UTF-8 string.
    ///
    /// - Parameter id: The UUID of the mnemonic entry to retrieve.
    /// - Returns: The decrypted mnemonic phrase string.
    /// - Throws:
    ///   - `WalletError.notFound` if no mnemonic entry matches the given UUID.
    ///   - `WalletError.decodingFailed` if decryption or UTF-8 conversion fails.
    public func getMnemonic(id: UUID) throws -> String {
        guard let entry = wallet.mnemonics.first(where: { $0.id == id }) else {
            throw WalletError.notFound
        }
        let decrypted = try AESWalletCrypto.decrypt(entry.encryptedData)
        guard let mnemonic = String(data: decrypted, encoding: .utf8) else {
            throw WalletError.decodingFailed
        }
        return mnemonic
    }
    
    /// Retrieves the decrypted mnemonic phrase at the specified index in the wallet.
    ///
    /// This method accesses the mnemonic entry at the given index, decrypts the stored encrypted data,
    /// and returns the mnemonic phrase as a UTF-8 string. It performs bounds checking to ensure the index is valid.
    ///
    /// - Parameter index: The position of the mnemonic entry in the wallet's mnemonic array.
    /// - Returns: The decrypted mnemonic phrase string.
    /// - Throws:
    ///   - `WalletError.notFound` if the index is out of bounds.
    ///   - `WalletError.decodingFailed` if decryption or UTF-8 conversion fails.
    public func getMnemonic(at index: Int) throws -> String {
        guard wallet.mnemonics.indices.contains(index) else {
            throw WalletError.indexOutOfBounds
        }

        let entry = wallet.mnemonics[index]
        let decrypted = try AESWalletCrypto.decrypt(entry.encryptedData)

        guard let mnemonic = String(data: decrypted, encoding: .utf8) else {
            throw WalletError.decodingFailed
        }

        return mnemonic
    }

    /// Adds a new private key to the wallet, encrypts it, and persists the updated wallet state.
    ///
    /// This method accepts a Base58-encoded private key string, decodes it, encrypts the raw key data,
    /// and stores it in the wallet. Optionally, it can associate the private key with a specific mnemonic
    /// entry by providing the mnemonic's UUID. After adding the key, the wallet data is saved asynchronously.
    ///
    /// - Parameters:
    ///   - privateKeyBase58: The Base58-encoded private key string to store.
    ///   - fromMnemonicID: (Optional) The UUID of the mnemonic from which the private key was derived.
    /// - Returns: A `PrivateKeyEntry` instance representing the newly stored private key.
    /// - Throws:
    ///   - `WalletError.invalidPrivateKeyFormat` if the Base58 decoding fails.
    ///   - Any error thrown during encryption or file saving.
    public func addPrivateKey(_ privateKeyBase58: String, fromMnemonicID: UUID? = nil) async throws -> PrivateKeyEntry {
        guard let keyData = Base58.decode(privateKeyBase58) else {
            throw WalletError.invalidPrivateKeyFormat
        }

        let encrypted = try AESWalletCrypto.encrypt(Data(keyData))
        guard let publicKey = PrivateKey.extractBase58PublicKey(from: Data(keyData)) else { throw WalletError.invalidPrivateKeyFormat }
        let entry = PrivateKeyEntry(id: UUID(), address: publicKey, encryptedData: encrypted, sourceMnemonicID: fromMnemonicID, createdAt: Date())
        wallet.privateKeys.append(entry)
        try await save()
        return entry
    }

    /// Retrieves and decrypts the Base58-encoded private key corresponding to the given ID.
    ///
    /// This method locates the encrypted private key stored in the wallet, decrypts it,
    /// and returns the resulting key as a Base58-encoded string.
    ///
    /// - Parameter id: The unique identifier of the private key entry to retrieve.
    /// - Returns: A Base58-encoded string representing the decrypted private key.
    /// - Throws:
    ///   - `WalletError.notFound` if no private key entry with the given ID exists.
    ///   - Any error thrown during decryption or Base58 encoding.
    public func getPrivateKeyBase58(id: UUID) throws -> String {
        guard let entry = wallet.privateKeys.first(where: { $0.id == id }) else {
            throw WalletError.notFound
        }

        let decrypted = try AESWalletCrypto.decrypt(entry.encryptedData)
        return decrypted.toBase58String()
    }

    /// Derives a private key from the given mnemonic entry at the specified index,
    /// encrypts it, stores it in the wallet, and returns the resulting private key entry.
    ///
    /// This function is typically used to derive additional addresses from an existing mnemonic.
    ///
    /// - Parameters:
    ///   - entry: The `MnemonicEntry` from which the private key should be derived.
    ///   - index: The derivation index used to generate the keypair (e.g., 0 for the first address).
    /// - Returns: A `PrivateKeyEntry` representing the encrypted and stored private key.
    /// - Throws:
    ///   - `WalletError.notFound` if the mnemonic ID does not exist.
    ///   - `WalletError.encodingFailed` if keypair derivation fails.
    ///   - Any error thrown during encryption or saving to disk.
    func deriveAndAddPrivateKey(from entry: MnemonicEntry, index: Int) async throws -> PrivateKeyEntry {
        let mnemonic = try getMnemonic(id: entry.id)
        guard let keypair = keypairOfMnemonicWalletByIndex(index: index, mnemonic: mnemonic) else {
            throw WalletError.encodingFailed
        }
        if let i = wallet.mnemonics.firstIndex(where: { $0.id == entry.id }) {
            wallet.mnemonics[i].generatedAddressCount += 1
        }
        return try await addPrivateKey(keypair.privateKey.toBase58String(), fromMnemonicID: entry.id)
    }
    
    /// Derives a new private key from the mnemonic at the specified index and adds it to the wallet.
    ///
    /// This function retrieves the mnemonic at the given index, derives a keypair for that index,
    /// then encrypts and stores the private key in the wallet's private key list.
    /// It also updates the `generatedAddressCount` of the corresponding mnemonic entry.
    ///
    /// - Parameter index: The index of the mnemonic to derive a private key from.
    /// - Returns: A newly created `PrivateKeyEntry`.
    /// - Throws: `WalletError` if the index is invalid, mnemonic retrieval fails, or key derivation fails.
    public func deriveAndAddPrivateKeyAt(index: Int) async throws -> PrivateKeyEntry {
        let entry = try await getMnemonicEntryAtIndex(index: index)
        return try await deriveAndAddPrivateKey(from: entry, index: entry.generatedAddressCount)
    }
    
    /// Derives a private key from the given mnemonic entry at the specified index,
    /// encrypts it, stores it in the wallet, and returns the resulting private key entry.
    ///
    /// This function is typically used to derive additional addresses from an existing mnemonic.
    ///
    /// - Parameters:
    ///   - entry: The `MnemonicEntry` from which the private key should be derived.
    /// - Returns: A `PrivateKeyEntry` representing the encrypted and stored private key.
    /// - Throws:
    ///   - `WalletError.notFound` if the mnemonic ID does not exist.
    ///   - `WalletError.encodingFailed` if keypair derivation fails.
    ///   - Any error thrown during encryption or saving to disk.
    func deriveAndAddPrivateKey(from entry: MnemonicEntry) async throws -> PrivateKeyEntry {
        try await deriveAndAddPrivateKey(from: entry, index: entry.generatedAddressCount)
    }
    
    /// Resets the entire wallet by clearing all stored mnemonics and private keys,
    /// and deleting the wallet data file from disk.
    ///
    /// This is useful for operations such as logging out, resetting the wallet,
    /// or restoring from a backup. Both in-memory and persisted data are cleared.
    ///
    /// - Throws: An error if deleting the file or saving the cleared state fails.
    public func resetWallet() async throws {
        self.wallet = WalletData(mnemonics: [], privateKeys: [])

        // Delete the saved JSON file if it exists.
        let fileURL = try Self.walletFileURL()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// Retrieves all stored mnemonic entries.
    ///
    /// - Returns: An array of `MnemonicEntry` representing all saved mnemonics.
    /// - Note: This method is async to ensure safe access within the actor context.
    func getMnemonicEntryArray() async -> [MnemonicEntry] {
        return self.wallet.mnemonics
    }
    
    /// Retrieves a `MnemonicEntry` at the specified index from the wallet's mnemonic list.
    ///
    /// This method provides safe access to the `mnemonics` array in the wallet data.
    /// If the specified index is out of bounds, it throws a `WalletError.indexOutOfBounds` error
    /// to prevent crashes due to invalid array access.
    ///
    /// - Parameter index: The index of the desired `MnemonicEntry`.
    /// - Returns: The `MnemonicEntry` at the given index if it exists.
    /// - Throws: `WalletError.indexOutOfBounds` if the index is outside the bounds of the `mnemonics` array.
    public func getMnemonicEntryAtIndex(index: Int) async throws -> MnemonicEntry {
        guard index >= 0 && index < self.wallet.mnemonics.count else {
            throw WalletError.indexOutOfBounds
        }
        return self.wallet.mnemonics[index]
    }
    
    /// Retrieves all stored private key entries.
    ///
    /// - Returns: An array of `PrivateKeyEntry` representing all saved private keys.
    /// - Note: This method is async to ensure safe access within the actor context.
    func getPrivateKeysEntry() async -> [PrivateKeyEntry] {
        return self.wallet.privateKeys
    }
    
    /// Retrieves a `PrivateKeyEntry` at the specified index from the wallet's private key list.
    ///
    /// This method safely accesses the wallet's private key array and throws an error
    /// if the given index is out of bounds, preventing potential crashes due to invalid access.
    ///
    /// - Parameter index: The index of the desired `PrivateKeyEntry`.
    /// - Returns: The `PrivateKeyEntry` at the given index if it exists.
    /// - Throws: `WalletError.indexOutOfBounds` if the index is not within the valid range of the array.
    public func getPrivateKeysEntryAtIndex(index: Int) async throws -> PrivateKeyEntry {
        guard index >= 0 && index < self.wallet.privateKeys.count else {
            throw WalletError.indexOutOfBounds
        }
        return self.wallet.privateKeys[index]
    }
}
