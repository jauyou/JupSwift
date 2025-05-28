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
            
            // check if default address set to index 0 and it's value
            var address = try await manager.getCurrentAddress()
            #expect(address == "9pMbqzoZJxSpaMtMJ9zaJqxY75K8esjL43WMTCnNCj1r")
            
            // set wallet to index 1 and check it's value
            try await manager.setCurrentWalletAtIndex(1)
            address = try await manager.getCurrentAddress()
            #expect(address == "2Hgf4yX6Xgv9jYisdyKPLpbgLAf8MEE4cuByUv7bYkvX")
            
            // sign transaction using current wallet
            let unsignedTransaction = "Afoj44vDVRXmWN+2b0XJsCMEUgahMabbSNU+vBnJylWI6A2wncgrljIZOZ9sre83TCsurVREk/X5rJSSiq6hxAuAAQAIDC1DU+v8CS6zsH6P1YDxv34gJqfH4duQts70riDegwRWh7Uj+ncbLnnXrncZ0M9fcpfQPh1Y9fJm+wF6ZvdeXAeT62WWp4H7+l5+SX/26TIX4kW9/UIESJwJ9fRHF2a4BeBV0h/1+T5UibrxqsSxFjlJUiOoGJgKrcpTt5U2/pOyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMlyWPTiSJ8bs9ECkUjg2DC1oTmdr/EIQEjnvY2+n4Wawfg/25zlUN6V1VjNx5VGHM9DdKxojsE6mEACIKeNoGAwZGb+UhFzL/7K26csOb57yM5bvF9xJrLEObOkAAAAC0P/on9df2SnTAmx8pWHneSwmrNt/J3VFLMhqns4zl6Mb6evO+2606PWXzaqvJdDGxu+TC0vbg5HymAgNFL11hBHnVW/IxwG7udMVuzmgVB/2xst6j9I5RArHNola8E48G3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8AqQctTjnSwEUMprS9ERx1Vf9YfO/78A64br56TcDYlZ4IBwcABQLAXBUABwAJA/ThBQAAAAAABAIAAwwCAAAA8P4UBgAAAAAKBQMAFQsECZPxe2T0hK52/gUGAAIACQQLAQEKGAsAAwIKCQEIChEUDQADAgwODxALExMSBiPlF8uXeuOtKgEAAAAZZAABAOH1BQAAAABm+LQAAAAAADMAAAsDAwAAAQkB1oUQRIHodQ7RqM53G2HBODrXHK0Mt23syD9oedgHJVAFuL2gvqEFOLs1vBY="
            let signedTransaction = try await manager.signTransaction(base64Transaction: unsignedTransaction)
            let correctedSignedTransaction = signTransaction(base64Transaction: unsignedTransaction, privateKey: "5H9zE9jtbsigsKRv5CTTZr8mCRYAyv9246bZFxkkLUyfhb3dDDPCgzR5L443J7oDZQvLSMqmT9mhscHGg1Zfo8xb")
            #expect(signedTransaction == correctedSignedTransaction)
        } catch {
            print("❌ addMnemonic test failed with error: \(error.localizedDescription)")
        }
    }
}
    
