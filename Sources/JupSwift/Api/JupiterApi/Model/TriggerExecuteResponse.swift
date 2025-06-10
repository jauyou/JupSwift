//
//  TriggerExecuteResponse.swift
//  JupSwift
//
//  Created by Zhao You on 10/6/25.
//

public struct TriggerExecuteResponse: Codable, Hashable, Sendable {
    public let code: Int
    public let signature: String
    public let status: String
}

internal struct TriggerExecuteRequest: Encodable {
    let requestId: String
    let signedTransaction: String
}
