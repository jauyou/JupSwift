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

    public enum Mode: Sendable {
        case pro(apiKey: String)
        case lite
    }

    private var mode: Mode = .lite
    private var component: String = "quote"
    private let version = "v1"

    var url: String {
        return baseDomain + "/" + component + "/" + version + "/"
    }

    var baseDomain: String {
        switch mode {
        case .pro:
            return "https://api.jup.ag"
        case .lite:
            return "https://lite-api.jup.ag"
        }
    }

    var apiKey: String? {
        switch mode {
        case .pro(let key):
            return key
        case .lite:
            return nil
        }
    }

    func configure(mode: Mode) {
        self.mode = mode
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
