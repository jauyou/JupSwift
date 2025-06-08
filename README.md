# JupSwift

JupSwift is a simple and secure Swift toolkit designed to help developers easily integrate Jupiter and Solana wallet functionalities into their iOS/MacOS applications.

## Features

* **Jupiter Integration:** Seamlessly connect to the Jupiter aggregator for token swaps and other features.
* **Solana Wallet Support:** Interact with Solana wallets to manage assets and sign transactions.
* **Swift Native:** Built with Swift for a modern and efficient development experience on iOS.

## Installation

JupSwift can be integrated into your Xcode project using Swift Package Manager.

1.  In Xcode, open your project and navigate to **File > Add Packages...**.
2.  Enter the repository URL in the search bar: `https://github.com/jauyou/JupSwift.git`
3.  For **Dependency Rule**, select your preferred option (e.g., "Up to Next Major Version").
4.  Click **Add Package**.
5.  Choose the `JupSwift` product and add it to your target.

## Usage

Below is a basic example of how to use JupSwift.

### Initialize Wallet Environment
1.  Generate Mnemonic or impore yours
```swift
let mnemonic = generateMnemonic() // or let mnemonic = { your own mnemonic }
print("mnemonic = \(mnemonic)")
```

2.  Import Mnemonic into wallet
```swift
///
/// Adding a mnemonic will automatically generate the first private key
/// Currently, the wallet only supports a single mnemonic
///
let manager = WalletManager()
do {
    let entry = try await manager.addMnemonic(mnemonic)
}   
```

3.  Retrieve the first private key
```swift
do {
    var privateKeyEntry = try await manager.deriveAndAddPrivateKeyAt(index: 0)
    let walletAddress = privateKeyEntry.address
    let privateKetBase58 = try await manager.getPrivateKeyBase58(id: privateKeyEntry.id)
}
```

### Use Jupiter API
1.  get account balance
```swift
let account = { target address }
let result = try await JupiterApi.balances(account: account)
```

2.  get an order
```swift
let inputMint = "So11111111111111111111111111111111111111112"    // SOL
let outputMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"  // USDC
let amount = "1000000"                                           
let taker = { your address }
        
let result = try await JupiterApi.order(inputMint: inputMint, outputMint: outputMint, amount: amount, taker: taker)
```

3.  get shieldMints
```swift
let mints = [
    "So11111111111111111111111111111111111111112", // Wrapped SOL
    "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"  // USDC
]

do {
    let result = try await JupiterApi.shield(mints: mints)
}
```

4.  get route
```swift
let routers = try await JupiterApi.routers()
```

5.  execute order
```swift
let orderResponse = // from responese of order api
let signedTransactionBase64 = signTransaction(base64Transaction: transaction, privateKey: privateKey)
JupiterApi.execute(signedTransaction: signedTransactionBase64, requestId: orderResponse.requestId) { result in
    switch result {
        case .success(let executeResponse):
            onComplete(.success(executeResponse))
        case .failure(let error):
            onComplete(.failure(error))
    }
}
```

6.  The easier way to get order and execute order 
```swift
JupiterApi.ultraSwap(inputMint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", outputMint: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN", amoumt: "22763399", taker: "YOUR_SOLANA_ADDRESS_HERE", privateKey: "YOUR_PRIVATE_KEY_HERE") { result in
    switch result {
        case .success(let executeResponse):
            print("✅ execute Order success")
            print(executeResponse)
        case .failure(let error):
            print("❌ API error: \(error.localizedDescription)")
    }
}
```

## Dependencies
```
dependencies: [
            .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
            .package(url: "https://github.com/jauyou/Clibsodium.git", from: "1.0.0"),
            .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2")
]
```

## Support
If you appreciate the work put into this open-source project and find JupSwift useful, please consider supporting its development. Your contributions help maintain and improve the toolkit. 🚀

You can show your support by sending a donation to one of the following wallet addresses:

EVM (Ethereum, BSC, Polygon, etc.) : 
```
0xC298710c19A8fE46d4f7FEbC88b35518E610dDf4
```

SOL (Solana) : 
```
ULNw3m7kxvPP8RHXAwYRTW5yQos7RWB4nmVBsiCix6V
```

Thank you for your support! ✨

## Contributing
Contributions to JupSwift are welcome! If you would like to contribute, please follow these steps:

1.  Fork the repository on GitHub.
2.  Create a new branch for your feature or bug fix: git checkout -b feature/your-feature-name or git checkout -b fix/your-bug-fix.
3.  Make your changes and commit them with descriptive messages: git commit -m "Add some amazing feature".
4.  Push your changes to your forked repository: git push origin feature/your-feature-name.
5.  Submit a pull request to the main branch of the original jauyou/JupSwift repository.

Please ensure your code adheres to the existing style and includes relevant tests if applicable.

## License
JupSwift is released under the MIT license. See [LICENSE](https://github.com/jauyou/JupSwift/blob/main/LICENSE) for details.
