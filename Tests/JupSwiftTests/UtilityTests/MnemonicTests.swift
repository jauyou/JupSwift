//
//  MnemonicTests.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation
import Testing
@testable import JupSwift

struct MnemonicTests {
    
    @Test
    func testGenerateMnemonic() {
        let mnemonic = generateMnemonic()
        print("mnemonic = \(mnemonic)")
    }

    @Test
    func testMnemonic() throws {
        // Example usage
        let mnemonic = "rival pledge marriage dove vicious okay ethics answer transfer link pave whip"

        guard let seed = mnemonicToSeed(mnemonic: mnemonic) else {
            fatalError("Seed fail")
        }
        try testKeypairOfMnemonicWalletByIndex(index: 0, seed: seed)
        try testKeypairOfMnemonicWalletByIndex(index: 1, seed: seed)
    }
    
    @Test
    func testMnemonicWithUpperCase() throws {
        // Example usage
        let mnemonic = "rival plEdge marriage dove vicious okAy ethics answer transfer link pave whip"

        guard let seed = mnemonicToSeed(mnemonic: mnemonic) else {
            fatalError("Seed fail")
        }
        try testKeypairOfMnemonicWalletByIndex(index: 0, seed: seed)
        try testKeypairOfMnemonicWalletByIndex(index: 1, seed: seed)
    }
    
    let publicKeyArray: [String] = [
        "9pMbqzoZJxSpaMtMJ9zaJqxY75K8esjL43WMTCnNCj1r",
        "2Hgf4yX6Xgv9jYisdyKPLpbgLAf8MEE4cuByUv7bYkvX"
    ]
    
    let privateKeyArray: [String] = [
        "4scfLzpeawg5YSGFHcQTndPvaLxqb7weSr1cwkEU7bpMhxgaWTjGavYyKrtgRV115H8uin1NKYQxvQwac78nz5BN",
        "5H9zE9jtbsigsKRv5CTTZr8mCRYAyv9246bZFxkkLUyfhb3dDDPCgzR5L443J7oDZQvLSMqmT9mhscHGg1Zfo8xb"
    ]
    
    func testKeypairOfMnemonicWalletByIndex(index: Int, seed: Data) throws {
        let path = "m/44'/501'/" + String(index) + "'/0'"
        let node = derivePath(path: path, seed: seed)

        if let keypair = keypairFromSeed(node.key) {
            let publicKeyBase58 = Base58.encode(keypair.publicKey)
            print("Public Key:", publicKeyBase58)
            let privateKeyBase58 = Base58.encode(keypair.privateKey)
            print("Private Key:", privateKeyBase58)
            
            #expect(publicKeyBase58 == publicKeyArray[index])
            #expect(privateKeyBase58 == privateKeyArray[index])
        }
    }
    
    @Test
    func testKeypairOfMnemonicWalletByIndex() throws {
        if let keypair = keypairOfMnemonicWalletByIndex(
            index: 0,
            mnemonic: "rival pledge marriage dove vicious okay ethics answer transfer link pave whip"
        ) {
            #expect(keypair.publicKey.toBase58String() == "9pMbqzoZJxSpaMtMJ9zaJqxY75K8esjL43WMTCnNCj1r")
            #expect(keypair.privateKey.toBase58String() == "4scfLzpeawg5YSGFHcQTndPvaLxqb7weSr1cwkEU7bpMhxgaWTjGavYyKrtgRV115H8uin1NKYQxvQwac78nz5BN")
            
            let publicKey = keypair.privateKey.subdata(in: 32..<64)
            #expect(keypair.publicKey.toBase58String() == publicKey.toBase58String())
        }
    }
    
    @Test func testValidMnemonicsWithArray() {
        let mnemonic = "rival pledge marriage develop vicious okay ethics answer transfer link pave whip"
        let words = mnemonic.lowercased().split(separator: " ").map { String($0) }
        let result = validateMnemonics(words)

        switch result {
        case .success:
            #expect(true)
        default:
            #expect(Bool(false), "Expected success for valid mnemonic")
        }
    }
    
    @Test
    func testValidMnemonics() {
        let mnemonic = "rival pledge marriage dove vicious okay ethics answer transfer link pave whip"
        let result = validateMnemonics(mnemonic)

        switch result {
        case .success:
            #expect(true)
        default:
            #expect(Bool(false), "Expected success for valid mnemonic")
        }
    }
    
    @Test
    func testValidMnemonicsWithUpperCase() {
        let mnemonic = "rival pledge marRiage dove vicious okay etHics answer transfer link pave whip"
        let result = validateMnemonics(mnemonic)

        switch result {
        case .success:
            #expect(true)
        default:
            #expect(Bool(false), "Expected success for valid mnemonic")
        }
    }

    @Test
    func testInvalidWordCount() {
        let mnemonic = "rival pledge marriage dove fakeword ethics answer transfer link pave whip"
        let result = validateMnemonics(mnemonic)

        switch result {
        case .failure(.invalidWordCount):
            #expect(true)
        default:
            #expect(Bool(false), "Expected .invalidWordCount error")
        }
    }

    @Test
    func testInvalidWords() {
        let mnemonic = "rival pledge marriage develops vicious okay ethics answer transfer link pave whip"
        let result = validateMnemonics(mnemonic)

        switch result {
        case .failure(.invalidWords(let indexes)):
            #expect(indexes == [3])
        default:
            #expect(Bool(false), "Expected .invalidWords with index 3")
        }
    }
    
    @Test
    func testExactMatch() {
        let result = validateMnemonicWord("apple")
        #expect(result == .exactMatch)
    }

    @Test
    func testPartialMatch() {
        let result = validateMnemonicWord("app")
        #expect(result == .partialMatch)
    }
    
    @Test
    func testNoMatch() {
        let result = validateMnemonicWord("zzzzzz")
        #expect(result == .noMatch)
    }
}
