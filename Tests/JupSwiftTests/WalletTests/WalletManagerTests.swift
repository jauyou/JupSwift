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
            
            privateKeyEntry = try await manager.getPrivateKeysEntryAtIndex(index: 1)
            #expect(privateKeyEntry.address == "2Hgf4yX6Xgv9jYisdyKPLpbgLAf8MEE4cuByUv7bYkvX")
            var privateKetBase58 = try await manager.getPrivateKeyBase58(id: privateKeyEntry.id)
            #expect(privateKetBase58 == "5H9zE9jtbsigsKRv5CTTZr8mCRYAyv9246bZFxkkLUyfhb3dDDPCgzR5L443J7oDZQvLSMqmT9mhscHGg1Zfo8xb")
            
            // import a private key
            let inputPrivateKey = "5JhEPjhLsS5zV9oacTrFWbmwogSeTq1L7Cn1KRSequcrWi971gLHd8bPb5ZTRzdBkcBc3EnhGTFYezb5HihcxbfD"
            _ = try await manager.addPrivateKey(inputPrivateKey)
            privateKeyEntry = try await manager.getPrivateKeysEntryAtIndex(index: 2)
            #expect(privateKeyEntry.address == "EKoFjerWQxNpwbj2piTgp89miobEe8nBKDPQvgeYzhH1")
            privateKetBase58 = try await manager.getPrivateKeyBase58(id: privateKeyEntry.id)
            #expect(privateKetBase58 == "5JhEPjhLsS5zV9oacTrFWbmwogSeTq1L7Cn1KRSequcrWi971gLHd8bPb5ZTRzdBkcBc3EnhGTFYezb5HihcxbfD")
            
            _ = try await manager.deriveAndAddPrivateKeyAt(index: 0)
            privateKeyEntry = try await manager.getPrivateKeysEntryAtIndex(index: 3)
            #expect(privateKeyEntry.address == "36zzFa2XdbAZWvV62eLDhmv9PJfdTRNVY1T915Z4P6hC")
            
            _ = try await manager.deriveAndAddPrivateKeyAt(index: 0)
            privateKeyEntry = try await manager.getPrivateKeysEntryAtIndex(index: 4)
            #expect(privateKeyEntry.address == "8LyaHvb6eeUw2M6yikT55RqrzMvijNzq5tFqfA67wULT")
            
            privateKeyCount = await manager.getPrivateKeysEntry().count
            #expect(privateKeyCount == 5)
        } catch {
            print("❌ addMnemonic test failed with error: \(error.localizedDescription)")
        }
    }
}
    
