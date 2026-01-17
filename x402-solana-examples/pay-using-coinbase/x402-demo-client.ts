// Source: https://github.com/Woody4618/x402-solana-examples
/**
 * x402 Compliant Solana Client
 *
 * This client automatically handles x402 payment flow:
 * 1. Receives 402 response with payment requirements
 * 2. Creates SPL token transfer transaction
 * 3. Signs transaction (but doesn't submit)
 * 4. Sends to server in X-Payment header
 * 5. Server's facilitator submits transaction
 * 6. Returns content + transaction signature
 *
 * Setup:
 * 1. npm install axios x402-axios @solana/web3.js
 * 2. Create client.json keypair: solana-keygen new --outfile pay-using-coinbase/client.json
 * 3. npm install -D tsx
 * 4. Make sure you have devnet USDC in your wallet
 * 5. Run: tsx pay-using-coinbase/x402-demo-client.ts
 *
 * Get devnet USDC:
 * - Airdrop SOL: solana airdrop 1 <your-address> --url devnet
 * - Get USDC: https://faucet.circle.com/ (select Solana Devnet)
 */

import axios from "axios";
import { withPaymentInterceptor, createSigner } from "x402-axios";
import { readFileSync } from "fs";
import bs58 from "bs58";

const SERVER_URL = "http://localhost:3000";

// Load your Solana wallet from client.json
function loadWallet(): { privateKeyBase58: string; publicKey: string } {
  try {
    const keypairData = JSON.parse(
      readFileSync("./pay-using-coinbase/client.json", "utf-8")
    );
    const secretKey = Uint8Array.from(keypairData);
    const privateKeyBase58 = bs58.encode(secretKey);

    // Derive public key from secret key (last 32 bytes are the public key in Solana keypairs)
    const publicKeyBytes = secretKey.slice(32, 64);
    const publicKey = bs58.encode(publicKeyBytes);

    return { privateKeyBase58, publicKey };
  } catch (error) {
    console.error("❌ Error: Could not load client.json");
    console.log("\n💡 To generate a keypair:");
    console.log(
      "   solana-keygen new --outfile pay-using-coinbase/client.json"
    );
    console.log("\n   Or use the Solana CLI:");
    console.log("   solana-keygen grind --starts-with c:1");
    process.exit(1);
  }
}

async function main() {
  const wallet = loadWallet();

  console.log("🚀 x402 Solana Client Demo");
  console.log(`💳 Wallet: ${wallet.publicKey}`);
  console.log(`🌐 Server: ${SERVER_URL}\n`);

  // Create a signer from the Solana keypair
  const signer = await createSigner("solana-devnet", wallet.privateKeyBase58);

  // Create axios client with x402 payment interceptor
  // This interceptor automatically handles 402 responses:
  // - Parses payment requirements
  // - Creates SPL token transfer transaction
  // - Signs it with your wallet
  // - Retries the request with X-Payment header
  const client = withPaymentInterceptor(
    axios.create({ baseURL: SERVER_URL }),
    signer
  );

  try {
    console.log("📡 Making requests...\n");

    // 1. Public endpoint (no payment)
    console.log("1️⃣  Accessing public endpoint (/)...");
    const publicResponse = await client.get("/");
    console.log("✅ Success (no payment required)");
    console.log(`   Response: ${publicResponse.data.message}\n`);

    // 2. Premium endpoint ($0.001 USDC payment)
    console.log("2️⃣  Accessing premium endpoint (/premium)...");
    console.log("   💰 Payment required: $0.001 USDC");
    console.log("   🔄 Creating and signing transaction...");

    const premiumResponse = await client.get("/premium");

    console.log("✅ Payment successful!");
    console.log(`   Message: ${premiumResponse.data.message}`);
    console.log(`   Secret: ${premiumResponse.data.data.secret}`);

    // Extract transaction signature from response header
    const paymentResponse = premiumResponse.headers["x-payment-response"];
    if (paymentResponse) {
      const decoded = JSON.parse(
        Buffer.from(paymentResponse, "base64").toString("utf-8")
      );
      console.log(`   📝 Transaction: ${decoded.transaction}`);
      console.log(
        `   🔗 Explorer: https://explorer.solana.com/tx/${decoded.transaction}?cluster=devnet\n`
      );
    }

    // 3. Expensive endpoint ($0.01 USDC payment)
    console.log("3️⃣  Accessing expensive endpoint (/expensive)...");
    console.log("   💰 Payment required: $0.01 USDC");
    console.log("   🔄 Creating and signing transaction...");

    const expensiveResponse = await client.get("/expensive");

    console.log("✅ Payment successful!");
    console.log(`   Message: ${expensiveResponse.data.message}`);
    console.log(`   Secret: ${expensiveResponse.data.data.secret}`);

    const expensivePaymentResponse =
      expensiveResponse.headers["x-payment-response"];
    if (expensivePaymentResponse) {
      const decoded = JSON.parse(
        Buffer.from(expensivePaymentResponse, "base64").toString("utf-8")
      );
      console.log(`   📝 Transaction: ${decoded.transaction}`);
      console.log(
        `   🔗 Explorer: https://explorer.solana.com/tx/${decoded.transaction}?cluster=devnet\n`
      );
    }

    console.log("🎉 All requests completed successfully!");
  } catch (error) {
    if (axios.isAxiosError(error)) {
      console.error("\n❌ Request failed:");
      console.error(`   Status: ${error.response?.status}`);
      console.error(
        `   Message: ${JSON.stringify(error.response?.data, null, 2)}`
      );
      console.error(`   Error message: ${error.message}`);

      if (error.code) {
        console.error(`   Error code: ${error.code}`);
      }

      if (error.response?.status === 402) {
        console.log("\n💡 Common issues:");
        console.log("   - Insufficient USDC balance in wallet");
        console.log("   - No SOL for gas fees (though facilitator should pay)");
        console.log("   - Get devnet USDC: https://faucet.circle.com/");
        console.log(
          "   - Get devnet SOL: solana airdrop 1 <address> --url devnet"
        );
      }
    } else {
      console.error("\n❌ Unexpected error:", error);
    }
    process.exit(1);
  }
}

// Run the main function
main().catch(console.error);
