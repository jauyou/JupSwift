//
//  TransferTokenExample.swift
//  JupSwift
//
//  Example: Transfer SPL tokens (e.g., USDC) on Solana
//
//  Created by Zhao You on 8/11/25.
//

import Foundation
import JupSwift

/// Example: Transfer USDC tokens on Devnet
func transferUSDCExample() async throws {
    print("=".repeating(count: 70))
    print("SPL Token Transfer Example")
    print("=".repeating(count: 70))
    
    // MARK: - Setup
    
    // 1. Initialize connection to Solana Devnet
    let connection = SolanaConnection(cluster: .devnet)
    print("\n✅ Connected to:", connection.endpoint)
    
    // 2. Load sender keypair (in production, load from secure storage)
    // Example: Using a base58 private key
    let senderPrivateKey = "YOUR_BASE58_PRIVATE_KEY_HERE"
    let senderKeypair = Keypair(base58PrivateKey: senderPrivateKey)
    
    print("📤 Sender:", senderKeypair.publicKey.base58())
    
    // 3. Define recipient
    let recipientAddress = PublicKey(base58: "RECIPIENT_WALLET_ADDRESS_HERE")
    print("📥 Recipient:", recipientAddress.base58())
    
    // 4. Define USDC mint (Devnet)
    let usdcMint = CommonTokenMints.Devnet.USDC
    print("🪙 Token Mint (USDC):", usdcMint.base58())
    
    // MARK: - Method 1: High-level transfer (Recommended)
    
    // This method automatically:
    // - Derives token accounts
    // - Creates destination token account if needed
    // - Sends the transfer
    
    print("\n" + "=".repeating(count: 70))
    print("Method 1: High-level Transfer")
    print("=".repeating(count: 70))
    
    let amount: UInt64 = 1_000_000  // 1 USDC (6 decimals)
    
    do {
        let signature = try await transferToken(
            connection: connection,
            payer: senderKeypair,
            mint: usdcMint,
            sender: senderKeypair.publicKey,
            recipient: recipientAddress,
            amount: amount
        )
        
        print("\n✅ Transfer Successful!")
        print("   Signature:", signature)
        print("   Explorer:", await connection.getExplorerUrl(signature: signature))
    } catch {
        print("❌ Transfer failed:", error)
    }
    
    // MARK: - Method 2: Manual instruction creation
    
    // This gives you more control over the transaction
    
    print("\n" + "=".repeating(count: 70))
    print("Method 2: Manual Instruction Creation")
    print("=".repeating(count: 70))
    
    // Step 1: Derive token accounts
    let sourceTokenAccount = findAssociatedTokenAddress(
        walletAddress: senderKeypair.publicKey,
        tokenMintAddress: usdcMint
    )
    let destinationTokenAccount = findAssociatedTokenAddress(
        walletAddress: recipientAddress,
        tokenMintAddress: usdcMint
    )
    
    print("\n📍 Token Accounts:")
    print("   Source:", sourceTokenAccount.base58())
    print("   Destination:", destinationTokenAccount.base58())
    
    // Step 2: Create transfer instruction
    let transferInstruction = createTransferInstruction(
        source: sourceTokenAccount,
        destination: destinationTokenAccount,
        authority: senderKeypair.publicKey,
        amount: amount
    )
    
    // Step 3: Send transaction
    do {
        let signature = try await connection.sendTransaction(
            instructions: [transferInstruction],
            signers: [senderKeypair]
        )
        
        print("\n✅ Transfer Successful!")
        print("   Signature:", signature)
        print("   Explorer:", await connection.getExplorerUrl(signature: signature))
    } catch {
        print("❌ Transfer failed:", error)
    }
    
    // MARK: - Method 3: Low-level transfer with explicit accounts
    
    // Use this when you already know the token account addresses
    
    print("\n" + "=".repeating(count: 70))
    print("Method 3: Low-level Transfer")
    print("=".repeating(count: 70))
    
    do {
        let signature = try await transferTokenWithAccounts(
            connection: connection,
            payer: senderKeypair,
            sourceTokenAccount: sourceTokenAccount,
            destinationTokenAccount: destinationTokenAccount,
            authority: senderKeypair.publicKey,
            amount: amount
        )
        
        print("\n✅ Transfer Successful!")
        print("   Signature:", signature)
        print("   Explorer:", await connection.getExplorerUrl(signature: signature))
    } catch {
        print("❌ Transfer failed:", error)
    }
}

/// Example: Decode and analyze a signed transaction
func analyzeTransactionExample() {
    print("\n" + "=".repeating(count: 70))
    print("Transaction Analysis Example")
    print("=".repeating(count: 70))
    
    // This is the base64 transaction from your analysis
    let base64Transaction = """
    ActW5lP6kA1I++eBiXYggGJLrPUi2EMa5dqVdxg6T9DZZugqeJi5xSaEFzdyfkiGaTLgv6LQL7PpZnk\
    2mGcauQgBAAEECQ1tXMKDI5yFjVxxmpzISyWyxVOc7ZqJ45ZpCTUZQ3XpW7B5domyepa2V2JS0dfSci\
    r44zb8K+YPbvN04pVdUPhnbp5dM7D5XNneZMBGuyrEiE0kHZvdyoPj23tqdN7FBt324ddloZPZy+FGz\
    ut5rBy0he1fWzeROoz1hX7/AKniTckB67MlW4GPomAWrc6nFloqEOsJZoQAlCNKEDWXhgEDAwIBAAkD\
    ZAAAAAAAAAA=
    """
    
    print("\n📦 Transaction Details:")
    print("   - Sender: cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
    print("   - Receiver: seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX")
    print("   - Amount: 0.0001 USDC (100 smallest units)")
    print("   - Instruction Type: SPL Token Transfer (Type 3)")
    print("\n📍 Token Accounts:")
    print("   - Source: HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
    print("   - Destination: Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
    print("\n🔍 Instruction Data (Hex): 036400000000000000")
    print("   - Byte 0 (03): Transfer instruction type")
    print("   - Bytes 1-8 (6400000000000000): Amount = 100 (little-endian u64)")
}

/// Example: Create a transfer instruction matching the analyzed transaction
func recreateTransferExample() {
    print("\n" + "=".repeating(count: 70))
    print("Recreate Transfer Instruction Example")
    print("=".repeating(count: 70))
    
    // From the analyzed transaction
    let sourceTokenAccount = PublicKey(base58: "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
    let destinationTokenAccount = PublicKey(base58: "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
    let authority = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
    let amount: UInt64 = 100  // 0.0001 USDC
    
    // Create the instruction
    let instruction = createTransferInstruction(
        source: sourceTokenAccount,
        destination: destinationTokenAccount,
        authority: authority,
        amount: amount
    )
    
    print("\n✅ Instruction Created:")
    print("   Program ID:", instruction.programId.base58())
    print("   Accounts:")
    for (index, key) in instruction.keys.enumerated() {
        print("      [\(index)] \(key.pubkey.base58())")
        print("          Writable: \(key.isWritable), Signer: \(key.isSigner)")
    }
    
    // Verify instruction data
    let dataHex = instruction.data.map { String(format: "%02x", $0) }.joined()
    print("   Data (Hex): \(dataHex)")
    print("   Data matches original: \(dataHex == "036400000000000000" ? "✅" : "❌")")
}

/// Example: Different token transfers
func multiTokenTransferExample() async throws {
    print("\n" + "=".repeating(count: 70))
    print("Multi-Token Transfer Example")
    print("=".repeating(count: 70))
    
    let connection = SolanaConnection(cluster: .devnet)
    let senderKeypair = Keypair(base58PrivateKey: "YOUR_PRIVATE_KEY")
    let recipient = PublicKey(base58: "RECIPIENT_ADDRESS")
    
    // Transfer different amounts with proper decimals
    
    // 1. Transfer 1 USDC (6 decimals)
    print("\n💵 Transferring 1 USDC...")
    let usdcAmount = 1_000_000  // 1.0 USDC
    _ = try await transferToken(
        connection: connection,
        payer: senderKeypair,
        mint: CommonTokenMints.Devnet.USDC,
        sender: senderKeypair.publicKey,
        recipient: recipient,
        amount: UInt64(usdcAmount)
    )
    
    // 2. Transfer 0.5 USDC
    print("\n💵 Transferring 0.5 USDC...")
    let halfUsdcAmount = 500_000  // 0.5 USDC
    _ = try await transferToken(
        connection: connection,
        payer: senderKeypair,
        mint: CommonTokenMints.Devnet.USDC,
        sender: senderKeypair.publicKey,
        recipient: recipient,
        amount: UInt64(halfUsdcAmount)
    )
    
    // 3. Transfer 0.01 USDC (like in the x402 payment example)
    print("\n💵 Transferring 0.01 USDC (x402 payment)...")
    let paymentAmount = 10_000  // 0.01 USDC
    _ = try await transferToken(
        connection: connection,
        payer: senderKeypair,
        mint: CommonTokenMints.Devnet.USDC,
        sender: senderKeypair.publicKey,
        recipient: recipient,
        amount: UInt64(paymentAmount)
    )
}

// MARK: - Helper Extension

extension String {
    func repeating(count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

// MARK: - Main Entry Point

/*
// Uncomment to run examples:

Task {
    // Analyze the transaction you provided
    analyzeTransactionExample()
    
    // Recreate the same instruction
    recreateTransferExample()
    
    // Try actual transfers (requires valid keypair and recipient)
    // try await transferUSDCExample()
    // try await multiTokenTransferExample()
}
*/
