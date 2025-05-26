//
//  UltraTests.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Testing
@testable import JupSwift


struct UltraTests {
    @Test
    func testBalancesWithValidAccount() async throws {
        let account = "ULNw3m7kxvPP8RHXAwYRTW5yQos7RWB4nmVBsiCix6V"

        // 呼叫 Jupiter API
        let result = try await JupiterApi.balances(account: account)
        
        #expect(result.balances.count > 0, "Expected balances to be non-empty")
        
        print("✅ Balance response: \(result)")
    }
    
    @Test
    func testOrder() async throws {
        let inputMint = "So11111111111111111111111111111111111111112"
        let outputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let amount = "1000000"
        let taker = "ULNw3m7kxvPP8RHXAwYRTW5yQos7RWB4nmVBsiCix6V"
        
        let result = try await JupiterApi.order(inputMint: inputMint, outputMint: outputMint, amount: amount, taker: taker)
        
        #expect(result.inAmount == amount)
        print("amout: \(amount)")
        print("✅ Order response: \(result)")
    }
    
    @Test
    func testUltraSwap() async throws {
        let inputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" // USDC
        let outputMint = "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN" // JUP
        let amount = "22763399" // minimal（lamports）
        let taker = "YOUR_SOLANA_ADDRESS_HERE" // replace by address
        let privateKey = "YOUR_PRIVATE_KEY_HERE" // fill out privateKey

        do {
            _ = try await JupiterApi.ultraSwap(
                inputMint: inputMint,
                outputMint: outputMint,
                amount: amount,
                taker: taker,
                privateKey: privateKey
            )
        } catch {
            print("❌ UltraSwap failed with error: \(error)")
            throw error
        }
    }
    
    @Test
    func testShieldMints() async throws {
        let mints = [
            "So11111111111111111111111111111111111111112", // Wrapped SOL
            "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"  // USDC
        ]

        do {
            let result = try await JupiterApi.shield(mints: mints)

//            #expect(!result.shields.isEmpty, "Shield list should not be empty")

            print("✅ Shield response: \(result)")
        } catch {
            print("❌ Shield API failed: \(error)")
            throw error
        }
    }
    
    @Test
    func testRoutersFetch() async throws {
        let routers = try await JupiterApi.routers()

        #expect(!routers.isEmpty, "Routers array should not be empty")

        print("✅ Routers: \(routers)")
    }
}
