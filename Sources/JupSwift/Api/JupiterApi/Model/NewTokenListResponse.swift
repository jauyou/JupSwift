//
//  NewTokenListResponse.swift
//  JupSwift
//
//  Created by Zhao You on 6/6/25.
//

public typealias NewTokenListResponse = [NewToken]

public struct NewToken: Codable, Hashable, Sendable {
    public let createdAt: String
    public let decimals: Int
    public let freezeAuthority: String?
    public let knownMarkets: [String]
    public let logoURI: String?
    public let metadataUpdatedAt: Int
    public let mint: String
    public let mintAuthority: String?
    public let name: String
    public let symbol: String

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case decimals
        case freezeAuthority = "freeze_authority"
        case knownMarkets = "known_markets"
        case logoURI = "logo_uri"
        case metadataUpdatedAt = "metadata_updated_at"
        case mint
        case mintAuthority = "mint_authority"
        case name
        case symbol
    }
}
