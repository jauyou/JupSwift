//
//  SystemProgram.swift
//  JupSwift
//
//  SystemProgram instructions for Solana
//
//  Created by Zhao You on 8/11/25.
//

import Foundation

/// System Program instructions
public enum SystemProgram {
    
    /// Create a transfer instruction for native SOL
    ///
    /// - Parameters:
    ///   - fromPubkey: Source account (will be debited)
    ///   - toPubkey: Destination account (will be credited)
    ///   - lamports: Amount to transfer in lamports (1 SOL = 1,000,000,000 lamports)
    /// - Returns: TransactionInstruction for SOL transfer
    public static func transfer(
        fromPubkey: PublicKey,
        toPubkey: PublicKey,
        lamports: UInt64
    ) -> TransactionInstruction {
        // SystemProgram transfer instruction format:
        // [0-3] = instruction type (2 for Transfer) as u32 little-endian
        // [4-11] = lamports (u64 little-endian)
        var data = [UInt8]()
        
        // Instruction type: 2 (Transfer) as u32 little-endian
        let instructionType: UInt32 = 2
        withUnsafeBytes(of: instructionType.littleEndian) { bytes in
            data.append(contentsOf: bytes)
        }
        
        // Lamports as u64 little-endian
        withUnsafeBytes(of: lamports.littleEndian) { bytes in
            data.append(contentsOf: bytes)
        }
        
        return TransactionInstruction(
            programId: SolanaProgramIds.SYSTEM_PROGRAM_ID,
            keys: [
                AccountMeta(pubkey: fromPubkey, isSigner: true, isWritable: true),
                AccountMeta(pubkey: toPubkey, isSigner: false, isWritable: true)
            ],
            data: data
        )
    }
}

/// SOL conversion utilities
public enum SolConversion {
    /// Convert SOL to lamports
    /// - Parameter sol: Amount in SOL
    /// - Returns: Amount in lamports
    public static func solToLamports(_ sol: Double) -> UInt64 {
        return UInt64(sol * 1_000_000_000)
    }
    
    /// Convert lamports to SOL
    /// - Parameter lamports: Amount in lamports
    /// - Returns: Amount in SOL
    public static func lamportsToSol(_ lamports: UInt64) -> Double {
        return Double(lamports) / 1_000_000_000
    }
}
