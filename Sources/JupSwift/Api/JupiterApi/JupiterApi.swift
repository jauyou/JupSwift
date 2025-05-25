//
//  JupiterApi.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Alamofire

public enum JupiterApi {
    internal static let retryPolicy = DefaultRetryPolicy()

    public static func configure(mode: JupiterApiConfig.Mode, component: String = "quote") async {
        await JupiterApiConfig.shared.configure(mode: mode)
        await JupiterApiConfig.shared.setComponent(component)
    }

    public static func getQuoteURL(endpoint: String) async -> String {
        let base = await JupiterApiConfig.shared.url
        return base + endpoint
    }

    public static func getHeaders() async -> HTTPHeaders {
        return await JupiterApiConfig.shared.getHeaders()
    }
}
