# x402 Solana Examples

A collection of minimal x402 (HTTP 402 Payment Required) implementations using Solana blockchain.

## What is x402?

x402 is an open payments standard that integrates micropayments directly into HTTP using the 402 "Payment Required" status code. These examples show how to implement x402 with Solana blockchain for payment verification.

## Examples

There are 3 examples in this project:

1. Pay in SOL
2. Pay in USDC
3. Pay with Coinbase Facilitator

Each example has its own README with detailed instructions on how to run the example.

## Running

From the project root:

### 💰 [Pay in SOL](./pay-in-sol/)

Basic x402 implementation using native SOL tokens.

**Features:**

- Client signs, server submits transactions
- 3-step verification: Introspect → Simulate → Submit
- Blockchain-native replay protection
- Minimal payload (just serialized transaction)

**Quick Start:**

```bash
# Terminal 1: Start server
npm run sol:server

# Terminal 2: Run client
npm run sol:client
```

[📖 Full Documentation →](./pay-in-sol/README.md)

---

### 🪙 [Pay in USDC](./pay-in-usdc/)

x402 implementation using USDC (SPL Token) on devnet.

**Features:**

- SPL Token transfer verification
- USD-denominated pricing (0.01 USDC)
- Automatic token account creation
- Decimal handling (6 decimals)

**Quick Start:**

```bash
# Terminal 1: Start server
npm run usdc:server

# Terminal 2: Run client (requires devnet USDC)
npm run usdc:client
```

[📖 Full Documentation →](./pay-in-usdc/README.md)

---

### 🏦 [Pay with Coinbase Facilitator](./pay-using-coinbase/)

x402 implementation using Coinbase's official libraries and facilitator service.

**Features:**

- **Gasless payments** - Users don't need SOL for fees (Until they maybe run out of funds)
- Official `x402-express` and `x402-axios` libraries
- Production-ready infrastructure
- Automatic transaction handling
- Minimal code (~50 lines per side)

**Quick Start:**

```bash
# Terminal 1: Start server
npm run coinbase:server

# Terminal 2: Run client (requires devnet USDC)
npm run coinbase:client
```

[📖 Full Documentation →](./pay-using-coinbase/README.md)

---

### ⚡ Pay with Blinks _(Coming Soon)_

x402 implementation using Solana Actions (Blinks).

**Features:**

- QR code payments
- Mobile wallet support
- Deep linking

---

## Key Concepts

### How x402 Works

1. **Client requests** a resource
2. **Server responds** with `402 Payment Required` and payment details
3. **Client creates and signs** a transaction (doesn't submit it)
4. **Client sends** the signed transaction in `X-Payment` header
5. **Server verifies and submits** the transaction to blockchain
6. **Server confirms** payment and grants access to the resource

### Why Solana?

- ⚡ **Fast**: Sub-second finality
- 💰 **Cheap**: Fractions of a cent per transaction
- 🔒 **Secure**: Built-in replay protection
- 🌍 **Global**: Permissionless and borderless

## Project Structure

```
402-minimal/
├── README.md              # This file
├── package.json           # Shared dependencies
├── tsconfig.json          # TypeScript config
│
├── pay-in-sol/           # Native SOL payments
│   ├── README.md
│   ├── server.ts
│   ├── client.ts
│   └── client.json
│
├── pay-in-usdc/          # SPL Token (USDC) payments
│   ├── README.md
│   ├── server.ts
│   ├── client.ts
│   └── client.json
│
├── pay-using-coinbase/   # Coinbase facilitator integration
│   ├── README.md
│   ├── x402-demo-server.ts
│   ├── x402-demo-client.ts
│   └── client.json
│
└── pay-with-blinks/      # Blinks example (coming soon)
    └── ...
```

## Prerequisites

- Node.js 18+
- Solana CLI (for devnet testing)
- Basic understanding of Solana transactions

## Development

Each example is self-contained with its own README and can be run independently using npm scripts:

```bash
# SOL payments
npm run sol:server    # Start SOL payment server
npm run sol:client    # Run SOL payment client

# USDC payments
npm run usdc:server   # Start USDC payment server
npm run usdc:client   # Run USDC payment client

# Coinbase facilitator
npm run coinbase:server   # Start Coinbase x402 server
npm run coinbase:client   # Run Coinbase x402 client
```

## Resources

- [x402 Specification](https://x402.org)
- [Coinbase x402 GitHub](https://github.com/coinbase/x402)
- [Solana Documentation](https://docs.solana.com)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

---

**Built with ❤️ for the Solana ecosystem**
