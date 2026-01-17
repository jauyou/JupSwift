// Source: https://github.com/Woody4618/x402-solana-examples
// x402-compliant server implementation
// Server receives signed transaction, verifies it, and submits it
import express from "express";
import { Connection, PublicKey, Transaction } from "@solana/web3.js";

const connection = new Connection("https://api.devnet.solana.com", "confirmed");
const RECIPIENT = new PublicKey(
  "seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX"
);
const PRICE_LAMPORTS = 100000; // 0.0001 SOL

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

      console.log("Received payment proof from client");
      console.log(`  Network: ${paymentData.network}`);

      // Deserialize the transaction
      const txBuffer = Buffer.from(
        paymentData.payload.serializedTransaction,
        "base64"
      );
      const tx = Transaction.from(txBuffer);

      console.log("Verifying transaction instructions...");

      // Step 1: Introspect and decode instructions to verify transfer details
      const instructions = tx.instructions;
      let validTransfer = false;
      let transferAmount = 0;

      for (const ix of instructions) {
        // Check if this is a SystemProgram transfer
        const SYSTEM_PROGRAM = new PublicKey(
          "11111111111111111111111111111111"
        );
        if (ix.programId.equals(SYSTEM_PROGRAM)) {
          // Decode the instruction data
          // SystemProgram.transfer has instruction type 2
          // Layout: [u32 instruction_type, u64 lamports]
          if (ix.data.length === 12 && ix.data[0] === 2) {
            // Read the amount (u64 in little-endian, starts at byte 4)
            transferAmount = Number(ix.data.readBigUInt64LE(4));

            // Verify accounts: [from, to]
            if (ix.keys.length >= 2) {
              const toAccount = ix.keys[1].pubkey;
              if (
                toAccount.equals(RECIPIENT) &&
                transferAmount >= PRICE_LAMPORTS
              ) {
                validTransfer = true;
                console.log(
                  `  ✓ Valid transfer: ${transferAmount} lamports to ${RECIPIENT.toBase58()}`
                );
                break;
              }
            }
          }
        }
      }

      if (!validTransfer) {
        return res.status(402).json({
          error:
            "Transaction does not contain valid transfer to recipient with correct amount",
          details:
            transferAmount > 0
              ? `Found transfer of ${transferAmount} lamports, expected ${PRICE_LAMPORTS}`
              : "No valid transfer instruction found",
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
      });

      if (!confirmedTx) {
        return res.status(402).json({
          error: "Could not fetch confirmed transaction",
        });
      }

      // Verify payment amount
      const preBalances = confirmedTx.meta?.preBalances ?? [];
      const postBalances = confirmedTx.meta?.postBalances ?? [];
      const txAccountKeys = confirmedTx.transaction.message.accountKeys;
      const recipientIndex = txAccountKeys.findIndex((key) =>
        key.equals(RECIPIENT)
      );

      if (recipientIndex === -1) {
        return res.status(402).json({
          error: "Recipient not found in confirmed transaction",
        });
      }

      const amountReceived =
        postBalances[recipientIndex] - preBalances[recipientIndex];

      if (amountReceived < PRICE_LAMPORTS) {
        return res.status(402).json({
          error: `Insufficient payment: received ${amountReceived}, expected ${PRICE_LAMPORTS}`,
        });
      }

      console.log(`Payment verified: ${amountReceived} lamports received`);
      console.log(
        `View transaction: https://explorer.solana.com/tx/${signature}?cluster=devnet`
      );

      // Payment verified! Return premium content
      return res.json({
        data: "Premium content - payment verified!",
        paymentDetails: {
          signature,
          amount: amountReceived,
          recipient: RECIPIENT.toBase58(),
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
  console.log("New payment quote requested");

  return res.status(402).json({
    payment: {
      recipient: RECIPIENT.toBase58(),
      amount: PRICE_LAMPORTS,
      cluster: "devnet",
    },
  });
});

app.listen(3000, () => console.log("x402 server listening on :3000"));
