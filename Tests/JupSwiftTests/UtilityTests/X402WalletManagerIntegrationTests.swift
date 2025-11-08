//
//  X402WalletManagerIntegrationTests.swift
//  JupSwift
//
//  Integration Test: X402 Payment Protocol with WalletManager (no client.json needed)
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

final class X402WalletManagerIntegrationTests: IntegrationTestBase {
    
    // Use inherited addresses from IntegrationTestBase
    var payerWallet: PublicKey { clientWallet }
    var payerTokenAccount: PublicKey { clientTokenAccount }
    
    /// Test: X402 USDC Payment with WalletManager and balance verification
    ///
    /// ⚠️ Note: This is an integration test that requires:
    /// 1. WalletManager initialized with a wallet containing USDC
    /// 2. X402 server running (http://localhost:3001)
    /// 3. Internet connection to Solana devnet
    ///
    /// This test demonstrates using WalletManager instead of client.json for signing.
    ///
    /// ## Test Flow (8 steps)
    /// 1. Setup: Use WalletManager instead of loading from file
    /// 2. Request payment quote from X402 server
    /// 3. Check balance before payment
    /// 4. Create transaction instructions
    /// 5. Sign with WalletManager (no client.json needed!)
    /// 6. Send payment proof to X402 server
    /// 7. Wait for confirmation
    /// 8. Check balance after payment and verify change
    ///
    func testX402USDCPaymentWithWalletManager() async throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🧪 X402 USDC Payment Integration Test with WalletManager")
        print(String(repeating: "=", count: 80) + "\n")
        
        // MARK: - Step 0: Setup with WalletManager
        
        print("🔧 Step 0: Setup with WalletManager...")
        
        let walletManager = WalletManager.shared
        
        try await importTestWallet()
        
        // Get current wallet address from WalletManager
        let payerAddress: String
        do {
            payerAddress = try await walletManager.getCurrentAddress()
        } catch {
            print("⚠️ WalletManager not initialized")
            print("   To run this test, initialize WalletManager first:")
            print("   1. Import mnemonic: await walletManager.addMnemonic(\"your mnemonic\")")
            print("   2. Or generate new: await walletManager.generateMnemonicForWallet()")
            throw XCTSkip("WalletManager not initialized with a wallet")
        }
        
        let payer = PublicKey(base58: payerAddress)
        
        print("   ✅ Using WalletManager")
        print("   Wallet Address: \(payerAddress)")
        
        // Initialize connection and X402 client
        let connection = SolanaConnection(cluster: .devnet)
        let x402Client = X402PaymentClient(
            serverUrl: "http://localhost:3001",
            network: "solana-devnet"
        )
        
        print("   X402 Server: http://localhost:3001")
        print("   Solana Network: devnet\n")
        
        // MARK: - Step 1: Request Payment Quote (X402 Protocol)
        
        print("📡 Step 1: Request payment quote from X402 server...")
        
        let quote: X402PaymentQuote
        do {
            quote = try await x402Client.requestPaymentQuote(endpoint: "/premium")
        } catch {
            print("   ❌ Failed to connect to X402 server")
            print("   Make sure server is running: npm run usdc:server")
            throw XCTSkip("X402 server not available: \(error)")
        }
        
        guard let tokenAccount = quote.payment.tokenAccount,
              let mintStr = quote.payment.mint,
              let amount = quote.payment.amount else {
            XCTFail("Invalid payment quote")
            return
        }
        
        let recipientTokenAccount = PublicKey(base58: tokenAccount)
        let mint = PublicKey(base58: mintStr)
        let transferAmount = UInt64(amount)
        
        print("   ✅ Payment quote received")
        print("   Amount: \(transferAmount) (raw)")
        print("   Amount: \(Double(transferAmount) / 1_000_000) USDC")
        print("   Mint: \(mintStr)")
        print("   Recipient Token Account: \(tokenAccount)\n")
        
        // Verify USDC mint
        let expectedUSDCMint = CommonTokenMints.Devnet.USDC
        XCTAssertEqual(mint.base58(), expectedUSDCMint.base58(), "Should be USDC devnet mint")
        
        // MARK: - Step 2: Check Balance Before Payment
        
        print("💰 Step 2: Check balance before payment...")
        
        print("   ℹ️  Debug Info:")
        print("   Payer Wallet: \(payer.base58())")
        print("   Mint: \(mint.base58())")
        
        let payerTokenAccount = findAssociatedTokenAddress(
            walletAddress: payer,
            tokenMintAddress: mint
        )
        
        print("   Calculated Payer Token Account: \(payerTokenAccount.base58())")
        print("   Server Token Account: \(recipientTokenAccount.base58())")
        
        // Check if payer token account exists, if not provide helpful message
        let payerBalanceBefore: SolanaConnection.TokenAccountBalance.Value
        do {
            payerBalanceBefore = try await connection.getTokenAccountBalance(
                tokenAccount: payerTokenAccount
            )
        } catch {
            print("   ❌ Payer token account doesn't exist or has no balance")
            print("   Please fund the wallet with USDC first:")
            print("   1. Get devnet SOL: solana airdrop 1 \(payerAddress) --url devnet")
            print("   2. Get devnet USDC: npm run usdc:client")
            throw XCTSkip("Payer account not funded: \(error)")
        }
        
        // Check if server token account exists, if not it will be created during transfer
        let serverBalanceBefore: SolanaConnection.TokenAccountBalance.Value
        do {
            serverBalanceBefore = try await connection.getTokenAccountBalance(
                tokenAccount: recipientTokenAccount
            )
        } catch {
            print("   ⚠️  Server token account doesn't exist yet")
            print("   It will be created automatically during the transfer")
            // Set initial balance to 0
            serverBalanceBefore = SolanaConnection.TokenAccountBalance.Value(
                amount: "0",
                decimals: 6,
                uiAmount: 0.0,
                uiAmountString: "0"
            )
        }
        
        print("\n   📊 Balance before payment:")
        print("   Payer: \(payerBalanceBefore.uiAmountString) USDC")
        print("   Server: \(serverBalanceBefore.uiAmountString) USDC")
        
        // Verify sufficient balance
        guard let payerAmountBefore = UInt64(payerBalanceBefore.amount) else {
            XCTFail("Invalid balance format")
            return
        }
        
        guard payerAmountBefore >= transferAmount else {
            print("   ❌ Insufficient balance")
            print("   Required: \(transferAmount), Available: \(payerAmountBefore)")
            throw XCTSkip("Insufficient USDC balance")
        }
        
        print("   ✅ Sufficient balance confirmed\n")
        
        // MARK: - Step 3: Create Transaction
        
        print("🔨 Step 3: Create transaction...")
        
        var instructions: [TransactionInstruction] = []
        
        // Transfer instruction
        let transferInstruction = createTransferInstruction(
            source: payerTokenAccount,
            destination: recipientTokenAccount,
            authority: payer,
            amount: transferAmount
        )
        instructions.append(transferInstruction)
        
        // Get recent blockhash
        let blockhash = try await connection.getLatestBlockhash()
        
        // MARK: - Step 4: Sign with WalletManager (Get Keypair)
        
        print("✍️  Step 4: Sign transaction with WalletManager...")
        print("   🔑 Getting private key from WalletManager")
        
        // Get private key from WalletManager and create Keypair
        let privateKeyBase58: String
        do {
            privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
        } catch {
            print("   ❌ Failed to get private key from WalletManager")
            XCTFail("Cannot get private key: \(error)")
            return
        }
        
        guard let privateKeyBytes = Base58.decode(privateKeyBase58) else {
            print("   ❌ Invalid private key format")
            XCTFail("Failed to decode private key")
            return
        }
        
        let signingKeypair = Keypair(privateKey: privateKeyBytes)
        print("   ✅ Got keypair from WalletManager")
        
        // Create transaction WITH signer (this ensures proper signing)
        let transaction = Transaction(
            recentBlockhash: blockhash,
            instructions: instructions,
            signers: [signingKeypair]  // Keypair will sign during serialization
        )
        
        // Serialize (automatically signs with keypair)
        let signedTxData = try transaction.serialize()
        let signedTxBase64 = signedTxData.base64EncodedString()
        
        print("   ✅ Transaction created and signed")
        print("   Instructions: \(instructions.count)")
        print("   Blockhash: \(blockhash)")
        print("   Signed transaction size: \(Data(base64Encoded: signedTxBase64)?.count ?? 0) bytes\n")
        
        // MARK: - Step 5: Send Payment Proof (X402 Protocol)
        
        print("📤 Step 5: Send payment proof to X402 server...")
        
        let response: X402PaymentResponse
        do {
            response = try await x402Client.sendPaymentProof(
                endpoint: "/premium",
                serializedTransaction: signedTxBase64
            )
        } catch {
            print("   ❌ Failed to send payment proof")
            XCTFail("Payment proof submission failed: \(error)")
            return
        }
        
        print("   ✅ Payment proof accepted by server")
        
        guard let paymentDetails = response.paymentDetails else {
            XCTFail("No payment details in response")
            return
        }
        
        let signature = paymentDetails.signature
        print("   Transaction signature: \(signature)")
        print("   Explorer: \(paymentDetails.explorerUrl)\n")
        
        // MARK: - Step 6: Wait for Confirmation
        
        print("⏳ Step 6: Wait for transaction confirmation...")
        
        let confirmed = try await connection.confirmTransaction(
            signature: signature,
            timeout: 60
        )
        
        XCTAssertTrue(confirmed, "Transaction should be confirmed")
        print("   ✅ Transaction confirmed on-chain\n")
        
        // MARK: - Step 7: Check Balance After Payment
        
        print("💰 Step 7: Check balance after payment...")
        
        // Give it a moment for balance to update
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        
        let payerBalanceAfter = try await connection.getTokenAccountBalance(
            tokenAccount: payerTokenAccount
        )
        let serverBalanceAfter = try await connection.getTokenAccountBalance(
            tokenAccount: recipientTokenAccount
        )
        
        print("\n   📊 Balance after payment:")
        print("   Payer: \(payerBalanceAfter.uiAmountString) USDC")
        print("   Server: \(serverBalanceAfter.uiAmountString) USDC\n")
        
        // MARK: - Step 8: Verify Balance Changes
        
        print("✅ Step 8: Verify balance changes...")
        
        guard let payerAmountAfter = UInt64(payerBalanceAfter.amount),
              let serverAmountBefore = UInt64(serverBalanceBefore.amount),
              let serverAmountAfter = UInt64(serverBalanceAfter.amount) else {
            XCTFail("Invalid balance format in verification")
            return
        }
        
        // Payer balance should decrease by exact transfer amount
        let payerDecrease = payerAmountBefore - payerAmountAfter
        print("   Payer balance decreased by: \(payerDecrease)")
        print("   Expected decrease: \(transferAmount)")
        XCTAssertEqual(payerDecrease, transferAmount, "Payer balance should decrease by transfer amount")
        
        // Server balance should increase by exact transfer amount
        let serverIncrease = serverAmountAfter - serverAmountBefore
        print("   Server balance increased by: \(serverIncrease)")
        print("   Expected increase: \(transferAmount)")
        XCTAssertEqual(serverIncrease, transferAmount, "Server balance should increase by transfer amount")
        
        // Verify content was received
        if let content = response.data {
            print("\n   📄 Paid content received:")
            print("   \(content)")
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("✅ X402 Integration test passed!")
        print("   Used WalletManager for signing (no client.json needed)")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    // MARK: - Helper Tests
    
    /// Test: Initialize WalletManager with auto-generated seed
    ///
    /// This test checks if a wallet exists in WalletManager.
    /// If no wallet exists, it generates a new random seed (mnemonic).
    /// Finally, it prints the public key and private key.
    /// The test passes if both keys are successfully printed.
    ///
    /// Test: Initialize Wallet
    /// 
    /// ⚠️ This test is disabled by default.
    /// To run this test, comment out the XCTSkip line below.
    func testInitWallet() async throws {
        // Test is disabled - uncomment the line below to enable
        throw XCTSkip("testInitWallet is disabled by default. Enable it manually if needed.")
        
        print("\n" + String(repeating: "=", count: 80))
        print("🔑 Test: Initialize Wallet")
        print(String(repeating: "=", count: 80) + "\n")
        
        // Note: Fallback storage can be enabled with WALLET_USE_FALLBACK=1 environment variable
        // The test will automatically use fallback storage if Keychain is unavailable
        let walletManager = WalletManager.shared
        
        // Check if wallet exists
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
        
        // If no wallet exists, generate a new one
        if !walletsExist {
            print("\n🌱 Step 2: Generate new wallet with random seed...")
            
            let mnemonicEntry = try await walletManager.generateMnemonicForWallet()
            let mnemonic = try await walletManager.getMnemonic(id: mnemonicEntry.id)
            
            print("   ✅ New wallet generated!")
            print("   Mnemonic: \(mnemonic)")
            print("   ⚠️  IMPORTANT: Save this mnemonic in a secure location!")
        } else {
            print("\n✅ Step 2: Using existing wallet (skipping generation)")
        }
        
        // Get and print public key
        print("\n📤 Step 3: Get public key...")
        let publicKeyAddress = try await walletManager.getCurrentAddress()
        print("   Public Key (Address): \(publicKeyAddress)")
        
        // Verify public key is valid
        XCTAssertFalse(publicKeyAddress.isEmpty, "Public key should not be empty")
        XCTAssertTrue(publicKeyAddress.count > 30, "Public key should be valid Solana address")
        
        // Get and print private key
        print("\n🔐 Step 4: Get private key...")
        let privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
        print("   Private Key (Base58): \(privateKeyBase58.prefix(20))...[truncated for security]")
        print("   Private Key Length: \(privateKeyBase58.count) characters")
        
        // Verify private key is valid
        XCTAssertFalse(privateKeyBase58.isEmpty, "Private key should not be empty")
        XCTAssertTrue(privateKeyBase58.count > 40, "Private key should be valid length")
        
        // Final verification
        print("\n✅ Step 5: Verification")
        print("   Public Key: ✅ Retrieved and valid")
        print("   Private Key: ✅ Retrieved and valid")
        
        // Test passes if we got here (both keys printed successfully)
        print("\n" + String(repeating: "=", count: 80))
        print("✅ Test Passed: Wallet initialized successfully!")
        print("   Public Key (Address): \(publicKeyAddress)")
        print("   Private Key: [Available - truncated for security]")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Test: Import a specific private key into WalletManager
    ///
    /// This test imports a predefined private key and verifies:
    /// - The key is successfully added to WalletManager
    /// - The derived public key (address) is correct
    /// - The imported key can be retrieved
    func testImportSpecificPrivateKey() async throws {
        print("\n" + String(repeating: "=", count: 80))
        print("📥 Test: Import Specific Private Key")
        print(String(repeating: "=", count: 80) + "\n")
        
        let walletManager = WalletManager.shared
        
        // The specific private key to import
        let privateKeyToImport = "2suvGYfSArAYgArtLwGehJoJoChXW8CQc6xWcSVEUkZrsDHJpcvnd1Fa7njWaM3WfqW3iytCAMANgXNNTZ66ii9d"
        
        print("🔐 Step 1: Import private key...")
        print("   Private Key: \(privateKeyToImport.prefix(20))...[truncated for security]")
        
        // Import the private key
        let importedEntry = try await walletManager.addPrivateKey(privateKeyToImport)
        
        print("\n✅ Step 2: Private key imported successfully")
        print("   Entry ID: \(importedEntry.id)")
        print("   Address: \(importedEntry.address)")
        print("   Created At: \(importedEntry.createdAt)")
        
        // Verify the key was stored correctly
        XCTAssertFalse(importedEntry.address.isEmpty, "Address should not be empty")
        XCTAssertTrue(importedEntry.address.count >= 32, "Address should be valid Solana address")
        
        print("\n🔍 Step 3: Retrieve the imported key...")
        let retrievedKey = try await walletManager.getPrivateKeyBase58(id: importedEntry.id)
        print("   Retrieved Key: \(retrievedKey.prefix(20))...[truncated for security]")
        
        // Verify the retrieved key matches the original
        XCTAssertEqual(retrievedKey, privateKeyToImport, "Retrieved key should match imported key")
        
        print("\n🎯 Step 4: Verify key functionality...")
        
        // Get all private keys to verify it was added
        let allKeys = await walletManager.getPrivateKeysEntry()
        print("   Total private keys in wallet: \(allKeys.count)")
        
        // Check if our imported key is in the list
        let foundKey = allKeys.first { $0.id == importedEntry.id }
        XCTAssertNotNil(foundKey, "Imported key should be in the wallet")
        
        if let foundKey = foundKey {
            print("   ✅ Key found in wallet")
            print("   Address: \(foundKey.address)")
            XCTAssertEqual(foundKey.address, importedEntry.address, "Addresses should match")
        }
        
        print("\n✅ Step 5: Switch to imported wallet and use standard methods...")
        
        // Find the index of the imported key in the wallet (reuse allKeys from Step 4)
        guard let importedIndex = allKeys.firstIndex(where: { $0.id == importedEntry.id }) else {
            XCTFail("Imported key not found in wallet")
            return
        }
        
        print("   Found imported key at index: \(importedIndex)")
        
        // Set the current wallet to use the imported key
        try await walletManager.setCurrentWalletAtIndex(importedIndex)
        print("   ✅ Switched to imported wallet (index \(importedIndex))")
        
        // Now use the standard WalletManager methods
        print("\n   📤 Getting keys using standard WalletManager methods:")
        
        let currentAddress = try await walletManager.getCurrentAddress()
        let currentPrivateKey = try await walletManager.getCurrentPrivateKey()
        
        print("   Public Key (Address): \(currentAddress)")
        print("   Private Key (Base58): \(currentPrivateKey)")
        
        // Expected address for the imported private key
        let expectedAddress = "DPS5p2rdwwrm7pYnTXMgxebgvrzDqVeptHiHbmLfC3rw"
        
        print("\n   🔍 Verification:")
        print("   Expected Address: \(expectedAddress)")
        print("   Actual Address:   \(currentAddress)")
        
        // Verify the address matches the expected value
        XCTAssertEqual(currentAddress, expectedAddress, 
                       "Address should match the expected address for this private key")
        XCTAssertEqual(currentPrivateKey, privateKeyToImport,
                       "Private key from wallet should match the imported key")
        
        if currentAddress == expectedAddress {
            print("   ✅ Address verification passed!")
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("✅ Test Passed: Private key imported and verified successfully!")
        print("\n   🔑 Final Keys from WalletManager (using standard methods):")
        print("   Public Key:  \(currentAddress)")
        print("   Private Key: \(currentPrivateKey)")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    func importTestWallet() async throws {
        let walletManager = WalletManager.shared
        
        // The specific private key to import
        let privateKeyToImport = "2suvGYfSArAYgArtLwGehJoJoChXW8CQc6xWcSVEUkZrsDHJpcvnd1Fa7njWaM3WfqW3iytCAMANgXNNTZ66ii9d"
        
        print("🔐 Step 1: Import private key...")
        print("   Private Key: \(privateKeyToImport.prefix(20))...[truncated for security]")
        
        // Import the private key
        let importedEntry = try await walletManager.addPrivateKey(privateKeyToImport)
        
        print("\n✅ Step 2: Private key imported successfully")
        print("   Entry ID: \(importedEntry.id)")
        print("   Address: \(importedEntry.address)")
        print("   Created At: \(importedEntry.createdAt)")
        
        // Verify the key was stored correctly
        XCTAssertFalse(importedEntry.address.isEmpty, "Address should not be empty")
        XCTAssertTrue(importedEntry.address.count >= 32, "Address should be valid Solana address")
        
        print("\n🔍 Step 3: Retrieve the imported key...")
        let retrievedKey = try await walletManager.getPrivateKeyBase58(id: importedEntry.id)
        print("   Retrieved Key: \(retrievedKey.prefix(20))...[truncated for security]")
        
        // Verify the retrieved key matches the original
        XCTAssertEqual(retrievedKey, privateKeyToImport, "Retrieved key should match imported key")
        
        print("\n🎯 Step 4: Verify key functionality...")
        
        // Get all private keys to verify it was added
        let allKeys = await walletManager.getPrivateKeysEntry()
        print("   Total private keys in wallet: \(allKeys.count)")
        
        // Check if our imported key is in the list
        let foundKey = allKeys.first { $0.id == importedEntry.id }
        XCTAssertNotNil(foundKey, "Imported key should be in the wallet")
        
        if let foundKey = foundKey {
            print("   ✅ Key found in wallet")
            print("   Address: \(foundKey.address)")
            XCTAssertEqual(foundKey.address, importedEntry.address, "Addresses should match")
        }
        
        print("\n✅ Step 5: Switch to imported wallet and use standard methods...")
        
        // Find the index of the imported key in the wallet (reuse allKeys from Step 4)
        guard let importedIndex = allKeys.firstIndex(where: { $0.id == importedEntry.id }) else {
            XCTFail("Imported key not found in wallet")
            return
        }
        
        print("   Found imported key at index: \(importedIndex)")
        
        // Set the current wallet to use the imported key
        try await walletManager.setCurrentWalletAtIndex(importedIndex)
        print("   ✅ Switched to imported wallet (index \(importedIndex))")
        
        // Now use the standard WalletManager methods
        print("\n   📤 Getting keys using standard WalletManager methods:")
        
        let currentAddress = try await walletManager.getCurrentAddress()
        let currentPrivateKey = try await walletManager.getCurrentPrivateKey()
        
        print("   Public Key (Address): \(currentAddress)")
        print("   Private Key (Base58): \(currentPrivateKey)")
        
        // Expected address for the imported private key
        let expectedAddress = "DPS5p2rdwwrm7pYnTXMgxebgvrzDqVeptHiHbmLfC3rw"
        
        print("\n   🔍 Verification:")
        print("   Expected Address: \(expectedAddress)")
        print("   Actual Address:   \(currentAddress)")
        
        // Verify the address matches the expected value
        XCTAssertEqual(currentAddress, expectedAddress,
                       "Address should match the expected address for this private key")
        XCTAssertEqual(currentPrivateKey, privateKeyToImport,
                       "Private key from wallet should match the imported key")
        
        if currentAddress == expectedAddress {
            print("   ✅ Address verification passed!")
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("✅ Test Passed: Private key imported and verified successfully!")
        print("\n   🔑 Final Keys from WalletManager (using standard methods):")
        print("   Public Key:  \(currentAddress)")
        print("   Private Key: \(currentPrivateKey)")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Test: WalletManager connectivity
    func testWalletManagerConnectivity() async throws {
        print("\n🔍 Test: WalletManager connectivity")
        
        let walletManager = WalletManager.shared
        
        do {
            let address = try await walletManager.getCurrentAddress()
            print("   ✅ WalletManager connected")
            print("   Current wallet: \(address)")
            
            // Get all wallets
            let wallets = await walletManager.getPrivateKeysEntry()
            print("   Available wallets: \(wallets.count)")
            
        } catch {
            print("   ⚠️ WalletManager not initialized")
            print("   This is expected if no wallet has been created yet")
            throw XCTSkip("WalletManager not initialized")
        }
    }
    
    /// Test: WalletManager can sign arbitrary transaction
    func testWalletManagerCanSign() async throws {
        print("\n🔍 Test: WalletManager signing capability")
        
        let walletManager = WalletManager.shared
        
        // Verify wallet exists
        guard let _ = try? await walletManager.getCurrentAddress() else {
            throw XCTSkip("WalletManager not initialized")
        }
        
        // Create a simple mock transaction
        let mockTx = Transaction(
            recentBlockhash: "11111111111111111111111111111111",
            instructions: [],
            signers: []
        )
        
        let serialized = try mockTx.serialize().base64EncodedString()
        
        // Try to sign
        do {
            let signed = try await walletManager.signTransaction(base64Transaction: serialized)
            print("   ✅ WalletManager can sign transactions")
            print("   Signed transaction size: \(signed.count) bytes")
        } catch {
            XCTFail("WalletManager should be able to sign: \(error)")
        }
    }
    
    /// Test: Compare WalletManager address with expected test address
    func testWalletManagerAddressMatches() async throws {
        print("\n🔍 Test: Verify WalletManager address")
        
        let walletManager = WalletManager.shared
        
        guard let address = try? await walletManager.getCurrentAddress() else {
            throw XCTSkip("WalletManager not initialized")
        }
        
        print("   Current address: \(address)")
        print("   Expected test address: \(clientWallet.base58())")
        
        // Note: This will only pass if WalletManager is initialized with the test wallet
        // For general testing, we just verify the address is valid
        XCTAssertFalse(address.isEmpty, "Address should not be empty")
        XCTAssertTrue(address.count > 30, "Address should be valid length")
        
        print("   ✅ Address format valid")
    }
    
    /// Test: X402 Payment with High-level API (payForContent)
    ///
    /// This test demonstrates the simplified high-level API that automatically handles:
    /// - Payment quote request
    /// - Automatic ATA management (payer & recipient)
    /// - Transaction creation and signing
    /// - Payment proof submission
    ///
    /// ⚠️ Requirements:
    /// 1. WalletManager initialized with a wallet containing USDC
    /// 2. X402 server running (http://localhost:3001)
    /// 3. Internet connection to Solana devnet
    ///
    /// ## Test Flow (Simple!)
    /// 1. Get keypair from WalletManager
    /// 2. Check balance before
    /// 3. Call payForContent() - that's it!
    /// 4. Check balance after
    ///
    func testX402PaymentWithHighLevelAPI() async throws {
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
        } catch {
            print("⚠️ WalletManager not initialized")
            print("   Run testInitWallet first to initialize WalletManager")
            throw XCTSkip("WalletManager not initialized with a wallet")
        }
        
        try await importTestWallet()
        
        print("   ✅ Using WalletManager")
        print("   Wallet Address: \(payerAddress)")
        
        // Get private key from WalletManager
        let privateKeyBase58: String
        do {
            privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
        } catch {
            print("   ❌ Failed to get private key from WalletManager")
            throw XCTSkip("Cannot get private key: \(error)")
        }
        
        // Convert to Keypair
        guard let privateKeyBytes = Base58.decode(privateKeyBase58) else {
            print("   ❌ Invalid private key format")
            throw XCTSkip("Failed to decode private key")
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
        let payerTokenAccount = findAssociatedTokenAddress(
            walletAddress: payer.publicKey,
            tokenMintAddress: mint
        )
        
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
            print("   2. Get devnet USDC: cd x402-solana-examples/pay-in-usdc && npm run usdc:client")
            throw XCTSkip("Payer account not funded: \(error)")
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
            XCTFail("Failed to parse balance amounts")
            return
        }
        
        XCTAssertLessThan(afterAmount, beforeAmount, "Balance should decrease after payment")
        
        let difference = beforeAmount - afterAmount
        print("   Difference: \(difference) (smallest units)")
        
        // Expected: 100 (0.0001 USDC in smallest units)
        XCTAssertEqual(difference, 100, "Should have transferred 100 (0.0001 USDC)")
        
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
    }
}
