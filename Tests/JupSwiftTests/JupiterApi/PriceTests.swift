//
//  PriceTests.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Testing
@testable import JupSwift


struct PriceTests {
    @Test
    func testPrice() async throws {
        var response = try await JupiterApi.price(for: "So11111111111111111111111111111111111111112,JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN")
        if let solPriceData = response.data["So11111111111111111111111111111111111111112"],
           let jupPriceData = response.data["JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"] {
            #expect(solPriceData.price.isEmpty == false)
            #expect(jupPriceData.price.isEmpty == false)
        } else {
            #expect(Bool(false))
        }
        print(response)
        
        response = try await JupiterApi.price(for: "So11111111111111111111111111111111111111112,JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN", includeExtraInfo: true)
        if let solPriceData = response.data["So11111111111111111111111111111111111111112"],
            let jupPriceData = response.data["JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"] {
            #expect(solPriceData.extraInfo != nil)
            #expect(jupPriceData.extraInfo != nil)
        } else {
            #expect(Bool(false))
        }
        
        response = try await JupiterApi.price(
            for: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN,27G8MtK7VtTcCHkpASjSDdkWWYfoqT6ggEuKidVJidD4",
            baseOnToken: "So11111111111111111111111111111111111111112")
        if let jupPriceData = response.data["JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"],
           let jlpPriceData = response.data["27G8MtK7VtTcCHkpASjSDdkWWYfoqT6ggEuKidVJidD4"] {
            #expect(jupPriceData.price.doubleValue() < 1)
            #expect(jlpPriceData.price.doubleValue() < 1)
        } else {
            #expect(Bool(false))
        }
    }
}

extension String {
    func doubleValue() -> Double {
        return Double(self) ?? 0
    }
}
