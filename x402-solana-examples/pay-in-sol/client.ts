// Source: https://github.com/Woody4618/x402-solana-examples
import {
  Connection,
  Keypair,
  PublicKey,
  SystemProgram,
  Transaction,
} from "@solana/web3.js";
import fetch from "node-fetch";
import { readFileSync } from "fs";

const connection = new Connection("https://api.devnet.solana.com", "confirmed");

const keypairData = JSON.parse(
  readFileSync("./pay-in-sol/client.json", "utf-8")
);
const payer = Keypair.fromSecretKey(Uint8Array.from(keypairData));

async function run() {
  // 1) Request payment quote from server
  const quote = await fetch("http://localhost:3000/premium");
  const q = (await quote.json()) as {
    payment: {
      recipient: string;
      amount: number;
      cluster: string;
    };
  };
  if (quote.status !== 402) throw new Error("Expected 402 quote");

  const recipient = new PublicKey(q.payment.recipient);
  const amount = q.payment.amount; // lamports

  console.log("Payment required:");
  console.log(`  Recipient: ${q.payment.recipient}`);
  console.log(`  Amount: ${amount} lamports`);

  // 2) Create transaction (but DON'T submit it)
  const ix = SystemProgram.transfer({
    fromPubkey: payer.publicKey,
    toPubkey: recipient,
    lamports: amount,
  });

  // Get recent blockhash
  const { blockhash } = await connection.getLatestBlockhash();
  const tx = new Transaction({
    feePayer: payer.publicKey,
    blockhash,
    lastValidBlockHeight: (await connection.getLatestBlockhash())
      .lastValidBlockHeight,
  }).add(ix);

  // Sign the transaction (but don't send it!)
  tx.sign(payer);

  // Serialize the signed transaction
  const serializedTx = tx.serialize().toString("base64");

  console.log("\nTransaction created and signed (not submitted yet)");

  // 3) Send X-Payment header with serialized transaction (x402 standard)
  const paymentProof = {
    x402Version: 1,
    scheme: "exact",
    network:
      q.payment.cluster === "devnet" ? "solana-devnet" : "solana-mainnet",
    payload: {
      serializedTransaction: serializedTx, // Signed but unsubmitted transaction
    },
  };

  // Base64 encode the payment proof
  const xPaymentHeader = Buffer.from(JSON.stringify(paymentProof)).toString(
    "base64"
  );

  console.log(
    "\nSending payment proof to server (server will submit transaction)..."
  );
  const paid = await fetch("http://localhost:3000/premium", {
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
      recipient: string;
      reference: string;
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
