// Source: https://github.com/Woody4618/x402-solana-examples
// Setup script to create server's Associated Token Account
import { Connection, PublicKey, Keypair } from "@solana/web3.js";
import { getOrCreateAssociatedTokenAccount } from "@solana/spl-token";
import * as fs from "fs";

const connection = new Connection("https://api.devnet.solana.com", "confirmed");

// New USDC mint on devnet
const USDC_MINT = new PublicKey("Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr");

// Server wallet
const SERVER_WALLET = new PublicKey("seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX");

async function setupServerATA() {
  console.log("================================================================================");
  console.log("🛠️  Setup Server Associated Token Account");
  console.log("================================================================================\n");
  
  console.log("Configuration:");
  console.log("  USDC Mint:", USDC_MINT.toBase58());
  console.log("  Server Wallet:", SERVER_WALLET.toBase58());
  console.log("");
  
  // Load server keypair from server.json
  let serverKeypair: Keypair;
  try {
    const serverKeyData = JSON.parse(fs.readFileSync("./server.json", "utf-8"));
    serverKeypair = Keypair.fromSecretKey(new Uint8Array(serverKeyData));
    console.log("✅ Loaded server keypair from server.json");
  } catch (error) {
    console.error("❌ Failed to load server.json");
    console.error("   Make sure server.json exists in this directory");
    process.exit(1);
  }
  
  // Verify keypair matches server wallet
  if (serverKeypair.publicKey.toBase58() !== SERVER_WALLET.toBase58()) {
    console.error("❌ Server keypair doesn't match expected wallet address!");
    console.error("   Expected:", SERVER_WALLET.toBase58());
    console.error("   Got:", serverKeypair.publicKey.toBase58());
    process.exit(1);
  }
  
  console.log("✅ Server keypair verified\n");
  
  // Get or create the server's USDC token account
  console.log("📤 Creating server's USDC token account...");
  try {
    const tokenAccount = await getOrCreateAssociatedTokenAccount(
      connection,
      serverKeypair,  // payer (pays for account creation)
      USDC_MINT,
      SERVER_WALLET,  // owner
      false,          // allowOwnerOffCurve
      "confirmed"     // commitment
    );
    
    console.log("✅ Server token account ready!");
    console.log("   Address:", tokenAccount.address.toBase58());
    console.log("");
    
    // Check balance
    const balance = await connection.getTokenAccountBalance(tokenAccount.address);
    console.log("📊 Current balance:");
    console.log("   Amount:", balance.value.uiAmountString, "USDC");
    console.log("");
    
    console.log("================================================================================");
    console.log("✅ Setup Complete!");
    console.log("================================================================================");
    console.log("Server is ready to receive USDC payments.");
    console.log("Token Account:", tokenAccount.address.toBase58());
    console.log("================================================================================\n");
    
  } catch (error) {
    console.error("❌ Failed to create token account");
    console.error(error);
    
    if (error instanceof Error && error.message.includes("insufficient")) {
      console.log("\n💡 Solution:");
      console.log("   Server needs SOL to pay for account creation.");
      console.log("   Run: solana airdrop 1", SERVER_WALLET.toBase58(), "--url devnet");
    }
    
    process.exit(1);
  }
}

setupServerATA().catch(console.error);
