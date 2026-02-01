//
//  Token.swift
//  JupSwift
//
//  Created by Zhao You on 6/6/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    
    /// Search for tokens by symbol, name, or mint address via Jupiter Tokens API V2.
    ///
    /// - Parameter query: The search query (symbol, name, or comma-separated mint addresses).
    /// - Returns: An array of `TokenInfoResponse` objects matching the query.
    /// - Throws: An error if the request fails or decoding fails.
    static func searchTokens(query: String) async throws -> [TokenInfoResponse] {
        let url = await getQuoteURL(endpoint: "/search?query=\(query)", version: .v2, component: "tokens")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable([TokenInfoResponse].self)
            .value
        return response
    }
    
    /// Fetches token metadata information from the Jupiter Tokens API for a given mint address.
    ///
    /// - Parameter mint: The SPL token mint address (as a `String`).
    /// - Returns: A `TokenInfoResponse` containing metadata.
    /// - Throws: `JupiterError` if token is not found, or network errors.
    @available(*, deprecated, message: "Use searchTokens(query:) instead.")
    static func token(mint: String) async throws -> TokenInfoResponse {
        let tokens = try await searchTokens(query: mint)
        guard let token = tokens.first else {
            throw JupiterError.invalidTransaction("Token not found")
        }
        return token
    }
    
    /// Fetches the list of token mints for a given liquidity pool market.
    ///
    /// - Parameter market: The address of the liquidity pool (market) to query.
    /// - Returns: An array of token mint addresses associated with the specified liquidity pool.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    @available(*, deprecated, message: "Tokens API V1 is deprecated.")
    static func market(market: String) async throws -> [String] {
        let url = await getQuoteURL(endpoint: "/market/\(market)/mints", version: .v1, component: "tokens")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable([String].self)
            .value
        return response
    }
    
    /// Retrieves a list of all tradable token mint addresses.
    ///
    /// - Returns: An array of strings representing the mint addresses of tradable tokens.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    @available(*, deprecated, message: "Tokens API V1 is deprecated.")
    static func tradableTokens() async throws -> [String] {
        let url = await getQuoteURL(endpoint: "/mints/tradable", version: .v1, component: "tokens")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable([String].self)
            .value
        return response
    }
    
    /// Fetches a list of tokens tagged with the given category (e.g., "lst", "stable", etc.).
    /// - Parameter tag: The tag used to filter tokens (e.g., "lst").
    /// - Returns: An array of tokens matching the given tag.
    /// - Throws: An error if the request fails or the response is invalid.
    @available(*, deprecated, message: "Tokens API V1 is deprecated.")
    static func taggedTokens(for tag: String) async throws -> TaggedTokenListResponse {
        let url = await getQuoteURL(endpoint: "/tagged/\(tag)", version: .v1, component: "tokens")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable(TaggedTokenListResponse.self)
            .value
        return response
    }
    
    /// Fetches the list of newly added tokens.
    ///
    /// - Returns: A `NewTokenListResponse` object containing information about the new tokens.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    @available(*, deprecated, message: "Tokens API V1 is deprecated.")
    static func newTokens() async throws -> NewTokenListResponse {
        let url = await getQuoteURL(endpoint: "/new", version: .v1, component: "tokens")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable(NewTokenListResponse.self)
            .value
        return response
    }
    
    /// Retrieves the complete list of all tokens available.
    ///
    /// - Returns: An array of `TokenInfoResponse` objects containing detailed information about each token.
    /// - Throws: An error if the network request fails or the response cannot be decoded.
    @available(*, deprecated, message: "Tokens API V1 is deprecated. For specific token lookups, use searchTokens(query:) with mint addresses.")
    static func allTokens() async throws -> [TokenInfoResponse] {
        let url = await getQuoteURL(endpoint: "/all", version: .v1, component: "tokens")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable([TokenInfoResponse].self)
            .value
        return response
    }
}
