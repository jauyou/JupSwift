//
//  PriceTests.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Testing
@testable import JupSwift


struct PriceTests {
    init() async {
        await ApiTestHelper.configure()
    }

    @Test
    func testPrice() async throws {
        let response = try await JupiterApi.price(for: "So11111111111111111111111111111111111111112,JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN")
        if let solPriceData = response.data["So11111111111111111111111111111111111111112"],
           let jupPriceData = response.data["JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"] {
            #expect(solPriceData.usdPrice > 0)
            #expect(jupPriceData.usdPrice > 0)
            #expect(solPriceData.decimals == 9)
            #expect(jupPriceData.decimals == 6)
        } else {
            #expect(Bool(false), "Missing price data for SOL or JUP")
        }
        print("✅ Price response: \(response)")
    }
}
