//
//  Mnemonic.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation
import CryptoKit
import CommonCrypto
import Clibsodium

/// Converts a mnemonic phrase into a seed using an optional passphrase, following the BIP39 standard.
/// - Parameters:
///   - mnemonic: The mnemonic phrase to convert.
///   - passphrase: An optional passphrase to secure the seed. Defaults to an empty string.
/// - Returns: The derived seed as `Data`. Returns `nil` if conversion fails.
func mnemonicToSeed(mnemonic: String, passphrase: String = "") -> Data! {
    let password = mnemonic.lowercased().decomposedStringWithCompatibilityMapping
    let salt = "mnemonic" + passphrase

    let passwordData = password.data(using: .utf8)!
    let saltData = salt.data(using: .utf8)!

    var derivedKey = Data(repeating: 0, count: 64)

    let status = derivedKey.withUnsafeMutableBytes { derivedKeyPtr in
        passwordData.withUnsafeBytes { passwordPtr in
            saltData.withUnsafeBytes { saltPtr in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordPtr.baseAddress!.assumingMemoryBound(to: Int8.self),
                    passwordData.count,
                    saltPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    saltData.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA512),
                    2048,
                    derivedKeyPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    64
                )
            }
        }
    }

    if (status == kCCSuccess) {
        return derivedKey
    } else {
        return nil
    }
}

// SLIP-0010 Ed25519 Master Key Derivation
struct KeyNode {
    let key: Data   // 32 bytes private key
    let chainCode: Data  // 32 bytes chain code
}

/// Generates the master key node for Ed25519 SLIP-0010 from the given seed.
/// - Parameter seed: The input seed data used for master key generation.
/// - Returns: A `KeyNode` representing the master key derived from the seed.
func ed25519Slip10MasterKey(from seed: Data) -> KeyNode {
    let key = Data("ed25519 seed".utf8)
    let digest = HMAC<SHA512>.authenticationCode(for: seed, using: SymmetricKey(data: key))
    let data = Data(digest)
    let privateKey = data.prefix(32)
    let chainCode = data.suffix(32)
    return KeyNode(key: privateKey, chainCode: chainCode)
}

/// Derives a child key node from a given parent key node using the specified index.
/// - Parameters:
///   - parent: The parent `KeyNode` from which to derive the child.
///   - index: The index of the child key to derive.
/// - Returns: A new `KeyNode` representing the derived child key.
func deriveChildKey(parent: KeyNode, index: UInt32) -> KeyNode {
    var data = Data([0x00]) // hard derivation
    data.append(parent.key)
    
    var indexBE = index.bigEndian
    data.append(Data(bytes: &indexBE, count: 4))

    let digest = HMAC<SHA512>.authenticationCode(for: data, using: SymmetricKey(data: parent.chainCode))
    let derived = Data(digest)
    return KeyNode(
        key: derived.prefix(32),
        chainCode: derived.suffix(32)
    )
}

/// Parses a derivation path string into an array of UInt32 indices.
/// - Parameter path: The derivation path string (e.g., "m/44'/501'/0'/0'").
/// - Returns: An array of UInt32 values representing each level of the derivation path.
func parsePath(_ path: String) -> [UInt32] {
    let segments = path.split(separator: "/").dropFirst()
    return segments.map { segment in
        let hardened = segment.hasSuffix("'")
        let numberStr = segment.replacingOccurrences(of: "'", with: "")
        let number = UInt32(numberStr)!
        return hardened ? number | 0x80000000 : number
    }
}

/// Derives a key node following the given derivation path from the provided seed.
/// - Parameters:
///   - path: The derivation path string (e.g., "m/44'/501'/0'/0'").
///   - seed: The seed data used as the root for derivation.
/// - Returns: A `KeyNode` representing the derived key at the specified path.
func derivePath(path: String, seed: Data) -> KeyNode {
    var node = ed25519Slip10MasterKey(from: seed)
    let indexes = parsePath(path)
    for index in indexes {
        node = deriveChildKey(parent: node, index: index)
    }
    return node
}

/// Derives an Ed25519 keypair from a mnemonic phrase at a specific derivation index.
/// - Parameters:
///   - index: The derivation index to specify which key to derive.
///   - mnemonic: The mnemonic phrase used to generate the seed for key derivation.
/// - Returns: A tuple containing the public key and private key as `Data` if successful; otherwise, returns `nil`.
func keypairOfMnemonicWalletByIndex(index: Int, mnemonic: String) -> (publicKey: Data, privateKey: Data)? {
    guard let seed = mnemonicToSeed(mnemonic: mnemonic) else { fatalError("Seed fail") }
    let path = "m/44'/501'/" + String(index) + "'/0'"
    let node = derivePath(path: path, seed: seed)

    if let keypair = keypairFromSeed(node.key) {
        return keypair
    }
    return nil
}

/// Generates an Ed25519 keypair (public and private keys) from the given seed using libsodium.
/// - Parameter seed: The seed data used to derive the keypair.
/// - Returns: A tuple containing the public key and private key as `Data` if successful; otherwise, returns `nil`.
func keypairFromSeed(_ seed: Data) -> (publicKey: Data, privateKey: Data)? {
    guard seed.count == 32 else { return nil }

    var pk = Data(repeating: 0, count: 32)
    var sk = Data(repeating: 0, count: 64)

    var resultSeed = seed // workaround exclusive access error
    _ = resultSeed.withUnsafeMutableBytes { seedPtr in
        pk.withUnsafeMutableBytes { pkPtr in
            sk.withUnsafeMutableBytes { skPtr in
                crypto_sign_seed_keypair(
                    pkPtr.bindMemory(to: UInt8.self).baseAddress!,
                    skPtr.bindMemory(to: UInt8.self).baseAddress!,
                    seedPtr.bindMemory(to: UInt8.self).baseAddress!
                )
            }
        }
    }
    return (pk, sk)
}

/// Generates a mnemonic phrase according to the BIP39 standard.
/// - Returns: A mnemonic phrase as a string, typically consisting of 12 or 24 words.
public func generateMnemonic() -> String {
    // Generate random entropy for mnemonic seed generation
    let entropy = Data((0..<16).map { _ in UInt8.random(in: 0...255) })

    // Calculate the checksum
    let hash = SHA256.hash(data: entropy)
    let checksum = hash.prefix(1) // 取前 1 個字節作為 checksum

    // Concatenate entropy and checksum bits
    let entropyWithChecksum = entropy + checksum

    let binaryString = entropyWithChecksum.map { byte in
        String(byte, radix: 2).leftPadding(toLength: 8, withPad: "0")
    }.joined()

    // Split the concatenated bits into groups of 11 bits
    var binaryWords: [String] = []
    for i in stride(from: 0, to: binaryString.count, by: 11) {
        let startIndex = binaryString.index(binaryString.startIndex, offsetBy: i)
        let endIndex = binaryString.index(startIndex, offsetBy: 11, limitedBy: binaryString.endIndex) ?? binaryString.endIndex
        let wordBinary = String(binaryString[startIndex..<endIndex])
        binaryWords.append(wordBinary)
    }

    // Load the BIP39 wordlist
    if let wordList = loadWordList() {
        // Decode 11-bit segments as indices into the BIP39 wordlist
        let mnemonicWords = binaryWords.compactMap { binary in
            let index = Int(binary, radix: 2)!
            return wordList[index]
        }
        
        // Construct the final mnemonic phrase from wordlist entries
        let mnemonic = mnemonicWords.joined(separator: " ")
        
        return mnemonic
    } else {
        print("Failed to load the word list.")
        return("")
    }
}

enum MnemonicValidationError: Error {
    case invalidWordCount
    case invalidWords(indexes: [Int])
}

/// Validates a BIP39 mnemonic phrase.
/// - Parameter mnemonicArray: The mnemonic phrase string (e.g., "apple banana cherry ...").
/// - Returns: `.success(())` if valid, otherwise `.failure` with reason.
func validateMnemonics(_ mnemonicArray: String) -> Result<Void, MnemonicValidationError> {
    let words = mnemonicArray.lowercased().split(separator: " ").map { String($0) }

    return validateMnemonics(words)
}

/// Validates a BIP39 mnemonic phrase.
/// - Parameter words: The mnemonic phrase as an array of words.
/// - Returns: `.success(())` if valid, otherwise `.failure` with reason.
func validateMnemonics(_ words: [String]) -> Result<Void, MnemonicValidationError> {
    guard let wordlist = loadWordList() else {
        return .failure(.invalidWordCount) // fallback error
    }

    let validWordCounts = [12, 15, 18, 21, 24]
    guard validWordCounts.contains(words.count) else {
        return .failure(.invalidWordCount)
    }

    let invalidIndexes = words.enumerated()
        .filter { !wordlist.contains($0.element.lowercased()) }
        .map { $0.offset }

    if !invalidIndexes.isEmpty {
        return .failure(.invalidWords(indexes: invalidIndexes))
    }

    return .success(())
}

enum MnemonicWordValidationResult: Equatable {
    case exactMatch
    case partialMatch
    case noMatch
}

/// Validates a single BIP39 mnemonic word.
/// - Parameter word: A single mnemonic word entered by the user.
/// - Returns:
///   - `.exactMatch` if the word is valid and fully matches a word in the BIP39 list.
///   - `.partialMatch` if the word is a valid prefix of any word in the BIP39 list.
///   - `.noMatch` if it doesn't match any word or prefix.
func validateMnemonicWord(_ word: String) -> MnemonicWordValidationResult {
    guard let wordlist = loadWordList() else {
        return .noMatch // fallback in case wordlist fails to load
    }

    let lowercase = word.lowercased()

    if wordlist.contains(lowercase) {
        return .exactMatch
    }

    if wordlist.contains(where: { $0.hasPrefix(lowercase) }) {
        return .partialMatch
    }

    return .noMatch
}

extension String {
    /// Pads the string on the left with the specified character until it reaches the given length.
    /// - Parameters:
    ///   - toLength: The desired total length of the resulting string after padding.
    ///   - character: The character to use for padding. Defaults to "0".
    /// - Returns: A new string padded on the left with the specified character to the desired length.
    ///            If the original string is already equal to or longer than `toLength`, returns the original string.
    func leftPadding(toLength: Int, withPad character: Character = "0") -> String {
        if self.count >= toLength { return self }
        return String(repeatElement(character, count: toLength - self.count)) + self
    }
}

/// Read the english.txt file from the local resources, split it by line breaks, and convert it into an array of words to be used as the BIP39 wordlist.
/// - Returns: An optional array of strings representing the wordlist. Returns nil if the file cannot be found or read.
func loadWordList() -> [String]? {
    guard let fileURL = Bundle.module.url(forResource: "english", withExtension: "txt") else {
        print("Failed to read the file: english.txt not found.")
        return nil
    }
    
    do {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let words = content.split(separator: "\n").map { String($0) }
        return words
    } catch {
        print("Failed to read the file: \(error)")
        return nil
    }
}

extension Data {
    /// Encodes the data (or string) into a Base58-encoded string representation.
    /// - Returns: A Base58-encoded string.
    func toBase58String() -> String {
        return Base58.encode(self)
    }
}
