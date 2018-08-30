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
//  ConfigureAVS.swift
//  EspressifProvision
//

#if AVS
    import Foundation

    class ConfigureAVS {
        let session: Session
        let security: Security
        let transport: Transport

        public static let AUTH_CODE = "authCode"
        public static let PRODUCT_ID = "productID"
        public static let CLIENT_ID = "clientId"
        public static let REDIRECT_URI = "redirectUri"
        public static let CODE_VERIFIER = "codeVerifier"
        public static let DEVICE_SERIAL_NUMBER = "deviceSerialNumber"
        public static let AVS_CONFIG_PATH = "avsconfig"
        public static let AVS_CONFIG_UUID_KEY = "avsconfigUUID"

        private static let PRODUCT_INSTANCE_ATTRIBUTES = "productInstanceAttributes"
        private static let AMZN_SCOPE = "alexa:all"

        init(session: Session) {
            self.session = session
            security = session.security
            transport = session.transport
        }

        public static func loginWithAmazon(productId: String,
                                           deviceSerialNumber: String,
                                           codeVerifier: String,
                                           completionHandler: @escaping ([String: String]?, Error?) -> Swift.Void) {
            let request = AMZNAuthorizeRequest()

            let scopeData: [AnyHashable: Any] = [
                PRODUCT_ID: productId,
                PRODUCT_INSTANCE_ATTRIBUTES: [DEVICE_SERIAL_NUMBER: deviceSerialNumber],
            ]
            request.scopes = [AMZNScopeFactory.scope(withName: AMZN_SCOPE, data: scopeData)]
            request.grantType = .code
            request.interactiveStrategy = .auto
            request.codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier)
            request.codeChallengeMethod = "S256"

            AMZNAuthorizationManager.shared().authorize(request) { result, didCancel, error in
                if let error = error {
                    print(error.localizedDescription)
                    completionHandler(nil, error)
                } else if didCancel {
                    completionHandler(nil, error)
                } else {
                    if let authCode = result?.authorizationCode,
                        let clientId = result?.clientId,
                        let redirectUri = result?.redirectUri {
                        completionHandler([
                            AUTH_CODE: authCode,
                            CODE_VERIFIER: codeVerifier,
                            CLIENT_ID: clientId,
                            REDIRECT_URI: redirectUri,
                        ], nil)
                    }
                }
            }
        }

        public func configureAmazonLogin(cliendId: String,
                                         authCode: String,
                                         redirectUri: String,
                                         codeVerifier: String,
                                         completionHandler: @escaping (Avs_AVSConfigStatus, Error?) -> Swift.Void) {
            if session.isEstablished {
                do {
                    let message = try createSetAVSConfigRequest(cliendId: cliendId,
                                                                authCode: authCode,
                                                                redirectUri: redirectUri,
                                                                codeVerifier: codeVerifier)
                    if let message = message {
                        transport.SendConfigData(path: ConfigureAVS.AVS_CONFIG_PATH, data: message) { response, error in
                            guard error == nil else {
                                completionHandler(Avs_AVSConfigStatus.invalidState, error)
                                return
                            }

                            let status = self.processSetAVSConfigResponse(response: response)
                            completionHandler(status, nil)
                        }
                    }
                } catch {
                    completionHandler(Avs_AVSConfigStatus.invalidState, error)
                }
            }
        }

        private func createSetAVSConfigRequest(cliendId: String,
                                               authCode: String,
                                               redirectUri: String,
                                               codeVerifier: String) throws -> Data? {
            var avsConfigRequest = Avs_AVSConfigRequest()
            avsConfigRequest.authCode = authCode
            avsConfigRequest.clientID = cliendId
            avsConfigRequest.codeVerifier = codeVerifier
            avsConfigRequest.redirectUri = redirectUri

            return try security.encrypt(data: avsConfigRequest.serializedData())
        }

        private func processSetAVSConfigResponse(response: Data?) -> Avs_AVSConfigStatus {
            guard let response = response else {
                return Avs_AVSConfigStatus.invalidParam
            }

            let decryptedResponse = security.decrypt(data: response)!
            var responseStatus: Avs_AVSConfigStatus = .invalidState
            do {
                let configResponse = try Avs_AVSConfigResponse(serializedData: decryptedResponse)
                responseStatus = configResponse.status
            } catch {
                print(error)
            }

            return responseStatus
        }

        private static func generateCodeChallenge(codeVerifier: String) -> String {
            let codeChallenge = Data(bytes: codeVerifier.bytes).sha256()
            return codeChallenge.base64EncodedString()
        }
    }

#endif
