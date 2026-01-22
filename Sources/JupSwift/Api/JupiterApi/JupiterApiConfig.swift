//
//  JupiterApiConfig.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Alamofire

// MARK: - Concurrency-Safe Config Actor
public actor JupiterApiConfig {
    static let shared = JupiterApiConfig()

    public enum Version: Sendable {
        case v1
        case v2
        case v3
        
        var stringValue: String {
            switch self {
            case .v1: return "v1"
            case .v2: return "v2"
            case .v3: return "v3"
            }
        }
    }

    private var apiKey: String?
    private var component: String = "quote"
    private var version: Version = Version.v1
    var isDebugMode: Bool = false

    var url: String {
        return baseDomain + "/" + component + "/" + version.stringValue
    }

    var baseDomain: String {
        return "https://api.jup.ag"
    }

    func getUrl(version: Version? = nil, component: String? = nil) -> String {
        let v = version ?? self.version
        let c = component ?? self.component
        return baseDomain + "/" + c + "/" + v.stringValue
    }

    func setApiKey(_ key: String) {
        self.apiKey = key
    }
    
    func setDebugMode(_ enabled: Bool) {
        self.isDebugMode = enabled
    }
    
    func setVersion(version: Version) {
        self.version = version
    }

    func setComponent(_ name: String) {
        self.component = name
    }

    func getHeaders() -> HTTPHeaders {
        var headers: [String: String] = [
            "Content-Type": "application/json"
        ]
        if let key = apiKey {
            headers["x-api-key"] = key
        }
        return HTTPHeaders(headers)
    }
}
