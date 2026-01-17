// Source: https://github.com/Woody4618/x402-solana-examples
// x402-compliant server with USDC (SPL Token) payments
import express from "express";
import { Connection, PublicKey, Transaction } from "@solana/web3.js";
import { TOKEN_PROGRAM_ID, getAssociatedTokenAddress } from "@solana/spl-token";

const connection = new Connection("https://api.devnet.solana.com", "confirmed");

// Devnet USDC mint address (correct one)
const USDC_MINT = new PublicKey("Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr"); // USD Coin-Dev
// const USDC_MINT = new PublicKey("4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU");

// Your recipient wallet address (same as SOL example)
const RECIPIENT_WALLET = new PublicKey(
  "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX"
);

// Derive the recipient's USDC token account (Associated Token Account)
const RECIPIENT_TOKEN_ACCOUNT = await getAssociatedTokenAddress(
  USDC_MINT,
  RECIPIENT_WALLET
);

console.log("================================================================================");
console.log("🚀 X402 USDC Payment Server Configuration");
console.log("================================================================================");
console.log("USDC Mint:", USDC_MINT.toBase58());
console.log("Recipient Wallet:", RECIPIENT_WALLET.toBase58());
console.log("Recipient Token Account:", RECIPIENT_TOKEN_ACCOUNT.toBase58());
console.log("Price: 0.01 USDC");
console.log("================================================================================\n");

// Price: 0.01 USDC (USDC has 6 decimals on devnet)
const PRICE_USDC = 100; // 0.01 USDC = 10,000 in smallest units

const app = express();
app.use(express.json());

// x402 endpoint - Quote or verify payment
app.get("/premium", async (req, res) => {
  const xPaymentHeader = req.header("X-Payment");

  // If client provided X-Payment header, verify and submit transaction
  if (xPaymentHeader) {
    try {
      // Decode base64 and parse JSON (x402 standard)
      const paymentData = JSON.parse(
        Buffer.from(xPaymentHeader, "base64").toString("utf-8")
      ) as {
        x402Version: number;
        scheme: string;
        network: string;
        payload: {
          serializedTransaction: string;
        };
      };

      console.log("Received USDC payment proof from client");
      console.log(`  Network: ${paymentData.network}`);

      // Deserialize the transaction
      const txBuffer = Buffer.from(
        paymentData.payload.serializedTransaction,
        "base64"
      );
      const tx = Transaction.from(txBuffer);

      console.log("Verifying SPL Token transfer instructions...");

      // Step 1: Introspect and decode SPL Token transfer instruction
      const instructions = tx.instructions;
      let validTransfer = false;
      let transferAmount = 0;

      for (const ix of instructions) {
        // Check if this is a Token Program instruction
        if (ix.programId.equals(TOKEN_PROGRAM_ID)) {
          // SPL Token Transfer instruction layout:
          // [0] = instruction type (3 for Transfer)
          // [1-8] = amount (u64, little-endian)
          if (ix.data.length >= 9 && ix.data[0] === 3) {
            // Read the amount (u64 in little-endian, starts at byte 1)
            transferAmount = Number(ix.data.readBigUInt64LE(1));

            // Verify accounts: [source, destination, owner]
            if (ix.keys.length >= 2) {
              const destAccount = ix.keys[1].pubkey;
              if (
                destAccount.equals(RECIPIENT_TOKEN_ACCOUNT) &&
                transferAmount >= PRICE_USDC
              ) {
                validTransfer = true;
                console.log(
                  `  ✓ Valid USDC transfer: ${transferAmount / 1000000} USDC`
                );
                console.log(`    To: ${RECIPIENT_TOKEN_ACCOUNT.toBase58()}`);
                break;
              }
            }
          }
        }
      }

      if (!validTransfer) {
        return res.status(402).json({
          error:
            "Transaction does not contain valid USDC transfer to recipient with correct amount",
          details:
            transferAmount > 0
              ? `Found transfer of ${transferAmount}, expected ${PRICE_USDC}`
              : "No valid token transfer instruction found",
        });
      }

      // Step 2: Simulate the transaction BEFORE submitting
      console.log("Simulating transaction...");
      try {
        const simulation = await connection.simulateTransaction(tx);

        if (simulation.value.err) {
          console.error("Simulation failed:", simulation.value.err);
          return res.status(402).json({
            error: "Transaction simulation failed",
            details: simulation.value.err,
            logs: simulation.value.logs,
          });
        }

        console.log("  ✓ Simulation successful");
      } catch (simError) {
        console.error("Simulation error:", simError);
        return res.status(402).json({
          error: "Failed to simulate transaction",
          details:
            simError instanceof Error ? simError.message : "Unknown error",
        });
      }

      // Step 3: Submit the transaction (only if verified and simulated successfully)
      // Note: Solana blockchain automatically rejects duplicate transaction signatures
      console.log("Submitting transaction to network...");

      const signature = await connection.sendRawTransaction(txBuffer, {
        skipPreflight: false,
        preflightCommitment: "confirmed",
      });

      console.log(`Transaction submitted: ${signature}`);

      // Wait for confirmation
      const confirmation = await connection.confirmTransaction(
        signature,
        "confirmed"
      );

      if (confirmation.value.err) {
        return res.status(402).json({
          error: "Transaction failed on-chain",
          details: confirmation.value.err,
        });
      }

      // Fetch the transaction to verify payment details
      const confirmedTx = await connection.getTransaction(signature, {
        commitment: "confirmed",
        maxSupportedTransactionVersion: 0,
      });

      if (!confirmedTx) {
        return res.status(402).json({
          error: "Could not fetch confirmed transaction",
        });
      }

      // Verify token balance changes from transaction metadata
      const postTokenBalances = confirmedTx.meta?.postTokenBalances ?? [];
      const preTokenBalances = confirmedTx.meta?.preTokenBalances ?? [];

      // Find the recipient's token account in the balance changes
      let amountReceived = 0;
      for (let i = 0; i < postTokenBalances.length; i++) {
        const postBal = postTokenBalances[i];
        const preBal = preTokenBalances.find(
          (pre) => pre.accountIndex === postBal.accountIndex
        );

        // Check if this is the recipient's account
        const accountKey =
          confirmedTx.transaction.message.staticAccountKeys[
            postBal.accountIndex
          ];
        if (accountKey && accountKey.equals(RECIPIENT_TOKEN_ACCOUNT)) {
          const postAmount = postBal.uiTokenAmount.amount;
          const preAmount = preBal?.uiTokenAmount.amount ?? "0";
          amountReceived = Number(postAmount) - Number(preAmount);
          break;
        }
      }

      if (amountReceived < PRICE_USDC) {
        return res.status(402).json({
          error: `Insufficient payment: received ${amountReceived}, expected ${PRICE_USDC}`,
        });
      }

      console.log(
        `Payment verified: ${amountReceived / 1000000} USDC received`
      );
      console.log(
        `View transaction: https://explorer.solana.com/tx/${signature}?cluster=devnet`
      );

      // Payment verified! Return premium content
      return res.json({
        data: "Premium content - USDC payment verified!",
        paymentDetails: {
          signature,
          amount: amountReceived,
          amountUSDC: amountReceived / 1000000,
          recipient: RECIPIENT_TOKEN_ACCOUNT.toBase58(),
          explorerUrl: `https://explorer.solana.com/tx/${signature}?cluster=devnet`,
        },
      });
    } catch (e) {
      console.error("Payment verification error:", e);
      return res.status(402).json({
        error: "Payment verification failed",
        details: e instanceof Error ? e.message : "Unknown error",
      });
    }
  }

  // No payment provided - return 402 with payment details
  console.log("New USDC payment quote requested");

  return res.status(402).json({
    payment: {
      recipientWallet: RECIPIENT_WALLET.toBase58(),
      tokenAccount: RECIPIENT_TOKEN_ACCOUNT.toBase58(),
      mint: USDC_MINT.toBase58(),
      amount: PRICE_USDC,
      amountUSDC: PRICE_USDC / 1000000,
      cluster: "devnet",
      message: "Send USDC to the token account",
    },
  });
});

app.listen(3001, () => {
  console.log("================================================================================");
  console.log("✅ x402 USDC server listening on http://localhost:3001");
  console.log("================================================================================");
  console.log("Ready to accept payments!");
  console.log("Endpoint: GET /premium");
  console.log("================================================================================\n");
});
