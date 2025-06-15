//
//  JupiterApi.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Alamofire

public enum JupiterApi {
    internal static let retryPolicy = DefaultRetryPolicy()

    public static func configure(version: JupiterApiConfig.Version = .v1, mode: JupiterApiConfig.Mode, component: String = "quote") async {
        await JupiterApiConfig.shared.configure(mode: mode)
        await JupiterApiConfig.shared.setVersion(version: version)
        await JupiterApiConfig.shared.setComponent(component)
    }

    public static func getQuoteURL(endpoint: String) async -> String {
        let base = await JupiterApiConfig.shared.url
        return base + endpoint
    }

    public static func getHeaders() async -> HTTPHeaders {
        return await JupiterApiConfig.shared.getHeaders()
    }
    
    static func debugLogRequest(_ request: DataRequest) {
    #if DEBUG
        request.cURLDescription { description in
            print("📤 cURL Request:\n\(description)")
        }

        request.responseString { response in
            if let body = response.value {
                print("📥 Raw Response:\n\(body)")
            } else {
                print("📥 No response body")
            }
        }
    #endif
    }
}
