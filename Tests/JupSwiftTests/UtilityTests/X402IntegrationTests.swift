//
//  X402IntegrationTests.swift
//  JupSwift
//
//  Integration Test: X402 Payment Protocol with real server and balance verification
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

final class X402IntegrationTests: IntegrationTestBase {
    
    // Use inherited addresses from IntegrationTestBase
    var payerWallet: PublicKey { clientWallet }
    var payerTokenAccount: PublicKey { clientTokenAccount }
    
    /// Test: X402 USDC Payment with balance verification
    ///
    /// ⚠️ Note: This is an integration test that requires:
    /// 1. Real private key (loaded from client.json)
    /// 2. X402 server running on http://localhost:3001
    /// 3. Devnet network connection
    /// 4. Payer account with sufficient USDC balance
    ///
    /// How to run:
    /// ```bash
    /// # Terminal 1: Start X402 USDC server
    /// cd x402-solana-examples
    /// npm run usdc:server
    ///
    /// # Terminal 2: Run test
    /// CLIENT_PRIVATE_KEY_PATH=./x402-solana-examples/pay-in-usdc/client.json \
    /// swift test --filter testX402USDCPaymentWithBalanceVerification
    /// ```
    func testX402USDCPaymentWithBalanceVerification() async throws {
        // Find the correct path to the private key
        let privateKeyPath: String
        
        if let envPath = ProcessInfo.processInfo.environment["CLIENT_PRIVATE_KEY_PATH"] {
            // Use environment variable if set
            privateKeyPath = envPath
        } else {
            // Find project root from test file location
            // #filePath gives us: /path/to/JupSwift/Tests/JupSwiftTests/UtilityTests/X402IntegrationTests.swift
            let testFilePath = URL(fileURLWithPath: #filePath)
            
            // Navigate up to project root: ../../../ from test file
            let projectRoot = testFilePath
                .deletingLastPathComponent()  // Remove X402IntegrationTests.swift
                .deletingLastPathComponent()  // Remove UtilityTests
                .deletingLastPathComponent()  // Remove JupSwiftTests
                .deletingLastPathComponent()  // Remove Tests
            
            // Construct the path to client.json
            let keyFileURL = projectRoot
                .appendingPathComponent("x402-solana-examples")
                .appendingPathComponent("pay-in-usdc")
                .appendingPathComponent("client.json")
            
            privateKeyPath = keyFileURL.path
            
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: privateKeyPath) else {
                print("⚠️  Skipping integration test: Private key file not found")
                print("   Test file: \(#filePath)")
                print("   Project root: \(projectRoot.path)")
                print("   Looking for: \(privateKeyPath)")
                print("   Current directory: \(fileManager.currentDirectoryPath)")
                print("")
                print("   Please ensure the file exists or set CLIENT_PRIVATE_KEY_PATH environment variable")
                print("   Example: CLIENT_PRIVATE_KEY_PATH=/path/to/client.json")
                throw XCTSkip("Private key file not found: \(privateKeyPath)")
            }
        }
        
        print("   Using private key: \(privateKeyPath)")
        
        print("\n" + String(repeating: "=", count: 70))
        print("X402 Integration Test: USDC Payment with Balance Verification")
        print(String(repeating: "=", count: 70))
        
        // Setup
        let serverUrl = "http://localhost:3001"
        let endpoint = "/premium"
        
        // Step 0: Load private key
        print("\n📝 Step 0: Load private key")
        let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))
        let privateKeyArray = try JSONDecoder().decode([UInt8].self, from: privateKeyData)
        let payer = Keypair(privateKey: privateKeyArray)
        
        XCTAssertEqual(
            payer.publicKey.base58(),
            payerWallet.base58(),
            "Private key should correspond to correct public key"
        )
        print("   ✅ Private key loaded successfully")
        print("   Payer: \(payer.publicKey.base58())")
        
        // Step 0.5: Initialize connection and X402 client
        print("\n📡 Step 0.5: Initialize connection and X402 client")
        let connection = SolanaConnection(cluster: .devnet)
        let x402Client = X402PaymentClient(
            serverUrl: serverUrl,
            network: "solana-devnet"
        )
        print("   ✅ Connected to: \(await connection.endpoint)")
        print("   ✅ X402 Server: \(serverUrl)")
        
        // Step 1: Request payment quote from server (X402 protocol step 1)
        print("\n📝 Step 1: Request payment quote from server")
        print("   Requesting: \(serverUrl)\(endpoint)")
        
        let quote: X402PaymentQuote
        do {
            quote = try await x402Client.requestPaymentQuote(endpoint: endpoint)
        } catch {
            print("   ❌ Failed to connect to X402 server: \(error)")
            print("   💡 Make sure the server is running:")
            print("      cd x402-solana-examples")
            print("      npm run usdc:server")
            throw XCTSkip("X402 server is not running")
        }
        
        guard let recipientTokenAccountStr = quote.payment.tokenAccount,
              let mintStr = quote.payment.mint,
              let amount = quote.payment.amount else {
            XCTFail("Invalid quote response")
            return
        }
        
        let recipientTokenAccount = PublicKey(base58: recipientTokenAccountStr)
        let mint = PublicKey(base58: mintStr)
        let transferAmount = UInt64(amount)
        
        print("   ✅ Payment quote received")
        print("   Recipient Token Account: \(recipientTokenAccountStr)")
        print("   Mint (USDC): \(mintStr)")
        print("   Amount: \(quote.payment.amountUSDC ?? 0) USDC (\(amount) smallest units)")
        print("   Network: \(quote.payment.cluster)")
        
        // Verify mint is USDC
        XCTAssertEqual(mint.base58(), usdcMint.base58(), "Mint should be USDC")
        
        // Step 2: Get balance before payment
        print("\n💰 Step 2: Get balance before payment")
        print("   Payer Token Account: \(payerTokenAccount.base58())")
        print("   Server Token Account: \(recipientTokenAccount.base58())")
        
        let payerBalanceBefore = try await connection.getTokenAccountBalance(tokenAccount: payerTokenAccount)
        let serverBalanceBefore = try await connection.getTokenAccountBalance(tokenAccount: recipientTokenAccount)
        
        print("\n   📊 Balance before payment:")
        print("   Payer: \(payerBalanceBefore.uiAmountString) USDC")
        print("   Server: \(serverBalanceBefore.uiAmountString) USDC")
        
        // Verify payer has sufficient balance
        guard let payerAmountBefore = UInt64(payerBalanceBefore.amount) else {
            XCTFail("Cannot parse payer balance")
            return
        }
        XCTAssertGreaterThanOrEqual(
            payerAmountBefore,
            transferAmount,
            "Payer has insufficient balance"
        )
        print("   ✅ Payer has sufficient balance")
        
        // Step 3: Create and sign transaction (user's responsibility)
        print("\n🔐 Step 3: Create and sign transaction")
        
        var instructions: [TransactionInstruction] = []
        
        // Check if payer's token account exists
        let payerAccountExists = (try? await connection.getTokenAccountBalance(tokenAccount: payerTokenAccount)) != nil
        if !payerAccountExists {
            print("   Creating payer's token account...")
            let createATAInstruction = createAssociatedTokenAccountInstruction(
                payer: payer.publicKey,
                owner: payer.publicKey,
                mint: mint
            )
            instructions.append(createATAInstruction)
            print("   ✅ Added create account instruction")
        }
        
        // Add transfer instruction
        let transferInstruction = createTransferInstruction(
            source: payerTokenAccount,
            destination: recipientTokenAccount,
            authority: payer.publicKey,
            amount: transferAmount
        )
        instructions.append(transferInstruction)
        print("   ✅ Added transfer instruction")
        
        // Create transaction
        let blockhash = try await connection.getLatestBlockhash()
        let transaction = Transaction(
            recentBlockhash: blockhash,
            instructions: instructions,
            signers: [payer]
        )
        
        // Serialize (this also signs the transaction)
        let serialized = try transaction.serialize()
        let serializedTxBase64 = serialized.base64EncodedString()
        
        print("   ✅ Transaction created and signed")
        print("   Instructions: \(instructions.count)")
        print("   Signature length: \(serializedTxBase64.count) chars")
        
        // Step 4: Send payment proof to server (X402 protocol step 4)
        print("\n📤 Step 4: Send payment proof to server")
        print("   Sending X-Payment header...")
        
        let response = try await x402Client.sendPaymentProof(
            endpoint: endpoint,
            serializedTransaction: serializedTxBase64
        )
        
        // Verify response
        if let error = response.error {
            XCTFail("Payment failed: \(error)")
            return
        }
        
        guard let paymentDetails = response.paymentDetails else {
            XCTFail("No payment details in response")
            return
        }
        
        print("   ✅ Payment proof sent and accepted by server")
        print("   Transaction Signature: \(paymentDetails.signature)")
        print("   Explorer: \(paymentDetails.explorerUrl)")
        
        if let content = response.data {
            print("   📦 Premium content received: \(content)")
        }
        
        // Step 5: Wait for transaction confirmation
        print("\n⏳ Step 5: Wait for transaction confirmation...")
        let confirmed = try await connection.confirmTransaction(
            signature: paymentDetails.signature,
            timeout: 60
        )
        XCTAssertTrue(confirmed, "Transaction should be confirmed")
        print("   ✅ Transaction confirmed on-chain")
        
        // Step 6: Get balance after payment
        print("\n💰 Step 6: Get balance after payment")
        
        // Wait briefly to ensure balance update
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        
        let payerBalanceAfter = try await connection.getTokenAccountBalance(tokenAccount: payerTokenAccount)
        let serverBalanceAfter = try await connection.getTokenAccountBalance(tokenAccount: recipientTokenAccount)
        
        print("\n   📊 Balance after payment:")
        print("   Payer: \(payerBalanceAfter.uiAmountString) USDC")
        print("   Server: \(serverBalanceAfter.uiAmountString) USDC")
        
        // Step 7: Verify balance changes
        print("\n✅ Step 7: Verify balance changes")
        
        guard let payerAmountAfter = UInt64(payerBalanceAfter.amount),
              let serverAmountBefore = UInt64(serverBalanceBefore.amount),
              let serverAmountAfter = UInt64(serverBalanceAfter.amount) else {
            XCTFail("Cannot parse balance")
            return
        }
        
        // Payer should decrease by transfer amount
        let payerDecrease = payerAmountBefore - payerAmountAfter
        print("   Payer decrease: \(payerDecrease) (expected: \(transferAmount))")
        XCTAssertEqual(
            payerDecrease,
            transferAmount,
            "Payer should decrease by transfer amount"
        )
        
        // Server should increase by transfer amount
        let serverIncrease = serverAmountAfter - serverAmountBefore
        print("   Server increase: \(serverIncrease) (expected: \(transferAmount))")
        XCTAssertEqual(
            serverIncrease,
            transferAmount,
            "Server should increase by transfer amount"
        )
        
        // Verify payment details match actual transfer
        XCTAssertEqual(
            UInt64(paymentDetails.amount),
            transferAmount,
            "Payment details amount should match transfer amount"
        )
        
        // Calculate human-readable amount (USDC 6 decimals)
        let transferAmountUI = Double(transferAmount) / 1_000_000
        print("\n   📈 Balance change summary:")
        print("   ├─ Payer decrease: \(transferAmountUI) USDC ✅")
        print("   └─ Server increase: \(transferAmountUI) USDC ✅")
        
        print("\n" + String(repeating: "=", count: 70))
        print("✅ X402 Integration test passed!")
        print("   ✓ Payment quote received from server")
        print("   ✓ Transaction created and signed by client")
        print("   ✓ Payment proof verified by server")
        print("   ✓ Transaction submitted by server")
        print("   ✓ Balance changes verified on-chain")
        print(String(repeating: "=", count: 70))
    }
    
    /// Test: X402 server connectivity
    func testX402ServerConnectivity() async throws {
        let serverUrl = "http://localhost:3001"
        let endpoint = "/premium"
        
        print("\n🔌 Test X402 Server Connectivity")
        print("   Server: \(serverUrl)")
        
        let x402Client = X402PaymentClient(
            serverUrl: serverUrl,
            network: "solana-devnet"
        )
        
        do {
            let quote = try await x402Client.requestPaymentQuote(endpoint: endpoint)
            print("   ✅ Server is responding")
            print("   Quote cluster: \(quote.payment.cluster)")
            
            XCTAssertNotNil(quote.payment.tokenAccount, "Quote should have tokenAccount")
            XCTAssertNotNil(quote.payment.mint, "Quote should have mint")
            XCTAssertNotNil(quote.payment.amount, "Quote should have amount")
            
        } catch {
            print("   ❌ Cannot connect to server: \(error)")
            print("   💡 Start the server with: npm run usdc:server")
            throw XCTSkip("X402 server is not running")
        }
    }
    
    /// Test: Verify payment quote structure
    func testPaymentQuoteStructure() async throws {
        let serverUrl = "http://localhost:3001"
        let endpoint = "/premium"
        
        print("\n📋 Test Payment Quote Structure")
        
        let x402Client = X402PaymentClient(
            serverUrl: serverUrl,
            network: "solana-devnet"
        )
        
        do {
            let quote = try await x402Client.requestPaymentQuote(endpoint: endpoint)
            
            // Verify all required fields exist
            XCTAssertNotNil(quote.payment.tokenAccount, "Should have tokenAccount")
            XCTAssertNotNil(quote.payment.mint, "Should have mint")
            XCTAssertNotNil(quote.payment.amount, "Should have amount")
            XCTAssertNotNil(quote.payment.amountUSDC, "Should have amountUSDC")
            XCTAssertEqual(quote.payment.cluster, "devnet", "Should be devnet")
            
            // Verify mint is USDC
            let mintStr = quote.payment.mint!
            XCTAssertEqual(mintStr, usdcMint.base58(), "Mint should be USDC")
            
            // Verify tokenAccount can be parsed as PublicKey
            let _ = PublicKey(base58: quote.payment.tokenAccount!)
            
            print("   ✅ Quote structure is valid")
            print("   Token Account: \(quote.payment.tokenAccount!)")
            print("   Mint: \(mintStr)")
            print("   Amount: \(quote.payment.amountUSDC!) USDC")
            
        } catch {
            throw XCTSkip("X402 server is not running")
        }
    }
    
    /// Test: Token Account derivation matches server expectation
    func testTokenAccountDerivation() {
        print("\n🔑 Verify Token Account derivation")
        
        // Expected Token Account addresses
        let expectedPayerTokenAccount = "5tupNS1d66vYzUKFyP3DQ5oG6S9t11ob7fhuh7oc22XH"
        let expectedServerTokenAccount = "ANVQMUvfjwJuwC8ML2bcqeqcwSZRFKPcera9T25KxU4Y"
        
        // Verify derived addresses are correct
        XCTAssertEqual(
            payerTokenAccount.base58(),
            expectedPayerTokenAccount,
            "Payer Token Account should be correctly derived"
        )
        
        XCTAssertEqual(
            serverTokenAccount.base58(),
            expectedServerTokenAccount,
            "Server Token Account should be correctly derived"
        )
        
        print("   ✅ Payer Token Account: \(payerTokenAccount.base58())")
        print("   ✅ Server Token Account: \(serverTokenAccount.base58())")
    }
}
