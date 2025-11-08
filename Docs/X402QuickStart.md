# X402 Payment Protocol - Quick Start Guide

Quick guide: How to start X402 server and test client

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Starting the Server](#starting-the-server)
3. [Testing the Client](#testing-the-client)
4. [Common Issues](#common-issues)

---

## Prerequisites

### 1. Install Dependencies

```bash
# Navigate to x402 examples directory
cd x402-solana-examples

# Install Node.js dependencies
npm install
```

### 2. Verify Configuration

Check if wallet configuration files exist:

```bash
ls pay-in-usdc/client.json    # Client wallet
ls pay-in-usdc/server.json    # Server wallet (optional)
```

If these files don't exist, the server will automatically generate them on first run.

---

## Starting the Server

### 🪙 USDC Server (Recommended)

**Start the server**:

```bash
# In the x402-solana-examples directory
npm run usdc:server
```

**Success output example**:

```
================================================================================
🚀 X402 USDC Payment Server Configuration
================================================================================
USDC Mint: Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr
Recipient Wallet: seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX
Recipient Token Account: ANVQMUvfjwJuwC8ML2bcqeqcwSZRFKPcera9T25KxU4Y
Price: 0.01 USDC
================================================================================

Server running on http://localhost:3001
```

**Important**:
- Server runs on `http://localhost:3001`
- Price is **0.01 USDC** (100 smallest units, USDC has 6 decimals)
- Using Solana Devnet

### 💰 SOL Server (Alternative)

```bash
# In the x402-solana-examples directory
npm run sol:server
```

Server runs on `http://localhost:3000`, price is **0.001 SOL**

---

## Testing the Client

### Method 1: Swift Integration Tests (Recommended)

This is the best way to test X402 payments with complete validation flow.

#### 📍 Test 1: High-Level API Test (Easiest)

```bash
# Return to project root
cd ..

# Run high-level API test
swift test --filter testX402PaymentWithHighLevelAPI
```

**This test will**:
- ✅ Use WalletManager to manage keys
- ✅ Automatically create necessary Token Accounts
- ✅ Complete USDC payment
- ✅ Verify balance changes
- ✅ Print transaction explorer link

**Success output example**:

```
✅ Step 5: Send payment proof to X402 server...
   ✅ Payment proof accepted by server
   Transaction signature: 5ckAQbFNdhgBumY8HLM7NsQHsc7eMrFcczvzyc2CupUX...
   Explorer: https://explorer.solana.com/tx/5ckAQ...?cluster=devnet

💰 Step 7: Check balance after payment...
   📊 Balance after payment:
   Payer: 3998.9987 USDC
   Server: 1.0017 USDC

✅ X402 Integration test passed!
```

#### 📍 Test 2: Import Private Key Test

```bash
swift test --filter testImportSpecificPrivateKey
```

**This test will**:
- ✅ Import specified private key
- ✅ Switch to imported wallet
- ✅ Use standard WalletManager methods to get keys
- ✅ Print complete public and private keys

#### 📍 Test 3: Run All X402 Tests

```bash
swift test --filter X402
```

### Method 2: Node.js Client (Optional)

If you want to test the Node.js client version:

```bash
# In the x402-solana-examples directory
npm run usdc:client
```

---

## Test Flow Explanation

### Complete X402 Payment Flow

```
Client                          Server
  |                               |
  | 1. GET /premium               |
  |------------------------------>|
  |                               |
  | 2. 402 Payment Required       |
  |     + Payment Quote           |
  |<------------------------------|
  |                               |
  | 3. Create & Sign Transaction  |
  |    (Auto ATA Management)      |
  |                               |
  | 4. GET /premium               |
  |    + X-Payment header         |
  |------------------------------>|
  |                               |
  | 5. Verify & Submit Tx         |
  |    + Return Content           |
  |<------------------------------|
```

### Automatic ATA Management

Swift client automatically handles:
- ✅ Check Payer's Token Account, create if not exists
- ✅ Check Server's Token Account
- ✅ Create transfer instruction
- ✅ Sign and send transaction

---

## Common Issues

### ❓ Server fails to start

**Problem**: `Error: listen EADDRINUSE :::3001`

**Solution**: Port is in use, close existing server first

```bash
# macOS/Linux
lsof -ti:3001 | xargs kill -9

# Or restart the server
```

### ❓ Client test fails: could not find account

**Problem**: Server's Token Account doesn't exist

**Solution**: 

1. Make sure server is running (will print Token Account address)
2. If you changed USDC mint, need to create ATA for server

```bash
# Get server address using Solana CLI
solana-keygen pubkey pay-in-usdc/server.json

# Then create ATA using Solana CLI or other tools
```

### ❓ Payment verification failed

**Common causes**:

1. **Server not restarted**: Must restart server after config changes
   ```bash
   # Ctrl+C to stop server
   npm run usdc:server  # Restart
   ```

2. **Insufficient balance**: Make sure client wallet has enough USDC
   ```bash
   # Check balance (in test output)
   Payer: 3998.9987 USDC
   ```

3. **Network issues**: Make sure you can connect to Solana Devnet
   ```bash
   # Test connection
   solana cluster-version --url https://api.devnet.solana.com
   ```

### ❓ How to get Devnet USDC?

```bash
# 1. Get SOL (for transaction fees)
solana airdrop 2 <YOUR_ADDRESS> --url devnet

# 2. Get USDC from SPL Token Faucet
# Visit: https://spl-token-faucet.com/
# Mint: Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr
```

### ❓ How to view transaction details?

After successful test, an explorer link will be printed:

```
Explorer: https://explorer.solana.com/tx/[SIGNATURE]?cluster=devnet
```

Click the link to view transaction details.

---

## 📚 Additional Resources

### Documentation

- **High-Level API**: `Docs/X402HighLevelAPI.md`
- **Test Instructions**: `Tests/JupSwiftTests/UtilityTests/X402_TEST_README.md`
- **Quick Test**: `QUICK_TEST_HIGH_LEVEL_API.md`

### Example Code

- **Simple Example**: `Examples/X402SimplePaymentExample.swift`

### Integration Tests

```bash
# High-level API test
swift test --filter testX402PaymentWithHighLevelAPI

# WalletManager test
swift test --filter testX402USDCPaymentWithWalletManager

# Import private key test
swift test --filter testImportSpecificPrivateKey

# All X402 tests
swift test --filter X402
```

---

## 🎯 Quick Command Reference

```bash
# Start USDC server
cd x402-solana-examples && npm run usdc:server

# Run Swift test (new terminal)
cd .. && swift test --filter testX402PaymentWithHighLevelAPI

# View all X402 tests
swift test --filter X402

# Build project
swift build

# Clean and rebuild
rm -rf .build && swift build
```

---

## ✅ Success Indicators

Signs of successful test:

1. ✅ Server starts normally and prints configuration
2. ✅ Client connects successfully
3. ✅ Transaction submitted successfully
4. ✅ Balance changes correctly
5. ✅ Content received after payment
6. ✅ Test passes

**Example success output**:

```
================================================================================
✅ X402 Integration test passed!
   Used WalletManager for signing (no client.json needed)
================================================================================
```

---

## 🚀 Next Steps

You've successfully run X402 payment test!

**Recommended actions**:

1. Check `Docs/X402HighLevelAPI.md` for API details
2. Read example code in `Examples/`
3. Integrate X402 payment in your application

**Basic integration code**:

```swift
import JupSwift

// 1. Create client
let client = X402PaymentClient(
    serverUrl: "http://localhost:3001",
    network: "solana-devnet",
    cluster: .devnet
)

// 2. One-line payment!
let response = try await client.payForContent(
    endpoint: "/premium",
    payer: keypair
)

// 3. Get content
print(response.content)  // "Premium content - USDC payment verified!"
```

It's that simple! 🎉

---

**Need help?** Check other documentation or submit an issue.
