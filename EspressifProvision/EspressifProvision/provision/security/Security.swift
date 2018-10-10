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
//  Security.swift
//  EspressifProvision
//

import Foundation

/// Enum which encapsulates errors which can occur in the Security handshake
/// with the device
///
/// - sessionStateError: session state mismatch between device and mobile
/// - handshakeError: handshake error between device and mobile
/// - keygenError: error is generating valid matching keys between device and mobile
enum SecurityError: Error {
    case sessionStateError(String)

    case handshakeError(String)

    case keygenError(String)
}

/// Security interface which abstracts
/// the handshake and crypto behavior supported by a specific
/// class / family of devices

protocol Security {
    /// Get the next request based upon the current Session
    /// state and the response data passed to this function

    ///
    /// - Parameter data: Data that was received in the previous step
    /// - Returns: Data to be sent in the next step
    /// - Throws: Security errors
    func getNextRequestInSession(data: Data?) throws -> Data?

    /// Encrypt data according to the Security implementation
    ///
    /// - Parameter data: data to be sent
    /// - Returns: encrypted version
    func encrypt(data: Data) -> Data?

    /// Decrypt data according to the Security implementation
    ///
    /// - Parameter data: data from device
    /// - Returns: decrypted data
    func decrypt(data: Data) -> Data?
}
