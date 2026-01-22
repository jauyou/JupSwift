import Foundation
import JupSwift

struct ApiTestHelper {
    static func configure() async {
        await JupiterApi.setDebugMode(false) // Disable debug mode
        
        if let apiKey = ProcessInfo.processInfo.environment["JUPITER_API_KEY"] {
            await JupiterApi.setApiKey(apiKey)
        }
    }
}
