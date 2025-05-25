//
//  BalancesResponse.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

public struct TokenBalance: Codable, Hashable, Sendable {
    let amount: String
    let uiAmount: Double
    let slot: Int
    let isFrozen: Bool
}

public struct BalancesResponse: Codable, Hashable, Sendable {
    public let balances: [String: TokenBalance]

    public static func == (lhs: BalancesResponse, rhs: BalancesResponse) -> Bool {
        lhs.balances == rhs.balances
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(balances)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.balances = try container.decode([String: TokenBalance].self)
    }
}
