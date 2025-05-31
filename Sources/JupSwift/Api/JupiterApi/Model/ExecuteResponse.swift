//
//  ExecuteResponse.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

public struct SwapEvent: Codable, Hashable, Sendable {
    public let inputMint: String
    public let inputAmount: String
    public let outputMint: String
    public let outputAmount: String
}

public struct ExecuteResponse: Codable, Hashable, Sendable {
    public let status: String
    public let signature: String?
    public let slot: String?
    public let code: Int
    public let inputAmountResult: String?
    public let outputAmountResult: String?
    public let swapEvents: [SwapEvent]?
}

internal struct ExecuteOrderRequest: Encodable {
    let signedTransaction: String
    let requestId: String
}
