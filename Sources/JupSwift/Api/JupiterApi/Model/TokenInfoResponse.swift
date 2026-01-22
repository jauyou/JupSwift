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
    public let icon: String?
    public let decimals: Int
    public let twitter: String?
    public let telegram: String?
    public let website: String?
    public let dev: String?
    
    public let circSupply: Double?
    public let totalSupply: Double?
    public let tokenProgram: String?
    
    public let launchpad: String?
    public let partnerConfig: String?
    public let graduatedPool: String?
    public let graduatedAt: String?
    
    public let holderCount: Int?
    public let fdv: Double?
    public let mcap: Double?
    public let usdPrice: Double?
    public let priceBlockId: Int?
    public let liquidity: Double?
    
    public let organicScore: Double?
    public let organicScoreLabel: OrganicScoreLabel?
    public let isVerified: Bool?
    public let cexes: [String]?
    public let tags: [String]?
    public let updatedAt: String?
    
    // New Fields
    public let firstPool: FirstPool?
    public let audit: TokenAudit?
    
    public let stats5m: TokenStats?
    public let stats1h: TokenStats?
    public let stats6h: TokenStats?
    public let stats24h: TokenStats?
    public let stats7d: TokenStats?
    public let stats30d: TokenStats?
    
    public enum OrganicScoreLabel: String, Codable, Hashable, Sendable {
        case high
        case medium
        case low
    }
    
    public struct TokenStats: Codable, Hashable, Sendable {
        public let priceChange: Double?
        public let holderChange: Double?
        public let liquidityChange: Double?
        public let volumeChange: Double?
        public let buyVolume: Double?
        public let sellVolume: Double?
        public let buyOrganicVolume: Double?
        public let sellOrganicVolume: Double?
        public let numBuys: Int?
        public let numSells: Int?
        public let numTraders: Int?
        public let numOrganicBuyers: Int?
        public let numNetBuyers: Int?
    }
    
    public struct FirstPool: Codable, Hashable, Sendable {
        public let id: String
        public let createdAt: String
    }
    
    public struct TokenAudit: Codable, Hashable, Sendable {
        public let mintAuthorityDisabled: Bool?
        public let freezeAuthorityDisabled: Bool?
        public let topHoldersPercentage: Double?
        public let devMints: Int?
        public let isSus: Bool?
        public let devMigrations: Int?
    }

    enum CodingKeys: String, CodingKey {
        case address = "id"
        case name
        case symbol
        case decimals
        case icon
        case twitter
        case telegram
        case website
        case dev
        case circSupply
        case totalSupply
        case tokenProgram
        case launchpad
        case partnerConfig
        case graduatedPool
        case graduatedAt
        case holderCount
        case fdv
        case mcap
        case usdPrice
        case priceBlockId
        case liquidity
        case organicScore
        case organicScoreLabel
        case isVerified
        case cexes
        case tags
        case updatedAt
        
        case firstPool
        case audit
        case stats5m
        case stats1h
        case stats6h
        case stats24h
        case stats7d
        case stats30d
    }
}
