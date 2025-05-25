//
//  PrivateKey.swift
//  JupSwift
//
//  Created by Zhao You on 24/5/25.
//

import Testing
@testable import JupSwift
import Foundation

struct PrivateKeyTests {
    @Test func testextractPublicKey() {
        let _: String = "9pMbqzoZJxSpaMtMJ9zaJqxY75K8esjL43WMTCnNCj1r"
        let privateKey: String = "4scfLzpeawg5YSGFHcQTndPvaLxqb7weSr1cwkEU7bpMhxgaWTjGavYyKrtgRV115H8uin1NKYQxvQwac78nz5BN"
        
        let privateKeyUInt8: [UInt8] = Base58.decode(privateKey)!
        let privateKeyData = PrivateKey.uint8ArrayToData(privateKeyUInt8)
        _ = PrivateKey.extractPublicKey(from: privateKeyData)
        let publicKeyBase58 = PrivateKey.extractBase58PublicKey(from: privateKeyData)
        
        #expect(publicKeyBase58 == "9pMbqzoZJxSpaMtMJ9zaJqxY75K8esjL43WMTCnNCj1r")
    }
}
        
