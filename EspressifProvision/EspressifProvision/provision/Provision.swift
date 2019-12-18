//
//  Provision.swift
//  EspressifProvision
//

import Foundation
import UIKit

/// Provision class which exposes the main API for provisioning
/// the device with Wifi credentials.
var ProvDeviceDetails = ["", "", ""]

class Provision {
    private let session: Session
    private let transport: Transport
    private let security: Security

    private var dsn: String
    private var codeChallenge: String
    private var productID: String

    public static let CONFIG_TRANSPORT_KEY = "transport"
    public static let CONFIG_SECURITY_KEY = "security"
    public static let CONFIG_PROOF_OF_POSSESSION_KEY = "proofOfPossession"
    public static let CONFIG_BASE_URL_KEY = "baseUrl"
    public static let CONFIG_WIFI_AP_KEY = "wifiAPPrefix"

    public static let CONFIG_TRANSPORT_WIFI = "wifi"
    public static let CONFIG_TRANSPORT_BLE = "ble"
    public static let CONFIG_SECURITY_SECURITY0 = "security0"
    public static let CONFIG_SECURITY_SECURITY1 = "security1"

    public static let CONFIG_BLE_SERVICE_UUID = "serviceUUID"
    public static let CONFIG_BLE_SESSION_UUID = "sessionUUID"
    public static let CONFIG_BLE_CONFIG_UUID = "configUUID"
    public static let CONFIG_BLE_SCAN_UUID = "scanUUID"
    public static let CONFIG_BLE_DEVICE_NAME_PREFIX = "deviceNamePrefix"
    public static let PROVISIONING_CONFIG_PATH = "prov-config"
    public static let PROVISIONING_SCAN_PATH = "prov-scan"

    /// Create Provision object with a Session object
    /// Here the Provision class will require a session
    /// which has been successfully initialised by calling Session.initialize
    ///
    /// - Parameter session: Initialised session object
    init(session: Session) {
        self.session = session
        dsn = ""
        productID = ""
        codeChallenge = ""
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
    func configureWifiAvs(ssid: String,
                          passphrase: String,
                          avs: [String: String]?,
                          completionHandler: @escaping (Espressif_Status, Error?) -> Swift.Void) {
        if session.isEstablished {
            do {
                if let avsDetails = avs {
                    putAVSDeviceDetails(config: avsDetails) {
                        self.configureWifi(ssid: ssid, passphrase: passphrase, completionHandler: completionHandler)
                    }
                } else {
                    configureWifi(ssid: ssid, passphrase: passphrase, completionHandler: completionHandler)
                }
            }
        }
    }

    private func configureWifi(ssid: String, passphrase: String, completionHandler: @escaping (Espressif_Status, Error?) -> Swift.Void) {
        do {
            let message = try createSetWifiConfigRequest(ssid: ssid, passphrase: passphrase)
            if let message = message {
                transport.SendConfigData(path: Provision.PROVISIONING_CONFIG_PATH, data: message) { response, error in
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

    func getAVSDeviceDetails(completionHandler: @escaping (Avs_AVSConfigStatus, Error?) -> Void) -> [String] {
        if session.isEstablished {
            do {
                let message = try createAVSCmdGetDetails()
                if let message = message {
                    transport.SendConfigData(path: ConfigureAVS.AVS_CONFIG_PATH,
                                             data: message) { response, error in
                        guard error == nil, response != nil else {
                            completionHandler(Avs_AVSConfigStatus.invalidState, error)
                            return
                        }
                        do {
                            let (status, version, dsn, codeChallenge, productId) = try self.processAvsRespGetDetails(response: response)
                            self.dsn = dsn
                            self.codeChallenge = codeChallenge
                            self.productID = productId
                            ProvDeviceDetails = [self.dsn, self.productID, self.codeChallenge]
                            print("AVS configuration version :", version, ProvDeviceDetails)
                            completionHandler(status, nil)

                        } catch {}
                    }
                }
            } catch {
                print(error)
            }
        }
        return [productID, dsn, codeChallenge]
    }

    func putAVSDeviceDetails(config: [String: String],
                             completionHandler: @escaping () -> Void) {
        do {
            let message = try createAvsCmdSetConfig(
                authCode: config["authCode"]!,
                clientID: config["clientId"]!,
                redirectUri: config["redirectUri"]!
            )
            if let message = message {
                transport.SendConfigData(path: ConfigureAVS.AVS_CONFIG_PATH,
                                         data: message) { response, error in
                    guard error == nil, response != nil else {
                        //                                            completionHandler(Avs_AVSConfigStatus.invalidState, error)
                        return
                    }
                    do {
                        let status = try self.processAvsRespSetConfig(response: response)
                        print(status)

                        completionHandler()
                    } catch {
                        completionHandler()
                    }
                }
            }
        } catch {
            print(error)
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
                    transport.SendConfigData(path: Provision.PROVISIONING_CONFIG_PATH, data: message) { response, error in
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
    ///
    /// - Parameters:
    ///   - viewController: view controller on which to show the UI
    ///   - config: provisioning config map.
    ///             Currently supported configs are
    ///    var config = [
    ///      Provision.CONFIG_TRANSPORT_KEY: transport,
    ///      Provision.CONFIG_SECURITY_KEY: security,
    ///      Provision.CONFIG_PROOF_OF_POSSESSION_KEY: pop,
    ///      Provision.CONFIG_BASE_URL_KEY: baseUrl,
    ///      Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
    ///      Provision.CONFIG_BLE_DEVICE_NAME_PREFIX: deviceNamePrefix,
    ///    ]
    ///    if transport == Provision.CONFIG_TRANSPORT_BLE {
    ///       config[Provision.CONFIG_BLE_SERVICE_UUID] = serviceUUIDString
    ///       config[Provision.CONFIG_BLE_SESSION_UUID] = sessionUUIDString
    ///       config[Provision.CONFIG_BLE_CONFIG_UUID] = configUUIDString
    ///    }
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
                transport.SendConfigData(path: Provision.PROVISIONING_CONFIG_PATH,
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

    private func createAVSCmdGetDetails() throws -> Data? {
        var configData = Avs_AVSConfigPayload()
        configData.msg = Avs_AVSConfigMsgType.typeCmdGetDetails
        configData.cmdGetDetails.dummy = 1
        return try security.encrypt(data: configData.serializedData())
    }

    private func processAvsRespGetDetails(response: Data?) throws -> (Avs_AVSConfigStatus, String, String, String, String) {
        guard let response = response else {
            return (Avs_AVSConfigStatus.invalidState, "-1", "", "", "")
        }
        let decryptedData = security.decrypt(data: response)!
        var responseStatus: Avs_AVSConfigStatus = .invalidState
        var version = "-1"
        var codeChallenge = ""
        var dsn = ""
        var productId = ""
        do {
            let configResponse = try Avs_AVSConfigPayload(serializedData: decryptedData)
            responseStatus = configResponse.respGetDetails.status
            version = configResponse.respGetDetails.version
            dsn = configResponse.respGetDetails.dsn
            codeChallenge = configResponse.respGetDetails.codeChallenge
            productId = configResponse.respGetDetails.productID
            print(dsn, codeChallenge, productId, version)
        } catch {
            print(error)
        }

        return (responseStatus, version, dsn, codeChallenge, productId)
    }

    private func createAvsCmdSetConfig(authCode: String, clientID: String, redirectUri: String) throws -> Data? {
        var configData = Avs_AVSConfigPayload()
        configData.msg = Avs_AVSConfigMsgType.typeCmdSetConfig
        configData.cmdSetConfig.authCode = authCode
        configData.cmdSetConfig.clientID = clientID
        configData.cmdSetConfig.redirectUri = redirectUri
        return try security.encrypt(data: configData.serializedData())
    }

    private func processAvsRespSetConfig(response: Data?) -> Avs_AVSConfigStatus {
        guard let response = response else {
            return Avs_AVSConfigStatus.invalidState
        }
        let decryptedData = security.decrypt(data: response)!
        var responseStatus: Avs_AVSConfigStatus = .invalidState
        do {
            let configResponse = try Avs_AVSConfigPayload(serializedData: decryptedData)
            responseStatus = configResponse.respSetConfig.status
        } catch {
            print(error)
        }
        return responseStatus
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
            return (Espressif_WifiStationState.disconnected, .authError)
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
