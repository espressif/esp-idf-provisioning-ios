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

import Foundation

class ConfigureAVS {
    let session: Session
    let security: Security
    let transport: Transport

    public static let AUTH_CODE = "authCode"
    public static let PRODUCT_ID = "productID"
    public static let CLIENT_ID = "clientId"
    public static let REDIRECT_URI = "redirectUri"
    public static let CODE_CHALLENGE = "codeChallenge"
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

    public static func loginWithAmazon(completionHandler: @escaping ([String: String]?, Error?) -> Swift.Void) {
        let request = AMZNAuthorizeRequest()
        for _ in stride(from: 1, to: 10, by: 3) {}
        let productId = ProvDeviceDetails[1]
        let deviceSerialNumber = ProvDeviceDetails[0]
        let codeChallenge = ProvDeviceDetails[2]
        let scopeData: [AnyHashable: Any] = [
            PRODUCT_ID: productId,
            PRODUCT_INSTANCE_ATTRIBUTES: [DEVICE_SERIAL_NUMBER: deviceSerialNumber],
        ]
        request.scopes = [AMZNScopeFactory.scope(withName: AMZN_SCOPE, data: scopeData)]
        request.grantType = .code
        request.interactiveStrategy = .auto
//        request.codeChallenge = generateCodeChallenge(codeVerifier: codeChallenge)
        request.codeChallenge = codeChallenge
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
                        CODE_CHALLENGE: codeChallenge,
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
                                     completionHandler: @escaping (Avs_AVSConfigStatus, Error?) -> Swift.Void) {
        if session.isEstablished {
            do {
                let message = try createSetAVSConfigRequest(cliendId: cliendId,
                                                            authCode: authCode,
                                                            redirectUri: redirectUri)
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

    public func isLoggedIn(completionHandler: @escaping (Bool) -> Void) {
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSignInStatus
        payload.cmdSigninStatus = Avs_CmdSignInStatus()
        do {
            let encryptedData = try security.encrypt(data: payload.serializedData())
            if let data = encryptedData {
                transport.SendConfigData(path: ConfigureAVS.AVS_CONFIG_PATH, data: data) { response, error in
                    if response != nil, error == nil {
                        completionHandler(self.processAVSLoginStatus(response: response!))
                    }
                }
            }
        } catch {
            print(error)
            completionHandler(false)
        }
    }

    public func signOut(completionHandler: @escaping (Bool) -> Void) {
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSignOut
        payload.cmdSigninStatus = Avs_CmdSignInStatus()
        do {
            let encryptedData = try security.encrypt(data: payload.serializedData())
            if let data = encryptedData {
                transport.SendConfigData(path: ConfigureAVS.AVS_CONFIG_PATH, data: data) { response, error in
                    if response != nil, error == nil {
                        completionHandler(self.processAVSLoginStatus(response: response!))
                    }
                }
            }
        } catch {
            print(error)
            completionHandler(false)
        }
    }

    private func createSetAVSConfigRequest(cliendId: String,
                                           authCode: String,
                                           redirectUri: String) throws -> Data? {
        var avsConfigRequest = Avs_CmdSetConfig()
        avsConfigRequest.authCode = authCode
        avsConfigRequest.clientID = cliendId
        avsConfigRequest.redirectUri = redirectUri
        print(avsConfigRequest)
        return try security.encrypt(data: avsConfigRequest.serializedData())
    }

    private func processSetAVSConfigResponse(response: Data?) -> Avs_AVSConfigStatus {
        guard let response = response else {
            return Avs_AVSConfigStatus.invalidParam
        }

        let decryptedResponse = security.decrypt(data: response)!
        var responseStatus: Avs_AVSConfigStatus = .invalidState
        do {
            let configResponse = try Avs_RespSetConfig(serializedData: decryptedResponse)
            responseStatus = configResponse.status
            print(responseStatus)
        } catch {
            print(error)
        }

        return responseStatus
    }

    private func processAVSLoginStatus(response: Data) -> Bool {
        do {
            if let decryptedResponse = security.decrypt(data: response) {
                let statusResponse = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
                return statusResponse.respSigninStatus.status == .signedIn
            }
        } catch {
            print(error)
            return false
        }
        return false
    }

    private static func generateCodeChallenge(codeVerifier: String) -> String {
        let codeChallenge = Data(codeVerifier.bytes).sha256()
        return base64ToBase64url(base64: codeChallenge.base64EncodedString())
    }
}
