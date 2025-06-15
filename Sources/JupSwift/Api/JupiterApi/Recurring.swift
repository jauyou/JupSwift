//
//  Recurring.swift
//  JupSwift
//
//  Created by Zhao You on 14/6/25.
//

import Alamofire
import Foundation

public extension JupiterApi {
    /// Creates a recurring order using the Jupiter Lite API.
    ///
    /// This function sends a POST request to the `/createOrder` endpoint
    /// with the given mints, user public key, and recurring order parameters.
    ///
    /// - Parameters:
    ///   - inputMint: The mint address of the input token (e.g., USDC).
    ///   - outputMint: The mint address of the output token (e.g., SOL).
    ///   - params: The recurring order parameters (either time-based or price-based).
    ///   - user: The user's public key string.
    ///
    /// - Returns: A `CreateRecurringOrderResponse` containing order details from the API.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    static func createRecurringOrder(inputMint: String, outputMint: String, params: RecurringParams, user: String) async throws -> CreateRecurringOrderResponse {
        await JupiterApi.configure(mode: .lite, component: "recurring")
        let url = await getQuoteURL(endpoint: "/createOrder")
        let requestBody = CreateRecurringOrderRequest(user: user, inputMint: inputMint, outputMint: outputMint, params: params)
        
        let headers = await getHeaders()
        
        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(CreateRecurringOrderResponse.self)
            .value
        return response
    }
    
    /// Executes a signed recurring order transaction via the Jupiter Lite API.
    ///
    /// This function submits a signed transaction for a recurring order execution
    /// to the `/execute` endpoint, using the provided request ID.
    ///
    /// - Parameters:
    ///   - requestId: The unique identifier for the recurring order execution request.
    ///   - signedTransaction: The base64-encoded signed transaction string.
    ///
    /// - Returns: A `RecurringExecuteResponse` with the result of the execution.
    /// - Throws: An error if the network request fails or the response cannot be parsed.
    static func recurringExecute(requestId: String, signedTransaction: String) async throws -> RecurringExecuteResponse {
        await JupiterApi.configure(mode: .lite, component: "recurring")
        let url = await getQuoteURL(endpoint: "/execute")
        let requestBody = RecurringExecuteRequest(requestId: requestId, signedTransaction: signedTransaction)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(RecurringExecuteResponse.self)
            .value
        return response
    }
    
    /// Fetches recurring orders for a given user account from the Jupiter Lite API.
    ///
    /// This function queries the `/getRecurringOrders` endpoint with the user's public key,
    /// filtered by order status and recurring type (time-based or price-based).
    ///
    /// - Parameters:
    ///   - account: The public key of the user whose recurring orders you want to fetch.
    ///   - orderStatus: The status of the orders to fetch (e.g., `.active`, `.history`).
    ///   - recurringType: The type of recurring order (e.g., `.time`, `.price`).
    ///
    /// - Returns: A `GetRecurringOrdersResponse` containing a list of matching recurring orders.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    static func getRecurringOrders(account: String, orderStatus: OrderStatus, recurringType: RecurringType) async throws -> GetRecurringOrdersResponse {
        await JupiterApi.configure(mode: .lite, component: "recurring")
        let url = await getQuoteURL(endpoint: "/getRecurringOrders?user=\(account)&orderStatus=\(orderStatus)&recurringType=\(recurringType)&includeFailedTx=true")
        let response = try await AF.request(url, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(GetRecurringOrdersResponse.self)
            .value
        return response
    }
    
    /// Cancels an existing recurring order using the Jupiter Lite API.
    ///
    /// This function sends a POST request to the `/cancelOrder` endpoint to cancel a specific recurring order.
    /// It requires the order ID, user public key, and the recurring type (e.g., "time" or "price").
    ///
    /// - Parameters:
    ///   - order: The order key (ID) of the recurring order to cancel.
    ///   - user: The public key of the user who owns the order.
    ///   - recurringType: The type of the recurring order ("time" or "price").
    ///
    /// - Returns: A `CancelRecurringOrderResponse` indicating the result of the cancellation.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    static func cancelRecurringOrder(order: String, user: String, recurringType: String) async throws -> CancelRecurringOrderResponse {
        await JupiterApi.configure(mode: .lite, component: "recurring")
        let url = await getQuoteURL(endpoint: "/cancelOrder")
        let requestBody = CancelRecurringOrderRequest(order: order, user: user, recurringType: recurringType)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(CancelRecurringOrderResponse.self)
            .value
        return response
    }
    
    /// Deposits additional funds into an existing price-based recurring order.
    ///
    /// This function sends a POST request to the `/priceDeposit` endpoint to increase the total deposit
    /// for a price-based recurring order. This is useful when the upcoming orders require more funds
    /// than originally provided.
    ///
    /// - Parameters:
    ///   - order: The order key (ID) of the recurring order to deposit into.
    ///   - user: The public key of the user who owns the order.
    ///   - amount: The amount to deposit, in base units (e.g., 6 decimals for USDC means 50 USDC = 50_000_000).
    ///
    /// - Returns: A `PriceDepositeResponse` confirming the deposit was processed.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    static func priceDeposit(order: String, user: String, amount: UInt64) async throws -> PriceDepositeResponse {
        await JupiterApi.configure(mode: .lite, component: "recurring")
        let url = await getQuoteURL(endpoint: "/priceDeposit")
        let requestBody = PriceDepositeRequest(order: order, user: user, amount: amount)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(PriceDepositeResponse.self)
            .value
        
        return response
    }
    
    /// Withdraws unused funds from a price-based recurring order on Jupiter.
    ///
    /// Sends a POST request to the `/priceWithdraw` endpoint to withdraw USDC that was previously
    /// deposited into a recurring order but not yet used in executed trades.
    ///
    /// - Parameters:
    ///   - order: The unique identifier (order key) of the recurring order.
    ///   - user: The user's public key (wallet address) who owns the order.
    ///   - amount: The amount to withdraw, in base units (e.g., 1 USDC = 1_000_000).
    ///
    /// - Returns: A `PriceWithdrawResponse` object containing the result of the withdrawal.
    /// - Throws: An error if the request fails or the response cannot be decoded.
    static func priceWithdraw(order: String, user: String, amount: UInt64) async throws -> PriceWithdrawResponse {
        await JupiterApi.configure(mode: .lite, component: "recurring")
        let url = await getQuoteURL(endpoint: "/priceWithdraw")
        let requestBody = PriceWithdrawRequest(order: order, user: user, amount: amount)
        
        let headers = await getHeaders()

        let response = try await AF.request(url,
                                            method: .post,
                                            parameters: requestBody,
                                            encoder: JSONParameterEncoder.default,
                                            headers: headers,
                                            interceptor: retryPolicy)
            .validate()
            .serializingDecodable(PriceWithdrawResponse.self)
            .value
        
//        let dataRequest = AF.request(url,
//                                     method: .post,
//                                     parameters: requestBody,
//                                     encoder: JSONParameterEncoder.default,
//                                     headers: headers,
//                                     interceptor: retryPolicy)
//        
//        dataRequest.cURLDescription { description in
//            print("📤 cURL Request:\n\(description)")
//        }
//        
//        let response = try await dataRequest
//            .validate()
//            .serializingDecodable(PriceWithdrawResponse.self)
//            .value
        
        return response
    }
}
