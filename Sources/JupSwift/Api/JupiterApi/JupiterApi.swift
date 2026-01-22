//
//  JupiterApi.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Alamofire
import Foundation

public enum JupiterApi {
    public static let version = "1.3.0"
    
    internal static let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        
        // Custom User-Agent
        // JupSwift/{Version} (Jupiter Aggregator SDK) Alamofire/5.10.2
        let userAgent = "JupSwift/\(version) (Jupiter Aggregator SDK) Alamofire/5.10.2"
        configuration.headers["User-Agent"] = userAgent
        
        return Session(configuration: configuration)
    }()

    internal static let retryPolicy = DefaultRetryPolicy()

    public static func configure(version: JupiterApiConfig.Version = .v1, component: String = "quote") async {
        await JupiterApiConfig.shared.setVersion(version: version)
        await JupiterApiConfig.shared.setComponent(component)
    }
    
    /// Sets the API key for Jupiter Pro API.
    /// This will automatically switch the configuration to `.pro` mode.
    /// - Parameter key: The API key from portal.jup.ag
    public static func setApiKey(_ key: String) async {
        await JupiterApiConfig.shared.setApiKey(key)
    }

    public static func getQuoteURL(endpoint: String, version: JupiterApiConfig.Version? = nil, component: String? = nil) async -> String {
        let base = await JupiterApiConfig.shared.getUrl(version: version, component: component)
        return base + endpoint
    }

    public static func getHeaders() async -> HTTPHeaders {
        return await JupiterApiConfig.shared.getHeaders()
    }
    
    public static func setDebugMode(_ enabled: Bool) async {
        await JupiterApiConfig.shared.setDebugMode(enabled)
    }
    
    static func debugLogRequest(_ request: DataRequest) async {
        let isDebug = await JupiterApiConfig.shared.isDebugMode
        guard isDebug else { return }
        
        request.cURLDescription { description in
            print("📤 cURL Request:\n\(description)")
        }

        request.responseString { response in
            if let statusCode = response.response?.statusCode {
                print("📥 Response Status: \(statusCode)")
            }
            if let body = response.value {
                print("📥 Raw Response:\n\(body)")
            } else {
                print("📥 No response body")
            }
        }
    }
}
