import Foundation

public enum JupiterError: Error, LocalizedError {
    case invalidTransaction(String)
    case signingFailed(String)
    case invalidPrivateKey
    case libsodiumInitFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidTransaction(let reason):
            return "Invalid transaction: \(reason)"
        case .signingFailed(let reason):
            return "Signing failed: \(reason)"
        case .invalidPrivateKey:
            return "Invalid private key"
        case .libsodiumInitFailed:
            return "Failed to initialize libsodium"
        }
    }
}
