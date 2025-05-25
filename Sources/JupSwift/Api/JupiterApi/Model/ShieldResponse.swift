//
//  ShieldResponse.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

public struct TokenWarning: Codable, Hashable, Sendable {
    public let type: String
    public let message: String
    public let severity: String
}

public struct ShieldResponse: Codable, Hashable, Sendable {
    public let warnings: [String: [TokenWarning]]

    private enum CodingKeys: String, CodingKey {
        case warnings
    }
}
