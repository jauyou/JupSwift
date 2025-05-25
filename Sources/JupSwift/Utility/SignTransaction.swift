//
//  SignTransaction.swift
//  JupSwift
//
//  Created by Zhao You on 24/5/25.
//

import Foundation
import Clibsodium

public func signTransaction(base64Transaction: String, privateKey: [UInt8]) -> String {
    guard sodium_init() >= 0 else {
        fatalError("Libsodium init fail")
    }

    // ✅ 1. resolve transaction data
    guard let fullTransactionData = Data(base64Encoded: base64Transaction) else {
        fatalError("Can't resolve base64")
    }
    let fullTransactionBytes = [UInt8](fullTransactionData)

    let signatureCount = Int(fullTransactionBytes[0])
    let signatureLength = 64
    let messageStartIndex = 1 + signatureCount * signatureLength

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
        fatalError("sign fail")
    }

    // ✅ 4. Manually reconstruct into a signed transaction
    let signedTransaction: [UInt8] = [UInt8(signatureCount)] + signature + message
    let signedTransactionBase64 = Data(signedTransaction).base64EncodedString()

    // ✅ 5. output result
    print("✅ signed transaction in Base64:")
    print(signedTransactionBase64)
    
    return signedTransactionBase64
}

public func signTransaction(base64Transaction: String, privateKey: String) -> String {
    guard let privateKey = Base58.decode(privateKey) else { return "" }
    return signTransaction(base64Transaction: base64Transaction, privateKey: privateKey)
}
