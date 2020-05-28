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
//  Security0.swift
//  EspressifProvision
//

import Foundation
import SwiftProtobuf

enum Security0SessionState: Int {
    case State0

    case State1
}

class Security0: Security {
    var sessionState: Security0SessionState = .State0
    func getNextRequestInSession(data: Data?) throws -> Data? {
        var response: Data?
        do {
            switch sessionState {
            case .State0:
                sessionState = .State1
                response = try getStep0Request()!
            case .State1:
                try processStep0Response(response: data)
            }
        } catch {
            response = nil
        }

        return response
    }

    func encrypt(data: Data) -> Data? {
        return data
    }

    func decrypt(data: Data) -> Data? {
        return data
    }

    private func getStep0Request() throws -> Data? {
        var request: Data?
        var sessionData = Espressif_SessionData()
        sessionData.secVer = .secScheme0
        do {
            try sessionData.sec0.sc.merge(serializedData: Espressif_S0SessionCmd().serializedData())
            request = try? sessionData.serializedData()
        } catch {
            throw error
        }

        return request
    }

    private func processStep0Response(response: Data?) throws {
        guard let response = response else {
            throw SecurityError.handshakeError("Response is nil")
        }
        var sessionData = try Espressif_SessionData(serializedData: response)
        if sessionData.secVer != .secScheme0 {
            throw SecurityError.handshakeError("Security version mismatch")
        }
    }
}
