//
//  ContentView.swift
//  JupSwiftDemo
//
//  Created by Maxwell on 12/11/25.
//

import SwiftUI
import JupSwift
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ContentView: View {
    @State private var publicKey: String = "Loading..."
    @State private var balance: String = "0"

    var body: some View {
        VStack {
            HStack {
                Text(publicKey)
                Button(action: {
                    copyToClipboard(text: publicKey)
                }) {
                    Image(systemName: "doc.on.doc")
                }
            }
            Text("Dev-USDC: \(balance)")
            Button(action: {
                Task {
                    do {
                        try await testX402PaymentWithHighLevelAPI()
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }) {
                Text("Test X402 Payment")
            }
        }
        .padding()
        .task {
            await loadPublicKey()
        }
    }

    func loadPublicKey() async {
        let walletManager = WalletManager.shared
        do {
            let address = try await walletManager.getCurrentAddress()
            self.publicKey = address
            await loadBalance(walletAddress: address)
        } catch {
            do {
                _ = try await walletManager.generateMnemonicForWallet()
                let privateKeyEntry = try await walletManager.deriveAndAddPrivateKeyAt(index: 0)
                self.publicKey = privateKeyEntry.address
                await loadBalance(walletAddress: privateKeyEntry.address)
            } catch {
                self.publicKey = "Failed to create wallet"
            }
        }
    }
    
    func loadBalance(walletAddress: String) async {
        let walletManager = WalletManager.shared
        let connection = SolanaConnection(cluster: .devnet)
        let mint = CommonTokenMints.Devnet.USDC
        let privateKeyBase58: String
        do {
            privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
            // Convert to Keypair
            guard let privateKeyBytes = Base58.decode(privateKeyBase58) else {
                print("   ❌ Invalid private key format")
                return
            }
            let payer = Keypair(privateKey: privateKeyBytes)
            
            print("   Payer PublicKey: \(payer.publicKey.base58())")
            
            let payerTokenAccount = findAssociatedTokenAddress(
                walletAddress: payer.publicKey,
                tokenMintAddress: mint
            )
            
            print("   Payer Token Account: \(payerTokenAccount.base58())")
            
            
            do {
                let balance = try await connection.getTokenAccountBalance(
                    tokenAccount: payerTokenAccount
                )
                self.balance = balance.uiAmountString
            } catch {
                print("   ⚠️  Token account not found or no balance")
                print("   Please fund the wallet with USDC first:")
                print("   1. Get devnet SOL: solana airdrop 1 \(self.publicKey) --url devnet")
                print("   2. Get devnet USDC: https://spl-token-faucet.com/?token-name=USDC")
            }
        } catch {
            print("   ❌ Failed to get private key from WalletManager")
        }
    }
    
    
    
    private func copyToClipboard(text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
    
    private func testX402PaymentWithHighLevelAPI() async throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🧪 X402 Payment with High-level API + WalletManager")
        print(String(repeating: "=", count: 80) + "\n")
        
        // MARK: - Step 1: Setup with WalletManager
        
        print("🔧 Step 1: Setup with WalletManager...")
        
        let walletManager = WalletManager.shared
        
        // Get current wallet address
        let payerAddress: String
        do {
            payerAddress = try await walletManager.getCurrentAddress()
            print("   ✅ Using WalletManager")
            print("   Wallet Address: \(payerAddress)")
        } catch {
            print("⚠️ WalletManager not initialized")
            print("   Run testInitWallet first to initialize WalletManager")
            return
        }
        
        // Get private key from WalletManager
        let privateKeyBase58: String
        do {
            privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
        } catch {
            print("   ❌ Failed to get private key from WalletManager")
            return
        }
        
        // Convert to Keypair
        guard let privateKeyBytes = Base58.decode(privateKeyBase58) else {
            print("   ❌ Invalid private key format")
            return
        }
        
        let payer = Keypair(privateKey: privateKeyBytes)
        
        // Initialize connection and X402 client with high-level API
        let connection = SolanaConnection(cluster: .devnet)
        let x402Client = X402PaymentClient(
            serverUrl: "http://localhost:3001",
            network: "solana-devnet",
            cluster: .devnet
        )
        
        print("   X402 Server: http://localhost:3001")
        print("   Solana Network: devnet\n")
        
        // MARK: - Step 2: Check Balance Before Payment
        
        print("💰 Step 2: Check balance before payment...")
        
        let mint = CommonTokenMints.Devnet.USDC
        
        // Get or create the ATA
        // Note: This assumes the ATA already exists on devnet
        // The function should detect it exists and return without creating a new one
        let payerTokenAccount = try await getOrCreateAssociatedTokenAccount(
            connection: connection,
            payer: payer,
            mint: mint,
            owner: payer.publicKey
        )
        
        print("   Payer Private Key: \(payer.privateKey)")
        print("   Payer Token Account: \(payerTokenAccount.base58())")
        
        let balanceBefore: SolanaConnection.TokenAccountBalance.Value
        do {
            balanceBefore = try await connection.getTokenAccountBalance(
                tokenAccount: payerTokenAccount
            )
            print("   Balance before: \(balanceBefore.uiAmountString) USDC")
        } catch {
            print("   ⚠️  Token account not found or no balance")
            print("   Please fund the wallet with USDC first:")
            print("   1. Get devnet SOL: solana airdrop 1 \(payerAddress) --url devnet")
            print("   2. Get devnet USDC: https://spl-token-faucet.com/?token-name=USDC")
            return
        }
        
        // MARK: - Step 3: Pay for Content (High-level API - Automatic!)
        
        print("\n🚀 Step 3: Pay for content using high-level API...")
        print("   (Automatic ATA management, transaction creation, signing, submission)\n")
        
        let response: X402PaymentResponse
        do {
            response = try await x402Client.payForContent(
                endpoint: "/premium",
                payer: payer
            )
        } catch {
            print("   ❌ Payment failed: \(error)")
            throw error
        }
        
        // MARK: - Step 4: Verify Response
        
        print("\n✅ Step 4: Payment successful!")
        
        if let content = response.data {
            print("   📦 Premium Content: \(content)")
        }
        
        if let details = response.paymentDetails {
            print("   💳 Transaction Details:")
            print("      Signature: \(details.signature)")
            if let amountUSDC = details.amountUSDC {
                print("      Amount: \(amountUSDC) USDC (\(details.amount) smallest units)")
            }
            print("      Recipient: \(details.recipient)")
            print("   🔗 Explorer: \(details.explorerUrl)")
        }
        
        // MARK: - Step 5: Wait for Confirmation
        
        print("\n⏳ Step 5: Waiting for confirmation...")
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        print("   ✅ Confirmation wait complete")
        
        // MARK: - Step 6: Check Balance After Payment
        
        print("\n📊 Step 6: Verify balance changes...")
        
        let balanceAfter = try await connection.getTokenAccountBalance(
            tokenAccount: payerTokenAccount
        )
        
        print("   Balance after:  \(balanceAfter.uiAmountString) USDC")
        print("   Balance before: \(balanceBefore.uiAmountString) USDC")
        
        // Verify balance decreased
        guard let beforeAmount = UInt64(balanceBefore.amount),
              let afterAmount = UInt64(balanceAfter.amount) else {
            return
        }
        
        let difference = beforeAmount - afterAmount
        print("   Difference: \(difference) (smallest units)")
        
        // Expected: 100 (0.0001 USDC in smallest units)
        print("\n" + String(repeating: "=", count: 80))
        print("✨ Summary")
        print(String(repeating: "=", count: 80))
        print("High-level API automatically handled:")
        print("  ✓ Request payment quote")
        print("  ✓ Check/create payer's token account")
        print("  ✓ Check/create recipient's token account")
        print("  ✓ Create and sign transaction")
        print("  ✓ Send payment proof to server")
        print("\nAll done with ONE method call: payForContent()! 🎉")
        print(String(repeating: "=", count: 80) + "\n")
        
        await loadPublicKey()
    }
}

#Preview {
    ContentView()
}
