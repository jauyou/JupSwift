//
//  TransferTokenTests.swift
//  JupSwift
//
//  Tests for SPL Token Transfer functionality
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

final class TransferTokenTests: XCTestCase {
    
    // MARK: - Test Create Transfer Instruction
    
    func testCreateTransferInstruction() {
        // Test data from the analyzed transaction
        let sourceTokenAccount = PublicKey(base58: "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
        let destinationTokenAccount = PublicKey(base58: "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
        let authority = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
        let amount: UInt64 = 100
        
        // Create instruction
        let instruction = createTransferInstruction(
            source: sourceTokenAccount,
            destination: destinationTokenAccount,
            authority: authority,
            amount: amount
        )
        
        // Verify program ID
        XCTAssertEqual(
            instruction.programId.base58(),
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            "Program ID should be SPL Token Program"
        )
        
        // Verify accounts
        XCTAssertEqual(instruction.keys.count, 3, "Should have 3 accounts")
        
        // Account 0: Source (writable, not signer)
        XCTAssertEqual(instruction.keys[0].pubkey.base58(), sourceTokenAccount.base58())
        XCTAssertTrue(instruction.keys[0].isWritable)
        XCTAssertFalse(instruction.keys[0].isSigner)
        
        // Account 1: Destination (writable, not signer)
        XCTAssertEqual(instruction.keys[1].pubkey.base58(), destinationTokenAccount.base58())
        XCTAssertTrue(instruction.keys[1].isWritable)
        XCTAssertFalse(instruction.keys[1].isSigner)
        
        // Account 2: Authority (not writable, signer)
        XCTAssertEqual(instruction.keys[2].pubkey.base58(), authority.base58())
        XCTAssertFalse(instruction.keys[2].isWritable)
        XCTAssertTrue(instruction.keys[2].isSigner)
        
        // Verify instruction data
        XCTAssertEqual(instruction.data.count, 9, "Instruction data should be 9 bytes")
        XCTAssertEqual(instruction.data[0], 3, "First byte should be 3 (Transfer type)")
        
        // Verify amount encoding (little-endian u64)
        let encodedBytes = Array(instruction.data[1...8])
        let decodedAmount = encodedBytes.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }
        XCTAssertEqual(decodedAmount, amount, "Amount should be correctly encoded")
        
        // Verify instruction data matches expected hex
        let dataHex = instruction.data.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(dataHex, "036400000000000000", "Instruction data should match expected format")
    }
    
    // MARK: - Test Different Amounts
    
    func testTransferInstructionWithDifferentAmounts() {
        let source = PublicKey(base58: "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
        let destination = PublicKey(base58: "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
        let authority = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
        
        // Test cases: (amount, expected hex)
        // Format: 1 byte instruction type + 8 bytes amount (little-endian) = 9 bytes = 18 hex chars
        let testCases: [(UInt64, String)] = [
            (100, "036400000000000000"),           // 0.0001 USDC
            (1_000_000, "0340420f0000000000"),     // 1 USDC
            (10_000, "031027000000000000"),        // 0.01 USDC
            (500_000, "0320a1070000000000"),       // 0.5 USDC
            (1, "030100000000000000"),             // 0.000001 USDC (smallest unit)
        ]
        
        for (amount, expectedHex) in testCases {
            let instruction = createTransferInstruction(
                source: source,
                destination: destination,
                authority: authority,
                amount: amount
            )
            
            let dataHex = instruction.data.map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(
                dataHex,
                expectedHex,
                "Amount \(amount) should encode to \(expectedHex)"
            )
        }
    }
    
    // MARK: - Test Instruction Structure
    
    func testTransferInstructionStructure() {
        let source = PublicKey(base58: "11111111111111111111111111111111")
        let destination = PublicKey(base58: "11111111111111111111111111111112")
        let authority = PublicKey(base58: "11111111111111111111111111111113")
        let amount: UInt64 = 1000
        
        let instruction = createTransferInstruction(
            source: source,
            destination: destination,
            authority: authority,
            amount: amount
        )
        
        // Verify instruction type byte
        XCTAssertEqual(instruction.data[0], 3, "Instruction type should be 3 (Transfer)")
        
        // Verify data length (1 byte type + 8 bytes amount)
        XCTAssertEqual(instruction.data.count, 9, "Instruction data should be 9 bytes total")
        
        // Verify account ordering
        XCTAssertEqual(instruction.keys[0].pubkey.base58(), source.base58(), "First account should be source")
        XCTAssertEqual(instruction.keys[1].pubkey.base58(), destination.base58(), "Second account should be destination")
        XCTAssertEqual(instruction.keys[2].pubkey.base58(), authority.base58(), "Third account should be authority")
    }
    
    // MARK: - Test Amount Encoding
    
    func testAmountEncodingLittleEndian() {
        let source = PublicKey(base58: "11111111111111111111111111111111")
        let destination = PublicKey(base58: "11111111111111111111111111111112")
        let authority = PublicKey(base58: "11111111111111111111111111111113")
        
        // Test edge cases
        let testAmounts: [UInt64] = [
            0,                          // Zero
            1,                          // Minimum
            255,                        // Max UInt8
            65535,                      // Max UInt16
            4294967295,                 // Max UInt32
            UInt64.max                  // Maximum UInt64
        ]
        
        for amount in testAmounts {
            let instruction = createTransferInstruction(
                source: source,
                destination: destination,
                authority: authority,
                amount: amount
            )
            
            // Extract and decode amount from instruction data
            // Use Array to ensure proper alignment
            let encodedBytes = Array(instruction.data[1...8])
            let decodedAmount = encodedBytes.withUnsafeBytes { 
                $0.loadUnaligned(as: UInt64.self)
            }
            
            XCTAssertEqual(
                decodedAmount,
                amount,
                "Amount \(amount) should encode and decode correctly"
            )
        }
    }
    
    // MARK: - Test Token Mint Addresses
    
    func testCommonTokenMints() {
        // Test Mainnet USDC
        XCTAssertEqual(
            CommonTokenMints.Mainnet.USDC.base58(),
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            "Mainnet USDC mint should be correct"
        )
        
        // Test Devnet USDC
        XCTAssertEqual(
            CommonTokenMints.Devnet.USDC.base58(),
            "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
            "Devnet USDC mint should be correct"
        )
        
        // Test Wrapped SOL
        XCTAssertEqual(
            CommonTokenMints.Mainnet.WSOL.base58(),
            "So11111111111111111111111111111111111111112",
            "Wrapped SOL mint should be correct"
        )
    }
    
    // MARK: - Test Program IDs
    
    func testProgramIds() {
        // Test Token Program ID
        XCTAssertEqual(
            TOKEN_PROGRAM_ID.base58(),
            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
            "Token Program ID should be correct"
        )
        
        // Test Associated Token Program ID
        XCTAssertEqual(
            ASSOCIATED_TOKEN_PROGRAM_ID.base58(),
            "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
            "Associated Token Program ID should be correct"
        )
        
        // Test System Program ID
        XCTAssertEqual(
            SYSTEM_PROGRAM_ID.base58(),
            "11111111111111111111111111111111",
            "System Program ID should be correct"
        )
    }
    
    // MARK: - Test Transfer Error Cases
    
    func testTransferErrorDescriptions() {
        let errors: [TransferError] = [
            .sourceAccountNotFound,
            .destinationAccountNotFound,
            .insufficientBalance,
            .invalidAmount
        ]
        
        for error in errors {
            // Verify all errors have descriptions
            XCTAssertFalse(
                error.localizedDescription.isEmpty,
                "Error \(error) should have a description"
            )
        }
    }
    
    // MARK: - Test Real Transaction Data
    
    func testRealTransactionInstructionMatches() {
        // This is from the actual analyzed transaction
        let sourceTokenAccount = PublicKey(base58: "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
        let destinationTokenAccount = PublicKey(base58: "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
        let authority = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
        let amount: UInt64 = 100  // 0.0001 USDC
        
        let instruction = createTransferInstruction(
            source: sourceTokenAccount,
            destination: destinationTokenAccount,
            authority: authority,
            amount: amount
        )
        
        // Verify it matches the expected instruction data from the real transaction
        let dataHex = instruction.data.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(
            dataHex,
            "036400000000000000",
            "Should match the instruction data from the analyzed transaction"
        )
        
        // Verify accounts match
        XCTAssertEqual(instruction.keys.count, 3)
        XCTAssertEqual(instruction.keys[0].pubkey.base58(), "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
        XCTAssertEqual(instruction.keys[1].pubkey.base58(), "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
        XCTAssertEqual(instruction.keys[2].pubkey.base58(), "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
    }
    
    // MARK: - Test USDC Amount Conversions
    
    func testUSDCAmountConversions() {
        // USDC has 6 decimals
        let decimals = 6
        
        let testCases: [(human: Double, smallest: UInt64)] = [
            (0.0001, 100),           // The amount from the analyzed transaction
            (0.01, 10_000),          // x402 payment example
            (0.5, 500_000),          // Half dollar
            (1.0, 1_000_000),        // One dollar
            (100.0, 100_000_000),    // One hundred dollars
        ]
        
        for (humanAmount, smallestUnits) in testCases {
            // Convert human-readable to smallest units
            let calculated = UInt64(humanAmount * pow(10, Double(decimals)))
            XCTAssertEqual(
                calculated,
                smallestUnits,
                "\(humanAmount) USDC should equal \(smallestUnits) smallest units"
            )
            
            // Convert back to human-readable
            let humanCalculated = Double(smallestUnits) / pow(10, Double(decimals))
            XCTAssertEqual(
                humanCalculated,
                humanAmount,
                accuracy: 0.000001,
                "\(smallestUnits) smallest units should equal \(humanAmount) USDC"
            )
        }
    }
}
