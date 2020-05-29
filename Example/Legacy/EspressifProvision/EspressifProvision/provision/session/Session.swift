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
//  Session.swift
//  EspressifProvision
//

import Foundation

class Session {
    private var transportPrivate: Transport

    var transport: Transport {
        return transportPrivate
    }

    private var securityPrivate: Security
    var security: Security {
        return securityPrivate
    }

    private var isSessionEstablished: Bool

    /// Flag which indicates if the session has been successfully established
    var isEstablished: Bool {
        return isSessionEstablished
    }

    /// Create a session object with the given Transport and Security implementations
    /// Session object is used for establishing a secure connection with the device before
    /// provisioning
    /// - Parameters:
    ///   - transport: Transport implementation
    ///   - security: Security implemenation
    init(transport: Transport, security: Security) {
        transportPrivate = transport
        securityPrivate = security
        isSessionEstablished = false
    }

    /// Initialize the session handshake to establish a secure session with the device
    ///
    /// - Parameters:
    ///   - response: response received from the device
    ///   - completionHandler: handler called when the session establishment completes
    func initialize(response: Data?, completionHandler: @escaping (Error?) -> Swift.Void) {
        do {
            let request = try securityPrivate.getNextRequestInSession(data: response)
            if let request = request {
                transportPrivate.SendSessionData(data: request) { responseData, error in
                    guard error == nil else {
                        completionHandler(error)
                        return
                    }

                    if let responseData = responseData {
                        self.initialize(response: responseData,
                                        completionHandler: completionHandler)
                    } else {
                        completionHandler(SecurityError.handshakeError("Session establish failed"))
                    }
                }
            } else {
                isSessionEstablished = true
                completionHandler(nil)
            }
        } catch {
            completionHandler(error)
        }
    }
}
