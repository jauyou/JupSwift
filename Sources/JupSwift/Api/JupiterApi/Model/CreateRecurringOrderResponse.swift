//
//  CreateRecurringOrderResponse.swift
//  JupSwift
//
//  Created by Zhao You on 14/6/25.
//

import Foundation

public struct CreateRecurringOrderRequest: Encodable, Sendable {
    let user: String
    let inputMint: String
    let outputMint: String
    let params: RecurringParams
}

public enum RecurringParams: Encodable, Sendable {
    case time(TimeParams)
    case price(PriceParams)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .time(let value):
            try container.encode(value, forKey: .time)
        case .price(let value):
            try container.encode(value, forKey: .price)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case time
        case price
    }
}

public struct TimeParams: Encodable, Sendable {
    let inAmount: UInt64
    let interval: UInt64
    var maxPrice: Double? = nil
    var minPrice: Double? = nil
    let numberOfOrders: UInt64
    var startAt: UInt64? = nil
    
    public init(
            inAmount: UInt64,
            interval: UInt64,
            maxPrice: Double? = nil,
            minPrice: Double? = nil,
            numberOfOrders: UInt64,
            startAt: UInt64? = nil
        ) {
            self.inAmount = inAmount
            self.interval = interval
            self.maxPrice = maxPrice
            self.minPrice = minPrice
            self.numberOfOrders = numberOfOrders
            self.startAt = startAt
        }
}

public struct PriceParams: Encodable, Sendable {
    let depositAmount: UInt64
    let incrementUsdcValue: UInt64
    let interval: UInt64
    var startAt: UInt64? = nil
    
    public init(depositAmount: UInt64, incrementUsdcValue: UInt64, interval: UInt64, startAt: UInt64? = nil) {
        self.depositAmount = depositAmount
        self.incrementUsdcValue = incrementUsdcValue
        self.interval = interval
        self.startAt = startAt
    }
}

public struct CancelRecurringOrderRequest: Encodable, Sendable {
    let order: String
    let user: String
    let recurringType: String
}

public struct PriceDepositeRequest: Encodable, Sendable {
    let order: String
    let user: String
    let amount: UInt64
}

public struct PriceWithdrawRequest: Encodable, Sendable {
    let order: String
    let user: String
    let inputOrOutput: String = "In"
    let amount: UInt64
}
