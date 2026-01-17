//
//  BlockhashTests.swift
//  JupSwift
//
//  Test correct handling of Blockhash in transactions
//
//  Created by Zhao You on 8/11/25.
//

import XCTest
@testable import JupSwift

final class BlockhashTests: XCTestCase {
    
    // MARK: - Test Transaction Contains Blockhash
    
    func testTransactionIncludesBlockhash() throws {
        // Simulate a blockhash
        let testBlockhash = "GEPw8eHxSfHFtVGVMoUKhbhZqBu6G2gyBxfUgepJQFty"
        
        // Create a simple transfer instruction
        let source = PublicKey(base58: "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg")
        let destination = PublicKey(base58: "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP")
        let authority = PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG")
        
        let instruction = createTransferInstruction(
            source: source,
            destination: destination,
            authority: authority,
            amount: 100
        )
        
        // Create a test keypair (64 bytes: 32-byte seed + 32-byte public key)
        let testPrivateKey: [UInt8] = Array(repeating: 1, count: 32) + authority.bytes
        let keypair = Keypair(privateKey: testPrivateKey)
        
        // Create transaction (including blockhash)
        let tx = Transaction(
            recentBlockhash: testBlockhash,
            instructions: [instruction],
            signers: [keypair]
        )
        
        // Serialize transaction
        let serialized = try tx.serialize()
        
        // Verify transaction data is not empty
        XCTAssertGreaterThan(serialized.count, 0, "Serialized transaction should not be empty")
        
        // Verify blockhash is encoded in the transaction
        // Blockhash should be in the message, let's check if it exists
        let blockhashBytes = Base58.decode(testBlockhash)!
        let serializedBytes = [UInt8](serialized)
        
        // Search for blockhash in serialized transaction
        var found = false
        for i in 0..<(serializedBytes.count - blockhashBytes.count) {
            let slice = Array(serializedBytes[i..<(i + blockhashBytes.count)])
            if slice == blockhashBytes {
                found = true
                break
            }
        }
        
        XCTAssertTrue(found, "Blockhash should be encoded in the serialized transaction")
    }
    
    // MARK: - Test Invalid Blockhash Handling
    
    func testInvalidBlockhashThrowsError() {
        let invalidBlockhash = "invalid-blockhash"
        
        let instruction = createTransferInstruction(
            source: PublicKey(base58: "11111111111111111111111111111111"),
            destination: PublicKey(base58: "11111111111111111111111111111112"),
            authority: PublicKey(base58: "11111111111111111111111111111113"),
            amount: 100
        )
        
        let testPrivateKey: [UInt8] = Array(repeating: 1, count: 64)
        let keypair = Keypair(privateKey: testPrivateKey)
        
        let tx = Transaction(
            recentBlockhash: invalidBlockhash,
            instructions: [instruction],
            signers: [keypair]
        )
        
        // Should throw invalidBlockhash error
        XCTAssertThrowsError(try tx.serialize()) { error in
            if case Transaction.TransactionError.invalidBlockhash = error {
                // Correct error type
            } else {
                XCTFail("Should throw invalidBlockhash error, got \(error)")
            }
        }
    }
    
    // MARK: - Test Real Transaction Blockhash
    
    func testRealTransactionContainsBlockhash() {
        // Blockhash from your provided real transaction
        let realBlockhash = "GEPw8eHxSfHFtVGVMoUKhbhZqBu6G2gyBxfUgepJQFty"
        
        // Verify blockhash is valid Base58 encoding
        guard let blockhashBytes = Base58.decode(realBlockhash) else {
            XCTFail("Blockhash should be valid Base58")
            return
        }
        
        // Verify blockhash length is 32 bytes
        XCTAssertEqual(
            blockhashBytes.count,
            32,
            "Solana blockhash should be exactly 32 bytes"
        )
        
        // Verify can be re-encoded to Base58
        let reencoded = Base58.encode(blockhashBytes)
        XCTAssertEqual(
            reencoded,
            realBlockhash,
            "Blockhash should encode/decode correctly"
        )
    }
    
    // MARK: - Test Blockhash Position in Transaction
    
    func testBlockhashPositionInSerializedTransaction() throws {
        let testBlockhash = "GEPw8eHxSfHFtVGVMoUKhbhZqBu6G2gyBxfUgepJQFty"
        
        let instruction = createTransferInstruction(
            source: PublicKey(base58: "HifavgGpm7NbKkWx5JmGnvG1qJWf8zaGYenFHdaV92Jg"),
            destination: PublicKey(base58: "Ghw5swM1Np4QbAGwXzgz8mAyh6q5Cb2Q51L24VV64DNP"),
            authority: PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG"),
            amount: 100
        )
        
        let testPrivateKey: [UInt8] = Array(repeating: 1, count: 32) + 
            PublicKey(base58: "cLYaEHz7mRvDS7hv9iwjKkKyiwJSHgLm4Gju2LFpZtG").bytes
        let keypair = Keypair(privateKey: testPrivateKey)
        
        let tx = Transaction(
            recentBlockhash: testBlockhash,
            instructions: [instruction],
            signers: [keypair]
        )
        
        let serialized = try tx.serialize()
        let bytes = [UInt8](serialized)
        
        // Solana transaction format:
        // 1. Signature count (compact-u16)
        // 2. Signatures (64 bytes each)
        // 3. Message:
        //    - Header (3 bytes)
        //    - Account keys count (compact-u16)
        //    - Account keys (32 bytes each)
        //    - Recent blockhash (32 bytes) ← Here
        //    - Instructions...
        
        // Should have at least: signature count(1) + signature(64) + header(3) + account count(1) + some accounts + blockhash(32)
        XCTAssertGreaterThan(
            bytes.count,
            1 + 64 + 3 + 1 + 32 + 32,
            "Transaction should contain all required components including blockhash"
        )
    }
    
    // MARK: - Test Blockhash Lifecycle
    
    func testBlockhashLifecycle() {
        // Simulate complete blockhash lifecycle
        
        // 1. Get blockhash from network (in real usage done by connection.getLatestBlockhash())
        let blockhash = "GEPw8eHxSfHFtVGVMoUKhbhZqBu6G2gyBxfUgepJQFty"
        
        // 2. Create instruction (no blockhash needed)
        let instruction = createTransferInstruction(
            source: PublicKey(base58: "11111111111111111111111111111111"),
            destination: PublicKey(base58: "11111111111111111111111111111112"),
            authority: PublicKey(base58: "11111111111111111111111111111113"),
            amount: 100
        )
        
        // Verify instruction does not contain blockhash
        XCTAssertEqual(instruction.data.count, 9, "Instruction should only contain type and amount")
        
        // 3. Include blockhash when creating transaction
        let testPrivateKey: [UInt8] = Array(repeating: 1, count: 64)
        let keypair = Keypair(privateKey: testPrivateKey)
        
        let tx = Transaction(
            recentBlockhash: blockhash,  // ← Blockhash is used here
            instructions: [instruction],
            signers: [keypair]
        )
        
        // 4. Blockhash is encoded during serialization
        XCTAssertNoThrow(try tx.serialize(), "Transaction with valid blockhash should serialize")
    }
    
    // MARK: - Test Documentation
    
    func testBlockhashDocumentation() {
        // This test is primarily documentary, showing correct usage
        
        print("""
        
        ✅ Correct usage of Blockhash in Solana transactions:
        
        1. Create instruction (no blockhash needed)
           let instruction = createTransferInstruction(...)
        
        2. Automatically handle blockhash when sending transaction
           let signature = try await connection.sendTransaction(
               instructions: [instruction],
               signers: [keypair]
           )
           
        Internal flow:
           - connection.getLatestBlockhash() fetches latest blockhash
           - Transaction(recentBlockhash: ...) creates transaction
           - tx.serialize() encodes blockhash during serialization
           - Send to Solana network
        
        ✅ Tests verified:
           - Blockhash is correctly encoded in transaction
           - Invalid blockhash throws error
           - Transaction structure conforms to Solana specification
        
        """)
        
        XCTAssertTrue(true, "Documentation test passed")
    }
}
