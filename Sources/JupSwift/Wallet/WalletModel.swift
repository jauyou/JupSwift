//
//  WalletModel.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation

/// Represents a single mnemonic phrase entry stored securely.
///
/// - `id`: Unique identifier for this mnemonic entry.
/// - `encryptedData`: The encrypted mnemonic phrase data.
/// - `createdAt`: Timestamp when this mnemonic was created.
/// - `generatedAddressCount`: Tracks how many addresses have been derived/generated from this mnemonic.
public struct MnemonicEntry: Codable, Sendable {
    let id: UUID
    let encryptedData: Data
    let createdAt: Date
    var generatedAddressCount: Int = 0
}

/// Represents a single private key entry stored securely.
///
/// - `id`: Unique identifier for this private key entry.
/// - `encryptedData`: The encrypted private key data.
/// - `sourceMnemonicID`: Optional reference to the mnemonic entry from which this key was derived.
/// - `createdAt`: Timestamp when this private key was created or added.
public struct PrivateKeyEntry: Codable, Sendable {
    let id: UUID
    let address: String
    let encryptedData: Data
    let sourceMnemonicID: UUID?
    let createdAt: Date
}

/// Aggregates all wallet-related data, including mnemonics and private keys.
///
/// - `mnemonics`: Array of stored mnemonic entries.
/// - `privateKeys`: Array of stored private key entries.
struct WalletData: Codable {
    var currentWalletIndex: Int = 0
    var mnemonics: [MnemonicEntry]
    var privateKeys: [PrivateKeyEntry]
}

/// Defines errors that can occur during wallet data operations.
///
/// - `notFound`: The requested entry was not found.
/// - `invalidPrivateKeyFormat`: The private key string is not a valid Base58 format.
/// - `decryptionFailed`: Decryption process failed with underlying error.
/// - `encodingFailed`: Encoding of data to persistent format failed.
/// - `decodingFailed`: Decoding of persisted data failed.
/// - `indexOutOfBounds`: Requested index exceeds available entries.
enum WalletError: Error, LocalizedError {
    case notFound
    case invalidPrivateKeyFormat
    case decryptionFailed(Error)
    case encodingFailed
    case decodingFailed
    case indexOutOfBounds

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Entry not found."
        case .invalidPrivateKeyFormat:
            return "Invalid private key format. Expecting Base58 string."
        case .decryptionFailed(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .encodingFailed:
            return "Failed to encode data."
        case .decodingFailed:
            return "Failed to decode data."
        case .indexOutOfBounds:
            return "Index out of bounds."
        }
    }
}
