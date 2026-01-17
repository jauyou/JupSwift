// Source: https://github.com/Woody4618/x402-solana-examples
import { Keypair } from "@solana/web3.js";
import fs from "fs";
import bs58 from "bs58";

// 1️⃣ 讀取 keypair JSON 檔案
const secret = JSON.parse(fs.readFileSync("pay-in-usdc/client.json", "utf-8"));

// 2️⃣ 建立 Solana Keypair
const keypair = Keypair.fromSecretKey(Uint8Array.from(secret));

// 3️⃣ 輸出結果
console.log("✅ Private key (base58):", bs58.encode(keypair.secretKey));
console.log("✅ Public key:", keypair.publicKey.toBase58());

