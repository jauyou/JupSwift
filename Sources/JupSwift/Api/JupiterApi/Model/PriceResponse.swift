//
//  PriceResponse.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Foundation

public struct PriceResponse: Codable, Hashable, Sendable  {
    let data: [String: PriceData]
    let timeTaken: Double
}

public struct PriceData: Codable, Hashable, Sendable  {
    let id: String
    let type: String
    let price: String
    let extraInfo: ExtraInfo?
}

public struct ExtraInfo: Codable, Hashable, Sendable  {
    let lastSwappedPrice: LastSwappedPrice
    let quotedPrice: QuotedPrice
    let confidenceLevel: String
    let depth: Depth
}

public struct LastSwappedPrice: Codable, Hashable, Sendable  {
    let lastJupiterSellAt: Int
    let lastJupiterSellPrice: String
    let lastJupiterBuyAt: Int
    let lastJupiterBuyPrice: String
}

public struct QuotedPrice: Codable, Hashable, Sendable  {
    let buyPrice: String
    let buyAt: Int
    let sellPrice: String
    let sellAt: Int
}

public struct Depth: Codable, Hashable, Sendable  {
    let buyPriceImpactRatio: PriceImpactRatio
    let sellPriceImpactRatio: PriceImpactRatio
}

public struct PriceImpactRatio: Codable, Hashable, Sendable  {
    let depth: [String: Double]
    let timestamp: Int
}
