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
//  HTTPTransport.swift
//  EspressifProvision
//

import Foundation

struct SoftAPTransport: Transport {
    var utility: Utility

    func isDeviceConfigured() -> Bool {
        return true
    }

    var baseUrl: String

    /// Create HTTP implementation of Transport protocol
    ///
    /// - Parameter baseUrl: base URL for the HTTP endpoints
    init(baseUrl: String) {
        self.baseUrl = baseUrl
        utility = Utility()
        utility.scanPath = "prov-scan"
    }

    private func SendHTTPData(path: String, data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void) {
        let url = URL(string: "http://\(baseUrl)/\(path)")!
        var request = URLRequest(url: url)

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")

        request.httpMethod = "POST"
        request.httpBody = data
        request.timeoutInterval = 10
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }

            let httpStatus = response as? HTTPURLResponse
            if httpStatus?.statusCode != 200 {
                print("statusCode should be 200, but is \(String(describing: httpStatus?.statusCode))")
            }

            completionHandler(data, nil)
        }
        task.resume()
    }

    /// HTTP implementation of the Transport protocol
    ///
    /// - Parameters:
    ///   - data: data to be sent
    ///   - completionHandler: handler called when data is successfully sent and response received
    func SendSessionData(data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void) {
        SendHTTPData(path: "prov-session", data: data, completionHandler: completionHandler)
    }

    /// HTTP implementation of the Transport protocol
    ///
    /// - Parameters:
    ///   - path: path to the config endpoint
    ///   - data: data to be sent
    ///   - completionHandler: handler called when data is successfully sent and response received
    func SendConfigData(path: String, data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void) {
        SendHTTPData(path: path, data: data, completionHandler: completionHandler)
    }

    func disconnect() {}
}
