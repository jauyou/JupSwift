# X402 Payment Protocol - Protocol Specification

Complete technical specification of the X402 Payment Protocol

## 📋 Table of Contents

1. [Protocol Overview](#protocol-overview)
2. [Protocol Flow](#protocol-flow)
3. [Data Structures](#data-structures)
4. [Payment Types](#payment-types)
5. [Implementation Details](#implementation-details)
6. [Security Considerations](#security-considerations)

---

## Protocol Overview

### What is X402?

X402 is an open payment standard based on HTTP 402 "Payment Required" status code, integrating micropayments directly into HTTP protocol.

**Core Features**:
- ✅ Based on standard HTTP protocol
- ✅ Uses 402 status code and custom headers
- ✅ Supports multiple payment networks (Solana, Ethereum, etc.)
- ✅ Client signs, server submits
- ✅ Blockchain-native replay attack protection

### Protocol Version

Current implementation: **X402 v1**

```swift
public struct X402PaymentProof {
    public let x402Version: Int = 1  // Protocol version
    public let scheme: String = "exact"  // Payment scheme
    // ...
}
```

---

## Protocol Flow

### Complete Flow Diagram

```
┌──────────┐                                    ┌──────────┐
│  Client  │                                    │  Server  │
└────┬─────┘                                    └────┬─────┘
     │                                                │
     │ 1. GET /premium                               │
     │ ──────────────────────────────────────────────>
     │                                                │
     │ 2. 402 Payment Required                       │
     │    X-Payment-Required: true                   │
     │    Body: Payment Quote (JSON)                 │
     │ <──────────────────────────────────────────────
     │                                                │
     │ 3. Create & Sign Transaction                  │
     │    - Build transaction                         │
     │    - Sign with private key                     │
     │    - Serialize transaction                     │
     │                                                │
     │ 4. GET /premium                               │
     │    X-Payment: <base64-encoded-proof>          │
     │ ──────────────────────────────────────────────>
     │                                                │
     │ 5. Verify & Submit                            │
     │    - Introspect transaction                    │
     │    - Simulate transaction                      │
     │    - Submit to blockchain                      │
     │                                                │
     │ 6. 200 OK                                     │
     │    Body: Protected Content                     │
     │ <──────────────────────────────────────────────
     │                                                │
```

### Step Descriptions

#### Step 1: Request Protected Resource

Client sends a standard HTTP GET request:

```http
GET /premium HTTP/1.1
Host: api.example.com
```

#### Step 2: Server Returns Payment Quote

Server returns 402 status code with payment information:

```http
HTTP/1.1 402 Payment Required
Content-Type: application/json
X-Payment-Required: true

{
  "payment": {
    "tokenAccount": "ANVQMUvfjwJuwC8ML2bcqeqcwSZRFKPcera9T25KxU4Y",
    "mint": "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
    "amountUSDC": 0.01,
    "cluster": "devnet"
  }
}
```

**SPL Token Fields**:
- `tokenAccount`: Recipient's Token Account
- `mint`: Token Mint address (e.g., USDC)
- `amountUSDC`: Amount (UI units)

**SOL Fields**:
- `recipient`: Recipient wallet address
- `amount`: Amount (lamports)

#### Step 3: Client Creates Transaction

Client creates and signs transaction based on Payment Quote.

**JupSwift Implementation**:

```swift
// SOL payment
let instruction = try SystemProgram.transfer(
    fromPubkey: payer.publicKey,
    toPubkey: recipientPubkey,
    lamports: UInt64(amount)
)

// SPL Token payment
let instruction = try SolanaSplToken.createTransferInstruction(
    source: payerTokenAccount,
    destination: recipientTokenAccount,
    owner: payer.publicKey,
    amount: UInt64(amountInSmallestUnit)
)

let transaction = Transaction(
    recentBlockhash: recentBlockhash,
    instructions: [instruction],
    signers: [payer]  // Client signs
)

let serialized = try transaction.serialize()
```

#### Step 4: Send Payment Proof

Client sends payment proof via `X-Payment` header:

```http
GET /premium HTTP/1.1
Host: api.example.com
X-Payment: eyJ4NDAyVmVyc2lvbiI6MSwic2NoZW1lIjoiZXhhY3QiLCJuZXR3b3JrIjoic29sYW5hLWRldm5ldCIsInBheWxvYWQiOnsic2VyaWFsaXplZFRyYW5zYWN0aW9uIjoiQVFBQUFBQUFBQUFBLi4uIn19
```

**X-Payment Header Format**:

```
base64(JSON({
  "x402Version": 1,
  "scheme": "exact",
  "network": "solana-devnet",
  "payload": {
    "serializedTransaction": "AQAAAAAAAAAAA..."
  }
}))
```

#### Step 5: Server Verification

Server performs three-step verification:

1. **Introspect** - Parse transaction, verify recipient and amount
2. **Simulate** - Simulate transaction to ensure it will succeed
3. **Submit** - Submit transaction to blockchain

```typescript
// Server-side (TypeScript example)
const tx = Transaction.from(Buffer.from(serializedTx, 'base64'))

// 1. Introspect
const instruction = tx.instructions[0]
// Verify recipient and amount

// 2. Simulate
const simulation = await connection.simulateTransaction(tx)
if (simulation.value.err) {
    throw new Error('Transaction simulation failed')
}

// 3. Submit
const signature = await connection.sendRawTransaction(
    tx.serialize(),
    { skipPreflight: true }
)
```

#### Step 6: Return Content

After successful verification, server returns protected content:

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": "Premium content - payment verified!",
  "paymentDetails": {
    "signature": "5ckAQbFNdhgBumY8...",
    "amount": 10000,
    "recipient": "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX",
    "timestamp": 1699564800
  }
}
```

---

## Data Structures

### X402PaymentQuote

Payment quote returned by server (402 response)

```swift
public struct X402PaymentQuote: Codable {
    public let payment: PaymentDetails
    
    public struct PaymentDetails: Codable {
        // SOL payment
        public let recipient: String?
        public let amount: Int?
        
        // SPL Token payment
        public let tokenAccount: String?
        public let mint: String?
        public let amountUSDC: Double?
        
        // Common fields
        public let cluster: String
    }
}
```

**Example - USDC Payment**:

```json
{
  "payment": {
    "tokenAccount": "ANVQMUvfjwJuwC8ML2bcqeqcwSZRFKPcera9T25KxU4Y",
    "mint": "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
    "amountUSDC": 0.01,
    "cluster": "devnet"
  }
}
```

**Example - SOL Payment**:

```json
{
  "payment": {
    "recipient": "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX",
    "amount": 1000000,
    "cluster": "devnet"
  }
}
```

### X402PaymentProof

Payment proof sent by client (X-Payment header)

```swift
public struct X402PaymentProof: Codable {
    public let x402Version: Int        // Protocol version (1)
    public let scheme: String          // Payment scheme ("exact")
    public let network: String         // Network identifier ("solana-devnet")
    public let payload: Payload
    
    public struct Payload: Codable {
        public let serializedTransaction: String  // Base64 encoded transaction
    }
}
```

**Complete Example**:

```json
{
  "x402Version": 1,
  "scheme": "exact",
  "network": "solana-devnet",
  "payload": {
    "serializedTransaction": "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQADBr..."
  }
}
```

### X402PaymentResponse

Response from server after verification

```swift
public struct X402PaymentResponse: Codable {
    public let data: String?              // Protected content
    public let error: String?             // Error message (if any)
    public let paymentDetails: PaymentDetails?
    
    public struct PaymentDetails: Codable {
        public let signature: String      // Transaction signature
        public let amount: Int            // Amount (smallest unit)
        public let amountUSDC: Double?    // Amount (UI unit, SPL Token only)
        public let recipient: String      // Recipient address
        public let timestamp: Int         // Timestamp
    }
}
```

---

## Payment Types

### 1. SOL Payment

Using Solana native token for payment.

**Payment Quote**:

```json
{
  "payment": {
    "recipient": "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX",
    "amount": 1000000,
    "cluster": "devnet"
  }
}
```

**Transaction Creation**:

```swift
let instruction = try SystemProgram.transfer(
    fromPubkey: payer.publicKey,
    toPubkey: PublicKey(base58: quote.payment.recipient!),
    lamports: UInt64(quote.payment.amount!)
)
```

### 2. SPL Token Payment (USDC)

Using SPL Token (like USDC) for payment.

**Payment Quote**:

```json
{
  "payment": {
    "tokenAccount": "ANVQMUvfjwJuwC8ML2bcqeqcwSZRFKPcera9T25KxU4Y",
    "mint": "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr",
    "amountUSDC": 0.01,
    "cluster": "devnet"
  }
}
```

**Transaction Creation**:

```swift
// 1. Find Token Accounts
let payerTokenAccount = try SolanaSplToken.findAssociatedTokenAddress(
    mint: mintPubkey,
    owner: payer.publicKey
)

// 2. Create transfer instruction
let transferInstruction = try SolanaSplToken.createTransferInstruction(
    source: payerTokenAccount,
    destination: recipientTokenAccount,
    owner: payer.publicKey,
    amount: 10000  // 0.01 USDC = 10000 (6 decimals)
)

// 3. If needed, create ATA
if payerTokenAccountNotExists {
    let createATAInstruction = try SolanaSplToken.createAssociatedTokenAccountInstruction(
        payer: payer.publicKey,
        owner: payer.publicKey,
        mint: mintPubkey
    )
    instructions.insert(createATAInstruction, at: 0)
}
```

---

## Implementation Details

### Unit Conversion

**SPL Token (USDC)**:
- Devnet USDC has **6 decimals**
- UI amount `0.01 USDC` = smallest unit `10000`
- Conversion formula: `smallestUnit = uiAmount * 10^decimals`

```swift
let decimals = 6  // USDC decimals
let uiAmount = 0.01
let smallestUnit = Int(uiAmount * pow(10.0, Double(decimals)))
// smallestUnit = 10000
```

**SOL**:
- 1 SOL = 1,000,000,000 lamports (9 decimals)
- UI amount `0.001 SOL` = smallest unit `1000000 lamports`

### Automatic ATA Management

High-level API automatically handles Associated Token Account (ATA):

```swift
// 1. Find Payer's ATA
let payerATA = try SolanaSplToken.findAssociatedTokenAddress(
    mint: mintPubkey,
    owner: payer.publicKey
)

// 2. Check if exists
let accountInfo = try? await connection.getAccountInfo(account: payerATA)

// 3. If not exists, add create instruction
if accountInfo == nil {
    let createInstruction = try SolanaSplToken.createAssociatedTokenAccountInstruction(
        payer: payer.publicKey,
        owner: payer.publicKey,
        mint: mintPubkey
    )
    instructions.insert(createInstruction, at: 0)
}
```

### Transaction Structure

**Solana Transaction Structure**:

```
Transaction {
    signatures: [Signature],        // Signature list
    message: Message {
        header: MessageHeader,
        accountKeys: [PublicKey],   // Involved accounts
        recentBlockhash: Hash,      // Recent blockhash
        instructions: [Instruction] // Instruction list
    }
}
```

**JupSwift Transaction Creation**:

```swift
let transaction = Transaction(
    recentBlockhash: recentBlockhash,
    instructions: [
        createATAInstruction,  // If needed
        transferInstruction
    ],
    signers: [payer]
)

let serialized = try transaction.serialize()
```

---

## Security Considerations

### 1. Replay Attack Protection

Using Solana's `recentBlockhash` mechanism:

- ✅ Each transaction must include a recent blockhash
- ✅ Blockhash expires in ~2 minutes
- ✅ Blockchain automatically rejects duplicate transactions

```swift
// Get latest blockhash
let recentBlockhash = try await connection.getLatestBlockhash()

// Transaction automatically expires
// No additional nonce mechanism needed
```

### 2. Client-Side Signing

- ✅ Private key **never** leaves the client
- ✅ Server only receives **signed** transactions
- ✅ Server cannot modify transaction content

```swift
// Client signs
let transaction = Transaction(
    recentBlockhash: blockhash,
    instructions: [instruction],
    signers: [payer]  // Signed on client
)

let serialized = try transaction.serialize()  // Includes signature

// Server can only:
// 1. Verify signature
// 2. Submit transaction
// Cannot modify transaction!
```

### 3. Three-Step Verification

Server must perform three-step verification:

```typescript
// 1. Introspect - Verify transaction content
const instruction = tx.instructions[0]
if (instruction.recipient !== EXPECTED_RECIPIENT) {
    throw new Error('Invalid recipient')
}
if (instruction.amount < EXPECTED_AMOUNT) {
    throw new Error('Insufficient amount')
}

// 2. Simulate - Simulate execution
const simulation = await connection.simulateTransaction(tx)
if (simulation.value.err) {
    throw new Error('Transaction would fail')
}

// 3. Submit - Submit to blockchain
const signature = await connection.sendRawTransaction(
    tx.serialize(),
    { skipPreflight: true }
)
```

### 4. Amount Verification

Server must verify exact amount:

```swift
// ❌ Insecure - Only check minimum amount
if actualAmount >= expectedAmount {
    // Client might pay excess
}

// ✅ Secure - Check exact amount
if actualAmount == expectedAmount {
    // Correct!
}
```

### 5. HTTPS Communication

Production environment must use HTTPS:

```swift
// ❌ Development - HTTP
let client = X402PaymentClient(
    serverUrl: "http://localhost:3001",
    cluster: .devnet
)

// ✅ Production - HTTPS
let client = X402PaymentClient(
    serverUrl: "https://api.myservice.com",
    cluster: .mainnet
)
```

---

## Error Handling

### Protocol-Level Errors

```swift
enum X402ProtocolError: Error {
    case invalidQuote           // Payment Quote format error
    case missingRequiredField   // Missing required field
    case unsupportedVersion     // Unsupported protocol version
    case invalidSignature       // Invalid signature
}
```

### Server Error Response

```json
{
  "error": "Payment verification failed",
  "details": "Transaction simulation failed: insufficient funds"
}
```

---

## Network Configuration

### Solana Networks

```swift
// Devnet - Development and testing
cluster: .devnet
network: "solana-devnet"
rpc: "https://api.devnet.solana.com"

// Mainnet - Production
cluster: .mainnet
network: "solana-mainnet"
rpc: "https://api.mainnet-beta.solana.com"

// Testnet - Test network
cluster: .testnet
network: "solana-testnet"
rpc: "https://api.testnet.solana.com"
```

### Token Mint Addresses

```swift
// USDC Devnet
mint: "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"

// USDC Mainnet
mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
```

---

## Reference Resources

### Specification Documents
- **X402 Official**: https://x402.org
- **Solana Documentation**: https://docs.solana.com

### JupSwift Implementation
- **Protocol Implementation**: `Sources/JupSwift/Utility/X402PaymentProtocol.swift`
- **SPL Token**: `Sources/JupSwift/Utility/SolanaSplToken.swift`
- **System Program**: `Sources/JupSwift/Utility/SystemProgram.swift`

### Related Documentation
- **Quick Start**: `Docs/X402QuickStart.md`
- **High-Level API**: `Docs/X402HighLevelAPI.md`
- **ATA Management**: `Docs/AssociatedTokenAccount.md`

---

## Protocol Extensions

X402 protocol is designed to be extensible:

### Future Support

- 🔄 **Subscription Payments** - Recurring payments
- 🎯 **Conditional Payments** - Condition-based payments
- 🌐 **Multi-Chain Support** - Ethereum, Bitcoin, etc.
- 💱 **Exchange Rate Conversion** - Automatic currency conversion

### Custom Implementation

You can implement custom features based on X402 protocol:

```swift
// Custom Payment Quote
struct CustomQuote {
    let payment: StandardPayment
    let metadata: CustomMetadata  // Extended fields
}
```

---

**Complete Implementation**: See `Sources/JupSwift/Utility/X402PaymentProtocol.swift`

**Need help?** Check `Docs/X402QuickStart.md` or submit an issue.
