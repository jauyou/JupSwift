//
//  TokenInfoResponse.swift
//  JupSwift
//
//  Created by Zhao You on 6/6/25.
//

/// The response for a tagged token query, e.g., all 'lst' tokens.
public typealias TaggedTokenListResponse = [TokenInfoResponse]

public struct TokenInfoResponse: Codable, Hashable, Sendable {
    public let address: String
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let logoURI: String?
    public let tags: [String]?
    public let dailyVolume: Double?
    public let createdAt: String
    public let freezeAuthority: String?
    public let mintAuthority: String?
    public let permanentDelegate: String?
    public let mintedAt: String?
    public let extensions: [String: String]?

    enum CodingKeys: String, CodingKey {
        case address
        case name
        case symbol
        case decimals
        case logoURI
        case tags
        case dailyVolume = "daily_volume"
        case createdAt = "created_at"
        case freezeAuthority = "freeze_authority"
        case mintAuthority = "mint_authority"
        case permanentDelegate = "permanent_delegate"
        case mintedAt = "minted_at"
        case extensions
    }
}
