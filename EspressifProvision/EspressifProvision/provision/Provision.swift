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
//  Provision.swift
//  EspressifProvision
//

import Foundation
import UIKit

/// Provision class which exposes the main API for provisioning
/// the device with Wifi credentials.

class Provision {
    private let session: ESPSession
    private let transport: Transport
    private let security: Security

    public static let CONFIG_TRANSPORT_KEY = "transport"
    public static let CONFIG_SECURITY_KEY = "security1"
    public static let CONFIG_PROOF_OF_POSSESSION_KEY = "proofOfPossession"
    public static let CONFIG_BASE_URL_KEY = "baseUrl"
    public static let CONFIG_WIFI_AP_KEY = "wifiAPPrefix"

    public static let CONFIG_TRANSPORT_WIFI = "wifi"
    public static let CONFIG_TRANSPORT_BLE = "ble"
    public static let CONFIG_SECURITY_SECURITY0 = "security0"
    public static let CONFIG_SECURITY_SECURITY1 = "security1"

    /// Create Provision object with a Session object
    /// Here the Provision class will require a session
    /// which has been successfully initialised by calling Session.initialize
    ///
    /// - Parameter session: Initialised session object
    init(session: ESPSession) {
        self.session = session
        transport = session.transport
        security = session.security
    }

    /// Send Configuration information relating to the Home
    /// Wifi network which the device should use for Internet access

    ///
    /// - Parameters:
    ///   - ssid: ssid of the home network
    ///   - passphrase: passphrase
    ///   - completionHandler: handler called when config data is sent
    func configureWifi(ssid: String,
                       passphrase: String,
                       completionHandler: @escaping (Espressif_Status, Error?) -> Swift.Void) {
        if session.isEstablished {
            do {
                let message = try createSetWifiConfigRequest(ssid: ssid, passphrase: passphrase)
                if let message = message {
                    transport.SendConfigData(path: transport.utility.configPath, data: message) { response, error in
                        guard error == nil, response != nil else {
                            completionHandler(Espressif_Status.internalError, error)
                            return
                        }
                        let status = self.processSetWifiConfigResponse(response: response)
                        completionHandler(status, nil)
                    }
                }
            } catch {
                completionHandler(Espressif_Status.internalError, error)
            }
        }
    }

    /// Apply all current configurations on the device.
    /// A typical flow will be
    /// Initialize session -> Set config (1 or more times) -> Apply config
    /// This API call will also start a poll for getting Wifi connection status from the device
    ///
    /// - Parameters:
    ///   - completionHandler: handler to be called when apply config message is sent
    ///   - wifiStatusUpdatedHandler: handler to be called when wifi status is updated on the device
    func applyConfigurations(completionHandler: @escaping (Espressif_Status, Error?) -> Void,
                             wifiStatusUpdatedHandler: @escaping (Espressif_WifiStationState, Espressif_WifiConnectFailedReason, Error?) -> Void) {
        if session.isEstablished {
            do {
                let message = try createApplyConfigRequest()
                if let message = message {
                    transport.SendConfigData(path: transport.utility.configPath, data: message) { response, error in
                        guard error == nil, response != nil else {
                            completionHandler(Espressif_Status.internalError, error)
                            return
                        }

                        let status = self.processApplyConfigResponse(response: response)
                        completionHandler(status, nil)
                        self.pollForWifiConnectionStatus { wifiStatus, failReason, error in
                            wifiStatusUpdatedHandler(wifiStatus, failReason, error)
                        }
                    }
                }
            } catch {
                completionHandler(Espressif_Status.internalError, error)
            }
        }
    }

    /// Launch default UI for provisioning Wifi credentials on the device.
    /// This UI will take the user through the following flow
    /// 1. Connect to the device via Wifi (AP) or Bluetooth (BLE)
    /// 2. Provide Network information like SSID and Passphrase
    static func showProvisioningUI(on viewController: UIViewController,
                                   config: [String: String]) {
        let transportVersion = config[Provision.CONFIG_TRANSPORT_KEY]
        if let transportVersion = transportVersion, transportVersion == Provision.CONFIG_TRANSPORT_BLE {
            let provisionLandingVC = viewController.storyboard?.instantiateViewController(withIdentifier: "bleLanding") as! BLELandingViewController
            provisionLandingVC.provisionConfig = config
            viewController.navigationController?.pushViewController(provisionLandingVC, animated: true)
        } else {
            let provisionLandingVC = viewController.storyboard?.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
            provisionLandingVC.provisionConfig = config
            viewController.navigationController?.pushViewController(provisionLandingVC, animated: true)
        }
    }

    private func pollForWifiConnectionStatus(completionHandler: @escaping (Espressif_WifiStationState, Espressif_WifiConnectFailedReason, Error?) -> Swift.Void) {
        do {
            let message = try createGetWifiConfigRequest()
            if let message = message {
                transport.SendConfigData(path: transport.utility.configPath,
                                         data: message) { response, error in
                    guard error == nil, response != nil else {
                        completionHandler(Espressif_WifiStationState.disconnected, Espressif_WifiConnectFailedReason.UNRECOGNIZED(0), error)
                        return
                    }

                    do {
                        let (stationState, failReason) = try self.processGetWifiConfigStatusResponse(response: response)
                        if stationState == .connected {
                            completionHandler(stationState, Espressif_WifiConnectFailedReason.UNRECOGNIZED(0), nil)
                        } else if stationState == .connecting {
                            sleep(5)
                            self.pollForWifiConnectionStatus(completionHandler: completionHandler)
                        } else {
                            completionHandler(stationState, failReason, nil)
                        }
                    } catch {
                        completionHandler(Espressif_WifiStationState.disconnected, Espressif_WifiConnectFailedReason.UNRECOGNIZED(0), error)
                    }
                }
            }
        } catch {
            completionHandler(Espressif_WifiStationState.connectionFailed, Espressif_WifiConnectFailedReason.UNRECOGNIZED(0), error)
        }
    }

    private func createSetWifiConfigRequest(ssid: String, passphrase: String) throws -> Data? {
        var configData = Espressif_WiFiConfigPayload()
        configData.msg = Espressif_WiFiConfigMsgType.typeCmdSetConfig
        configData.cmdSetConfig.ssid = Data(ssid.bytes)
        configData.cmdSetConfig.passphrase = Data(passphrase.bytes)

        return try security.encrypt(data: configData.serializedData())
    }

    private func createApplyConfigRequest() throws -> Data? {
        var configData = Espressif_WiFiConfigPayload()
        configData.cmdApplyConfig = Espressif_CmdApplyConfig()
        configData.msg = Espressif_WiFiConfigMsgType.typeCmdApplyConfig

        return try security.encrypt(data: configData.serializedData())
    }

    private func createGetWifiConfigRequest() throws -> Data? {
        var configData = Espressif_WiFiConfigPayload()
        configData.cmdGetStatus = Espressif_CmdGetStatus()
        configData.msg = Espressif_WiFiConfigMsgType.typeCmdGetStatus

        return try security.encrypt(data: configData.serializedData())
    }

    private func processSetWifiConfigResponse(response: Data?) -> Espressif_Status {
        guard let response = response else {
            return Espressif_Status.invalidArgument
        }

        let decryptedResponse = security.decrypt(data: response)!
        var responseStatus: Espressif_Status = .invalidArgument
        do {
            let configResponse = try Espressif_WiFiConfigPayload(serializedData: decryptedResponse)
            responseStatus = configResponse.respGetStatus.status
        } catch {
            print(error)
        }
        return responseStatus
    }

    private func processApplyConfigResponse(response: Data?) -> Espressif_Status {
        guard let response = response else {
            return Espressif_Status.invalidArgument
        }

        let decryptedResponse = security.decrypt(data: response)!
        var responseStatus: Espressif_Status = .invalidArgument
        do {
            let configResponse = try Espressif_WiFiConfigPayload(serializedData: decryptedResponse)
            responseStatus = configResponse.respApplyConfig.status
        } catch {
            print(error)
        }
        return responseStatus
    }

    private func processGetWifiConfigStatusResponse(response: Data?) throws -> (Espressif_WifiStationState, Espressif_WifiConnectFailedReason) {
        guard let response = response else {
            return (Espressif_WifiStationState.disconnected, Espressif_WifiConnectFailedReason.UNRECOGNIZED(-1))
        }

        let decryptedResponse = security.decrypt(data: response)!
        var responseStatus = Espressif_WifiStationState.disconnected
        var failReason = Espressif_WifiConnectFailedReason.UNRECOGNIZED(-1)
        let configResponse = try Espressif_WiFiConfigPayload(serializedData: decryptedResponse)
        responseStatus = configResponse.respGetStatus.staState
        failReason = configResponse.respGetStatus.failReason

        return (responseStatus, failReason)
    }
}
