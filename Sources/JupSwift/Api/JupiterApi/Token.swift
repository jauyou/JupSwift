//
//  Token.swift
//  JupSwift
//
//  Created by Zhao You on 6/6/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    
    /// Fetches token metadata information from the Jupiter Tokens API for a given mint address.
    ///
    /// This function configures the Jupiter API in `.lite` mode and targets the `"tokens"` component.
    /// It then builds a request to fetch the token info from the `"token/{mint}"` endpoint,
    /// performs the request with a retry policy, and decodes the response into a `TokenInfoResponse` object.
    ///
    /// - Parameter mint: The SPL token mint address (as a `String`) for which to fetch metadata.
    /// - Returns: A `TokenInfoResponse` containing metadata such as name, symbol, decimals, logoURI, etc.
    /// - Throws: An error if the request fails, the response is invalid, or decoding fails.
    static func token(mint: String) async throws -> TokenInfoResponse {
        await JupiterApi.configure(mode: .lite, component: "tokens")
        let url = await getQuoteURL(endpoint: "token/") + mint
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(TokenInfoResponse.self)
            .value
        return response
    }
    
    /// Fetches the list of token mints for a given liquidity pool market.
    ///
    /// - Parameter market: The address of the liquidity pool (market) to query.
    /// - Returns: An array of token mint addresses associated with the specified liquidity pool.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    static func market(market: String) async throws -> [String] {
        await JupiterApi.configure(mode: .lite, component: "tokens")
        let url = await getQuoteURL(endpoint: "market/\(market)/mints")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable([String].self)
            .value
        return response
    }
    
    /// Retrieves a list of all tradable token mint addresses.
    ///
    /// - Returns: An array of strings representing the mint addresses of tradable tokens.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    static func tradableTokens() async throws -> [String] {
        await JupiterApi.configure(mode: .lite, component: "tokens")
        let url = await getQuoteURL(endpoint: "mints/tradable")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable([String].self)
            .value
        return response
    }
    
    /// Fetches a list of tokens tagged with the given category (e.g., "lst", "stable", etc.).
    /// - Parameter tag: The tag used to filter tokens (e.g., "lst").
    /// - Returns: An array of tokens matching the given tag.
    /// - Throws: An error if the request fails or the response is invalid.
    static func taggedTokens(for tag: String) async throws -> TaggedTokenListResponse {
        await JupiterApi.configure(mode: .lite, component: "tokens")
        let url = await getQuoteURL(endpoint: "tagged/\(tag)")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(TaggedTokenListResponse.self)
            .value
        return response
    }
    
    /// Fetches the list of newly added tokens.
    ///
    /// - Returns: A `NewTokenListResponse` object containing information about the new tokens.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    static func newTokens() async throws -> NewTokenListResponse {
        await JupiterApi.configure(mode: .lite, component: "tokens")
        let url = await getQuoteURL(endpoint: "new")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(NewTokenListResponse.self)
            .value
        return response
    }
    
    /// Retrieves the complete list of all tokens available.
    ///
    /// - Returns: An array of `TokenInfoResponse` objects containing detailed information about each token.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    static func allTokens() async throws -> [TokenInfoResponse] {
        await JupiterApi.configure(mode: .lite, component: "tokens")
        let url = await getQuoteURL(endpoint: "all")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable([TokenInfoResponse].self)
            .value
        return response
    }
}
