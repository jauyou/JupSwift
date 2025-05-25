//
//  DefaultRetryPolicy.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Alamofire

public final class DefaultRetryPolicy: RequestInterceptor {
    public init() {}
    
    /// Called when a request fails to determine whether it should be retried.
    ///
    /// - Parameters:
    ///   - request: The original `Request` object that failed.
    ///   - session: The current `Session` handling the request.
    ///   - error: The error that triggered the retry logic.
    ///   - completion: A closure that must be called with a `RetryResult` to indicate how to proceed.
    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if request.retryCount < 2 {
            completion(.retryWithDelay(1.0))
        } else {
            completion(.doNotRetry)
        }
    }
}
