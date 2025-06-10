//
//  GetTriggerOrdersResponse.swift
//  JupSwift
//
//  Created by Zhao You on 11/6/25.
//

import Foundation

public struct GetTriggerOrdersResponse: Codable, Hashable, Sendable {
    public let user: String
    public let orderStatus: String
    public let orders: [Order]
    public let totalPages: Int
    public let page: Int
    public let totalItems: Int?
}

public struct Order: Codable, Hashable, Sendable {
    public let userPubkey: String
    public let orderKey: String
    public let inputMint: String
    public let outputMint: String
    public let makingAmount: String
    public let takingAmount: String
    public let remainingMakingAmount: String
    public let remainingTakingAmount: String
    public let rawMakingAmount: String
    public let rawTakingAmount: String
    public let rawRemainingMakingAmount: String
    public let rawRemainingTakingAmount: String
    public let slippageBps: String
    public let slTakingAmount: String?
    public let rawSlTakingAmount: String?
    public let expiredAt: String?
    public let createdAt: String
    public let updatedAt: String
    public  let status: String
    public let openTx: String
    public let closeTx: String
    public let programVersion: String
    public let trades: [Trade]
}

public struct Trade: Codable, Hashable, Sendable {
    public let orderKey: String
    public let keeper: String
    public let inputMint: String
    public let outputMint: String
    public let inputAmount: String
    public let outputAmount: String
    public let rawInputAmount: String
    public let rawOutputAmount: String
    public let feeMint: String
    public let feeAmount: String
    public let rawFeeAmount: String
    public let txId: String
    public let confirmedAt: String
    public let action: String
    public let productMeta: String?
}
