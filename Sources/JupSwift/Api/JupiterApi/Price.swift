//
//  Price.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    
    /// Fetches the current price of one or more tokens from Jupiter's Price API V3.
    ///
    /// - Parameters:
    ///   - tokenIds: A comma-separated string of token mint addresses (e.g., `"So111...,JUP..."`).
    /// - Returns: A `PriceResponse` object containing pricing data keyed by token ID.
    /// - Throws: An error if the request fails or if decoding the response fails.
    static func price(for tokenIds: String) async throws -> PriceResponse {
        await JupiterApi.configure(version: .v3, component: "price")
        let url = await getQuoteURL(endpoint: "?ids=\(tokenIds)")
        let headers = await getHeaders()
        let dataRequest = session.request(url, headers: headers, interceptor: retryPolicy)
        await debugLogRequest(dataRequest)
        let response = try await dataRequest
            .validate()
            .serializingDecodable(PriceResponse.self)
            .value
        return response
    }
}