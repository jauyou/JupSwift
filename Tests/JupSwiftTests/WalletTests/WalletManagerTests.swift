//
//  WalletManagerTests.swift
//  JupSwift
//
//  Created by Zhao You on 25/5/25.
//

import Foundation
import Testing
@testable import JupSwift

struct WalletManagerTests {
    
    @Test
    func testResetWallet() async {
        let manager = WalletManager()
        do {
            try await manager.resetWallet()
            
            let walletCount = await manager.getMnemonicEntryArray().count
            #expect(walletCount == 0)
            
            let privateKeyCount = await manager.getPrivateKeysEntry().count
            #expect(privateKeyCount == 0)
        } catch {
            print("❌ resetWallet test failed with error: \(error.localizedDescription)")
        }
    }
    
    @Test
    func testAddMnemonicFunction() async {
        let testMnemonic = "rival pledge marriage dove vicious okay ethics answer transfer link pave whip"
        let manager = WalletManager()

        do {
            try await manager.resetWallet()
            let entry = try await manager.addMnemonic(testMnemonic)
            let restored = try await manager.getMnemonic(id: entry.id)

            #expect(restored == testMnemonic)

            var mnemonicCount = await manager.getMnemonicEntryArray().count
            #expect(mnemonicCount == 1)
            
            var privateKeyCount = await manager.getPrivateKeysEntry().count
            #expect(privateKeyCount == 1)
            
            var privateKeyEntry = try await manager.deriveAndAddPrivateKeyAt(index: 0)
            mnemonicCount = await manager.getMnemonicEntryArray().count
            #expect(mnemonicCount == 1)
            
            privateKeyCount = await manager.getPrivateKeysEntry().count
            #expect(privateKeyCount == 2)
            
            var privateKey = try await manager.getPrivateKeysEntryAtIndex(index: 1)
            #expect(privateKeyEntry.address == "2Hgf4yX6Xgv9jYisdyKPLpbgLAf8MEE4cuByUv7bYkvX")
            
            // import a private key
            let inputPrivateKey = "5JhEPjhLsS5zV9oacTrFWbmwogSeTq1L7Cn1KRSequcrWi971gLHd8bPb5ZTRzdBkcBc3EnhGTFYezb5HihcxbfD"
            _ = try await manager.addPrivateKey(inputPrivateKey)
            privateKey = try await manager.getPrivateKeysEntryAtIndex(index: 2)
            #expect(privateKey.address == "EKoFjerWQxNpwbj2piTgp89miobEe8nBKDPQvgeYzhH1")
            
            privateKeyEntry = try await manager.deriveAndAddPrivateKeyAt(index: 0)
            privateKey = try await manager.getPrivateKeysEntryAtIndex(index: 3)
            #expect(privateKey.address == "36zzFa2XdbAZWvV62eLDhmv9PJfdTRNVY1T915Z4P6hC")
            
            privateKeyEntry = try await manager.deriveAndAddPrivateKeyAt(index: 0)
            privateKey = try await manager.getPrivateKeysEntryAtIndex(index: 4)
            #expect(privateKey.address == "8LyaHvb6eeUw2M6yikT55RqrzMvijNzq5tFqfA67wULT")
            
            privateKeyCount = await manager.getPrivateKeysEntry().count
            #expect(privateKeyCount == 5)
        } catch {
            print("❌ addMnemonic test failed with error: \(error.localizedDescription)")
        }
    }
}
    
