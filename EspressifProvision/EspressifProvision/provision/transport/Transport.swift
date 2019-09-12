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
//  Transport.swift
//  EspressifProvision
//

import Foundation

enum TransportError: Error {
    case deviceUnreachableError(String)

    case communicationError(Int)
}

/**
 * Transport interface which abstracts the
 * transport layer to send messages to the Device.
 */
protocol Transport {
    var utility: Utility { get }
    /// Send message data relating to session establishment.
    ///
    /// - Parameters:
    ///   - data: data to be sent
    ///   - completionHandler: handler called when data is successfully sent and response is received
    func SendSessionData(data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void)

    /// Send data relating to device configurations
    ///
    /// - Parameters:
    ///   - path: path of the config endpoint
    ///   - data: config data to be sent
    ///   - completionHandler: handler called when data is successfully sent and response is recieved
    func SendConfigData(path: String, data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void)

    func isDeviceConfigured() -> Bool

    func disconnect()
}
