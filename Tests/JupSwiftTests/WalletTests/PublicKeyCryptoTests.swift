//
//  PublicKeyCryptoTests.swift
//  JupSwift
//
//  Created by Claude on 16/4/26.
//

import Foundation
import Testing
@testable import JupSwift

struct PublicKeyCryptoTests {

    // Test keypair from MnemonicTests (known good values)
    let testPublicKey = "9pMbqzoZJxSpaMtMJ9zaJqxY75K8esjL43WMTCnNCj1r"
    let testPrivateKey = "4scfLzpeawg5YSGFHcQTndPvaLxqb7weSr1cwkEU7bpMhxgaWTjGavYyKrtgRV115H8uin1NKYQxvQwac78nz5BN"

    let crypto = PublicKeyCrypto.shared

    // MARK: - Round-trip Tests

    @Test
    func testEncryptDecryptRoundTrip() async throws {
        let message = "Hello Solana".data(using: .utf8)!

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: testPrivateKey)

        #expect(decrypted == message)
    }

    @Test
    func testEncryptDecryptEmptyData() async throws {
        let message = Data()

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: testPrivateKey)

        #expect(decrypted == message)
    }

    @Test
    func testEncryptDecryptLargeData() async throws {
        // 10KB of random-ish data
        let message = Data((0..<10240).map { UInt8($0 % 256) })

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: testPrivateKey)

        #expect(decrypted == message)
    }

    @Test
    func testEncryptDecryptUTF8() async throws {
        let message = "你好世界 🌍 Solana".data(using: .utf8)!

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: testPrivateKey)

        #expect(decrypted == message)
        #expect(String(data: decrypted, encoding: .utf8) == "你好世界 🌍 Solana")
    }

    @Test
    func testEncryptWithPublicKeyStruct() async throws {
        let publicKey = PublicKey(base58: testPublicKey)
        let message = "test with PublicKey struct".data(using: .utf8)!

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: publicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: testPrivateKey)

        #expect(decrypted == message)
    }

    @Test
    func testDecryptWithUInt8ArrayPrivateKey() async throws {
        let message = "test with [UInt8] key".data(using: .utf8)!
        let privateKeyBytes = Base58.decode(testPrivateKey)!

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: privateKeyBytes)

        #expect(decrypted == message)
    }

    // MARK: - Ciphertext Properties

    @Test
    func testCiphertextDiffersEachTime() async throws {
        let message = "same message".data(using: .utf8)!

        let encrypted1 = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)
        let encrypted2 = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)

        // Sealed box uses ephemeral keys, so ciphertexts should differ
        #expect(encrypted1 != encrypted2)

        // But both should decrypt to the same plaintext
        let decrypted1 = try await crypto.decrypt(encrypted1, privateKey: testPrivateKey)
        let decrypted2 = try await crypto.decrypt(encrypted2, privateKey: testPrivateKey)
        #expect(decrypted1 == message)
        #expect(decrypted2 == message)
    }

    @Test
    func testCiphertextSizeOverhead() async throws {
        let message = "test".data(using: .utf8)!
        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)

        // Sealed box overhead = crypto_box_sealbytes() = 48 bytes
        // (32 bytes ephemeral public key + 16 bytes MAC)
        #expect(encrypted.count == message.count + 48)
    }

    // MARK: - Error Cases

    @Test
    func testEncryptWithInvalidPublicKey() async {
        let message = "test".data(using: .utf8)!

        do {
            _ = try await crypto.encrypt(message, recipientPublicKey: "invalidBase58Key")
            #expect(Bool(false), "Should have thrown")
        } catch let error as PublicKeyCryptoError {
            #expect(error == .invalidPublicKey)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test
    func testDecryptWithInvalidPrivateKey() async {
        let message = "test".data(using: .utf8)!
        let encrypted = try! await crypto.encrypt(message, recipientPublicKey: testPublicKey)

        do {
            _ = try await crypto.decrypt(encrypted, privateKey: "invalidKey")
            #expect(Bool(false), "Should have thrown")
        } catch let error as PublicKeyCryptoError {
            #expect(error == .invalidPrivateKey)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test
    func testDecryptWithWrongPrivateKey() async throws {
        let message = "secret message".data(using: .utf8)!
        let encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)

        // Use the second keypair from MnemonicTests (different key)
        let wrongPrivateKey = "5H9zE9jtbsigsKRv5CTTZr8mCRYAyv9246bZFxkkLUyfhb3dDDPCgzR5L443J7oDZQvLSMqmT9mhscHGg1Zfo8xb"

        do {
            _ = try await crypto.decrypt(encrypted, privateKey: wrongPrivateKey)
            #expect(Bool(false), "Should have thrown")
        } catch let error as PublicKeyCryptoError {
            #expect(error == .decryptionFailed)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test
    func testDecryptTamperedCiphertext() async throws {
        let message = "important data".data(using: .utf8)!
        var encrypted = try await crypto.encrypt(message, recipientPublicKey: testPublicKey)

        // Tamper with the ciphertext
        encrypted[encrypted.count - 1] ^= 0xFF

        do {
            _ = try await crypto.decrypt(encrypted, privateKey: testPrivateKey)
            #expect(Bool(false), "Should have thrown")
        } catch let error as PublicKeyCryptoError {
            #expect(error == .decryptionFailed)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test
    func testDecryptTruncatedCiphertext() async {
        // Ciphertext shorter than sealed box overhead should fail
        let shortData = Data(repeating: 0, count: 10)

        do {
            _ = try await crypto.decrypt(shortData, privateKey: testPrivateKey)
            #expect(Bool(false), "Should have thrown")
        } catch let error as PublicKeyCryptoError {
            #expect(error == .decryptionFailed)
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    // MARK: - Key Conversion Tests

    @Test
    func testEd25519ToX25519KeyConversion() async throws {
        let publicKeyBytes = Base58.decode(testPublicKey)!
        let x25519PK = try await crypto.ed25519PublicKeyToX25519(publicKeyBytes)

        #expect(x25519PK.count == 32)
        // Converted key should differ from original
        #expect(x25519PK != publicKeyBytes)
    }

    @Test
    func testEd25519ToX25519SecretKeyConversion() async throws {
        let privateKeyBytes = Base58.decode(testPrivateKey)!
        let x25519SK = try await crypto.ed25519SecretKeyToX25519(privateKeyBytes)

        #expect(x25519SK.count == 32)
    }

    // MARK: - Cross-keypair Test

    @Test
    func testEncryptForSecondKeypairDecryptWithSecond() async throws {
        let secondPublicKey = "2Hgf4yX6Xgv9jYisdyKPLpbgLAf8MEE4cuByUv7bYkvX"
        let secondPrivateKey = "5H9zE9jtbsigsKRv5CTTZr8mCRYAyv9246bZFxkkLUyfhb3dDDPCgzR5L443J7oDZQvLSMqmT9mhscHGg1Zfo8xb"

        let message = "message for second keypair".data(using: .utf8)!

        let encrypted = try await crypto.encrypt(message, recipientPublicKey: secondPublicKey)
        let decrypted = try await crypto.decrypt(encrypted, privateKey: secondPrivateKey)

        #expect(decrypted == message)
    }
}

