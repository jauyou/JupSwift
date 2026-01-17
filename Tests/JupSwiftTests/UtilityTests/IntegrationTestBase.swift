//
//  IntegrationTestBase.swift
//  JupSwift
//
//  Base class for integration tests with shared setup and utilities
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

/// Base class for integration tests with common setup
class IntegrationTestBase: XCTestCase {
    
    // MARK: - Common Test Addresses
    
    /// Sender/Payer wallet (client)
    let clientWallet = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
    
    /// Receiver/Server wallet
    let serverWallet = PublicKey(base58: "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX")
    
    /// USDC mint address on devnet
    let usdcMint = CommonTokenMints.Devnet.USDC
    
    // MARK: - Derived Token Accounts
    
    /// Client's USDC token account
    lazy var clientTokenAccount: PublicKey = {
        findAssociatedTokenAddress(walletAddress: clientWallet, tokenMintAddress: usdcMint)
    }()
    
    /// Server's USDC token account
    lazy var serverTokenAccount: PublicKey = {
        findAssociatedTokenAddress(walletAddress: serverWallet, tokenMintAddress: usdcMint)
    }()
    
    // MARK: - Helper Methods
    
    /// Load private key from environment variable or default path
    func loadPrivateKey(defaultPath: String? = nil) throws -> Keypair {
        let privateKeyPath = try findPrivateKeyPath(defaultPath: defaultPath)
        let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))
        let privateKeyArray = try JSONDecoder().decode([UInt8].self, from: privateKeyData)
        return Keypair(privateKey: privateKeyArray)
    }
    
    /// Find private key file path
    private func findPrivateKeyPath(defaultPath: String?) throws -> String {
        // Check environment variable first
        if let envPath = ProcessInfo.processInfo.environment["CLIENT_PRIVATE_KEY_PATH"] {
            return envPath
        }
        
        // Use provided default or compute from test file location
        if let defaultPath = defaultPath {
            guard FileManager.default.fileExists(atPath: defaultPath) else {
                throw TestError.fileNotFound(defaultPath)
            }
            return defaultPath
        }
        
        // Derive path from test file location
        let testFilePath = URL(fileURLWithPath: #filePath)
        let projectRoot = testFilePath
            .deletingLastPathComponent()  // Remove current file
            .deletingLastPathComponent()  // Remove UtilityTests
            .deletingLastPathComponent()  // Remove JupSwiftTests
            .deletingLastPathComponent()  // Remove Tests
        
        let keyFileURL = projectRoot
            .appendingPathComponent("x402-solana-examples")
            .appendingPathComponent("pay-in-usdc")
            .appendingPathComponent("client.json")
        
        let path = keyFileURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw TestError.fileNotFound(path)
        }
        
        return path
    }
    
    /// Verify token account address matches expected
    func verifyTokenAccount(_ account: PublicKey, expected: String, message: String) {
        XCTAssertEqual(
            account.base58(),
            expected,
            message
        )
    }
    
    /// Print balance information
    func printBalance(label: String, balance: SolanaConnection.TokenAccountBalance.Value) {
        print("   \(label): \(balance.uiAmountString) USDC")
    }
    
    /// Calculate and print balance change
    func printBalanceChange(before: UInt64, after: UInt64, expected: UInt64, label: String) {
        let change = before > after ? before - after : after - before
        let direction = before > after ? "decrease" : "increase"
        print("   \(label) \(direction): \(change) (expected: \(expected))")
    }
}

// MARK: - Test Errors

enum TestError: Error, LocalizedError {
    case fileNotFound(String)
    case insufficientBalance
    case serverNotRunning
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .insufficientBalance:
            return "Insufficient balance for test"
        case .serverNotRunning:
            return "Server is not running"
        }
    }
}
