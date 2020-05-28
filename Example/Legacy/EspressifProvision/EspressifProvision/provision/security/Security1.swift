// Copyright 2018 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Security1.swift
//  EspressifProvision
//

import Curve25519
import Foundation
import Security
import SwiftProtobuf

enum Security1SessionState: Int {
    case Request1
    case Response1Request2
    case Response2
    case Finished
}

class Security1: Security {
    private static let basePoint = Data([9] + [UInt8](repeating: 0, count: 31))

    private var sessionState: Security1SessionState = .Request1
    private var proofOfPossession: Data?
    private var privateKey: Data?
    private var publicKey: Data?
    private var clientVerify: Data?
    private var cryptoAES: CryptoAES?

    private var sharedKey: Data?
    private var deviceRandom: Data?

    /// Create Security 1 implementation with given proof of possession
    ///
    /// - Parameter proofOfPossession: proof of possession identifying the physical device
    init(proofOfPossession: String) {
        self.proofOfPossession = proofOfPossession.data(using: .utf8)
        generateKeyPair()
    }

    func getNextRequestInSession(data: Data?) throws -> Data? {
        var request: Data?
        do {
            switch sessionState {
            case .Request1:
                sessionState = .Response1Request2
                request = try getStep0Request()
            case .Response1Request2:
                sessionState = .Response2
                try processStep0Response(response: data)
                request = try getStep1Request()
            case .Response2:
                sessionState = .Finished
                try processStep1Response(response: data)
            default:
                request = nil
            }
        } catch {
            throw error
        }

        return request
    }

    func encrypt(data: Data) -> Data? {
        guard let cryptoAES = self.cryptoAES else {
            return nil
        }
        return cryptoAES.encrypt(data: data)
    }

    func decrypt(data: Data) -> Data? {
        guard let cryptoAES = self.cryptoAES else {
            return nil
        }
        return cryptoAES.encrypt(data: data)
    }

    private func generatePrivateKey() -> Data? {
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }

    private func generateKeyPair() {
        self.privateKey = generatePrivateKey()
        guard let privateKey = self.privateKey else {
            publicKey = nil
            return
        }
        publicKey = try? Curve25519.publicKey(for: privateKey, basepoint: Security1.basePoint)
    }

    private func getStep0Request() throws -> Data? {
        guard let publicKey = self.publicKey else {
            throw SecurityError.keygenError("Could not generate keypair")
        }
        var sessionData = Espressif_SessionData()
        sessionData.secVer = .secScheme1
        sessionData.sec1.sc0.clientPubkey = publicKey
        do {
            return try sessionData.serializedData()
        } catch {
            throw SecurityError.handshakeError("Cannot create handshake request 0")
        }
    }

    private func getStep1Request() throws -> Data? {
        guard let verifyData = self.clientVerify else {
            throw SecurityError.keygenError("Could not generate keypair")
        }

        var sessionData = Espressif_SessionData()
        sessionData.secVer = .secScheme1
        sessionData.sec1.msg = .sessionCommand1
        sessionData.sec1.sc1.clientVerifyData = verifyData
        do {
            return try sessionData.serializedData()
        } catch {
            throw SecurityError.handshakeError("Cannot create handshake request 1")
        }
    }

    private func processStep0Response(response: Data?) throws {
        guard let response = response else {
            throw SecurityError.handshakeError("Response 0 is nil")
        }
        var sessionData = try Espressif_SessionData(serializedData: response)
        if sessionData.secVer != .secScheme1 {
            throw SecurityError.handshakeError("Security version mismatch")
        }

        let devicePublicKey = sessionData.sec1.sr0.devicePubkey
        let deviceRandom = sessionData.sec1.sr0.deviceRandom
        do {
            var sharedKey = try Curve25519.calculateAgreement(privateKey: privateKey!, publicKey: devicePublicKey)
            if let pop = self.proofOfPossession, pop.count > 0 {
                let digest = pop.sha256()
                sharedKey = HexUtils.xor(first: sharedKey, second: digest)
            }

            cryptoAES = CryptoAES(key: sharedKey, iv: deviceRandom)

            let verifyBytes = encrypt(data: devicePublicKey)

            if verifyBytes == nil {
                throw SecurityError.handshakeError("Cannot encrypt device key")
            }

            clientVerify = verifyBytes
        } catch {
            print(error)
        }
    }

    private func processStep1Response(response: Data?) throws {
        guard let response = response else {
            throw SecurityError.handshakeError("Response 1 is nil")
        }
        var sessionData = try Espressif_SessionData(serializedData: response)
        if sessionData.secVer != .secScheme1 {
            throw SecurityError.handshakeError("Security version mismatch")
        }

        let deviceVerify = sessionData.sec1.sr1.deviceVerifyData
        let decryptedDeviceVerify = decrypt(data: deviceVerify)
        if let decryptedDeviceVerify = decryptedDeviceVerify,
            !decryptedDeviceVerify.bytes.elementsEqual(self.publicKey!.bytes) {
            throw SecurityError.handshakeError("Key mismatch")
        }
    }
}
