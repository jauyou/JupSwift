//
//  AssociatedTokenAccountExample.swift
//  JupSwift
//
//  Usage Example: How to get or create associated token accounts
//
//  Created by Zhao You on 8/11/25.
//

import Foundation
import JupSwift

/// Example: Get or create associated token account (using cluster configuration)
func exampleGetOrCreateAssociatedTokenAccountWithCluster() async throws {
    // Method 1: Use predefined cluster
    let connection = SolanaConnection(cluster: .devnet)
    
    // Method 2: Use custom endpoint and specify cluster
    // let connection = SolanaConnection(endpoint: "https://api.devnet.solana.com", cluster: .devnet)
    
    // Create or load payer's keypair
    let payerPrivateKey = "YOUR_BASE58_PRIVATE_KEY_HERE"
    let payer = Keypair(base58PrivateKey: payerPrivateKey)
    
    // Use network-specific USDC mint
    let mint = CommonTokenMints.Devnet.USDC  // Devnet USDC
    // Or mainnet: CommonTokenMints.Mainnet.USDC
    
    let owner = payer.publicKey
    
    print("\n🔍 Checking/creating associated token account...")
    print("Network: \(connection.cluster?.rawValue ?? "custom")")
    
    // Get or create associated token account
    let tokenAccount = try await getOrCreateAssociatedTokenAccount(
        connection: connection,
        payer: payer,
        mint: mint,
        owner: owner
    )
    
    print("✅ Associated token account address:", tokenAccount.base58())
    print("🔗 Explorer:", await connection.getExplorerUrl(address: tokenAccount.base58()))
}

/// Example: Get or create associated token account (traditional method)
func exampleGetOrCreateAssociatedTokenAccount() async throws {
    // 1. Initialize Solana connection
    let connection = SolanaConnection(
        endpoint: "https://api.devnet.solana.com",
        cluster: .devnet  // Optional, but recommended to specify for better Explorer links
    )
    
    // 2. Create or load payer's keypair
    // Note: Need to use real private key, format is Base58 string
    let payerPrivateKey = "YOUR_BASE58_PRIVATE_KEY_HERE"
    let payer = Keypair(base58PrivateKey: payerPrivateKey)
    
    // 3. Define token mint address
    // For example: USDC mint address
    let mint = PublicKey(base58: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
    
    // 4. Define owner address, usually payer themselves
    let owner = payer.publicKey
    
    print("\n🔍 Checking/creating associated token account...")
    
    // 5. Get or create associated token account
    let tokenAccount = try await getOrCreateAssociatedTokenAccount(
        connection: connection,
        payer: payer,
        mint: mint,
        owner: owner
    )
    
    print("✅ Associated token account address:", tokenAccount.base58())
}

/// Example: Only find associated token account address (don't create)
func exampleFindAssociatedTokenAddress() {
    print("\n🔍 Find associated token account address...")
    
    // Wallet address
    let walletAddress = PublicKey(base58: "YOUR_WALLET_ADDRESS_HERE")
    
    // Token mint address (e.g., USDC)
    let tokenMint = PublicKey(base58: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
    
    // Calculate associated token account address
    let ata = findAssociatedTokenAddress(
        walletAddress: walletAddress,
        tokenMintAddress: tokenMint
    )
    
    print("📍 Associated token account address:", ata.base58())
}

/// Example: Check if account exists
func exampleCheckAccountExists() async throws {
    let connection = SolanaConnection(
        endpoint: "https://api.mainnet-beta.solana.com"
    )
    
    // Account address to check
    let accountAddress = PublicKey(base58: "YOUR_ACCOUNT_ADDRESS_HERE")
    
    print("\n🔍 Checking if account exists...")
    
    if let accountInfo = try await connection.getAccountInfo(account: accountAddress) {
        print("✅ Account exists")
        print("- Balance:", accountInfo.lamports, "lamports")
        print("- Owner:", accountInfo.owner)
        print("- Executable:", accountInfo.executable)
    } else {
        print("❌ Account does not exist")
    }
}

// MARK: - Usage

// Run examples in async context:
/*
Task {
    do {
        // Example 1: Get or create associated token account
        try await exampleGetOrCreateAssociatedTokenAccount()
        
        // Example 2: Only find address
        exampleFindAssociatedTokenAddress()
        
        // Example 3: Check if account exists
        try await exampleCheckAccountExists()
    } catch {
        print("❌ Error:", error)
    }
}
*/
