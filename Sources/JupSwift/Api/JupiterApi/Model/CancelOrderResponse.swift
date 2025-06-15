//
//  CancelOrderResponse.swift
//  JupSwift
//
//  Created by Zhao You on 11/6/25.
//

public struct CancelTriggerOrdersResponse: Codable, Hashable, Sendable {
    public let requestId: String
    public let transactions: [String]
}

internal struct CancelOrder: Encodable {
    let maker: String
    let order: String
}

internal struct CancelOrders: Encodable {
    let maker: String
    let orders: [String]
}
