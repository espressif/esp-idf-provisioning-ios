// Copyright 2024 Espressif Systems
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
//  ThreadCredentialsManager.swift
//  ESPProvisionSample
//

import UIKit
import ThreadNetwork
import ESPProvision

@available(iOS 16.4, *)
class ThreadCredentialsManager: NSObject {
    
    static let shared = ThreadCredentialsManager()
    let client = THClient()
    
    /// Is thread supported
    /// - Parameter completion: status
    func isThreadSupported(_ completion: @escaping (Bool) -> Void) {
        self.client.isPreferredNetworkAvailable { result in
            completion(result)
        }
    }
    
    /// Fetch thread credetials
    /// - Parameter completion: THCredentials
    func fetchThreadCredentials(_ completion: @escaping (THCredentials?) -> Void) {
        self.client.retrievePreferredCredentials { credentials, _ in
            completion(credentials)
        }
    }
}
