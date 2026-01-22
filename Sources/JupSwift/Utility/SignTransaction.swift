//
//  SignTransaction.swift
//  JupSwift
//
//  Created by Zhao You on 24/5/25.
//

import Foundation
import Clibsodium

public func signTransaction(base64Transaction: String, privateKey: [UInt8]) throws -> String {
    guard !base64Transaction.isEmpty else {
        throw JupiterError.invalidTransaction("Transaction cannot be empty")
    }

    guard sodium_init() >= 0 else {
        throw JupiterError.libsodiumInitFailed
    }

    // ✅ 1. resolve transaction data
    guard let fullTransactionData = Data(base64Encoded: base64Transaction) else {
        throw JupiterError.invalidTransaction("Invalid base64 encoding")
    }
    let fullTransactionBytes = [UInt8](fullTransactionData)

    let signatureCount = Int(fullTransactionBytes[0])
    let signatureLength = 64
    let messageStartIndex = 1 + signatureCount * signatureLength
    
    // Bounds check
    guard messageStartIndex <= fullTransactionBytes.count else {
        throw JupiterError.invalidTransaction("Transaction data too short")
    }

    // ✅ 2. get message
    let message = Array(fullTransactionBytes[messageStartIndex...])

    // ✅ 3. sign message with private key
    var signature = [UInt8](repeating: 0, count: Int(crypto_sign_BYTES))
    var signatureLen: UInt64 = 0

    let result = crypto_sign_ed25519_detached(
        &signature,
        &signatureLen,
        message,
        UInt64(message.count),
        privateKey
    )

    guard result == 0 else {
        throw JupiterError.signingFailed("Crypto sign detached failed")
    }

    // ✅ 4. Manually reconstruct into a signed transaction
    let signedTransaction: [UInt8] = [UInt8(signatureCount)] + signature + message
    let signedTransactionBase64 = Data(signedTransaction).base64EncodedString()

    // ✅ 5. return result
    
    return signedTransactionBase64
}

public func signTransaction(base64Transaction: String, privateKey: String) throws -> String {
    guard let privateKeyBytes = Base58.decode(privateKey) else {
        throw JupiterError.invalidPrivateKey
    }
    return try signTransaction(base64Transaction: base64Transaction, privateKey: privateKeyBytes)
}
