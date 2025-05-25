//
//  PrivateKey.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation

class PrivateKey {
    /// Extracts the public key from a 64-byte Ed25519 private key
    /// - Parameter privateKey: A 64-byte Ed25519 private key
    /// - Returns: A 32-byte public key if the input is valid, otherwise `nil`
    static public func extractPublicKey(from privateKey: Data) -> Data? {
        guard privateKey.count == 64 else { return nil }
        return privateKey.subdata(in: 32..<64)
    }
    
    /// Extracts the public key from a 64-byte Ed25519 private key
    /// - Parameter privateKey: A 64-byte Ed25519 private key with Base58 format
    /// - Returns: A 32-byte public key if the input is valid, otherwise `nil`
    static public func extractBase58PublicKey(from privateKey: Data) -> String? {
        guard privateKey.count == 64 else { return nil }
        return privateKey.subdata(in: 32..<64).toBase58String()
    }
    
    /// Convert an array of UInt8 to Data
    /// - Parameter bytes: The UInt8 array to convert
    /// - Returns: A Data object representing the bytes
    static public func uint8ArrayToData(_ bytes: [UInt8]) -> Data {
        return Data(bytes)
    }
    
    /// Convert Data to an array of UInt8
    /// - Parameter data: The Data object to convert
    /// - Returns: A UInt8 array representing the data
    static public func dataToUint8Array(_ data: Data) -> [UInt8] {
        return [UInt8](data)
    }
}
