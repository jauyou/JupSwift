//
//  SolanaSplToken.swift
//  JupSwift
//
//  Created by Zhao You on 2/11/25.
//

import Foundation
import CryptoKit
import Clibsodium

// MARK: - Solana Cluster Configuration

/// Solana network cluster
public enum SolanaCluster: String, Sendable {
    case mainnet = "mainnet-beta"
    case devnet = "devnet"
    case testnet = "testnet"
    case localnet = "localnet"
    
    /// Default RPC endpoint
    public var defaultRpcEndpoint: String {
        switch self {
        case .mainnet:
            return "https://api.mainnet-beta.solana.com"
        case .devnet:
            return "https://api.devnet.solana.com"
        case .testnet:
            return "https://api.testnet.solana.com"
        case .localnet:
            return "http://localhost:8899"
        }
    }
    
    /// Solana Explorer URL
    public var explorerUrl: String {
        switch self {
        case .mainnet:
            return "https://explorer.solana.com"
        case .devnet:
            return "https://explorer.solana.com?cluster=devnet"
        case .testnet:
            return "https://explorer.solana.com?cluster=testnet"
        case .localnet:
            return "https://explorer.solana.com?cluster=custom&customUrl=http://localhost:8899"
        }
    }
}

/// Solana Program IDs
/// These Program IDs are the same across mainnet/devnet/testnet
/// Reference: https://github.com/solana-labs/solana-program-library
public struct SolanaProgramIds {
    /// SPL Token Program
    /// Used for managing SPL Token accounts and operations
    public static let TOKEN_PROGRAM_ID = PublicKey(base58: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
    
    /// Associated Token Account Program
    /// Used for creating and managing Associated Token Accounts (ATA)
    public static let ASSOCIATED_TOKEN_PROGRAM_ID = PublicKey(base58: "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
    
    /// System Program
    /// Solana's core program for creating accounts and transferring SOL
    public static let SYSTEM_PROGRAM_ID = PublicKey(base58: "11111111111111111111111111111111")
    
    /// Token-2022 Program (Token Extensions Program)
    /// New Token program with additional features and extensions
    public static let TOKEN_2022_PROGRAM_ID = PublicKey(base58: "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb")
}

// MARK: - Common Token Mints

/// Common Token Mint addresses
/// Provides commonly used Token Mint addresses for convenience
public struct CommonTokenMints {
    /// Mainnet tokens
    public struct Mainnet {
        /// USDC (USD Coin)
        public static let USDC = PublicKey(base58: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
        
        /// USDT (Tether USD)
        public static let USDT = PublicKey(base58: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB")
        
        /// SOL (Wrapped SOL)
        public static let WSOL = PublicKey(base58: "So11111111111111111111111111111111111111112")
        
        /// BONK
        public static let BONK = PublicKey(base58: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263")
    }
    
    /// Devnet test tokens
    public struct Devnet {
        /// USDC (Devnet)
        public static let USDC = PublicKey(base58: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr")
        
        /// Wrapped SOL (Devnet)
        public static let WSOL = PublicKey(base58: "So11111111111111111111111111111111111111112")
    }
}

// MARK: - Backward Compatibility
// Maintain backward compatibility with existing code

/// SPL Token Program ID (backward compatibility)
public let TOKEN_PROGRAM_ID = SolanaProgramIds.TOKEN_PROGRAM_ID

/// Associated Token Account Program ID (backward compatibility)
public let ASSOCIATED_TOKEN_PROGRAM_ID = SolanaProgramIds.ASSOCIATED_TOKEN_PROGRAM_ID

/// System Program ID (backward compatibility)
public let SYSTEM_PROGRAM_ID = SolanaProgramIds.SYSTEM_PROGRAM_ID

// MARK: - Keypair
public struct Keypair: Sendable {
    public let privateKey: [UInt8]
    public let publicKey: PublicKey
    
    public init(privateKey: [UInt8]) {
        self.privateKey = privateKey
        // If it's 64 bytes, the last 32 bytes are the public key
        if privateKey.count == 64 {
            let pubKeyBytes = Array(privateKey[32..<64])
            self.publicKey = PublicKey(bytes: pubKeyBytes)
        } else {
            // If it's 32 bytes, need to derive public key using libsodium
            fatalError("Must provide 64-byte private key (seed + public key)")
        }
    }
    
    public init(base58PrivateKey: String) {
        guard let privateKeyBytes = Base58.decode(base58PrivateKey) else {
            fatalError("Invalid Base58 private key")
        }
        self.init(privateKey: privateKeyBytes)
    }
}

// MARK: - Transaction Instruction
public struct AccountMeta: Sendable {
    public let pubkey: PublicKey
    public let isSigner: Bool
    public let isWritable: Bool
    
    public init(pubkey: PublicKey, isSigner: Bool, isWritable: Bool) {
        self.pubkey = pubkey
        self.isSigner = isSigner
        self.isWritable = isWritable
    }
}

public struct TransactionInstruction: Sendable {
    public let programId: PublicKey
    public let keys: [AccountMeta]
    public let data: [UInt8]
    
    public init(programId: PublicKey, keys: [AccountMeta], data: [UInt8]) {
        self.programId = programId
        self.keys = keys
        self.data = data
    }
}

// MARK: - PublicKey
public struct PublicKey: Sendable {
    public let bytes: [UInt8]
    public init(base58: String) {
        self.bytes = Base58.decode(base58) ?? []
    }
    
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public func base58() -> String {
        Base58.encode(self.bytes)
    }
    
    /// Find a Program Derived Address (PDA) for the given seeds and Program ID
    public static func findProgramAddress(seeds: [[UInt8]], programId: PublicKey) -> (PublicKey, UInt8) {
        var bump: UInt8 = 255
        while bump >= 0 {
            var allSeeds = seeds
            allSeeds.append([bump])

            if let derived = try? PublicKey.createProgramAddress(seeds: allSeeds, programId: programId) {
                return (derived, bump)
            }
            if bump == 0 { break }
            bump -= 1
        }
        fatalError("Unable to find a valid program address.")
    }

    /// Create a PDA, throws if the result is on the Ed25519 curve
    public static func createProgramAddress(seeds: [[UInt8]], programId: PublicKey) throws -> PublicKey {
        // Hash: seeds + programId + "ProgramDerivedAddress"
        var buffer = Data()
        for s in seeds { buffer.append(contentsOf: s) }
        buffer.append(contentsOf: programId.bytes)
        buffer.append("ProgramDerivedAddress".data(using: .utf8)!)

        // SHA256 hash
        let hash = SHA256.hash(data: buffer)
        let hashBytes = Array(hash)

        // Check if the result is on the Ed25519 curve (not a valid PDA if it is)
        if isOnCurve(publicKeyBytes: hashBytes) {
            throw ProgramAddressError.invalidAddressOnCurve
        }
        return PublicKey(bytes: hashBytes)
    }

    public static func isOnCurve(publicKeyBytes: [UInt8]) -> Bool {
        guard publicKeyBytes.count == 32 else { return false }
        guard sodium_init() >= 0 else { return false }
        
        // Use crypto_sign_ed25519_pk_to_curve25519 to check if on curve
        // Returns 0 if conversion succeeds (key is on Ed25519 curve)
        var curve25519_pk = [UInt8](repeating: 0, count: 32)
        var ed25519_pk = publicKeyBytes
        
        let result = crypto_sign_ed25519_pk_to_curve25519(&curve25519_pk, &ed25519_pk)
        return result == 0
    }

    enum ProgramAddressError: Error {
        case invalidAddressOnCurve
    }
}

// MARK: - Derive Associated Token Address
public func findAssociatedTokenAddress(walletAddress: PublicKey, tokenMintAddress: PublicKey) -> PublicKey {
    // Equivalent to JS: findProgramAddressSync([wallet, TOKEN_PROGRAM_ID, mint], ASSOCIATED_TOKEN_PROGRAM_ID)
    let (ataAddress, _) = PublicKey.findProgramAddress(seeds: [walletAddress.bytes,
                                                               TOKEN_PROGRAM_ID.bytes,
                                                               tokenMintAddress.bytes],
                                                       programId: ASSOCIATED_TOKEN_PROGRAM_ID)
    return ataAddress
}

// MARK: - Get or Create Associated Token Account
public func getOrCreateAssociatedTokenAccount(
    connection: SolanaConnection,
    payer: Keypair,
    mint: PublicKey,
    owner: PublicKey
) async throws -> PublicKey {
    // Step 1: Derive ATA
    let ata = findAssociatedTokenAddress(walletAddress: owner, tokenMintAddress: mint)

    // Step 2: Check if ATA exists
    if try await connection.getAccountInfo(account: ata) != nil {
        print("? Associated token account already exists:", ata)
        return ata
    }

    print("? Creating associated token account:", ata)

    // Step 3: Create instruction
    let instruction = createAssociatedTokenAccountInstruction(
        payer: payer.publicKey,
        owner: owner,
        mint: mint
    )

    // Step 4: Send transaction
    let txSignature = try await connection.sendTransaction(instructions: [instruction], signers: [payer])
    print("? Transaction signature:", txSignature)

    print("? Created ATA successfully:", ata)
    return ata
}

// MARK: - Create ATA Instruction
public func createAssociatedTokenAccountInstruction(
    payer: PublicKey,
    owner: PublicKey,
    mint: PublicKey
) -> TransactionInstruction {
    let ata = findAssociatedTokenAddress(walletAddress: owner, tokenMintAddress: mint)
    return TransactionInstruction(
        programId: ASSOCIATED_TOKEN_PROGRAM_ID,
        keys: [
            AccountMeta(pubkey: payer, isSigner: true, isWritable: true),
            AccountMeta(pubkey: ata, isSigner: false, isWritable: true),
            AccountMeta(pubkey: owner, isSigner: false, isWritable: false),
            AccountMeta(pubkey: mint, isSigner: false, isWritable: false),
            AccountMeta(pubkey: SYSTEM_PROGRAM_ID, isSigner: false, isWritable: false),
            AccountMeta(pubkey: TOKEN_PROGRAM_ID, isSigner: false, isWritable: false)
        ],
        data: [] // createAssociatedTokenAccount instruction has no data
    )
}

// MARK: - SPL Token Transfer

/// Create a Transfer instruction for SPL Token
///
/// This creates an instruction to transfer SPL tokens from one token account to another.
///
/// - Parameters:
///   - source: The source token account (must be owned by the authority)
///   - destination: The destination token account
///   - authority: The owner/authority of the source token account (must be a signer)
///   - amount: The amount to transfer (in smallest units, e.g., for USDC with 6 decimals, 1 USDC = 1_000_000)
///
/// - Returns: A TransactionInstruction that can be added to a transaction
///
/// - Note: The instruction format follows SPL Token Program specification:
///   - Instruction type: 3 (Transfer)
///   - Data: [3, amount (u64 little-endian)]
///   - Accounts: [source, destination, authority]
///
/// Example:
/// ```swift
/// let transferIx = createTransferInstruction(
///     source: senderTokenAccount,
///     destination: receiverTokenAccount,
///     authority: payer.publicKey,
///     amount: 1_000_000  // 1 USDC (6 decimals)
/// )
/// ```
public func createTransferInstruction(
    source: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64
) -> TransactionInstruction {
    // SPL Token Transfer instruction format:
    // [0] = instruction type (3 for Transfer)
    // [1-8] = amount (u64, little-endian)
    var data = [UInt8]()
    data.append(3) // Transfer instruction type
    
    // Encode amount as little-endian u64
    withUnsafeBytes(of: amount.littleEndian) { bytes in
        data.append(contentsOf: bytes)
    }
    
    return TransactionInstruction(
        programId: TOKEN_PROGRAM_ID,
        keys: [
            AccountMeta(pubkey: source, isSigner: false, isWritable: true),
            AccountMeta(pubkey: destination, isSigner: false, isWritable: true),
            AccountMeta(pubkey: authority, isSigner: true, isWritable: false)
        ],
        data: data
    )
}

/// Transfer SPL tokens from one account to another
///
/// This is a high-level convenience method that:
/// 1. Derives the source and destination Associated Token Accounts (ATAs)
/// 2. Creates a transfer instruction
/// 3. Sends the transaction
///
/// - Parameters:
///   - connection: The Solana RPC connection
///   - payer: The keypair that will pay for transaction fees and sign the transfer
///   - mint: The token mint address (e.g., USDC mint)
///   - sender: The sender's wallet address (must match payer)
///   - recipient: The recipient's wallet address
///   - amount: The amount to transfer (in smallest units)
///
/// - Returns: The transaction signature
///
/// - Throws: An error if the transaction fails
///
/// Example:
/// ```swift
/// let signature = try await transferToken(
///     connection: connection,
///     payer: senderKeypair,
///     mint: CommonTokenMints.Devnet.USDC,
///     sender: senderKeypair.publicKey,
///     recipient: recipientPublicKey,
///     amount: 1_000_000  // 1 USDC
/// )
/// print("Transfer successful:", signature)
/// ```
public func transferToken(
    connection: SolanaConnection,
    payer: Keypair,
    mint: PublicKey,
    sender: PublicKey,
    recipient: PublicKey,
    amount: UInt64
) async throws -> String {
    // Step 1: Derive source and destination token accounts
    let sourceTokenAccount = findAssociatedTokenAddress(
        walletAddress: sender,
        tokenMintAddress: mint
    )
    let destinationTokenAccount = findAssociatedTokenAddress(
        walletAddress: recipient,
        tokenMintAddress: mint
    )
    
    print("📤 Transferring \(amount) tokens")
    print("   From: \(sender.base58())")
    print("   To: \(recipient.base58())")
    print("   Source Token Account: \(sourceTokenAccount.base58())")
    print("   Destination Token Account: \(destinationTokenAccount.base58())")
    
    // Step 2: Check if source account exists
    guard try await connection.getAccountInfo(account: sourceTokenAccount) != nil else {
        throw TransferError.sourceAccountNotFound
    }
    
    // Step 3: Check if destination account exists, create if not
    var instructions: [TransactionInstruction] = []
    
    if try await connection.getAccountInfo(account: destinationTokenAccount) == nil {
        print("⚠️  Destination token account doesn't exist, creating it...")
        let createAccountIx = createAssociatedTokenAccountInstruction(
            payer: payer.publicKey,
            owner: recipient,
            mint: mint
        )
        instructions.append(createAccountIx)
    }
    
    // Step 4: Create transfer instruction
    let transferIx = createTransferInstruction(
        source: sourceTokenAccount,
        destination: destinationTokenAccount,
        authority: sender,
        amount: amount
    )
    instructions.append(transferIx)
    
    // Step 5: Send transaction
    let signature = try await connection.sendTransaction(
        instructions: instructions,
        signers: [payer]
    )
    
    print("✅ Transfer successful!")
    print("   Signature: \(signature)")
    
    return signature
}

/// Transfer SPL tokens using explicit token account addresses
///
/// This is a lower-level method when you already know the token account addresses.
///
/// - Parameters:
///   - connection: The Solana RPC connection
///   - payer: The keypair that will pay for transaction fees and sign the transfer
///   - sourceTokenAccount: The source token account address
///   - destinationTokenAccount: The destination token account address
///   - authority: The authority/owner of the source token account
///   - amount: The amount to transfer (in smallest units)
///
/// - Returns: The transaction signature
///
/// Example:
/// ```swift
/// let signature = try await transferTokenWithAccounts(
///     connection: connection,
///     payer: senderKeypair,
///     sourceTokenAccount: sourceATA,
///     destinationTokenAccount: destinationATA,
///     authority: senderKeypair.publicKey,
///     amount: 1_000_000
/// )
/// ```
public func transferTokenWithAccounts(
    connection: SolanaConnection,
    payer: Keypair,
    sourceTokenAccount: PublicKey,
    destinationTokenAccount: PublicKey,
    authority: PublicKey,
    amount: UInt64
) async throws -> String {
    print("📤 Transferring \(amount) tokens")
    print("   Source Token Account: \(sourceTokenAccount.base58())")
    print("   Destination Token Account: \(destinationTokenAccount.base58())")
    print("   Authority: \(authority.base58())")
    
    // Create transfer instruction
    let transferIx = createTransferInstruction(
        source: sourceTokenAccount,
        destination: destinationTokenAccount,
        authority: authority,
        amount: amount
    )
    
    // Send transaction
    let signature = try await connection.sendTransaction(
        instructions: [transferIx],
        signers: [payer]
    )
    
    print("✅ Transfer successful!")
    print("   Signature: \(signature)")
    
    return signature
}

/// Errors that can occur during token transfers
public enum TransferError: Error {
    case sourceAccountNotFound
    case destinationAccountNotFound
    case insufficientBalance
    case invalidAmount
    
    public var localizedDescription: String {
        switch self {
        case .sourceAccountNotFound:
            return "Source token account not found. Make sure the sender has a token account for this mint."
        case .destinationAccountNotFound:
            return "Destination token account not found and could not be created."
        case .insufficientBalance:
            return "Insufficient token balance in source account."
        case .invalidAmount:
            return "Invalid transfer amount. Amount must be greater than 0."
        }
    }
}

// MARK: - Transaction
struct Transaction {
    let recentBlockhash: String
    let instructions: [TransactionInstruction]
    let signers: [Keypair]
    
    func serialize() throws -> Data {
        guard sodium_init() >= 0 else {
            throw TransactionError.sodiumInitFailed
        }
        
        // Collect all account keys
        var accountKeys: [PublicKey] = []
        
        // Add signers first
        for signer in signers {
            if !accountKeys.contains(where: { $0.bytes == signer.publicKey.bytes }) {
                accountKeys.append(signer.publicKey)
            }
        }
        
        // Add accounts from instructions
        for instruction in instructions {
            for key in instruction.keys {
                if !accountKeys.contains(where: { $0.bytes == key.pubkey.bytes }) {
                    accountKeys.append(key.pubkey)
                }
            }
            if !accountKeys.contains(where: { $0.bytes == instruction.programId.bytes }) {
                accountKeys.append(instruction.programId)
            }
        }
        
        // Build message
        var message = Data()
        
        // 1. Message header (3 bytes)
        let numRequiredSignatures = UInt8(signers.count)
        let numReadonlySignedAccounts: UInt8 = 0
        var numReadonlyUnsignedAccounts: UInt8 = 0
        
        // Count readonly unsigned accounts
        for instruction in instructions {
            for key in instruction.keys {
                if !key.isWritable && !key.isSigner {
                    let isInSigners = signers.contains(where: { $0.publicKey.bytes == key.pubkey.bytes })
                    if !isInSigners {
                        numReadonlyUnsignedAccounts += 1
                    }
                }
            }
        }
        
        message.append(numRequiredSignatures)
        message.append(numReadonlySignedAccounts)
        message.append(numReadonlyUnsignedAccounts)
        
        // 2. Account keys count (compact-u16)
        message.append(encodeLength(accountKeys.count))
        
        // 3. Account keys
        for key in accountKeys {
            message.append(contentsOf: key.bytes)
        }
        
        // 4. Recent blockhash (32 bytes)
        guard let blockhashBytes = Base58.decode(recentBlockhash), blockhashBytes.count == 32 else {
            throw TransactionError.invalidBlockhash
        }
        message.append(contentsOf: blockhashBytes)
        
        // 5. Instruction count
        message.append(encodeLength(instructions.count))
        
        // 6. Instructions
        for instruction in instructions {
            // Program ID index
            guard let programIdIndex = accountKeys.firstIndex(where: { $0.bytes == instruction.programId.bytes }) else {
                throw TransactionError.accountNotFound
            }
            message.append(UInt8(programIdIndex))
            
            // Account indices count
            message.append(encodeLength(instruction.keys.count))
            
            // Account indices
            for key in instruction.keys {
                guard let accountIndex = accountKeys.firstIndex(where: { $0.bytes == key.pubkey.bytes }) else {
                    throw TransactionError.accountNotFound
                }
                message.append(UInt8(accountIndex))
            }
            
            // Instruction data
            message.append(encodeLength(instruction.data.count))
            message.append(contentsOf: instruction.data)
        }
        
        // Sign the message
        var signatures = Data()
        let messageBytes = [UInt8](message)
        
        for signer in signers {
            var signature = [UInt8](repeating: 0, count: Int(crypto_sign_BYTES))
            var signatureLen: UInt64 = 0
            
            let result = crypto_sign_ed25519_detached(
                &signature,
                &signatureLen,
                messageBytes,
                UInt64(messageBytes.count),
                signer.privateKey
            )
            
            guard result == 0 else {
                throw TransactionError.signatureFailed
            }
            
            signatures.append(contentsOf: signature)
        }
        
        // Final transaction format: signature count + signatures + message
        var transaction = Data()
        transaction.append(encodeLength(signers.count))
        transaction.append(signatures)
        transaction.append(message)
        
        return transaction
    }
    
    private func encodeLength(_ length: Int) -> Data {
        // Compact-u16 encoding
        if length < 128 {
            return Data([UInt8(length)])
        } else if length < 16384 {
            let byte1 = UInt8((length & 0x7F) | 0x80)
            let byte2 = UInt8((length >> 7) & 0x7F)
            return Data([byte1, byte2])
        } else {
            let byte1 = UInt8((length & 0x7F) | 0x80)
            let byte2 = UInt8(((length >> 7) & 0x7F) | 0x80)
            let byte3 = UInt8((length >> 14) & 0x7F)
            return Data([byte1, byte2, byte3])
        }
    }
    
    enum TransactionError: Error {
        case sodiumInitFailed
        case invalidBlockhash
        case accountNotFound
        case signatureFailed
    }
}
