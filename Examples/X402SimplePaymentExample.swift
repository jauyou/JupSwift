//
//  X402SimplePaymentExample.swift
//  JupSwift
//
//  Example: X402 Payment with High-level API (Automatic ATA Management)
//  Demonstrates using the simplified `payForContent()` method
//
//  Note: This is an example file, not an executable.
//  To run this example, copy the code to a Swift script or playground.
//
//  Created by Zhao You on 8/11/25.
//

import Foundation
import JupSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Example function demonstrating X402 payment with high-level API
func x402SimplePaymentExample() async throws {
    print("================================================================================")
    print("X402 Simple Payment Example (High-level API)")
    print("================================================================================\n")
    
    // Step 1: Initialize X402 client
    let x402Client = X402PaymentClient(
        serverUrl: "http://localhost:3001",
        network: "solana-devnet",
        cluster: .devnet
    )
    
    // Step 2: Load payer keypair
    let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: "./x402-solana-examples/pay-in-usdc/client.json"))
    let privateKeyArray = try JSONDecoder().decode([UInt8].self, from: privateKeyData)
    let payer = Keypair(privateKey: privateKeyArray)
    
    print("Payer: \(payer.publicKey.base58())\n")
    
    // Step 3: Pay for content (automatic ATA management!)
    print("🚀 Starting payment flow with automatic ATA management...\n")
    
    let response = try await x402Client.payForContent(
        endpoint: "/premium",
        payer: payer
    )
    
    // Step 4: Display result
    print("\n================================================================================")
    print("✅ Payment Successful!")
    print("================================================================================\n")
    
    if let content = response.data {
        print("📦 Premium Content:")
        print("  \(content)\n")
    }
    
    if let details = response.paymentDetails {
        print("💳 Transaction Details:")
        print("  Signature: \(details.signature)")
        if let amountUSDC = details.amountUSDC {
            print("  Amount: \(amountUSDC) USDC (\(details.amount) smallest units)")
        } else {
            print("  Amount: \(details.amount) lamports")
        }
        print("  Recipient: \(details.recipient)")
        print("\n🔗 View on Solana Explorer:")
        print("  \(details.explorerUrl)")
    }
    
    print("\n================================================================================")
    print("✨ Summary")
    print("================================================================================")
    print("The payForContent() method automatically handled:")
    print("  ✓ Request payment quote")
    print("  ✓ Check/create payer's token account")
    print("  ✓ Check/create recipient's token account (if needed)")
    print("  ✓ Create and sign transaction")
    print("  ✓ Send payment proof to server")
    print("================================================================================\n")
}
