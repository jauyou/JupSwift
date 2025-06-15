//
//  GetRecurringOrdersResponse.swift
//  JupSwift
//
//  Created by Zhao You on 14/6/25.
//

import Foundation

public struct GetRecurringOrdersResponse: Codable, Sendable {
    public let user: String
    public let orderStatus: OrderStatus
    public let all: [RecurringOrder]
    public let totalPages: Int
    public let totalItems: Int
    public let page: Int
}

public enum OrderStatus: String, Codable, Sendable {
    case active
    case history
}

public enum RecurringType: String, Codable {
    case time
    case price
    case all
}

public struct RecurringOrder: Codable, Sendable {
    public let recurringType: String
    public let userPubkey: String
    public let orderKey: String
    public let inputMint: String
    public let outputMint: String
    public let inDeposited: String
    public let inWithdrawn: String
    public let rawInDeposited: String
    public let rawInWithdrawn: String
    public let cycleFrequency: String
    public let outWithdrawn: String
    public let inAmountPerCycle: String
    public let minOutAmount: String
    public let maxOutAmount: String
    public let inUsed: String
    public let outReceived: String
    public let rawOutWithdrawn: String
    public let rawInAmountPerCycle: String
    public let rawMinOutAmount: String
    public let rawMaxOutAmount: String
    public let rawInUsed: String
    public let rawOutReceived: String
    public let openTx: String
    public let closeTx: String
    public let userClosed: Bool
    public let createdAt: String
    public let updatedAt: String
    public let trades: [Trade]
}
