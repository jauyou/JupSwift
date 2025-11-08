# X402 Payment Protocol - High-Level API

Complete X402 High-Level API Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Core Concepts](#core-concepts)
3. [High-Level API](#high-level-api)
4. [Configuration](#configuration)
5. [Complete Examples](#complete-examples)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)

---

## Overview

X402PaymentProtocol provides a simplified high-level API that automatically handles the entire payment flow, including:

- ✅ **Automatic ATA Management** - Automatically checks and creates necessary Token Accounts
- ✅ **One-Click Payment** - Complete payment flow with a single method call
- ✅ **Multi-Currency Support** - Supports SOL and any SPL Token (like USDC)
- ✅ **WalletManager Integration** - Seamless integration with secure WalletManager

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    X402PaymentClient                         │
│                   (High-Level API)                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  payForContent(endpoint, payer)                             │
│     │                                                        │
│     ├─► 1. requestPaymentQuote()      Get payment info     │
│     │                                                        │
│     ├─► 2. Auto ATA Management        Check/Create ATAs    │
│     │      - findAssociatedTokenAddress()                  │
│     │      - createAssociatedTokenAccountInstruction()     │
│     │                                                        │
│     ├─► 3. Create Transaction          Build & sign        │
│     │      - createTransferInstruction() or                │
│     │      - SystemProgram.transfer()                      │
│     │                                                        │
│     └─► 4. sendPaymentProof()          Verify & get content│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### X402 Payment Protocol

X402 is a payment protocol based on HTTP 402 status code:

1. **Client** requests protected content
2. **Server** returns 402 + Payment Quote
3. **Client** creates and signs transaction
4. **Server** verifies transaction and returns content

### Automatic ATA Management

For SPL Token payments, client needs Token Accounts. The high-level API automatically handles:

- Checks Payer's Token Account, creates if not exists
- Checks Recipient (Server) Token Account
- If Server's Token Account doesn't exist, provides clear error message

---

## High-Level API

### X402PaymentClient

#### Initialization

```swift
import JupSwift

// Method 1: Using serverUrl and cluster
let client = X402PaymentClient(
    serverUrl: "http://localhost:3001",
    network: "solana-devnet",
    cluster: .devnet
)

// Method 2: Using configuration object
let config = X402PaymentConfig(
    serverUrl: "http://localhost:3001",
    cluster: .devnet
)
let client = X402PaymentClient(
    config: config,
    connection: SolanaConnection(cluster: .devnet)
)
```

#### Core Method

##### `payForContent(endpoint:payer:) async throws -> X402PaymentResponse`

**One-click payment** - Automatically handles the entire flow

```swift
let response = try await client.payForContent(
    endpoint: "/premium",
    payer: keypair
)

print(response.content)  // "Premium content!"
print(response.signature)  // Transaction signature
```

**Parameters**:
- `endpoint`: String - Server endpoint (e.g., "/premium")
- `payer`: Keypair - Payer's keypair

**Returns**: `X402PaymentResponse`
- `content`: String? - Content received after payment
- `signature`: String - Transaction signature
- `amount`: Int - Payment amount (smallest unit)
- `recipient`: String - Recipient address

**Automatically handles**:
1. ✅ Request Payment Quote
2. ✅ Determine payment type (SOL vs SPL Token)
3. ✅ Automatically create Payer's ATA (if needed)
4. ✅ Check Recipient's ATA
5. ✅ Create and sign transaction
6. ✅ Send Payment Proof
7. ✅ Return content

---

## Configuration

### X402PaymentConfig

```swift
public struct X402PaymentConfig {
    public let serverUrl: String
    public let network: String
    
    // Initialization method 1: Manually specify network
    public init(serverUrl: String, network: String = "solana-devnet")
    
    // Initialization method 2: Use SolanaCluster
    public init(serverUrl: String, cluster: SolanaCluster)
}
```

### SolanaCluster

```swift
public enum SolanaCluster {
    case mainnet    // "solana-mainnet"
    case devnet     // "solana-devnet"
    case testnet    // "solana-testnet"
    case localnet   // "solana-localnet"
}
```

### Network Configuration

```swift
// Devnet (development and testing)
let devnetClient = X402PaymentClient(
    serverUrl: "http://localhost:3001",
    cluster: .devnet
)

// Mainnet (production)
let mainnetClient = X402PaymentClient(
    serverUrl: "https://api.myservice.com",
    cluster: .mainnet
)
```

---

## Complete Examples

### Example 1: Basic USDC Payment

```swift
import JupSwift

func payForPremiumContent() async throws {
    // 1. Create X402 Client
    let client = X402PaymentClient(
        serverUrl: "http://localhost:3001",
        cluster: .devnet
    )
    
    // 2. Load or create Keypair
    let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: "./client.json"))
    let privateKeyArray = try JSONDecoder().decode([UInt8].self, from: privateKeyData)
    let payer = Keypair(privateKey: privateKeyArray)
    
    // 3. One-click payment!
    let response = try await client.payForContent(
        endpoint: "/premium",
        payer: payer
    )
    
    // 4. Use content
    print("Content: \(response.content ?? "No content")")
    print("Transaction: https://explorer.solana.com/tx/\(response.signature)?cluster=devnet")
}
```

### Example 2: Using WalletManager

```swift
import JupSwift

func payWithWalletManager() async throws {
    // 1. Get WalletManager
    let walletManager = WalletManager.shared
    
    // 2. Create X402 Client
    let client = X402PaymentClient(
        serverUrl: "http://localhost:3001",
        cluster: .devnet
    )
    
    // 3. Get Keypair from WalletManager
    let privateKeyBase58 = try await walletManager.getCurrentPrivateKey()
    guard let privateKeyData = Base58.decode(privateKeyBase58) else {
        throw WalletError.invalidPrivateKeyFormat
    }
    let payer = Keypair(privateKey: Array(privateKeyData))
    
    // 4. Payment
    let response = try await client.payForContent(
        endpoint: "/premium",
        payer: payer
    )
    
    print("✅ Payment successful!")
    print("Content: \(response.content ?? "")")
}
```

### Example 3: Complete Flow with Balance Check

```swift
import JupSwift

func completePaymentFlow() async throws {
    let connection = SolanaConnection(cluster: .devnet)
    let client = X402PaymentClient(
        serverUrl: "http://localhost:3001",
        cluster: .devnet
    )
    
    // Prepare payer
    let payer = try loadKeypair()
    let payerPubkey = payer.publicKey
    
    // USDC Mint (Devnet)
    let usdcMint = PublicKey(base58: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr")
    
    // Get Token Account
    let payerTokenAccount = try SolanaSplToken.findAssociatedTokenAddress(
        mint: usdcMint,
        owner: payerPubkey
    )
    
    // Check balance before payment
    print("💰 Balance before payment:")
    let balanceBefore = try await connection.getTokenAccountBalance(
        account: payerTokenAccount
    )
    print("   Payer: \(balanceBefore.uiAmountString ?? "0") USDC")
    
    // Payment
    print("\n🚀 Starting payment...")
    let response = try await client.payForContent(
        endpoint: "/premium",
        payer: payer
    )
    
    // Wait for confirmation
    print("\n⏳ Waiting for confirmation...")
    try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
    
    // Check balance after payment
    print("\n💰 Balance after payment:")
    let balanceAfter = try await connection.getTokenAccountBalance(
        account: payerTokenAccount
    )
    print("   Payer: \(balanceAfter.uiAmountString ?? "0") USDC")
    
    // Verification
    let amountPaid = (balanceBefore.uiAmount ?? 0) - (balanceAfter.uiAmount ?? 0)
    print("\n✅ Payment successful!")
    print("   Amount paid: \(amountPaid) USDC")
    print("   Content: \(response.content ?? "")")
    print("   Explorer: https://explorer.solana.com/tx/\(response.signature)?cluster=devnet")
}
```

---

## Error Handling

### Common Error Types

```swift
enum X402PaymentError: Error {
    case invalidQuote(String)          // Payment quote invalid
    case paymentFailed(String)         // Payment failed
    case networkError(Error)           // Network error
    case transactionFailed(String)     // Transaction failed
}
```

### Error Handling Example

```swift
do {
    let response = try await client.payForContent(
        endpoint: "/premium",
        payer: payer
    )
    print("✅ Success: \(response.content ?? "")")
    
} catch let error as X402PaymentError {
    switch error {
    case .invalidQuote(let message):
        print("❌ Invalid quote: \(message)")
        // Server configuration issue, usually need to fix server
        
    case .paymentFailed(let message):
        print("❌ Payment failed: \(message)")
        // Possible insufficient balance, ATA doesn't exist, etc.
        
    case .networkError(let error):
        print("❌ Network error: \(error)")
        // Network connection issue, retry
        
    case .transactionFailed(let message):
        print("❌ Transaction failed: \(message)")
        // Transaction failed on-chain, check logs
    }
    
} catch {
    print("❌ Unexpected error: \(error)")
}
```

### Specific Error Handling

#### 1. Recipient ATA doesn't exist

```swift
// Error message
"Cannot create recipient token account: owner wallet address not provided by server"

// Solution
// Create ATA for recipient on server side:
// solana-keygen pubkey server.json
// Then create ATA or wait for first transaction to auto-create
```

#### 2. Payer insufficient balance

```swift
// Error message
"Insufficient balance"

// Solution
// Get Devnet USDC:
// 1. solana airdrop 2 <address> --url devnet
// 2. Use SPL Token Faucet
```

#### 3. Network connection failure

```swift
// Use retry mechanism
func payWithRetry(maxRetries: Int = 3) async throws -> X402PaymentResponse {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try await client.payForContent(
                endpoint: "/premium",
                payer: payer
            )
        } catch {
            lastError = error
            print("❌ Attempt \(attempt) failed: \(error)")
            if attempt < maxRetries {
                try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            }
        }
    }
    
    throw lastError!
}
```

---

## Best Practices

### 1. Use WalletManager

✅ **Recommended**: Use WalletManager to manage keys

```swift
let walletManager = WalletManager.shared
let privateKey = try await walletManager.getCurrentPrivateKey()
```

❌ **Not Recommended**: Hardcode private keys in code

```swift
let privateKey = "2suvGYfS..."  // Insecure!
```

### 2. Error Handling

✅ **Recommended**: Detailed error handling and user feedback

```swift
do {
    let response = try await client.payForContent(...)
    showSuccess(response)
} catch {
    handleError(error)
    showUserFriendlyMessage()
}
```

### 3. Balance Check

✅ **Recommended**: Check balance before payment

```swift
let balance = try await connection.getTokenAccountBalance(account: payerTokenAccount)
guard balance.uiAmount ?? 0 >= expectedAmount else {
    throw PaymentError.insufficientBalance
}
```

### 4. Transaction Confirmation

✅ **Recommended**: Wait for transaction confirmation

```swift
let response = try await client.payForContent(...)
try await Task.sleep(nanoseconds: 3_000_000_000)  // Wait for confirmation
```

### 5. Logging

✅ **Recommended**: Log key operations

```swift
print("💰 Starting payment: \(endpoint)")
print("🔑 Payer: \(payer.publicKey.base58())")
print("✅ Transaction: \(response.signature)")
```

---

## Low-Level API (Optional)

If you need more fine-grained control, you can use the low-level API:

### requestPaymentQuote

```swift
let quote = try await client.requestPaymentQuote(endpoint: "/premium")
print("Price: \(quote.payment.amountUSDC ?? 0) USDC")
```

### sendPaymentProof

```swift
let serializedTx = try transaction.serialize().base64EncodedString()
let response = try await client.sendPaymentProof(
    endpoint: "/premium",
    serializedTransaction: serializedTx
)
```

**Note**: In most cases, you should use the `payForContent()` high-level API.

---

## Related Documentation

- **Quick Start**: `Docs/X402QuickStart.md`
- **Protocol Explanation**: `Docs/X402PaymentProtocol.md`
- **ATA Management**: `Docs/AssociatedTokenAccount.md`
- **Transfer Functions**: `Docs/TransferToken.md`

---

## Example Code Locations

- `Examples/X402SimplePaymentExample.swift` - Basic example
- `Tests/JupSwiftTests/UtilityTests/X402WalletManagerIntegrationTests.swift` - Integration tests

---

**Complete Implementation**: `Sources/JupSwift/Utility/X402PaymentProtocol.swift`

Need help? Check `Docs/X402QuickStart.md` or submit an issue.
