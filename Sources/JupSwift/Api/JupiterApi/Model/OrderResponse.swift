//
//  OrderResponse.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

public struct RoutePlan: Codable, Hashable, Sendable {
    let swapInfo: SwapInfo
    let percent: Int
}

public struct SwapInfo: Codable, Hashable, Sendable {
    let ammKey: String
    let label: String
    let inputMint: String
    let outputMint: String
    let inAmount: String
    let outAmount: String
    let feeAmount: String
    let feeMint: String
}

public struct PlatformFee: Codable, Hashable, Sendable {
    let amount: String
    let feeBps: Int
}

public struct DynamicSlippageReport: Codable, Hashable, Sendable {
    let amplificationRatio: String?
    let otherAmount: Int?
    let simulatedIncurredSlippageBps: Int?
    let slippageBps: Int
    let categoryName: String
    let heuristicMaxSlippageBps: Int
}

public struct OrderResponse: Codable, Hashable, Sendable {
    public let inputMint: String        // require but nullable
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
