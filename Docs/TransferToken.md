# Token Transfer - Complete Guide

Comprehensive documentation for Solana Token transfers

## 📋 Table of Contents

1. [Transfer Overview](#transfer-overview)
2. [SOL Transfer](#sol-transfer)
3. [SPL Token Transfer](#spl-token-transfer)
4. [Complete Examples](#complete-examples)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Transfer Overview

### Two Transfer Types

There are two main types of transfers on Solana:

```
┌────────────────────────────────────────────────────────┐
│                   SOL Transfer                          │
│  Using: SystemProgram.transfer()                       │
│  Features: Native token, direct wallet-to-wallet       │
├────────────────────────────────────────────────────────┤
│                SPL Token Transfer                       │
│  Using: SolanaSplToken.createTransferInstruction()    │
│  Features: Requires Token Account, supports all tokens │
└────────────────────────────────────────────────────────┘
```

### Basic Flow

```
1. Preparation
   ├─ Determine sender and receiver
   ├─ Check balance
   └─ Get latest blockhash

2. Create Instruction
   ├─ SOL: SystemProgram.transfer()
   └─ SPL Token: createTransferInstruction()

3. Build Transaction
   ├─ Add instruction
   └─ Add signers

4. Send Transaction
   └─ Submit to Solana network

5. Confirmation
   └─ Wait for transaction confirmation
```

---

## SOL Transfer

### Basic Concept

SOL is Solana's native token:

- **Unit**: lamports (1 SOL = 1,000,000,000 lamports)
- **Storage**: Directly in wallet account
- **Transfer**: Using System Program

### Using SystemProgram.transfer()

```swift
import JupSwift

func transferSOL() async throws {
    let connection = SolanaConnection(cluster: .devnet)
    let sender = try loadKeypair()
    let recipient = PublicKey(base58: "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX")
    
    // Transfer 0.1 SOL = 100,000,000 lamports
    let amount: UInt64 = 100_000_000
    
    // 1. Create transfer instruction
    let instruction = try SystemProgram.transfer(
        fromPubkey: sender.publicKey,
        toPubkey: recipient,
        lamports: amount
    )
    
    // 2. Build transaction
    let blockhash = try await connection.getLatestBlockhash()
    let transaction = Transaction(
        recentBlockhash: blockhash,
        instructions: [instruction],
        signers: [sender]
    )
    
    // 3. Send transaction
    let signature = try await connection.sendTransaction(transaction: transaction)
    
    print("✅ Transfer successful!")
    print("Signature: \(signature)")
    print("Explorer: https://explorer.solana.com/tx/\(signature)?cluster=devnet")
}
```

### SystemProgram.transfer() Parameters

```swift
public static func transfer(
    fromPubkey: PublicKey,  // Sender address
    toPubkey: PublicKey,    // Receiver address
    lamports: UInt64        // Amount (lamports)
) throws -> TransactionInstruction
```

### Unit Conversion

```swift
// SOL → lamports
let sol = 0.1
let lamports = UInt64(sol * 1_000_000_000)  // 100,000,000

// lamports → SOL
let lamports: UInt64 = 100_000_000
let sol = Double(lamports) / 1_000_000_000  // 0.1
```

### Complete Example (with Balance Check)

```swift
func transferSOLWithBalanceCheck() async throws {
    let connection = SolanaConnection(cluster: .devnet)
    let sender = try loadKeypair()
    let recipient = PublicKey(base58: "...")
    let amountSOL = 0.1
    let amountLamports = UInt64(amountSOL * 1_000_000_000)
    
    // 1. Check sender balance
    print("💰 Checking balance...")
    let balanceInfo = try await connection.getAccountInfo(account: sender.publicKey)
    let balance = balanceInfo?.lamports ?? 0
    let balanceSOL = Double(balance) / 1_000_000_000
    
    print("Sender balance: \(balanceSOL) SOL")
    
    guard balance >= amountLamports else {
        throw TransferError.insufficientBalance
    }
    
    // 2. Create transfer instruction
    print("\n📝 Creating transfer instruction...")
    let instruction = try SystemProgram.transfer(
        fromPubkey: sender.publicKey,
        toPubkey: recipient,
        lamports: amountLamports
    )
    
    // 3. Build and send transaction
    print("\n🚀 Sending transaction...")
    let blockhash = try await connection.getLatestBlockhash()
    let transaction = Transaction(
        recentBlockhash: blockhash,
        instructions: [instruction],
        signers: [sender]
    )
    
    let signature = try await connection.sendTransaction(transaction: transaction)
    
    print("\n✅ Transfer successful!")
    print("Amount: \(amountSOL) SOL")
    print("From: \(sender.publicKey.base58())")
    print("To: \(recipient.base58())")
    print("Signature: \(signature)")
    print("Explorer: https://explorer.solana.com/tx/\(signature)?cluster=devnet")
}
```

---

## SPL Token Transfer

### Basic Concept

SPL Token is a token based on SPL Token Program:

- **Requires**: Associated Token Account (ATA)
- **Examples**: USDC, BONK, any SPL Token
- **Storage**: In Token Account, not wallet account

### Token Account Requirements

Before transferring SPL Token, must ensure:

1. ✅ Sender has Token Account
2. ✅ Receiver has Token Account
3. ✅ Sender has sufficient balance

### Using createTransferInstruction()

```swift
import JupSwift

func transferUSDC() async throws {
    let connection = SolanaConnection(cluster: .devnet)
    let sender = try loadKeypair()
    let recipient = PublicKey(base58: "...")
    
    // USDC Devnet Mint
    let usdcMint = PublicKey(base58: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr")
    
    // 1. Find Token Accounts
    let senderATA = try SolanaSplToken.findAssociatedTokenAddress(
        mint: usdcMint,
        owner: sender.publicKey
    )
    
    let recipientATA = try SolanaSplToken.findAssociatedTokenAddress(
        mint: usdcMint,
        owner: recipient
    )
    
    // 2. Transfer 1 USDC = 1,000,000 (USDC has 6 decimals)
    let amount: UInt64 = 1_000_000
    
    // 3. Create transfer instruction
    let instruction = try SolanaSplToken.createTransferInstruction(
        source: senderATA,
        destination: recipientATA,
        owner: sender.publicKey,
        amount: amount
    )
    
    // 4. Build and send transaction
    let blockhash = try await connection.getLatestBlockhash()
    let transaction = Transaction(
        recentBlockhash: blockhash,
        instructions: [instruction],
        signers: [sender]
    )
    
    let signature = try await connection.sendTransaction(transaction: transaction)
    
    print("✅ Transfer successful!")
    print("Signature: \(signature)")
}
```

### createTransferInstruction() Parameters

```swift
public static func createTransferInstruction(
    source: PublicKey,      // Sender's Token Account
    destination: PublicKey,  // Receiver's Token Account
    owner: PublicKey,       // Token Account owner (signer)
    amount: UInt64,         // Amount (smallest unit)
    programId: PublicKey = SolanaProgramIds.TOKEN_PROGRAM_ID
) throws -> TransactionInstruction
```

### SPL Token Unit Conversion

Different Tokens have different decimals:

```swift
// USDC (6 decimals)
let usdcDecimals = 6
let uiAmount = 1.5  // 1.5 USDC
let smallestUnit = UInt64(uiAmount * pow(10.0, Double(usdcDecimals)))
// smallestUnit = 1,500,000

// BONK (5 decimals)
let bonkDecimals = 5
let uiAmount = 100.0  // 100 BONK
let smallestUnit = UInt64(uiAmount * pow(10.0, Double(bonkDecimals)))
// smallestUnit = 10,000,000
```

### Complete Example (Auto-create ATA)

```swift
func transferUSDCWithATACreation() async throws {
    let connection = SolanaConnection(cluster: .devnet)
    let sender = try loadKeypair()
    let recipient = PublicKey(base58: "...")
    let usdcMint = CommonTokenMints.Devnet.USDC
    
    var instructions: [TransactionInstruction] = []
    
    // 1. Find Token Accounts
    let senderATA = try SolanaSplToken.findAssociatedTokenAddress(
        mint: usdcMint,
        owner: sender.publicKey
    )
    
    let recipientATA = try SolanaSplToken.findAssociatedTokenAddress(
        mint: usdcMint,
        owner: recipient
    )
    
    // 2. Check sender's Token Account
    print("💰 Checking sender's token account...")
    let senderAccountInfo = try? await connection.getAccountInfo(account: senderATA)
    
    if senderAccountInfo == nil {
        print("📝 Creating sender's token account...")
        let createSenderATA = try SolanaSplToken.createAssociatedTokenAccountInstruction(
            payer: sender.publicKey,
            owner: sender.publicKey,
            mint: usdcMint
        )
        instructions.append(createSenderATA)
    }
    
    // 3. Check receiver's Token Account
    print("💰 Checking recipient's token account...")
    let recipientAccountInfo = try? await connection.getAccountInfo(account: recipientATA)
    
    if recipientAccountInfo == nil {
        print("📝 Creating recipient's token account...")
        let createRecipientATA = try SolanaSplToken.createAssociatedTokenAccountInstruction(
            payer: sender.publicKey,  // Sender pays creation fee
            owner: recipient,
            mint: usdcMint
        )
        instructions.append(createRecipientATA)
    }
    
    // 4. Check sender balance
    if let accountInfo = senderAccountInfo {
        let balance = try await connection.getTokenAccountBalance(account: senderATA)
        print("Sender balance: \(balance.uiAmountString ?? "0") USDC")
    }
    
    // 5. Create transfer instruction
    let transferAmount: UInt64 = 1_000_000  // 1 USDC
    let transferInstruction = try SolanaSplToken.createTransferInstruction(
        source: senderATA,
        destination: recipientATA,
        owner: sender.publicKey,
        amount: transferAmount
    )
    instructions.append(transferInstruction)
    
    // 6. Build and send transaction
    print("\n🚀 Sending transaction...")
    let blockhash = try await connection.getLatestBlockhash()
    let transaction = Transaction(
        recentBlockhash: blockhash,
        instructions: instructions,
        signers: [sender]
    )
    
    let signature = try await connection.sendTransaction(transaction: transaction)
    
    print("\n✅ Transfer successful!")
    print("Amount: 1 USDC")
    print("From: \(sender.publicKey.base58())")
    print("To: \(recipient.base58())")
    print("Signature: \(signature)")
    print("Explorer: https://explorer.solana.com/tx/\(signature)?cluster=devnet")
}
```

---

## Complete Examples

### Example 1: Simple SOL Transfer

```swift
import JupSwift

let connection = SolanaConnection(cluster: .devnet)
let sender = try loadKeypair()
let recipient = PublicKey(base58: "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX")

// Transfer 0.1 SOL
let instruction = try SystemProgram.transfer(
    fromPubkey: sender.publicKey,
    toPubkey: recipient,
    lamports: 100_000_000
)

let transaction = Transaction(
    recentBlockhash: try await connection.getLatestBlockhash(),
    instructions: [instruction],
    signers: [sender]
)

let signature = try await connection.sendTransaction(transaction: transaction)
print("Signature: \(signature)")
```

### Example 2: USDC Transfer (Using High-Level API)

```swift
import JupSwift

let connection = SolanaConnection(cluster: .devnet)
let sender = try loadKeypair()
let recipient = PublicKey(base58: "...")
let usdcMint = CommonTokenMints.Devnet.USDC

// Using high-level API - Auto-handle ATA
let senderATA = try await SolanaSplToken.getOrCreateAssociatedTokenAccount(
    connection: connection,
    payer: sender,
    mint: usdcMint,
    owner: sender.publicKey
)

let recipientATA = try await SolanaSplToken.getOrCreateAssociatedTokenAccount(
    connection: connection,
    payer: sender,
    mint: usdcMint,
    owner: recipient
)

// Transfer
let instruction = try SolanaSplToken.createTransferInstruction(
    source: senderATA,
    destination: recipientATA,
    owner: sender.publicKey,
    amount: 1_000_000  // 1 USDC
)

let transaction = Transaction(
    recentBlockhash: try await connection.getLatestBlockhash(),
    instructions: [instruction],
    signers: [sender]
)

let signature = try await connection.sendTransaction(transaction: transaction)
print("Signature: \(signature)")
```

### Example 3: Batch Transfer

```swift
func batchTransfer() async throws {
    let connection = SolanaConnection(cluster: .devnet)
    let sender = try loadKeypair()
    
    let recipients = [
        PublicKey(base58: "address1..."),
        PublicKey(base58: "address2..."),
        PublicKey(base58: "address3...")
    ]
    
    let amountPerRecipient: UInt64 = 10_000_000  // 0.01 SOL each
    
    // Create multiple transfer instructions
    let instructions = try recipients.map { recipient in
        try SystemProgram.transfer(
            fromPubkey: sender.publicKey,
            toPubkey: recipient,
            lamports: amountPerRecipient
        )
    }
    
    // Send in single transaction
    let transaction = Transaction(
        recentBlockhash: try await connection.getLatestBlockhash(),
        instructions: instructions,
        signers: [sender]
    )
    
    let signature = try await connection.sendTransaction(transaction: transaction)
    print("Batch transfer: \(signature)")
}
```

---

## Best Practices

### 1. Balance Check

✅ **Recommended**: Check balance before transfer

```swift
// SOL
let accountInfo = try await connection.getAccountInfo(account: sender.publicKey)
let balance = accountInfo?.lamports ?? 0
guard balance >= amountToSend else {
    throw TransferError.insufficientBalance
}

// SPL Token
let tokenBalance = try await connection.getTokenAccountBalance(account: senderATA)
let balance = UInt64(tokenBalance.amount) ?? 0
guard balance >= amountToSend else {
    throw TransferError.insufficientBalance
}
```

### 2. ATA Management

✅ **Recommended**: Use `getOrCreateAssociatedTokenAccount`

```swift
let ata = try await SolanaSplToken.getOrCreateAssociatedTokenAccount(
    connection: connection,
    payer: payer,
    mint: mint,
    owner: owner
)
```

❌ **Not Recommended**: Assume ATA exists

```swift
let ata = try SolanaSplToken.findAssociatedTokenAddress(...)
// Might not exist!
```

### 3. Error Handling

```swift
do {
    let signature = try await connection.sendTransaction(transaction: transaction)
    print("✅ Success: \(signature)")
    
} catch let error as SolanaError {
    switch error {
    case .insufficientBalance:
        print("❌ Insufficient balance")
    case .accountNotFound:
        print("❌ Account not found")
    default:
        print("❌ Error: \(error)")
    }
} catch {
    print("❌ Unexpected error: \(error)")
}
```

### 4. Transaction Confirmation

```swift
// Send transaction
let signature = try await connection.sendTransaction(transaction: transaction)

// Wait for confirmation
print("⏳ Waiting for confirmation...")
try await Task.sleep(nanoseconds: 3_000_000_000)

// Check confirmation status
let status = try await connection.getSignatureStatus(signature: signature)
if status.confirmationStatus == "confirmed" {
    print("✅ Transaction confirmed")
}
```

### 5. Use Constants

```swift
// ✅ Use predefined constants
let usdcMint = CommonTokenMints.Devnet.USDC
let tokenProgramId = SolanaProgramIds.TOKEN_PROGRAM_ID

// ❌ Hardcode addresses
let usdcMint = PublicKey(base58: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr")
```

---

## Troubleshooting

### Issue 1: Insufficient balance

**Error**: Transaction failed: insufficient funds

**Solution**:
```swift
// Check SOL balance (for transaction fees)
let accountInfo = try await connection.getAccountInfo(account: sender.publicKey)
let solBalance = Double(accountInfo?.lamports ?? 0) / 1_000_000_000
print("SOL Balance: \(solBalance) SOL")

// Get SOL on devnet
// solana airdrop 2 <address> --url devnet
```

### Issue 2: Account not found

**Error**: Account not found

**Solution**:
```swift
// Ensure Token Account exists
let accountInfo = try? await connection.getAccountInfo(account: ata)
if accountInfo == nil {
    print("Creating token account...")
    // Create ATA
}
```

### Issue 3: Invalid instruction data

**Error**: Invalid instruction data

**Solution**:
```swift
// Check parameters
print("Source: \(source.base58())")
print("Destination: \(destination.base58())")
print("Owner: \(owner.base58())")
print("Amount: \(amount)")

// Ensure using correct Program ID
let instruction = try SolanaSplToken.createTransferInstruction(
    source: source,
    destination: destination,
    owner: owner,
    amount: amount,
    programId: SolanaProgramIds.TOKEN_PROGRAM_ID  // Correct Program ID
)
```

### Issue 4: Transaction too large

**Error**: Transaction too large

**Solution**:
```swift
// Batch processing
let batchSize = 5  // Max 5 instructions per batch

for batch in recipients.chunked(into: batchSize) {
    let instructions = batch.map { recipient in
        try SystemProgram.transfer(...)
    }
    
    let transaction = Transaction(
        recentBlockhash: blockhash,
        instructions: instructions,
        signers: [sender]
    )
    
    let signature = try await connection.sendTransaction(transaction: transaction)
    print("Batch sent: \(signature)")
}
```

### Issue 5: Blockhash not found

**Error**: Blockhash not found

**Solution**:
```swift
// Use latest blockhash
let blockhash = try await connection.getLatestBlockhash()

// Don't reuse old blockhash
// Blockhash expires in ~2 minutes
```

---

## Common Token Mint Addresses

### Devnet

```swift
// USDC
Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr

// Using JupSwift constants
CommonTokenMints.Devnet.USDC
```

### Mainnet

```swift
// USDC
EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v

// Using JupSwift constants
CommonTokenMints.Mainnet.USDC
```

---

## Related Resources

### JupSwift Implementation

- **SystemProgram.swift**: `Sources/JupSwift/Utility/SystemProgram.swift`
- **SolanaSplToken.swift**: `Sources/JupSwift/Utility/SolanaSplToken.swift`
- **Test Files**: `Tests/JupSwiftTests/UtilityTests/TransferTokenTests.swift`

### Related Documentation

- **ATA Management**: `Docs/AssociatedTokenAccount.md`
- **X402 Payment**: `Docs/X402PaymentProtocol.md`
- **Quick Start**: `Docs/X402QuickStart.md`

### External Resources

- **SPL Token**: https://spl.solana.com/token
- **Solana Documentation**: https://docs.solana.com

---

**Need help?** Check test files or submit an issue.
