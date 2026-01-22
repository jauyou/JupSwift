//
//  RecurringTests.swift
//  JupSwift
//
//  Created by Zhao You on 14/6/25.
//

import Testing
@testable import JupSwift

struct RecurringTests {

    init() async {

        await ApiTestHelper.configure()

    }



    @Test
    func testCreateRecurringOrderByTimeAndExecute() async throws {
        let privateKey = "{YOUR_PRIVATE_KEY}"
        let inputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let outputMint = "So11111111111111111111111111111111111111112"
        // call Jupiter API
        let timeParams = TimeParams(inAmount: 100000000, interval: 86400, numberOfOrders: 2)
        let result = try await JupiterApi.createRecurringOrder(inputMint: inputMint, outputMint: outputMint, params: .time(timeParams), user: "{YOUR_ADDRESS}")
        print("✅ CreateOrder response: \(result)")
        
        let signedTransaction = try signTransaction(base64Transaction: result.transaction, privateKey: privateKey)
        let executeResult = try await JupiterApi.recurringExecute(requestId: result.requestId, signedTransaction: signedTransaction)
        print("✅ Execute response: \(executeResult)")
    }
    
    @Test
    func testCreateRecurringOrderByPriceAndExecute() async throws {
        let privateKey = "{YOUR_PRIVATE_KEY}"
        let inputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let outputMint = "So11111111111111111111111111111111111111112"
        // call Jupiter API
        let priceParams = PriceParams(depositAmount: 100000000, incrementUsdcValue: 10000000, interval: 86400)
        let result = try await JupiterApi.createRecurringOrder(inputMint: inputMint, outputMint: outputMint, params: .price(priceParams), user: "{YOUR_ADDRESS}")
        print("✅ CreateOrder response: \(result)")
        
        let signedTransaction = try signTransaction(base64Transaction: result.transaction, privateKey: privateKey)
        let executeResult = try await JupiterApi.recurringExecute(requestId: result.requestId, signedTransaction: signedTransaction)
        print("✅ Execute response: \(executeResult)")
    }
    
    @Test
    func testGetRecurringOrders() async throws {
        let result = try await JupiterApi.getRecurringOrders(account: "{YOUR_ADDRESS}", orderStatus: .history, recurringType: .all)
        print("✅ GetRecurringOrders response: \(result)")
    }
    
    @Test
    func testCancelkRecurringOrder() async throws {
        let result = try await JupiterApi.cancelRecurringOrder(order: "{ORDER_FROM_GET_RECURRING_ORDERS_RESPONSE}", user: "{YOUR_ADDRESS}", recurringType: "time")
        print("cancel RecurringOrder response: \(result)")
    }
    
    @Test
    func testPriceDeposit() async throws {
        let result = try await JupiterApi.priceDeposit(order: "{ORDER_FROM_GET_RECURRING_ORDERS_RESPONSE}", user: "{YOUR_ADDRESS}", amount: 60000000)
        print("PriceDeposit response: \(result)")
    }
    
    @Test
    func testPriceWithdraw() async throws {
        let result = try await JupiterApi.priceWithdraw(order: "{ORDER_FROM_GET_RECURRING_ORDERS_RESPONSE}", user: "{YOUR_ADDRESS}", amount: 60000000)
        print("PriceWithdraw response: \(result)")
    }
}
