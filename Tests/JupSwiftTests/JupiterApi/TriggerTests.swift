//
//  TriggerTests.swift
//  JupSwift
//
//  Created by Zhao You on 9/6/25.
//

import Testing
@testable import JupSwift

struct TriggerTests {

    init() async {

        await ApiTestHelper.configure()

    }



    @Test
    func testCreateOrderAndExecute() async throws {
        let privateKey = "{YOUR_PRIVATE_KEY}"
        let inputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let outputMint = "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN"
        // call Jupiter API
        let result = try await JupiterApi.createOrder(inputMint: inputMint, outputMint: outputMint, makingAmount: "90000000", takingAmount: "200000000", payer: "{YOUR ADDRESS}")
        print("✅ CreateOrder response: \(result)")
        let signedTransaction = try signTransaction(base64Transaction: result.transaction, privateKey: privateKey)
        
        let executeResult = try await JupiterApi.triggerExecute(requestId: result.requestId, signedTransaction: signedTransaction)
        print("✅ Execute response: \(executeResult)")
    }
    
    @Test
    func testCancelOrder() async throws {
        let privateKey = "{YOUR_PRIVATE_KEY}"
        let maker = "{YOUR ADDRESS}"
        let order = "{YOUR ORDERS}"
        let result = try await JupiterApi.cancelTriggerOrder(maker: maker, order: order)
        print("✅ CancelOrder response: \(result)")
        let signedTransaction = try signTransaction(base64Transaction: result.transaction, privateKey: privateKey)
        
        let executeResult = try await JupiterApi.triggerExecute(requestId: result.requestId, signedTransaction: signedTransaction)
        print("✅ Execute response: \(executeResult)")
    }
    
    @Test
    func testCancelOrders() async throws {
        let privateKey = "{YOUR_PRIVATE_KEY}"
        let maker = "{YOUR_ADDRESS}"
        let orders = ["", ""] // your orders
        let result = try await JupiterApi.cancelTriggerOrders(maker: maker, orders: orders)
        print("✅ CancelOrder response: \(result)")
        for base64Transaction in result.transactions {
            do {
                let signedTransaction = try signTransaction(base64Transaction: base64Transaction, privateKey: privateKey)
                
                let executeResult = try await JupiterApi.triggerExecute(
                    requestId: result.requestId,
                    signedTransaction: signedTransaction
                )
                
                print("✅ Execute response: \(executeResult)")
            } catch {
                print("❌ Failed to execute transaction: \(error)")
            }
        }
    }
    
    @Test
    func testGetActiveTriggerOrders() async throws {
        let user = "{YOUR_ADDRESS}"
        let result = try await JupiterApi.getActiveTriggerOrders(user: user)
        print(result)
        
        let historyResult = try await JupiterApi.getHistoryTriggerOrders(user: user)
        print(historyResult)
    }
}
