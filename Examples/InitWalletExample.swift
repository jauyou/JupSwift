//
//  InitWalletExample.swift
//  JupSwift
//
//  Example: Initialize Wallet with WalletManager
//
//  This example demonstrates how to:
//  1. Check if a wallet exists
//  2. Generate a new random seed if needed
//  3. Print public key and private key
//
//  Created by Zhao You on 8/11/25.
//

import Foundation
import JupSwift

/// Example: Initialize and verify wallet
///
/// This function checks if a wallet exists in WalletManager.
/// If no wallet exists, it generates a new random seed (mnemonic).
/// Finally, it prints the public key and private key.
///
func initWalletExample() async throws {
    print("=" + String(repeating: "=", count: 79))
    print("🔑 Initialize Wallet Example")
    print("=" + String(repeating: "=", count: 79) + "\n")
    
    let walletManager = WalletManager.shared
    
    // MARK: - Step 1: Check if wallet exists
    
    print("📋 Step 1: Check if wallet exists...")
    
    let walletsExist: Bool
    do {
        let address = try await walletManager.getCurrentAddress()
        walletsExist = !address.isEmpty
        print("   ✅ Wallet found!")
        print("   Current address: \(address)")
    } catch {
        walletsExist = false
        print("   ℹ️  No wallet found in WalletManager")
    }
    
    // MARK: - Step 2: Generate new wallet if needed
    
    if !walletsExist {
        print("\n🌱 Step 2: Generate new wallet with random seed...")
        
        let mnemonicEntry = try await walletManager.generateMnemonicForWallet()
        let mnemonic = try await walletManager.getMnemonic(id: mnemonicEntry.id)
        
        print("   ✅ New wallet generated!")
        print("   Mnemonic: \(mnemonic)")
        print("   ⚠️  IMPORTANT: Save this mnemonic in a secure location!")
        print("   Entry ID: \(mnemonicEntry.id)")
    } else {
        print("\n✅ Step 2: Using existing wallet (skipping generation)")
    }
    
    // MARK: - Step 3: Get and print public key
    
    print("\n📤 Step 3: Get public key...")
    let publicKeyAddress = try await walletManager.getCurrentAddress()
    print("   Public Key (Address): \(publicKeyAddress)")
    
    // Verify public key format
    if publicKeyAddress.count > 30 && !publicKeyAddress.isEmpty {
        print("   ✅ Public key format is valid")
    } else {
        print("   ⚠️  Public key format may be invalid")
    }
    
    // MARK: - Step 4: Get and print private key
    
    print("\n🔐 Step 4: Get private key...")
    let privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
    
    // For security, show only first 20 characters
    let privateKeyPreview = String(privateKeyBase58.prefix(20))
    print("   Private Key (Base58): \(privateKeyPreview)...[truncated]")
    print("   Private Key Length: \(privateKeyBase58.count) characters")
    
    // Verify private key format
    if privateKeyBase58.count > 40 && !privateKeyBase58.isEmpty {
        print("   ✅ Private key format is valid")
    } else {
        print("   ⚠️  Private key format may be invalid")
    }
    
    // MARK: - Step 5: Additional wallet information
    
    print("\n📊 Step 5: Get wallet information...")
    let wallets = await walletManager.getPrivateKeysEntry()
    print("   Total wallets in WalletManager: \(wallets.count)")
    
    for (index, wallet) in wallets.enumerated() {
        print("   Wallet \(index): \(wallet.address)")
        if let sourceMnemonicID = wallet.sourceMnemonicID {
            print("      Derived from mnemonic: \(sourceMnemonicID)")
        }
    }
    
    // MARK: - Summary
    
    print("\n" + String(repeating: "=", count: 80))
    print("✅ Wallet Initialization Complete!")
    print(String(repeating: "=", count: 80))
    print("\n📋 Summary:")
    print("   Public Key: \(publicKeyAddress)")
    print("   Private Key: [Available - \(privateKeyBase58.count) characters]")
    print("   Total Wallets: \(wallets.count)")
    print("\n" + String(repeating: "=", count: 80) + "\n")
}

/// Example: Initialize wallet and use for X402 payment
func initWalletAndPay() async throws {
    print("🚀 Initialize Wallet and Make Payment\n")
    
    // Initialize wallet
    try await initWalletExample()
    
    // Use wallet for X402 payment
    print("💰 Now you can use the wallet for X402 payments")
}

// MARK: - Usage Instructions

/*
 To run this example:
 
 1. In your main app or script:
 
    Task {
        do {
            try await initWalletExample()
        } catch {
            print("Error: \(error)")
        }
    }
 
 2. Expected output when no wallet exists:
 
    ================================================================================
    🔑 Initialize Wallet Example
    ================================================================================
    
    📋 Step 1: Check if wallet exists...
       ℹ️  No wallet found in WalletManager
    
    🌱 Step 2: Generate new wallet with random seed...
       ✅ New wallet generated!
       Mnemonic: word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12
       ⚠️  IMPORTANT: Save this mnemonic in a secure location!
    
    📤 Step 3: Get public key...
       Public Key (Address): cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG
       ✅ Public key format is valid
    
    🔐 Step 4: Get private key...
       Private Key (Base58): 5J3mBbAH58CkqGx...[truncated]
       Private Key Length: 88 characters
       ✅ Private key format is valid
    
    📊 Step 5: Get wallet information...
       Total wallets in WalletManager: 1
       Wallet 0: cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG
          Derived from mnemonic: 12345678-1234-1234-1234-123456789012
    
    ================================================================================
    ✅ Wallet Initialization Complete!
    ================================================================================
    
    📋 Summary:
       Public Key: cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG
       Private Key: [Available - 88 characters]
       Total Wallets: 1
    
    ================================================================================

 3. Expected output when wallet already exists:
 
    📋 Step 1: Check if wallet exists...
       ✅ Wallet found!
       Current address: cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG
    
    ✅ Step 2: Using existing wallet (skipping generation)
    
    [... rest of output showing existing wallet info ...]

 4. Integration with X402:
 
    After initializing the wallet, you can use it for X402 payments:
    
    Task {
        try await initWalletExample()
        // Wallet is now ready
        try await x402PaymentWithWalletManager()
    }
*/
