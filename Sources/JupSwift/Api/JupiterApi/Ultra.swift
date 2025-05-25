//
//  Ultra.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    
    static var component: String {
        get {
            return "ultra"
        }
    }
    
    /// Fetch the balances for a specific account from Jupiter's Ultra API.
    ///
    /// - Parameter account: The Solana wallet address whose balances will be queried.
    /// - Returns: A `BalancesResponse` object containing balance details.
    /// - Throws: An error if the request fails or decoding fails.
    static func balances(account: String) async throws -> BalancesResponse {
        await JupiterApi.configure(mode: .lite, component: "ultra")
        let url = await getQuoteURL(endpoint: "balances/") + account
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(BalancesResponse.self)
            .value
        return response
    }

    /// Fetch shield information for a list of token mints from Jupiter Ultra API.
    ///
    /// - Parameter mints: An array of token mint addresses (base58 encoded).
    /// - Returns: A `ShieldResponse` object containing shielded token info.
    /// - Throws: An error if the network request or decoding fails.
    static func shield(mints: [String]) async throws -> ShieldResponse {
        await JupiterApi.configure(mode: .lite, component: "ultra")
        let mintString = mints.joined(separator: ",")
        let url = await getQuoteURL(endpoint: "shield") + "?mints=" + mintString
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(ShieldResponse.self)
            .value
        return response
    }

    /// Fetch the list of available routers from Jupiter API.
    ///
    /// - Returns: An array of `Router` objects representing available liquidity routes.
    /// - Throws: An error if the request fails or decoding fails.
    static func routers() async throws -> [Router] {
        await JupiterApi.configure(mode: .lite, component: "ultra")
        let url = await getQuoteURL(endpoint: "order/routers")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable([Router].self)
            .value
        return response
    }

    /// Fetch an order quote from Jupiter API.
    ///
    /// - Parameters:
    ///   - inputMint: The mint address of the input token (e.g., USDC).
    ///   - outputMint: The mint address of the output token (e.g., JUP).
    ///   - amount: The amount of input token, in base units (e.g., lamports for SOL).
    ///   - taker: (Optional) The taker's wallet address.
    /// - Returns: An `OrderResponse` object with the transaction and request ID.
    /// - Throws: An error if the request or decoding fails.
    static func order(inputMint: String, outputMint: String, amount: String, taker: String?) async throws -> OrderResponse {
        await JupiterApi.configure(mode: .lite, component: "ultra")
        let takerString = taker.map { "&taker=\($0)" } ?? ""
        let param = "?inputMint=\(inputMint)&outputMint=\(outputMint)&amount=\(amount)" + takerString
        let url = await getQuoteURL(endpoint: "order") + param
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(OrderResponse.self)
            .value
        return response
    }

    /// Submit a signed transaction to Jupiter for execution.
    ///
    /// - Parameters:
    ///   - signedTransaction: The base64-encoded signed transaction.
    ///   - requestId: The request ID from a previous `order` call.
    /// - Returns: An `ExecuteResponse` object indicating execution result.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    static func execute(signedTransaction: String, requestId: String) async throws -> ExecuteResponse {
        await JupiterApi.configure(mode: .lite, component: "ultra")
        let url = await getQuoteURL(endpoint: "execute")
        let requestBody = ExecuteOrderRequest(signedTransaction: signedTransaction, requestId: requestId)
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(ExecuteResponse.self)
            .value
        return response
    }

    /// Performs an ultra swap via Jupiter: place order, sign it, and execute it.
    ///
    /// - Parameters:
    ///   - inputMint: The mint address of the input token.
    ///   - outputMint: The mint address of the output token.
    ///   - amount: The amount of input token to swap, in raw units (e.g., lamports).
    ///   - taker: (Optional) The taker's wallet address.
    ///   - privateKey: The private key used to sign the transaction (base64 or raw bytes as expected by your signer).
    /// - Returns: An `ExecuteResponse` containing execution result.
    /// - Throws: Any error encountered during order, signing, or execution.
    static func ultraSwap(inputMint: String, outputMint: String, amount: String, taker: String?, privateKey: String) async throws -> ExecuteResponse {
        let orderResponse = try await order(inputMint: inputMint, outputMint: outputMint, amount: amount, taker: taker)

        guard let transaction = orderResponse.transaction else {
            throw NSError(domain: "No transaction to execute", code: -1)
        }

        let signedTx = signTransaction(base64Transaction: transaction, privateKey: privateKey)
        let response = try await execute(signedTransaction: signedTx, requestId: orderResponse.requestId)
        return response
    }
}
