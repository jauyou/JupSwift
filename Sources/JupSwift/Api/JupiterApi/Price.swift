//
//  Price.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    
    /// Fetches the current price of one or more tokens from Jupiter's Price API.
    ///
    /// - Parameters:
    ///   - tokenIds: A comma-separated string of token mint addresses (e.g., `"So111...,JUP..."`).
    ///   - includeExtraInfo: A Boolean indicating whether to include detailed price information such as depth and confidence levels. Defaults to `false`.
    /// - Returns: A `PriceResponse` object containing pricing data keyed by token ID.
    /// - Throws: An error if the request fails or if decoding the response fails.
    static func price(for tokenIds: String, includeExtraInfo: Bool = false) async throws -> PriceResponse {
        await JupiterApi.configure(version: .v2, mode: .lite, component: "price")
        let extraInfoString = includeExtraInfo ? "&showExtraInfo=true" : ""
        let url = await getQuoteURL(endpoint: "?ids=\(tokenIds)\(extraInfoString)")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(PriceResponse.self)
            .value
        return response
    }
    
    /// Fetches the current price of one or more tokens from Jupiter's Price API, quoted in terms of another token.
    ///
    /// - Parameters:
    ///   - tokenIds: A comma-separated string of token mint addresses whose prices you want to query.
    ///   - vsToken: The token mint address to use as the quote currency (e.g., `"So111..."` for SOL).
    /// - Returns: A `PriceResponse` object containing pricing data keyed by token ID, quoted against `vsToken`.
    /// - Throws: An error if the request fails or if decoding the response fails.
    static func price(for tokenIds: String, baseOnToken vsToken: String) async throws -> PriceResponse {
        await JupiterApi.configure(version: .v2, mode: .lite, component: "price")

        let url = await getQuoteURL(endpoint: "?ids=\(tokenIds)&vsToken=\(vsToken)")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(PriceResponse.self)
            .value
        return response
    }
}
