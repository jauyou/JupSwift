//
//  SignMessage.swift
//  JupSwift
//
//  Detached Ed25519 signing over arbitrary bytes (e.g. wallet-link nonce
//  messages). Companion to SignTransaction.swift.
//

import Foundation
import Clibsodium

/// Signs an arbitrary message with a 64-byte Ed25519 private key and
/// returns the 64-byte detached signature.
public func signMessage(message: [UInt8], privateKey: [UInt8]) throws -> [UInt8] {
    guard sodium_init() >= 0 else {
        throw JupiterError.libsodiumInitFailed
    }
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
    return signature
}

/// Convenience: base58 private key in, base58 signature out.
public func signMessage(message: Data, privateKeyBase58: String) throws -> String {
    guard let privateKeyBytes = Base58.decode(privateKeyBase58) else {
        throw JupiterError.invalidPrivateKey
    }
    let signature = try signMessage(message: [UInt8](message), privateKey: privateKeyBytes)
    return Base58.encode(signature)
}
