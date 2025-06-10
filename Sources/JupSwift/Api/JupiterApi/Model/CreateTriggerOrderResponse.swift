//
//  CreateTriggerOrderResponse.swift
//  JupSwift
//
//  Created by Zhao You on 9/6/25.
//

public struct CreateTriggerOrderResponse: Codable, Hashable, Sendable {
    public let requestId: String
    public let transaction: String
    public let order: String?
}

internal struct CreateTriggerOrderRequest: Encodable {
    let inputMint: String
    let outputMint: String
    let maker: String
    let payer: String
    let params: TriggerParams
    var feeAccount: String?
}

internal struct TriggerParams: Encodable {
    let makingAmount: String
    let takingAmount: String
    let feeBps: String = "50"
}
