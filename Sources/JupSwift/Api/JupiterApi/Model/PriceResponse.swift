//
//  PriceResponse.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Foundation

/// Represents the response from the Jupiter Price API.
/// The API returns a dictionary mapping token mint addresses to their price data.
public struct PriceResponse: Codable, Hashable, Sendable {
    /// A dictionary containing price data, keyed by the token mint address.
    public let data: [String: PriceData]
    
    /// The time taken for the request (Deprecated/Not available in V2 direct response).
    public let timeTaken: Double?

    public init(data: [String: PriceData], timeTaken: Double? = nil) {
        self.data = data
        self.timeTaken = timeTaken
    }

    // Custom decoding to handle the dynamic key dictionary structure
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode([String: PriceData].self)
        self.timeTaken = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

public struct PriceData: Codable, Hashable, Sendable {
    public let usdPrice: Double
    public let decimals: Int
    public let createdAt: String?
    public let liquidity: Double?
    public let blockId: Int?
    public let priceChange24h: Double?
}