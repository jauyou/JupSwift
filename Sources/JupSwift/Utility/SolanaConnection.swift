//
//  SolanaConnection.swift
//  JupSwift
//
//  Created by Zhao You on 2/11/25.
//


import Foundation

// Define RPC response format
struct RPCResponse<T: Decodable>: Decodable {
    let jsonrpc: String
    let result: T?
    let error: RPCError?
    let id: Int
    
    struct RPCError: Decodable {
        let code: Int
        let message: String
    }
}


public actor SolanaConnection {
    public let endpoint: String
    public let cluster: SolanaCluster?
    private let session = URLSession.shared

    /// Initialize with custom RPC endpoint
    public init(endpoint: String, cluster: SolanaCluster? = nil) {
        self.endpoint = endpoint
        self.cluster = cluster
    }
    
    /// Initialize with predefined cluster
    public init(cluster: SolanaCluster) {
        self.endpoint = cluster.defaultRpcEndpoint
        self.cluster = cluster
    }
    
    /// Get Solana Explorer transaction link
    public func getExplorerUrl(signature: String) -> String {
        let baseUrl = cluster?.explorerUrl ?? "https://explorer.solana.com"
        return "\(baseUrl)/tx/\(signature)"
    }
    
    /// Get Solana Explorer address link
    public func getExplorerUrl(address: String) -> String {
        let baseUrl = cluster?.explorerUrl ?? "https://explorer.solana.com"
        return "\(baseUrl)/address/\(address)"
    }

    // RPC request sender
    private func sendRPCRequest<T: Decodable>(
        method: String,
        params: [Any]
    ) async throws -> T {
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)

        let decoded = try JSONDecoder().decode(RPCResponse<T>.self, from: data)
        if let error = decoded.error {
            throw NSError(domain: "SolanaRPC", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
        }
        guard let result = decoded.result else {
            throw NSError(domain: "SolanaRPC", code: -1, userInfo: [NSLocalizedDescriptionKey: "No result"])
        }
        return result
    }
}

extension SolanaConnection {
    public struct AccountInfoResult: Decodable {
        public struct Value: Decodable, Sendable {
            public let data: [String]
            public let executable: Bool
            public let lamports: UInt64
            public let owner: String
            public let rentEpoch: UInt64
        }
        public let value: Value?
    }

    public func getAccountInfo(account: PublicKey) async throws -> AccountInfoResult.Value? {
        let result: AccountInfoResult = try await sendRPCRequest(
            method: "getAccountInfo",
            params: [account.base58(), ["encoding": "base64"]]
        )
        return result.value
    }
}

extension SolanaConnection {
    public struct RecentBlockhashResult: Decodable {
        public struct Value: Decodable {
            let blockhash: String
            let lastValidBlockHeight: UInt64
        }
        let value: Value
    }
    
    public func getLatestBlockhash() async throws -> String {
        let result: RecentBlockhashResult = try await sendRPCRequest(
            method: "getLatestBlockhash",
            params: [["commitment": "finalized"]]
        )
        return result.value.blockhash
    }
    
    public func sendTransaction(
        instructions: [TransactionInstruction],
        signers: [Keypair]
    ) async throws -> String {
        // Step 1: Get latest blockhash
        let recentBlockhash = try await getLatestBlockhash()
        
        // Step 2: Build transaction
        let tx = Transaction(
            recentBlockhash: recentBlockhash,
            instructions: instructions,
            signers: signers
        )
        
        // Step 3: Serialize and sign
        let serialized = try tx.serialize()
        let base64String = serialized.base64EncodedString()
        
        // Step 4: Send RPC request
        let txSignature: String = try await sendRPCRequest(
            method: "sendTransaction",
            params: [base64String, ["encoding": "base64", "skipPreflight": false]]
        )
        
        print("📤 Transaction sent:", txSignature)
        return txSignature
    }
}

// MARK: - Token Account Balance
extension SolanaConnection {
    /// Token account balance information
    public struct TokenAccountBalance: Decodable, Sendable {
        public struct Value: Decodable, Sendable {
            public let amount: String
            public let decimals: UInt8
            public let uiAmount: Double?
            public let uiAmountString: String
        }
        public let value: Value
    }
    
    /// Get SPL Token account balance
    ///
    /// - Parameter tokenAccount: The token account public key
    /// - Returns: Token account balance information
    /// - Throws: An error if the request fails or account doesn't exist
    public func getTokenAccountBalance(tokenAccount: PublicKey) async throws -> TokenAccountBalance.Value {
        let result: TokenAccountBalance = try await sendRPCRequest(
            method: "getTokenAccountBalance",
            params: [tokenAccount.base58(), ["commitment": "confirmed"]]
        )
        return result.value
    }
    
    /// Wait for transaction confirmation
    ///
    /// - Parameters:
    ///   - signature: The transaction signature
    ///   - timeout: Maximum time to wait in seconds (default: 30)
    /// - Returns: true if confirmed, false if timeout
    public func confirmTransaction(signature: String, timeout: TimeInterval = 30) async throws -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            struct SignatureStatus: Decodable {
                struct Value: Decodable {
                    let confirmationStatus: String?
                    let err: String?
                }
                let value: [Value?]
            }
            
            do {
                let result: SignatureStatus = try await sendRPCRequest(
                    method: "getSignatureStatuses",
                    params: [[signature], ["searchTransactionHistory": true]]
                )
                
                if let status = result.value.first {
                    if let status = status {
                        if status.err != nil {
                            return false // Transaction failed
                        }
                        if let confirmationStatus = status.confirmationStatus {
                            if confirmationStatus == "confirmed" || confirmationStatus == "finalized" {
                                return true
                            }
                        }
                    }
                }
            } catch {
                // Continue polling on error
            }
            
            // Wait 1 second before next poll
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        return false // Timeout
    }
}
