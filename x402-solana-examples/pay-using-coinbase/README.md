# x402 with Coinbase Facilitator

Pay-per-request API using Coinbase's official x402 libraries with facilitator service on Solana devnet.

[← Back to Examples](../README.md)

## Quickstart

From the project root:

```bash
npm install
```

### Terminal 1: Start the Coinbase x402 server

```bash
npm run coinbase:server
```

### Terminal 2: Run the client

```bash
npm run coinbase:client
```

## Overview

This example demonstrates x402 payments using **Coinbase's official x402 libraries** (`x402-express` and `x402-axios`) with a facilitator service.

**Key Features:**

- **Gasless Payments** - Users don't need SOL for transaction fees (facilitator pays)
- **Official Libraries** - Uses `x402-express` and `x402-axios` packages from Coinbase
- **Automatic Handling** - No manual transaction creation, signing, or verification
- **Flexible Facilitator** - Works with default facilitator (used here), Coinbase's, or your own
- **Production Ready** - Same libraries used in production systems

## Setup

### 1. Install Dependencies

```bash
cd ..  # Go to project root
npm install
```

### 2. Configure Environment (Optional)

By default, the server uses a hardcoded recipient address. To use your own address, create a `.env` file in the project root:

```bash
# Optional: Use your own recipient address for payments
RECIPIENT_ADDRESS=YOUR_SOLANA_ADDRESS_HERE

# Default if not set: seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX
```

**Note:** If you don't create a `.env` file, payments will go to the default address shown above.

### 3. Get Devnet USDC

The client wallet needs USDC for payments:

```bash
# Get your wallet address
solana address -k pay-using-coinbase/client.json

# Option 1: Use Circle's USDC faucet (easiest)
# Visit: https://faucet.circle.com/
# Select "Solana Devnet" and paste your address
```

**Important:** You typically don't need SOL in the client wallet because the facilitator pays gas fees!

### 4. Run the Example

Start the server:

```bash
npm run coinbase:server
```

You should see:

```
🚀 Starting x402 Solana Server
💰 Recipient address: seFkx...CfsRX
🌐 Network: solana-devnet
✅ Server running at http://localhost:3000
```

In another terminal, run the client:

```bash
npm run coinbase:client
```

Expected output:

```
🚀 x402 Solana Client Demo
💳 Wallet: cLYaE...FpZtG
🌐 Server: http://localhost:3000

📡 Making requests...

1️⃣  Accessing public endpoint (/)...
✅ Success (no payment required)
   Response: x402 Solana Server

2️⃣  Accessing premium endpoint (/premium)...
   💰 Payment required: $0.0001 USDC
   🔄 Creating and signing transaction...
✅ Payment successful!
   Message: 🎉 Premium content accessed!
   Secret: This is premium content
   📝 Transaction: 4eEK8...44uG
   🔗 Explorer: https://explorer.solana.com/tx/4eEK8...44uG?cluster=devnet

3️⃣  Accessing expensive endpoint (/expensive)...
   💰 Payment required: $0.001 USDC
   🔄 Creating and signing transaction...
✅ Payment successful!
   Message: 💎 Expensive content accessed!
   Secret: This is very expensive premium content
   📝 Transaction: 5fFK9...55vH
   🔗 Explorer: https://explorer.solana.com/tx/5fFK9...55vH?cluster=devnet

🎉 All requests completed successfully!
```

## How It Works

### Server Side

The server uses `x402-express` middleware that automatically:

1. **Returns 402 responses** with payment requirements
2. **Verifies transactions** via the facilitator
3. **Submits transactions** to Solana blockchain
4. **Confirms settlement** before serving content

```typescript
import { paymentMiddleware } from "x402-express";

// The middleware uses a default facilitator (can be customized - see Configuration section)
app.use(
  paymentMiddleware(RECIPIENT, {
    // Protected endpoints with different prices
    "GET /premium": {
      price: "$0.0001", // Price in USD (converted to USDC)
      network: "solana-devnet",
    },
    "GET /expensive": {
      price: "$0.001",
      network: "solana-devnet",
    },
  })
);

// Protected endpoints - only accessible after payment
app.get("/premium", (req, res) => {
  res.json({
    message: "🎉 Premium content accessed!",
    data: {
      secret: "This is premium content",
      timestamp: new Date().toISOString(),
    },
  });
});

app.get("/expensive", (req, res) => {
  res.json({
    message: "💎 Expensive content accessed!",
    data: {
      secret: "This is very expensive premium content",
      timestamp: new Date().toISOString(),
    },
  });
});
```

### Client Side

The client uses `x402-axios` interceptor that automatically:

1. **Detects 402 responses** with payment requirements
2. **Creates SPL token transfer** transactions
3. **Signs with user wallet** (but doesn't submit)
4. **Retries request** with signed transaction in `X-Payment` header

```typescript
import { withPaymentInterceptor, createSigner } from "x402-axios";

const signer = await createSigner("solana-devnet", privateKeyBase58);
const client = withPaymentInterceptor(axios.create(), signer);

// Automatically handles payment when needed!
const response = await client.get("/premium");
```

### Payment Flow

```
1. Client → Server: GET /premium
2. Server → Client: 402 Payment Required
   {
     "amount": "$0.001",
     "recipient": "seFkx...",
     "network": "solana-devnet"
   }

3. Client creates & signs transaction (doesn't submit)

4. Client → Server: GET /premium (with X-Payment header)
5. Server → Facilitator: Verify transaction
6. Facilitator: ✓ Valid transaction
7. Facilitator → Solana: Submit transaction (pays gas)
8. Solana: ✓ Transaction confirmed
9. Server → Client: 200 OK + content + transaction signature
```

## What Makes This Different

### Compared to Manual Examples (pay-in-sol, pay-in-usdc)

| Feature                      | Manual Examples      | x402 Libraries + Facilitator |
| ---------------------------- | -------------------- | ---------------------------- |
| **Transaction Creation**     | Manual code          | Automatic                    |
| **Transaction Verification** | Manual introspection | Facilitator handles          |
| **Transaction Submission**   | Server submits       | Facilitator submits          |
| **Gas Fees**                 | Payer needs SOL      | Facilitator pays             |
| **Code Complexity**          | ~200 lines           | ~90 lines (server)           |
| **Production Ready**         | Reference only       | Production grade             |

### Benefits of Using x402 Libraries with Facilitator

✅ **Gasless for Users** - Users only need USDC, no SOL required (facilitator pays gas)
✅ **Lower Complexity** - Libraries handle all transaction logic
✅ **Better UX** - Users don't worry about gas or transaction details
✅ **Flexible** - Can use default facilitator, Coinbase's, or your own
✅ **Maintained** - Official libraries receive updates

### Trade-offs

⚠️ **Third-party Dependency** - Relies on facilitator service. Facilitator can run out of funds
⚠️ **Less Control** - Fixed payment flow and verification (unless using custom facilitator)
⚠️ **Network Requirements** - Depends on facilitator service availability

## Security Features

### Facilitator Service Handles

The facilitator service (default, Coinbase, or custom) provides:

1. **Transaction Validation**

   - Verifies correct recipient and amount
   - Checks signature validity
   - Ensures transaction is well-formed

2. **Replay Protection**

   - Tracks transaction signatures
   - Prevents duplicate submissions
   - Rejects invalid transactions before submission

3. **Rate Limiting**

   - Prevents abuse of facilitator service
   - Protects against spam attacks

4. **Secure Submission**
   - Uses authenticated RPC endpoints
   - Handles transaction priority fees
   - Manages nonce and retry logic

## Configuration

### Endpoint Prices

Configure different prices for different endpoints:

```typescript
paymentMiddleware(recipient, {
  "GET /premium": {
    price: "$0.0001",
    network: "solana-devnet",
  },
  "GET /expensive": {
    price: "$0.001",
    network: "solana-devnet",
  },
  "POST /api/data": {
    price: "$0.01",
    network: "solana-devnet",
  },
});
```

### Custom Facilitator (Advanced)

**Default Behavior:** When no facilitator is specified, `x402-express` uses a built-in default facilitator that handles transaction verification and submission. This example uses the default facilitator.

**Using Coinbase's Facilitator:** You can explicitly use Coinbase's facilitator service (requires CDP API keys):

```typescript
import { facilitator } from "@coinbase/x402";

// Requires CDP_API_KEY_ID and CDP_API_KEY_SECRET in environment
app.use(paymentMiddleware(recipient, routes, facilitator));
```

**Custom Facilitator:** You can also implement your own facilitator for full control:

```typescript
const customFacilitator = {
  url: "https://your-facilitator.com",
  createAuthHeaders: async () => ({
    verify: { Authorization: "Bearer your-token" },
    settle: { Authorization: "Bearer your-token" },
    supported: { Authorization: "Bearer your-token" },
  }),
};

app.use(paymentMiddleware(recipient, routes, customFacilitator));
```

## Moving to Production (Mainnet)

### 1. Update Network

Change network from devnet to mainnet:

```typescript
"GET /premium": {
  price: "$0.0001",
  network: "solana", // mainnet
}
```

### 2. Use Real USDC

Mainnet USDC mint: `EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v`

### 3. Security Checklist

- [ ] Enable HTTPS on your server
- [ ] Set up proper logging and monitoring
- [ ] Configure rate limiting on endpoints
- [ ] Test with small amounts first
- [ ] Monitor facilitator service reliability
- [ ] Have fallback error handling
- [ ] Consider using a custom facilitator for production

## Troubleshooting

### "Failed to get supported payment kinds: Unauthorized"

**Cause:** Using Coinbase's facilitator without proper authentication

**Solution:**

This example uses the default facilitator. If you're explicitly using Coinbase's facilitator (`import { facilitator } from "@coinbase/x402"`), you'll need CDP API keys:

1. Create `.env` file with `CDP_API_KEY_ID` and `CDP_API_KEY_SECRET`
2. Get keys from https://portal.cdp.coinbase.com/
3. Ensure keys are for the correct environment (sandbox vs production)

**Alternative:** Use the default facilitator (remove the `facilitator` parameter from `paymentMiddleware`)

### "Insufficient funds" or "Account not found"

**Cause:** Client wallet doesn't have USDC

**Solution:**

```bash
# Get devnet USDC
# Visit: https://faucet.circle.com/ (select Solana Devnet)
```

### Client shows "socket hang up" or "ECONNRESET"

**Cause:** Server crashed or restarted during request

**Solution:**

1. Check server logs for errors
2. Ensure server is running: `npm run coinbase:server`
3. Verify CDP credentials are valid
4. Check network connectivity

### "Payment successful but balance didn't change"

**Cause:** Transaction succeeded but viewing wrong account

**Solution:**

```bash
# Check USDC balance (not SOL balance!)
spl-token balance 4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU \
  --url devnet \
  --owner <YOUR_WALLET_ADDRESS>
```

**Solution:**

- Implement client-side rate limiting
- Add delays between test requests
- If using Coinbase facilitator: Check CDP dashboard for limits
- Consider implementing your own facilitator for higher limits
- Add retry logic with exponential backoff

## Resources

- **x402 Specification:** https://x402.org
- **Coinbase x402 GitHub:** https://github.com/coinbase/x402
- **CDP Portal:** https://portal.cdp.coinbase.com/
- **Solana Explorer (Devnet):** https://explorer.solana.com/?cluster=devnet
- **USDC Devnet Faucet:** https://faucet.circle.com/

## Why Use x402 Libraries with Facilitator?

### Best For:

- **Production applications** requiring reliability and gasless payments
- **Consumer-facing apps** where users shouldn't worry about gas fees
- **Quick prototypes** needing minimal setup
- **Projects** that benefit from managed transaction submission
- **Teams** wanting to focus on business logic, not payment infrastructure

### Consider Manual Implementation If:

- Need full control over transaction flow and verification
- Want to minimize external dependencies
- Have specific verification requirements
- Running on networks the facilitator doesn't support
- Want to understand x402 internals deeply

---

**Ready to build?** This example works out of the box with the default facilitator! 🚀
