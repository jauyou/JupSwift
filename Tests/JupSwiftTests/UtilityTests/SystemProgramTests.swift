//
//  SystemProgramTests.swift
//  JupSwift
//
//  Tests for SystemProgram SOL transfers
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

final class SystemProgramTests: XCTestCase {
    
    func testSystemProgramID() {
        let expectedID = "11111111111111111111111111111111"
        XCTAssertEqual(SYSTEM_PROGRAM_ID.base58(), expectedID)
    }
    
    func testTransferInstruction() {
        let fromPubkey = PublicKey(base58: "11111111111111111111111111111111")
        let toPubkey = PublicKey(base58: "11111111111111111111111111111112")
        let lamports: UInt64 = 100_000 // 0.0001 SOL
        
        let instruction = SystemProgram.transfer(
            fromPubkey: fromPubkey,
            toPubkey: toPubkey,
            lamports: lamports
        )
        
        // Verify program ID
        XCTAssertEqual(instruction.programId.base58(), SYSTEM_PROGRAM_ID.base58())
        
        // Verify accounts
        XCTAssertEqual(instruction.keys.count, 2)
        
        // First account (from) should be signer and writable
        XCTAssertEqual(instruction.keys[0].pubkey.base58(), fromPubkey.base58())
        XCTAssertTrue(instruction.keys[0].isSigner)
        XCTAssertTrue(instruction.keys[0].isWritable)
        
        // Second account (to) should not be signer but writable
        XCTAssertEqual(instruction.keys[1].pubkey.base58(), toPubkey.base58())
        XCTAssertFalse(instruction.keys[1].isSigner)
        XCTAssertTrue(instruction.keys[1].isWritable)
        
        // Verify instruction data
        XCTAssertEqual(instruction.data.count, 12) // 4 bytes (u32) + 8 bytes (u64)
        
        // First 4 bytes should be instruction type (2 for Transfer)
        let instructionType = instruction.data.withUnsafeBytes { bytes in
            bytes.loadUnaligned(as: UInt32.self)
        }
        XCTAssertEqual(instructionType, 2)
        
        // Next 8 bytes should be lamports amount (decode manually to avoid alignment issues)
        var amount: UInt64 = 0
        for i in 0..<8 {
            amount |= UInt64(instruction.data[4 + i]) << (i * 8)
        }
        XCTAssertEqual(amount, lamports)
    }
    
    func testTransferInstructionDataEncoding() {
        let fromPubkey = PublicKey(base58: "11111111111111111111111111111111")
        let toPubkey = PublicKey(base58: "11111111111111111111111111111112")
        
        // Test different amounts
        let testAmounts: [UInt64] = [
            100_000,      // 0.0001 SOL
            1_000_000,    // 0.001 SOL
            10_000_000,   // 0.01 SOL
            100_000_000,  // 0.1 SOL
            1_000_000_000 // 1 SOL
        ]
        
        for lamports in testAmounts {
            let instruction = SystemProgram.transfer(
                fromPubkey: fromPubkey,
                toPubkey: toPubkey,
                lamports: lamports
            )
            
            // Verify amount encoding (decode manually to avoid alignment issues)
            var encodedAmount: UInt64 = 0
            for i in 0..<8 {
                encodedAmount |= UInt64(instruction.data[4 + i]) << (i * 8)
            }
            XCTAssertEqual(encodedAmount, lamports, "Amount \(lamports) should be correctly encoded")
        }
    }
    
    func testSolToLamportsConversion() {
        XCTAssertEqual(SolConversion.solToLamports(1.0), 1_000_000_000)
        XCTAssertEqual(SolConversion.solToLamports(0.1), 100_000_000)
        XCTAssertEqual(SolConversion.solToLamports(0.01), 10_000_000)
        XCTAssertEqual(SolConversion.solToLamports(0.001), 1_000_000)
        XCTAssertEqual(SolConversion.solToLamports(0.0001), 100_000)
    }
    
    func testLamportsToSolConversion() {
        XCTAssertEqual(SolConversion.lamportsToSol(1_000_000_000), 1.0)
        XCTAssertEqual(SolConversion.lamportsToSol(100_000_000), 0.1)
        XCTAssertEqual(SolConversion.lamportsToSol(10_000_000), 0.01)
        XCTAssertEqual(SolConversion.lamportsToSol(1_000_000), 0.001)
        XCTAssertEqual(SolConversion.lamportsToSol(100_000), 0.0001)
    }
    
    func testRoundTripConversion() {
        let testValues: [Double] = [1.0, 0.5, 0.1, 0.01, 0.001, 0.0001]
        
        for sol in testValues {
            let lamports = SolConversion.solToLamports(sol)
            let convertedBack = SolConversion.lamportsToSol(lamports)
            XCTAssertEqual(convertedBack, sol, accuracy: 0.000000001, "Round trip conversion should be accurate")
        }
    }
    
    func testTransferInstructionFormat() {
        // This test verifies the instruction format matches Solana's SystemProgram
        let fromPubkey = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
        let toPubkey = PublicKey(base58: "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX")
        let lamports: UInt64 = 100_000 // 0.0001 SOL
        
        let instruction = SystemProgram.transfer(
            fromPubkey: fromPubkey,
            toPubkey: toPubkey,
            lamports: lamports
        )
        
        // Convert data to hex for inspection
        let hexData = instruction.data.map { String(format: "%02x", $0) }.joined()
        
        // Expected format: 02000000 (u32 instruction type = 2) + a086010000000000 (u64 amount = 100000)
        XCTAssertEqual(hexData.prefix(8), "02000000", "First 4 bytes should be instruction type 2")
        
        print("\nSystemProgram.transfer instruction:")
        print("  From: \(fromPubkey.base58())")
        print("  To: \(toPubkey.base58())")
        print("  Amount: \(lamports) lamports (\(SolConversion.lamportsToSol(lamports)) SOL)")
        print("  Instruction data (hex): \(hexData)")
    }
}
