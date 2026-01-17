// Source: https://github.com/Woody4618/x402-solana-examples
import { Connection, Keypair, PublicKey, Transaction } from "@solana/web3.js";
import {
  createTransferInstruction,
  getOrCreateAssociatedTokenAccount,
  createAssociatedTokenAccountInstruction,
  getAccount,
} from "@solana/spl-token";
import fetch from "node-fetch";
import { readFileSync } from "fs";

const connection = new Connection("https://api.devnet.solana.com", "confirmed");

const keypairData = JSON.parse(
  readFileSync("./pay-in-usdc/client.json", "utf-8")
);
const payer = Keypair.fromSecretKey(Uint8Array.from(keypairData));

async function run() {
  // 1) Request payment quote from server
  const quote = await fetch("http://localhost:3001/premium");
  const q = (await quote.json()) as {
    payment: {
      tokenAccount: string;
      mint: string;
      amount: number;
      amountUSDC: number;
      cluster: string;
    };
  };
  if (quote.status !== 402) throw new Error("Expected 402 quote");

  const recipientTokenAccount = new PublicKey(q.payment.tokenAccount);
  const mint = new PublicKey(q.payment.mint);
  const amount = q.payment.amount;

  console.log("USDC Payment required:");
  console.log(`  Recipient Token Account: ${q.payment.tokenAccount}`);
  console.log(`  Mint (USDC): ${q.payment.mint}`);
  console.log(
    `  Amount: ${q.payment.amountUSDC} USDC (${amount} smallest units)`
  );

  // 2) Get or create the payer's associated token account
  console.log("\nChecking/creating associated token account...");
  const payerTokenAccount = await getOrCreateAssociatedTokenAccount(
    connection,
    payer,
    mint,
    payer.publicKey
  );

  console.log(`  Payer Token Account: ${payerTokenAccount.address.toBase58()}`);

  // Check if payer has enough USDC
  const balance = await connection.getTokenAccountBalance(
    payerTokenAccount.address
  );
  console.log(`  Current Balance: ${balance.value.uiAmountString} USDC`);

  if (Number(balance.value.amount) < amount) {
    throw new Error(
      `Insufficient USDC balance. Have: ${balance.value.uiAmountString}, Need: ${q.payment.amountUSDC}`
    );
  }

  // 3) Check if recipient token account exists, create if not
  console.log("\nChecking recipient token account...");
  let recipientAccountExists = false;
  try {
    await getAccount(connection, recipientTokenAccount);
    recipientAccountExists = true;
    console.log("  ✓ Recipient token account exists");
  } catch (error) {
    console.log("  ⚠ Recipient token account doesn't exist, will create it");
  }

  // 4) Create USDC transfer transaction (but DON'T submit it)
  const { blockhash } = await connection.getLatestBlockhash();
  const tx = new Transaction({
    feePayer: payer.publicKey,
    blockhash,
    lastValidBlockHeight: (await connection.getLatestBlockhash())
      .lastValidBlockHeight,
  });

  // Add create account instruction if needed
  if (!recipientAccountExists) {
    // We need to know the recipient wallet address to create the ATA
    // The server should provide this, so let's get it from the wallet address
    // For now, we'll derive it from the known wallet
    const recipientWallet = new PublicKey(
      "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX"
    );

    const createAccountIx = createAssociatedTokenAccountInstruction(
      payer.publicKey, // payer
      recipientTokenAccount, // associated token account address
      recipientWallet, // owner
      mint // mint
    );

    // Print raw instruction data
    console.log("\n=== createAccountIx Raw Data ===");
    console.log("Program ID:", createAccountIx.programId.toBase58());
    console.log("Keys:", createAccountIx.keys.map(k => ({
      pubkey: k.pubkey.toBase58(),
      isSigner: k.isSigner,
      isWritable: k.isWritable
    })));
    console.log("Data (hex):", createAccountIx.data.toString('hex'));
    console.log("Data (base64):", createAccountIx.data.toString('base64'));
    console.log("Data (buffer):", createAccountIx.data);
    console.log("================================\n");

    tx.add(createAccountIx);
    console.log("  + Added create token account instruction");
  }

  // Add transfer instruction
  const transferIx = createTransferInstruction(
    payerTokenAccount.address, // source
    recipientTokenAccount, // destination
    payer.publicKey, // owner
    amount // amount in smallest units
  );

  tx.add(transferIx);

  // Sign the transaction (but don't send it!)
  tx.sign(payer);

  // Serialize the signed transaction
  const serializedTx = tx.serialize().toString("base64");

  console.log("\nTransaction created and signed (not submitted yet)");
  console.log(`  Instructions: ${tx.instructions.length}`);

  // 4) Send X-Payment header with serialized transaction (x402 standard)
  const paymentProof = {
    x402Version: 1,
    scheme: "exact",
    network:
      q.payment.cluster === "devnet" ? "solana-devnet" : "solana-mainnet",
    payload: {
      serializedTransaction: serializedTx,
    },
  };

  // Base64 encode the payment proof
  const xPaymentHeader = Buffer.from(JSON.stringify(paymentProof)).toString(
    "base64"
  );

  console.log(
    "\nSending payment proof to server (server will submit transaction)..."
  );
  const paid = await fetch("http://localhost:3001/premium", {
    headers: {
      "X-Payment": xPaymentHeader,
    },
  });

  const result = (await paid.json()) as {
    data?: string;
    error?: string;
    paymentDetails?: {
      signature: string;
      amount: number;
      amountUSDC: number;
      recipient: string;
      explorerUrl: string;
    };
  };

  console.log("\nServer response:");
  console.log(result);

  // Display explorer link if payment was successful
  if (result.paymentDetails?.explorerUrl) {
    console.log("\n🔗 View transaction on Solana Explorer:");
    console.log(result.paymentDetails.explorerUrl);
  }
}

run().catch(console.error);
