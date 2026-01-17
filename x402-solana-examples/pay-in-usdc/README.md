# x402 Pay in USDC

Pay-per-request API using USDC (SPL Token) on Solana devnet.

[← Back to Examples](../README.md)

## Quickstart

From the project root:

### Terminal 1: Start the USDC server

```bash
npm run usdc:server
```

### Terminal 2: Run the client

```bash
npm run usdc:client
```

## Overview

This example demonstrates x402 payments using USDC tokens instead of native SOL.

**Key Differences from SOL:**

- Uses SPL Token Program instead of System Program
- Transfers happen between token accounts (not wallet addresses)
- Requires Associated Token Accounts for both payer and recipient
- Amount uses token decimals (USDC has 6 decimals)

## Setup

### 1. Install Dependencies

```bash
cd ..  # Go to project root
npm install
```

### 2. Get Devnet USDC

You'll need devnet USDC tokens for testing:

```bash
# Get your wallet address
solana address -k pay-in-usdc/client.json

# Fund with SOL first (for transaction fees)
solana airdrop 1 <YOUR_WALLET_ADDRESS> --url devnet

# Get devnet USDC from the faucet
# Use the Solana devnet USDC faucet at: https://spl-token-faucet.com/
# Or use the CLI to mint devnet USDC
```

### 3. Get Devnet USDC Tokens

The client will automatically create the Associated Token Account if it doesn't exist.

```bash
# Devnet USDC mint address
USDC_MINT="4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU"

# Option 1: Use the SPL Token Faucet (easiest)
# Visit: https://spl-token-faucet.com/
# Enter your wallet address and select USDC

# Option 2: Create account and request from CLI
spl-token create-account $USDC_MINT --url devnet
# Then request from faucet or mint if you have authority
```

### 4. Server Configuration

The server is already configured! It automatically derives the USDC token account from the recipient wallet address:

```typescript
// Recipient wallet (same as SOL example)
const RECIPIENT_WALLET = new PublicKey(
  "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX"
);

// Token account is automatically derived
const RECIPIENT_TOKEN_ACCOUNT = await getAssociatedTokenAddress(
  USDC_MINT,
  RECIPIENT_WALLET
);
```

No manual configuration needed! 🎉

### 5. Automatic Token Account Creation

**The client handles everything automatically!**

- Checks if recipient's USDC token account exists
- If not, adds a `createAssociatedTokenAccount` instruction
- Pays the rent (~0.002 SOL) for account creation
- Transfers USDC in the same transaction

**First payment creates the account + transfers!** 🚀

## How It Works

### Payment Flow

1. **Client requests** `/premium` endpoint
2. **Server responds** with `402 Payment Required` including:
   - Recipient's USDC token account
   - USDC mint address
   - Amount in smallest units (e.g., 10000 = 0.01 USDC)
3. **Client creates** SPL Token transfer instruction
4. **Client signs** transaction (doesn't submit)
5. **Server verifies**:
   - Decodes token transfer instruction
   - Validates recipient token account
   - Validates transfer amount
   - Simulates transaction
6. **Server submits** transaction to blockchain
7. **Server confirms** token balance change
8. **Server returns** premium content

### SPL Token Transfer Instruction

```typescript
// Client creates
const transferIx = createTransferInstruction(
  payerTokenAccount.address, // source
  recipientTokenAccount, // destination
  payer.publicKey, // owner/signer
  amount // in smallest units
);
```

### Server Verification

```typescript
// Decode SPL Token transfer (instruction type 3)
if (ix.data[0] === 3) {
  const amount = ix.data.readBigUInt64LE(1);
  const destAccount = ix.keys[1].pubkey;

  // Verify destination and amount
  if (destAccount.equals(RECIPIENT_TOKEN_ACCOUNT) && amount >= PRICE_USDC) {
    validTransfer = true;
  }
}
```

## USDC Specifics

### Decimals

- USDC on devnet has **6 decimals**
- 1 USDC = 1,000,000 smallest units
- 0.01 USDC = 10,000 smallest units

### Token Accounts

- You need Associated Token Accounts (ATA) for each mint
- Wallets can't hold tokens directly
- Each token account is specific to one mint (USDC, USDT, etc.)

### Devnet USDC Mint

```
4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU
```

This is the official devnet USDC mint address used by the server.

## Verification Steps

The server performs 3-step verification:

### Step 1: Decode & Validate Instruction

```typescript
// Extract token transfer details
const transferAmount = ix.data.readBigUInt64LE(1);
const destAccount = ix.keys[1].pubkey;

// Verify recipient and amount
if (destAccount.equals(RECIPIENT) && transferAmount >= PRICE) {
  valid = true;
}
```

### Step 2: Simulate Transaction

```typescript
// Test execution without submitting
const simulation = await connection.simulateTransaction(tx);
if (simulation.value.err) {
  return error;
}
```

### Step 3: Submit & Verify Balance Change

```typescript
// Submit and check actual token balance changes
const signature = await connection.sendRawTransaction(txBuffer);
await connection.confirmTransaction(signature);

// Verify token balance increased
const amountReceived = postBalance - preBalance;
```

## Common Issues

### "Insufficient USDC balance"

- Get devnet USDC from: https://spl-token-faucet.com/
- Or use `spl-token mint` if you have mint authority

### "Account not found"

- No worries! The client automatically creates the recipient's token account
- You just need to have enough SOL for rent (~0.002 SOL)
- Make sure you're using devnet

### "Invalid recipient token account"

- The token account is automatically derived from the wallet address
- The client creates it automatically on first payment
- The server uses `getAssociatedTokenAddress()` to calculate it automatically

## Production Checklist

- [ ] Switch to mainnet USDC mint
- [ ] Validate token decimals
- [ ] Add token account existence checks
- [ ] Implement proper error handling for token operations
- [ ] Add amount slippage protection
- [ ] Monitor token account balances
- [ ] Handle token account rent exemption
- [ ] Add support for multiple tokens
- [ ] Implement price feeds for dynamic pricing

## Resources

- [SPL Token Documentation](https://spl.solana.com/token)
- [Devnet USDC Faucet](https://spl-token-faucet.com/)
- [Associated Token Accounts](https://spl.solana.com/associated-token-account)

---

**💡 Tip**: USDC payments are ideal for production since they're USD-pegged and widely supported!
