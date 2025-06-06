//
//  TokensTests.swift
//  JupSwift
//
//  Created by Zhao You on 6/6/25.
//

import Testing
@testable import JupSwift


struct TokensTests {
    @Test
    func testToken() async throws {
        let token = "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"
        
        // call Jupiter API
        let result = try await JupiterApi.token(mint: token)
        
        #expect(result.symbol == "JUP", "Expected symbol to be JUP")
        #expect(result.decimals == 6, "Expected decimals to be 6")
        
        print("✅ Token response: \(result)")
    }
    
    @Test
    func testMarket() async throws {
        let market = "BVRbyLjjfSBcoyiYFuxbgKYnWuiFaF9CSXEa5vdSZ9Hh"
        
        // call Jupiter API
        let result = try await JupiterApi.market(market: market)
        
        #expect(result.count == 2, "Expected length to be 2")
        #expect(result.contains("So11111111111111111111111111111111111111112"), "Expected result to contain wrapped SOL")
        #expect(result.contains("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"), "Expected result to contain USDC")
        
        print("✅ Market response: \(result)")
    }
    
    @Test
    func testTradable() async throws {
        // call Jupiter API
        let result = try await JupiterApi.tradableTokens()
        
        #expect(result.count > 8888, "Expected length to be greater than 8888")
    }
    
    @Test
    func testTaggedTokens() async throws {
        // call Jupiter API
        let tag = "lst"
        let result = try await JupiterApi.taggedTokens(for: tag)
        
        #expect(result.count > 10, "Expected length to be greater than 10")
    }
    
    @Test
    func testNewTokens() async throws {
        // call Jupiter API
        let result = try await JupiterApi.newTokens()
        
        #expect(result.count > 8888, "Expected length to be greater than 8888")
    }
    
    @Test
    func testAllTokens() async throws {
        // call Jupiter API
        let result = try await JupiterApi.allTokens()
        
        #expect(result.count > 8888, "Expected length to be greater than 8888")
    }
}
