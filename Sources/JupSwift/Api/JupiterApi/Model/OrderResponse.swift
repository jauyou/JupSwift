//
//  OrderResponse.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

public struct RoutePlan: Codable, Hashable, Sendable {
    public let swapInfo: SwapInfo
    public let percent: Int
}

public struct SwapInfo: Codable, Hashable, Sendable {
    public let ammKey: String
    public let label: String
    public let inputMint: String
    public let outputMint: String
    public let inAmount: String
    public let outAmount: String
}

public struct PlatformFee: Codable, Hashable, Sendable {
    public let amount: String?
    public let feeBps: Int
}

public struct DynamicSlippageReport: Codable, Hashable, Sendable {
    public let amplificationRatio: String?
    public let otherAmount: Int?
    public let simulatedIncurredSlippageBps: Int?
    public let slippageBps: Int
    public let categoryName: String
    public let heuristicMaxSlippageBps: Int
}

public struct OrderResponse: Codable, Hashable, Sendable {
    public let inputMint: String
    public let outputMint: String
    public let inAmount: String
    public let outAmount: String
    public let otherAmountThreshold: String
    public let swapMode: String
    public let slippageBps: Int
    public let priceImpactPct: String
    public let routePlan: [RoutePlan]
    public let contextSlot: Int?
    public let feeBps: Int
    public let prioritizationType: String?  // 2025/05/05 update to optional
    public let prioritizationFeeLamports: Int
    public let swapType: String
    public let transaction: String?     // require but nullable
    public let gasless: Bool
    public let requestId: String
    public let totalTime: Int
    public let taker: String?           // require but nullable
    // non require
    public let quoteId: String?
    public let maker: String?
    public let expireAt: String?
    public let lastValidBlockHeight: Int?
    public let platformFee: PlatformFee?
    public let dynamicSlippageReport: DynamicSlippageReport?
}
