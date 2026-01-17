# x402 Pay in SOL

A minimal implementation of HTTP 402 Payment Required using native SOL tokens on Solana blockchain.

[← Back to Examples](../README.md)

## Quickstart

From the project root:

1. Start the server:

```bash
npm run sol:server
```

2. In another terminal, run the client:

```bash
npm run sol:client
```

## Overview

This example demonstrates a complete x402 payment flow on Solana:

- **Server** (`server.ts`): Express API that requires payment before serving content
  - Issues payment quotes with recipient and amount
  - Verifies, simulates, and submits transactions
  - Solana blockchain prevents duplicate transactions
- **Client** (`client.ts`): Pays for content using Solana transactions
  - Requests payment quote
  - Creates and signs transaction (doesn't submit)
  - Sends signed transaction to server for verification

> **Note**: The official x402 middleware packages (`@coinbase/x402-express`) are not yet published on npm. This implementation follows the x402 specification manually with full transparency.

## Setup

1. Install dependencies (from project root):

```bash
cd ..  # Go to project root if you're in pay-in-sol/
npm install
```

2. The recipient address is already set in `server.ts`. Update if needed:

   ```typescript
   const RECIPIENT = new PublicKey("YourWalletAddressHere");
   ```

3. For devnet testing, fund your client wallet with SOL:

```bash
# Get the wallet address from client.json
solana address -k pay-in-sol/client.json

# Request airdrop
solana airdrop 1 <YOUR_WALLET_ADDRESS> --url devnet
```

## How It Works (x402 Standard)

1. **Client requests** `/premium` endpoint
2. **Server responds** with `402 Payment Required` and payment details (recipient, amount)
3. **Client creates and signs** a Solana transaction (but does NOT submit it)
4. **Client sends** `X-Payment` header with the serialized signed transaction:
   ```json
   {
     "x402Version": 1,
     "scheme": "exact",
     "network": "solana-devnet",
     "payload": {
       "serializedTransaction": "base64-encoded-signed-tx"
     }
   }
   ```
   Simple and minimal - just the transaction!
5. **Server (acting as facilitator)**:
   - Decodes and deserializes the transaction
   - **Introspects instructions** to verify transfer amount and recipient
   - **Simulates the transaction** to ensure it will succeed
   - **Submits the transaction** to the blockchain (only if verified)
   - Waits for confirmation
   - Verifies payment details on-chain
   - Returns premium content with Solana Explorer link

## x402 Standard

This implementation follows the [x402 protocol specification](https://x402.org):

**How it works:**

1. Client requests a resource
2. Server responds with `402 Payment Required` and payment details
3. Client creates and signs a transaction (but doesn't submit it)
4. Client sends the serialized transaction in `X-Payment` header
5. Server verifies, submits the transaction, confirms payment, and grants access

**Key Features:**

- **Client signs, server submits**: Client creates signed transaction, server acts as facilitator
- **On-chain payment verification**: Server confirms transaction on Solana blockchain
- **Automatic replay protection**: Solana blockchain rejects duplicate transaction signatures
- **Trustless**: Client maintains custody, only signs what they approve
- **Minimal payload**: Just the serialized transaction, nothing else needed

## Future: Official Middleware

The official middleware packages are being developed:

```typescript
import { x402Middleware } from "@coinbase/x402-express";

app.get(
  "/premium",
  x402Middleware(RECIPIENT, {
    price: "$0.0001",
    network: "solana-devnet",
    asset: "USDC",
  }),
  (req, res) => res.json({ data: "Premium content" })
);
```

Once published, this will provide automatic payment verification with less boilerplate.

## Key Differences from Traditional Payment Flows

### 1. Client Signs, Server Submits

❌ **Wrong**: Client submits transaction, then sends signature to server  
✅ **Correct**: Client signs transaction, server receives & submits it

**Why?**

- Server acts as a **facilitator** (similar to Solana Pay)
- Client maintains custody and only approves the exact transaction
- Server can **verify & simulate** transaction before submitting
- Enables atomic payment verification (no race conditions)
- Protects against malformed or failing transactions

### 2. Minimal Payload

✅ **x402**: Just serialized transaction in payload  
❌ **Not needed**: signers (extracted from tx), references (tracked via tx signature)

**Why so simple?**

- Server can extract all needed info from the transaction itself
- Transaction signature serves as unique identifier
- Replay protection via signature tracking (not reference tracking)
- Cleaner, simpler protocol

## Server Response

When payment is verified, the server returns:

```json
{
  "data": "Premium content - payment verified!",
  "paymentDetails": {
    "signature": "5xK7hN9wvE...",
    "amount": 100000,
    "recipient": "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX",
    "explorerUrl": "https://explorer.solana.com/tx/5xK7...?cluster=devnet"
  }
}
```

The client automatically displays a clickable link to view the transaction on Solana Explorer! 🔗

## Security: 3-Step Verification

The server implements defense-in-depth verification **before** submitting:

### Step 1: Introspect Instructions

```typescript
// Decode SystemProgram transfer instruction
// Verify: correct recipient + sufficient amount
const transferAmount = ix.data.readBigUInt64LE(4);
if (toAccount.equals(RECIPIENT) && transferAmount >= PRICE_LAMPORTS) {
  validTransfer = true;
}
```

### Step 2: Simulate Transaction

```typescript
// Test transaction execution without submitting
const simulation = await connection.simulateTransaction(tx);
if (simulation.value.err) {
  return error; // Don't submit failing transactions
}
```

### Step 3: Submit & Confirm

```typescript
// Only submit if steps 1 & 2 pass
// Solana automatically rejects duplicate transaction signatures
const signature = await connection.sendRawTransaction(txBuffer);
await connection.confirmTransaction(signature);
```

**Benefits:**

- ✅ Prevents submitting invalid transactions
- ✅ Verifies exact amount before submission
- ✅ Catches issues early (insufficient balance, etc.)
- ✅ Better error messages for clients
- ✅ No wasted transaction fees on failed attempts
- ✅ Replay protection built into Solana blockchain

## What Makes This Implementation Special

✅ **Correct x402 flow**: Client signs, server verifies & submits  
✅ **Minimal payload**: Just the serialized transaction  
✅ **3-step verification**: Introspect → Simulate → Submit  
✅ **Blockchain replay protection**: Solana rejects duplicate signatures automatically  
✅ **Full transparency**: See exactly how payment verification works

## Production Checklist

- [ ] Add transaction recency validation (check blockhash age)
- [ ] Implement proper error handling and logging
- [ ] Add monitoring and rate limiting
- [ ] Switch to mainnet RPC endpoint
- [ ] Use USDC instead of SOL (add SPL Token instruction decoding)
- [ ] Set up proper key management for the recipient wallet
- [ ] Add webhook notifications for successful payments
- [ ] Implement proper CORS configuration
- [ ] Add request authentication/API keys if needed
- [ ] Consider caching recent signatures if you want faster duplicate detection
