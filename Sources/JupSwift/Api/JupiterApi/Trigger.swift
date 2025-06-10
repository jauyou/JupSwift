//
//  Trigger.swift
//  JupSwift
//
//  Created by Zhao You on 8/6/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    
    /// Creates a trigger order via Jupiter API.
    ///
    /// - Parameters:
    ///   - inputMint: The mint address of the input token.
    ///   - outputMint: The mint address of the output token.
    ///   - makingAmount: The amount of the input token to provide.
    ///   - takingAmount: The minimum amount of output token to receive.
    ///   - payer: The wallet address paying for the transaction.
    /// - Returns: A `CreateTriggerOrderResponse` containing the order details.
    static func createOrder(inputMint: String, outputMint: String, makingAmount: String, takingAmount: String, payer: String) async throws -> CreateTriggerOrderResponse {
        await JupiterApi.configure(mode: .lite, component: "trigger")
        let url = await getQuoteURL(endpoint: "/createOrder")
        let params: TriggerParams = TriggerParams(makingAmount: makingAmount, takingAmount: takingAmount)
        var requestBody = CreateTriggerOrderRequest(inputMint: inputMint, outputMint: outputMint, maker: payer, payer: payer, params: params)
        if (outputMint == "So11111111111111111111111111111111111111112") {
            requestBody.feeAccount = "3ssPtzEQc42w5zRMjNZSroQ36cToxUGx5AjD3HZCku9N"
        } else if (outputMint == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v") {
            requestBody.feeAccount = "Afkk6kwhiGtRnKwYEJY1XbSG4J8oedB5CXW4zrPy6MLV"
        } else if (outputMint == "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN") {
            requestBody.feeAccount = "4eNzPMjH2Xw5ggXGLeRbZNgxTdDD5KxqKrFAxMJQ5hya"
        }
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(CreateTriggerOrderResponse.self)
            .value
        return response
    }
    
    /// Executes a signed trigger transaction using the Jupiter API.
    ///
    /// - Parameters:
    ///   - requestId: The ID returned from the createOrder call, used to link the transaction.
    ///   - signedTransaction: The base64-encoded signed transaction to be executed.
    /// - Returns: A `TriggerExecuteResponse` containing the execution result.
    static func triggerExecute(requestId: String, signedTransaction: String) async throws -> TriggerExecuteResponse {
        await JupiterApi.configure(mode: .lite, component: "trigger")
        let url = await getQuoteURL(endpoint: "/execute")
        let requestBody = TriggerExecuteRequest(requestId: requestId, signedTransaction: signedTransaction)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(TriggerExecuteResponse.self)
            .value
        return response
    }
    
    /// Cancels a trigger order via the Jupiter API.
    ///
    /// - Parameters:
    ///   - maker: The wallet address that created the order.
    ///   - order: The unique order ID to be cancelled.
    /// - Returns: A `CancelOrderResponse` containing the result of the cancellation.
    static func cancelTriggerOrder(maker: String, order: String) async throws -> CancelOrderResponse {
        await JupiterApi.configure(mode: .lite, component: "trigger")
        let url = await getQuoteURL(endpoint: "/cancelOrder")
        let requestBody = CancelOrder(maker: maker, order: order)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(CancelOrderResponse.self)
            .value
        return response
    }
    
    /// Cancels multiple trigger orders via the Jupiter API.
    ///
    /// - Parameters:
    ///   - maker: The wallet address that created the orders.
    ///   - orders: An array of order IDs to be cancelled.
    /// - Returns: A `CancelOrdersResponse` containing the result of the batch cancellation.
    static func cancelTriggerOrders(maker: String, orders: [String]) async throws -> CancelOrdersResponse {
        await JupiterApi.configure(mode: .lite, component: "trigger")
        let url = await getQuoteURL(endpoint: "/cancelOrder")
        let requestBody = CancelOrders(maker: maker, orders: orders)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(CancelOrdersResponse.self)
            .value
        return response
    }
    
    /// Retrieves all active trigger orders for a specific user.
    ///
    /// - Parameter user: The wallet address of the user.
    /// - Returns: A `GetTriggerOrdersResponse` containing all active orders for the user.
    static func getActiveTriggerOrders(user: String) async throws -> GetTriggerOrdersResponse {
        return try await getTriggerOrders(user: user, orderStatus: "active")
    }
    
    /// Retrieves all historical (executed or cancelled) trigger orders for a specific user.
    ///
    /// - Parameter user: The wallet address of the user.
    /// - Returns: A `GetTriggerOrdersResponse` containing the user's order history.
    static func getHistoryTriggerOrders(user: String) async throws -> GetTriggerOrdersResponse {
        return try await getTriggerOrders(user: user, orderStatus: "history")
    }
    
    static func getTriggerOrders(user: String, orderStatus: String) async throws -> GetTriggerOrdersResponse {
        await JupiterApi.configure(mode: .lite, component: "trigger")
        let url = await getQuoteURL(endpoint: "/getTriggerOrders?user=\(user)&orderStatus=\(orderStatus)")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(GetTriggerOrdersResponse.self)
            .value
        return response
    }
}
