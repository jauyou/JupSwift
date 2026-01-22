//
//  TransferIntegrationTests.swift
//  JupSwift
//
//  Integration Test: Real transfer with balance verification
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

final class TransferIntegrationTests: IntegrationTestBase {
    
    // Use inherited addresses from IntegrationTestBase
    var senderWallet: PublicKey { clientWallet }
    var receiverWallet: PublicKey { serverWallet }
    var senderTokenAccount: PublicKey { clientTokenAccount }
    var receiverTokenAccount: PublicKey { serverTokenAccount }
    
    /// Test: Real transfer of 0.0001 USDC and verify balance changes
    ///
    /// ⚠️ Note: This is an integration test that requires:
    /// 1. Real private key (loaded from client.json)
    /// 2. Devnet network connection
    /// 3. Sender account with sufficient USDC balance
    ///
    /// How to run:
    /// ```bash
    /// swift test --filter testTransferWithBalanceVerification
    /// ```
    func testTransferWithBalanceVerification() async throws {
        // Skip test if no private key provided
        guard let privateKeyPath = ProcessInfo.processInfo.environment["CLIENT_PRIVATE_KEY_PATH"] else {
            print("⚠️  Skipping integration test: CLIENT_PRIVATE_KEY_PATH environment variable not set")
            print("   Example: CLIENT_PRIVATE_KEY_PATH=/path/to/client.json swift test")
            throw XCTSkip("Real private key required to run integration test")
        }
        
        print("\n" + String(repeating: "=", count: 70))
        print("Start integration test: Real transfer with balance verification")
        print(String(repeating: "=", count: 70))
        
        // Step 1: Load private key
        print("\n📝 Step 1: Load private key")
        let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: privateKeyPath))
        let privateKeyArray = try JSONDecoder().decode([UInt8].self, from: privateKeyData)
        let senderKeypair = Keypair(privateKey: privateKeyArray)
        
        XCTAssertEqual(
            senderKeypair.publicKey.base58(),
            senderWallet.base58(),
            "Private key should correspond to correct public key"
        )
        print("   ✅ Private key loaded successfully")
        print("   Sender: \(senderKeypair.publicKey.base58())")
        
        // Step 2: Connect to Devnet
        print("\n📡 Step 2: Connect to Solana Devnet")
        let connection = SolanaConnection(cluster: .devnet)
        print("   ✅ Connected to: \(await connection.endpoint)")
        
        // Step 3: Get balance before transfer
        print("\n💰 Step 3: Get balance before transfer")
        print("   Sender Token Account: \(senderTokenAccount.base58())")
        print("   Receiver Token Account: \(receiverTokenAccount.base58())")
        
        let senderBalanceBefore = try await connection.getTokenAccountBalance(tokenAccount: senderTokenAccount)
        let receiverBalanceBefore = try await connection.getTokenAccountBalance(tokenAccount: receiverTokenAccount)
        
        print("\n   📊 Balance before transfer:")
        print("   Sender: \(senderBalanceBefore.uiAmountString) USDC")
        print("   Receiver: \(receiverBalanceBefore.uiAmountString) USDC")
        
        // Verify sender has sufficient balance
        let transferAmount: UInt64 = 100  // 0.0001 USDC
        guard let senderAmountBefore = UInt64(senderBalanceBefore.amount) else {
            XCTFail("Cannot parse sender balance")
            return
        }
        XCTAssertGreaterThanOrEqual(
            senderAmountBefore,
            transferAmount,
            "Sender has insufficient balance"
        )
        
        // Step 4: Execute transfer
        print("\n💸 Step 4: Execute transfer 0.0001 USDC")
        let transferInstruction = createTransferInstruction(
            source: senderTokenAccount,
            destination: receiverTokenAccount,
            authority: senderWallet,
            amount: transferAmount
        )
        
        print("   Sending transaction...")
        let signature = try await connection.sendTransaction(
            instructions: [transferInstruction],
            signers: [senderKeypair]
        )
        
        print("   ✅ Transaction sent")
        print("   Signature: \(signature)")
        print("   Explorer: \(await connection.getExplorerUrl(signature: signature))")
        
        // Step 5: Wait for transaction confirmation
        print("\n⏳ Step 5: Wait for transaction confirmation...")
        let confirmed = try await connection.confirmTransaction(signature: signature, timeout: 60)
        XCTAssertTrue(confirmed, "Transaction should be confirmed")
        print("   ✅ Transaction confirmed")
        
        // Step 6: Get balance after transfer
        print("\n💰 Step 6: Get balance after transfer")
        
        // Wait briefly to ensure balance update
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        
        let senderBalanceAfter = try await connection.getTokenAccountBalance(tokenAccount: senderTokenAccount)
        let receiverBalanceAfter = try await connection.getTokenAccountBalance(tokenAccount: receiverTokenAccount)
        
        print("\n   📊 Balance after transfer:")
        print("   Sender: \(senderBalanceAfter.uiAmountString) USDC")
        print("   Receiver: \(receiverBalanceAfter.uiAmountString) USDC")
        
        // Step 7: Verify balance changes
        print("\n✅ Step 7: Verify balance changes")
        
        guard let senderAmountAfter = UInt64(senderBalanceAfter.amount),
              let receiverAmountBefore = UInt64(receiverBalanceBefore.amount),
              let receiverAmountAfter = UInt64(receiverBalanceAfter.amount) else {
            XCTFail("Cannot parse balance")
            return
        }
        
        // Sender should decrease (transfer amount + possible rent fees, but Token transfers usually don't require additional fees)
        let senderDecrease = senderAmountBefore - senderAmountAfter
        print("   Sender decrease: \(senderDecrease) (expected: \(transferAmount))")
        XCTAssertEqual(
            senderDecrease,
            transferAmount,
            "Sender should decrease by transfer amount"
        )
        
        // Receiver should increase
        let receiverIncrease = receiverAmountAfter - receiverAmountBefore
        print("   Receiver increase: \(receiverIncrease) (expected: \(transferAmount))")
        XCTAssertEqual(
            receiverIncrease,
            transferAmount,
            "Receiver should increase by transfer amount"
        )
        
        // Calculate human-readable amount (USDC 6 decimals)
        let transferAmountUI = Double(transferAmount) / 1_000_000
        print("\n   📈 Balance change summary:")
        print("   ├─ Sender decrease: \(transferAmountUI) USDC ✅")
        print("   └─ Receiver increase: \(transferAmountUI) USDC ✅")
        
        print("\n" + String(repeating: "=", count: 70))
        print("✅ Integration test passed! Transfer successful and balance changes correct")
        print(String(repeating: "=", count: 70))
    }
    
    /// Test: Get balance functionality
    func testGetTokenAccountBalance() async throws {
        let connection = SolanaConnection(cluster: .devnet)
        
        print("\n📊 Get Token Account Balance")
        print("   Sender Token Account: \(senderTokenAccount.base58())")
        print("   Receiver Token Account: \(receiverTokenAccount.base58())")
        
        // Get sender balance
        let senderBalance = try await connection.getTokenAccountBalance(tokenAccount: senderTokenAccount)
        print("\n   Sender balance:")
        print("   ├─ Smallest units: \(senderBalance.amount)")
        print("   ├─ Human readable: \(senderBalance.uiAmountString) USDC")
        print("   └─ Decimals: \(senderBalance.decimals)")
        
        XCTAssertEqual(senderBalance.decimals, 6, "USDC should have 6 decimals")
        XCTAssertFalse(senderBalance.amount.isEmpty, "Balance should not be empty")
        
        // Get receiver balance
        let receiverBalance = try await connection.getTokenAccountBalance(tokenAccount: receiverTokenAccount)
        print("\n   Receiver balance:")
        print("   ├─ Smallest units: \(receiverBalance.amount)")
        print("   ├─ Human readable: \(receiverBalance.uiAmountString) USDC")
        print("   └─ Decimals: \(receiverBalance.decimals)")
        
        XCTAssertEqual(receiverBalance.decimals, 6, "USDC should have 6 decimals")
        XCTAssertFalse(receiverBalance.amount.isEmpty, "Balance should not be empty")
    }
    
    /// Test: Verify Token Account derivation
    func testTokenAccountDerivation() {
        print("\n🔑 Verify Token Account derivation")
        
        // Expected Token Account addresses (obtained from real transaction)
        let expectedSenderTokenAccount = "5tupNS1d66vYzUKFyP3DQ5oG6S9t11ob7fhuh7oc22XH"
        let expectedReceiverTokenAccount = "ANVQMUvfjwJuwC8ML2bcqeqcwSZRFKPcera9T25KxU4Y"
        
        // Verify derived addresses are correct
        XCTAssertEqual(
            senderTokenAccount.base58(),
            expectedSenderTokenAccount,
            "Sender Token Account should be correctly derived"
        )
        
        XCTAssertEqual(
            receiverTokenAccount.base58(),
            expectedReceiverTokenAccount,
            "Receiver Token Account should be correctly derived"
        )
        
        print("   ✅ Sender Token Account: \(senderTokenAccount.base58())")
        print("   ✅ Receiver Token Account: \(receiverTokenAccount.base58())")
    }
}
