//
//  RecurringExecuteResponse.swift
//  JupSwift
//
//  Created by Zhao You on 14/6/25.
//

public struct RecurringExecuteResponse: Codable, Hashable, Sendable {
    public let signature: String
    public let status: String
    public let order: String?
    public let error: String?
}

internal struct RecurringExecuteRequest: Encodable {
    let requestId: String
    let signedTransaction: String
}
