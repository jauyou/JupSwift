//
//  X402PaymentProtocol.swift
//  JupSwift
//
//  Unified implementation of X402 Payment Protocol for Solana
//  Supports SOL and any SPL Token through configuration
//  https://x402.org
//
//  Created by Zhao You on 8/11/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Configuration

/// X402 Payment configuration
public struct X402PaymentConfig: Sendable {
    /// Server base URL
    public let serverUrl: String
    
    /// Solana network identifier (e.g., "solana-devnet", "solana-mainnet")
    public let network: String
    
    public init(
        serverUrl: String,
        network: String = "solana-devnet"
    ) {
        self.serverUrl = serverUrl
        self.network = network
    }
    
    /// Convenience initializer with SolanaCluster
    public init(
        serverUrl: String,
        cluster: SolanaCluster
    ) {
        self.serverUrl = serverUrl
        switch cluster {
        case .mainnet:
            self.network = "solana-mainnet"
        case .testnet:
            self.network = "solana-testnet"
        default:
            self.network = "solana-devnet"
        }
    }
}

// MARK: - Protocol Structures

/// X402 Payment Quote returned by server (402 status)
public struct X402PaymentQuote: Codable {
    public let payment: PaymentDetails
    
    public struct PaymentDetails: Codable {
        // For SOL payments
        public let recipient: String?
        public let amount: Int?
        
        // For SPL Token payments
        public let tokenAccount: String?
        public let mint: String?
        public let amountUSDC: Double?
        
        // Common fields
        public let cluster: String
    }
}

/// X402 Payment Proof sent to server in X-Payment header
public struct X402PaymentProof: Codable {
    public let x402Version: Int
    public let scheme: String
    public let network: String
    public let payload: Payload
    
    public struct Payload: Codable {
        public let serializedTransaction: String
    }
    
    public init(network: String, serializedTransaction: String) {
        self.x402Version = 1
        self.scheme = "exact"
        self.network = network
        self.payload = Payload(serializedTransaction: serializedTransaction)
    }
}

/// X402 Payment Response from server after verification
public struct X402PaymentResponse: Codable {
    public let data: String?
    public let error: String?
    public let paymentDetails: PaymentDetails?
    
    public struct PaymentDetails: Codable {
        public let signature: String
        public let amount: Int
        public let amountUSDC: Double?
        public let recipient: String
        public let reference: String?
        public let explorerUrl: String
    }
}

// MARK: - X402 Payment Client

/// X402 Payment Protocol Client
/// 
/// This client provides two usage patterns:
/// 
/// **Pattern 1: High-level API (Recommended)**
/// - Use `payForContent()` for complete payment flow with automatic ATA management
/// 
/// **Pattern 2: Low-level API (Advanced)**
/// - Step 1: `requestPaymentQuote()` to get payment details
/// - Step 2-3: Manual transaction creation using SolanaSplToken utilities
/// - Step 4: `sendPaymentProof()` to submit payment
public class X402PaymentClient {
    
    private let config: X402PaymentConfig
    private let connection: SolanaConnection
    
    /// Initialize X402 Payment Client
    /// - Parameters:
    ///   - config: Payment configuration (server URL and network)
    ///   - connection: Solana RPC connection
    public init(config: X402PaymentConfig, connection: SolanaConnection) {
        self.config = config
        self.connection = connection
    }
    
    /// Convenience initializer
    /// - Parameters:
    ///   - serverUrl: X402 server URL
    ///   - network: Network identifier (default: "solana-devnet")
    ///   - cluster: Solana cluster (default: .devnet)
    public convenience init(
        serverUrl: String,
        network: String = "solana-devnet",
        cluster: SolanaCluster = .devnet
    ) {
        let config = X402PaymentConfig(serverUrl: serverUrl, network: network)
        let connection = SolanaConnection(cluster: cluster)
        self.init(config: config, connection: connection)
    }
    
    // MARK: - Step 1: Request Payment Quote
    
    /// Request payment quote from server (Low-level API)
    /// 
    /// Use this for manual transaction creation.
    /// For automatic payment flow, use `payForContent()` instead.
    /// 
    /// - Parameter endpoint: API endpoint (e.g., "/premium")
    /// - Returns: Payment quote with recipient and amount
    public func requestPaymentQuote(endpoint: String) async throws -> X402PaymentQuote {
        let url = URL(string: "\(config.serverUrl)\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw X402Error.invalidResponse
        }
        
        // Expect 402 Payment Required
        guard httpResponse.statusCode == 402 else {
            throw X402Error.unexpectedStatusCode(httpResponse.statusCode)
        }
        
        let quote = try JSONDecoder().decode(X402PaymentQuote.self, from: data)
        return quote
    }
    
    // MARK: - High-level API: Complete Payment Flow
    
    /// Complete payment flow with automatic ATA management
    /// 
    /// This method handles the entire X402 payment process:
    /// 1. Request payment quote from server
    /// 2. Get or create payer's associated token account
    /// 3. Check if recipient token account exists, create if not
    /// 4. Create and sign transaction
    /// 5. Send payment proof to server
    /// 
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/premium")
    ///   - payer: Keypair for signing the transaction
    /// - Returns: Payment response with content and transaction details
    public func payForContent(
        endpoint: String,
        payer: Keypair
    ) async throws -> X402PaymentResponse {
        // Step 1: Request payment quote
        print("📡 Step 1: Request payment quote from X402 server...")
        let quote = try await requestPaymentQuote(endpoint: endpoint)
        
        // Determine payment type and create transaction
        if let recipient = quote.payment.recipient,
           let amount = quote.payment.amount {
            // SOL payment
            return try await payWithSOL(
                endpoint: endpoint,
                payer: payer,
                recipient: PublicKey(base58: recipient),
                amount: UInt64(amount)
            )
        } else if let tokenAccountStr = quote.payment.tokenAccount,
                  let mintStr = quote.payment.mint,
                  let amount = quote.payment.amount {
            // SPL Token payment (USDC, etc.)
            return try await payWithSPLToken(
                endpoint: endpoint,
                payer: payer,
                recipientTokenAccount: PublicKey(base58: tokenAccountStr),
                mint: PublicKey(base58: mintStr),
                amount: UInt64(amount)
            )
        } else {
            throw X402Error.invalidQuote("Missing required payment fields")
        }
    }
    
    // MARK: - Private: SOL Payment
    
    private func payWithSOL(
        endpoint: String,
        payer: Keypair,
        recipient: PublicKey,
        amount: UInt64
    ) async throws -> X402PaymentResponse {
        print("   ✅ Payment quote received (SOL)")
        print("   Amount: \(amount) lamports")
        print("   Recipient: \(recipient.base58())\n")
        
        // Step 2: Create SOL transfer transaction
        print("🔨 Step 2: Create SOL transfer transaction...")
        
        let instruction = SystemProgram.transfer(
            fromPubkey: payer.publicKey,
            toPubkey: recipient,
            lamports: amount
        )
        
        let blockhash = try await connection.getLatestBlockhash()
        let transaction = Transaction(
            recentBlockhash: blockhash,
            instructions: [instruction],
            signers: [payer]
        )
        
        print("   ✅ Transaction created")
        print("   Instructions: 1 (SOL transfer)\n")
        
        // Step 3: Sign and serialize
        print("✍️  Step 3: Sign transaction...")
        let serializedTx = try transaction.serialize()
        let serializedTxBase64 = serializedTx.base64EncodedString()
        print("   ✅ Transaction signed\n")
        
        // Step 4: Send payment proof
        print("📤 Step 4: Send payment proof to X402 server...")
        let response = try await sendPaymentProof(
            endpoint: endpoint,
            serializedTransaction: serializedTxBase64
        )
        print("   ✅ Payment proof accepted\n")
        
        return response
    }
    
    // MARK: - Private: SPL Token Payment
    
    private func payWithSPLToken(
        endpoint: String,
        payer: Keypair,
        recipientTokenAccount: PublicKey,
        mint: PublicKey,
        amount: UInt64
    ) async throws -> X402PaymentResponse {
        print("   ✅ Payment quote received (SPL Token)")
        print("   Mint: \(mint.base58())")
        print("   Amount: \(amount) (smallest units)")
        print("   Recipient Token Account: \(recipientTokenAccount.base58())\n")
        
        // Step 2: Get or create payer's associated token account
        print("🔨 Step 2: Get or create payer's associated token account...")
        
        let payerTokenAccount = findAssociatedTokenAddress(
            walletAddress: payer.publicKey,
            tokenMintAddress: mint
        )
        print("   Payer Token Account: \(payerTokenAccount.base58())")
        
        var instructions: [TransactionInstruction] = []
        
        // Check if payer's token account exists
        let payerAccountInfo = try? await connection.getAccountInfo(account: payerTokenAccount)
        if payerAccountInfo == nil {
            print("   ⚠️  Payer token account doesn't exist, creating...")
            let createPayerATAIx = createAssociatedTokenAccountInstruction(
                payer: payer.publicKey,
                owner: payer.publicKey,
                mint: mint
            )
            instructions.append(createPayerATAIx)
            print("   ✅ Added create payer ATA instruction")
        } else {
            print("   ✅ Payer token account exists")
            
            // Verify balance
            let balance = try await connection.getTokenAccountBalance(tokenAccount: payerTokenAccount)
            print("   Balance: \(balance.uiAmountString)")
            
            guard let balanceAmount = UInt64(balance.amount), balanceAmount >= amount else {
                throw X402Error.invalidQuote("Insufficient token balance")
            }
        }
        
        // Step 3: Check if recipient token account exists
        print("\n🔍 Step 3: Check recipient token account...")
        print("   Recipient Token Account: \(recipientTokenAccount.base58())")
        
        let recipientAccountInfo = try? await connection.getAccountInfo(account: recipientTokenAccount)
        if recipientAccountInfo == nil {
            print("   ⚠️  Recipient token account doesn't exist!")
            print("   ")
            print("   The server's token account must be created before accepting payments.")
            print("   This is the server's responsibility, not the client's.")
            print("   ")
            print("   To fix this issue:")
            print("   1. Stop the X402 server")
            print("   2. Run this command to create the server's token account:")
            print("      ")
            print("      cd x402-solana-examples/pay-in-usdc")
            print("      ")
            print("      # First, ensure server wallet has SOL:")
            print("      solana airdrop 1 seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX --url devnet")
            print("      ")
            print("      # Then create the token account:")
            print("      spl-token create-account \(mint.base58()) \\")
            print("        --owner seFkxFkXEY9JGEpCyPfCWTuPZG9WK6ucf95zvKCfsRX \\")
            print("        --url devnet")
            print("      ")
            print("      # Expected output:")
            print("      # Creating account \(recipientTokenAccount.base58())")
            print("      ")
            print("   3. Restart the X402 server")
            print("   4. Re-run this test")
            print("   ")
            
            throw X402Error.invalidQuote(
                "Recipient token account does not exist. " +
                "The server must create its token account before accepting payments. " +
                "See the instructions above."
            )
        } else {
            print("   ✅ Recipient token account exists")
        }
        
        // Step 4: Create transfer instruction
        print("\n💸 Step 4: Create transfer instruction...")
        
        let transferIx = createTransferInstruction(
            source: payerTokenAccount,
            destination: recipientTokenAccount,
            authority: payer.publicKey,
            amount: amount
        )
        instructions.append(transferIx)
        print("   ✅ Added transfer instruction")
        
        // Step 5: Create and sign transaction
        print("\n🔐 Step 5: Create and sign transaction...")
        
        let blockhash = try await connection.getLatestBlockhash()
        let transaction = Transaction(
            recentBlockhash: blockhash,
            instructions: instructions,
            signers: [payer]
        )
        
        let serializedTx = try transaction.serialize()
        let serializedTxBase64 = serializedTx.base64EncodedString()
        
        print("   ✅ Transaction created and signed")
        print("   Instructions: \(transaction.instructions.count)")
        print("   Blockhash: \(blockhash)\n")
        
        // Step 6: Send payment proof
        print("📤 Step 6: Send payment proof to X402 server...")
        let response = try await sendPaymentProof(
            endpoint: endpoint,
            serializedTransaction: serializedTxBase64
        )
        print("   ✅ Payment proof accepted\n")
        
        return response
    }
    
    
    // MARK: - Low-level API: Manual Control
    
    // MARK: - Step 4: Send Payment Proof (Low-level)
    
    /// Send payment proof to server with X-Payment header (Low-level API)
    /// 
    /// Use this after manually creating and signing the transaction.
    /// For automatic payment flow, use `payForContent()` instead.
    /// 
    /// - Parameters:
    ///   - endpoint: API endpoint (e.g., "/premium")
    ///   - serializedTransaction: Base64-encoded signed transaction
    /// - Returns: Payment response with content and payment details
    public func sendPaymentProof(
        endpoint: String,
        serializedTransaction: String
    ) async throws -> X402PaymentResponse {
        let url = URL(string: "\(config.serverUrl)\(endpoint)")!
        
        // Create payment proof
        let paymentProof = X402PaymentProof(
            network: config.network,
            serializedTransaction: serializedTransaction
        )
        
        // Encode as JSON then base64
        let jsonData = try JSONEncoder().encode(paymentProof)
        let xPaymentHeader = jsonData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(xPaymentHeader, forHTTPHeaderField: "X-Payment")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard response is HTTPURLResponse else {
            throw X402Error.invalidResponse
        }
        
        // Check response
        let paymentResponse = try JSONDecoder().decode(X402PaymentResponse.self, from: data)
        
        if let error = paymentResponse.error {
            throw X402Error.paymentFailed(error)
        }
        
        return paymentResponse
    }
}

// MARK: - Error Types

public enum X402Error: Error, LocalizedError {
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidQuote(String)
    case paymentFailed(String)
    case networkError(Error)
    case unsupportedCurrency
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .unexpectedStatusCode(let code):
            return "Unexpected status code: \(code)"
        case .invalidQuote(let message):
            return "Invalid payment quote: \(message)"
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unsupportedCurrency:
            return "Unsupported currency type"
        }
    }
}
