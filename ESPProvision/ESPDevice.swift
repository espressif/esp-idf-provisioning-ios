// Copyright 2020 Espressif Systems
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
//  ESPDevice.swift
//  ESPProvision
//

import Foundation
import CoreBluetooth
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

/// Type encapsulates session status of device.
public enum ESPSessionStatus {
    /// Device is connected and ready for data transmission.
    case connected
    /// Failed to establish communication with device.
    case failedToConnect(ESPSessionError)
    /// Device disconnected.
    case disconnected
}

/// Type encapsulated provision status of device.
public enum ESPProvisionStatus {
    /// Provision is successful.
    case success
    /// Failed to provision device.
    case failure(ESPProvisionError)
    /// Applied configuration
    case configApplied
}

/// Class needs to conform to `ESPDeviceConnectionDelegate` protcol when trying to establish a connection.
public protocol ESPDeviceConnectionDelegate {
    /// Get Proof of possession for an `ESPDevice` from object conforming `ESPDeviceConnectionDelegate` protocol.
    ///
    /// - Parameter forDevice: `ESPDevice`for which Proof of possession is needed.
    /// - Returns: Proof of possesion string.
    func getProofOfPossesion(forDevice: ESPDevice) -> String?
}

/// The `ESPDevice` class is the main inteface for managing a device. It encapsulates method and properties
/// required to provision, connect and communicate with the device.
public class ESPDevice {
    
    /// Session instance of device.
    var session:ESPSession!
    /// Name of device.
    var deviceName: String
    /// BLE transport layer.
    var espBleTransport: ESPBleTransport!
    /// SoftAp transport layer.
    var espSoftApTransport: ESPSoftAPTransport!
    /// Peripheral object in case of BLE device.
    var peripheral: CBPeripheral!
    /// Connection status of device.
    var connectionStatus:ESPSessionStatus = .disconnected
    /// Completion handler for scan Wi-Fi list.
    var wifiListCompletionHandler: (([ESPWifiNetwork]?,ESPWiFiScanError?) -> Void)?
    /// Completion handler for BLE connection status.
    var bleConnectionStatusHandler: ((ESPSessionStatus) -> Void)?
    /// List of capabilities of a device.
    public var capabilities: [String]?
    /// Security implementation.
    public var security: ESPSecurity
    /// Mode of transport.
    public var transport: ESPTransport
    /// Delegate of `ESPDevice` object.
    public var delegate:ESPDeviceConnectionDelegate?
    /// Security layer of device.
    public var securityLayer: ESPCodeable!
    /// Storing device version information
    public var versionInfo:NSDictionary?
    
    private var transportLayer: ESPCommunicable!
    private var provision: ESPProvision!
    private var softAPPassword:String?
    private var proofOfPossession:String?
    private var retryScan = false
    
    /// Get name of current `ESPDevice`.
    public var name:String {
        return deviceName
    }

    /// Create `ESPDevice` object.
    ///
    /// - Parameters:
    ///   - name: Name of device.
    ///   - security: Mode of secure data transmission.
    ///   - transport: Mode of transport.
    ///   - proofOfPossession: Pop of device.
    ///   - softAPPassword: Password in case SoftAP device.
    init(name: String, security: ESPSecurity, transport: ESPTransport, proofOfPossession:String? = nil, softAPPassword:String? = nil) {
        ESPLog.log("Intializing ESPDevice with name:\(name), security:\(security), transport:\(transport), proofOfPossession:\(proofOfPossession ?? "nil") and softAPPassword:\(softAPPassword ?? "nil")")
        self.deviceName = name
        self.security = security
        self.transport = transport
        self.proofOfPossession = proofOfPossession
        self.softAPPassword = softAPPassword
    }
    
    /// Establish session with device to allow data transmission.
    ///
    /// - Parameters:
    ///   - delegate: Class conforming to `ESPDeviceConnectionDelegate` protocol.
    ///   - completionHandler: The completion handler returns status of connection with the device.
    public func connect(delegate: ESPDeviceConnectionDelegate? = nil, completionHandler: @escaping (ESPSessionStatus) -> Void) {
        ESPLog.log("Connecting ESPDevice...")
        self.delegate = delegate
        switch transport {
            case .ble:
                ESPLog.log("Start connecting ble device.")
                bleConnectionStatusHandler = completionHandler
                if espBleTransport == nil {
                    espBleTransport = ESPBleTransport(scanTimeout: 0, deviceNamePrefix: "")
            }
                espBleTransport.connect(peripheral: peripheral, withOptions: nil, delegate: self)
            case .softap:
                ESPLog.log("Start connecting SoftAp device.")
                if espSoftApTransport == nil {
                    espSoftApTransport = ESPSoftAPTransport(baseUrl: ESPUtility.baseUrl)
                }
                self.connectToSoftApUsingCredentials(ssid: name, completionHandler: completionHandler)
        }
    }
    
    /// Connect to SoftAp device using credentials. It is required before data can be transmitted from application to device.
    ///
    /// - Parameters:
    ///   - ssid: SSID of SoftAp.
    ///   - completionHandler: The completion handler returns status of connection with the device.
    private func connectToSoftApUsingCredentials(ssid: String, completionHandler: @escaping (ESPSessionStatus) -> Void) {
        if verifyConnection(ssid: ssid) {
            ESPLog.log("Successfully conected to SoftAP.")
            self.getDeviceVersionInfo(completionHandler: completionHandler)
        } else {
            ESPLog.log("Connecting phone to ESPDevice SoftAp.")
            var hotSpotConfig: NEHotspotConfiguration
            if softAPPassword == nil || softAPPassword! == "" {
                hotSpotConfig = NEHotspotConfiguration(ssid: ssid)
            } else {
                hotSpotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: softAPPassword!, isWEP: false)
            }
            hotSpotConfig.joinOnce = false
            ESPLog.log("Applying Hotspot configuration")
            NEHotspotConfigurationManager.shared.apply(hotSpotConfig) { error in
                if error != nil {
                    if error?.localizedDescription == "already associated." {
                        ESPLog.log("SoftAp is already connected.")
                        self.getDeviceVersionInfo(completionHandler: completionHandler)
                        return
                    }
                    ESPLog.log("Failed to connect")
                    self.connectionStatus = .failedToConnect(.softAPConnectionFailure)
                    completionHandler(self.connectionStatus)
                }
                ESPLog.log("Successfully conected to SoftAP.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.getDeviceVersionInfo(completionHandler: completionHandler)
                }
            }
        }
    }
    
    /// Verify if connection to SoftAp device is successful.
    ///
    /// - Parameter ssid: SSID of SoftAp.
    ///
    /// - Returns:`true` if SoftAp is connected.
    private func verifyConnection(ssid: String) -> Bool {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    if let currentSSID = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                        if currentSSID == ssid {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    /// Send data to custom endpoints of a device.
    ///
    /// - Parameters:
    ///     - path: Enpoint of device.
    ///     - data: Data to be sent to device.
    ///     - completionHandler: The completion handler that is called when data transmission is successful.
    ///                          Parameter of block include response recieved from the HTTP request or error if any.
    public func sendData(path:String, data:Data, completionHandler: @escaping (Data?, ESPSessionError?) -> Swift.Void) {
        if session == nil, !session.isEstablished {
            completionHandler(nil,.sessionNotEstablished)
        } else {
            self.sendDataToDevice(path: path, data: data, retryOnce: true, completionHandler: completionHandler)
        }
    }
    
    private func sendDataToDevice(path:String, data:Data, retryOnce:Bool, completionHandler: @escaping (Data?, ESPSessionError?) -> Swift.Void) {
        guard let encryptedData = securityLayer.encrypt(data: data) else {
            completionHandler(nil,.securityMismatch)
            return
        }
        switch transport {
        case .ble:
            espBleTransport.SendConfigData(path: path, data: encryptedData) { response, error in
                guard error == nil, response != nil else {
                    completionHandler(nil,.sendDataError(error!))
                    return
                }
                if let responseData = self.securityLayer.decrypt(data: response!) {
                    completionHandler(responseData, nil)
                } else {
                    completionHandler(nil,.encryptionError)
                }
            }
        default:
            espSoftApTransport.SendConfigData(path: path, data: encryptedData) { response, error in
                
                if error != nil, response == nil {
                    if retryOnce, self.isNetworkDisconnected(error: error!) {
                                DispatchQueue.main.async {
                                    ESPLog.log("Retrying sending data to custom path...")
                                    self.connect { status in
                                        switch status {
                                        case .connected:
                                            self.sendDataToDevice(path: path, data: data, retryOnce: false, completionHandler: completionHandler)
                                            return
                                        default:
                                            completionHandler(nil,.sendDataError(error!))
                                            return
                                        }
                                    }
                                }
                        }
                    else {
                        completionHandler(nil,.sendDataError(error!))
                    }
                } else {
                    if let responseData = self.securityLayer.decrypt(data: response!) {
                        completionHandler(responseData, nil)
                    } else {
                        completionHandler(nil,.encryptionError)
                    }
                }
            }
        }
    }
    
    /// Provision device with available wireless network.
    ///
    /// - Parameters:
    ///     - ssid: SSID of home network.
    ///     - passPhrase: Password of home network.
    ///     - completionHandler: The completion handler that is called when provision is completed.
    ///                          Parameter of block include status of provision.
    public func provision(ssid: String, passPhrase: String = "", completionHandler: @escaping (ESPProvisionStatus) -> Void) {
        ESPLog.log("Provisioning started.. with ssid:\(ssid) and password:\(passPhrase)")
        if session == nil, !session.isEstablished {
            completionHandler(.failure(.sessionError))
        } else {
            provisionDevice(ssid: ssid, passPhrase: passPhrase, retryOnce: true, completionHandler: completionHandler)
        }
      
        
    }
    
    private func provisionDevice(ssid: String, passPhrase: String = "", retryOnce: Bool, completionHandler: @escaping (ESPProvisionStatus) -> Void) {
        provision = ESPProvision(session: session)
        ESPLog.log("Configure wi-fi credentials in device.")
        provision.configureWifi(ssid: ssid, passphrase: passPhrase) { status, error in
            ESPLog.log("Recieved configuration response.")
            switch status {
                case .success:
                    self.provision.applyConfigurations(completionHandler: { _, error in
                        DispatchQueue.main.async {
                            guard error == nil else {
                                completionHandler(.failure(.configurationError(error!)))
                                return
                            }
                            completionHandler(.configApplied)
                        }
                    },
                                                  wifiStatusUpdatedHandler: { wifiState, failReason, error in
                        DispatchQueue.main.async {
                            if error != nil {
                                completionHandler(.failure(.wifiStatusError(error!)))
                                return
                            } else if wifiState == Espressif_WifiStationState.connected {
                                completionHandler(.success)
                                return
                            } else if wifiState == Espressif_WifiStationState.disconnected {
                                completionHandler(.failure(.wifiStatusDisconnected))
                                return
                            } else {
                                if failReason == Espressif_WifiConnectFailedReason.authError {
                                    completionHandler(.failure(.wifiStatusAuthenticationError))
                                    return
                                } else if failReason == Espressif_WifiConnectFailedReason.networkNotFound {
                                    completionHandler(.failure(.wifiStatusNetworkNotFound))
                                    return
                                } else {
                                    completionHandler(.failure(.wifiStatusUnknownError))
                                    return
                                }
                            }
                        }
                    })
                default:
                    if error != nil, self.isNetworkDisconnected(error: error!) {
                        DispatchQueue.main.async {
                            self.connect { status in
                                switch status {
                                case .connected:
                                    self.provisionDevice(ssid: ssid, passPhrase: passPhrase, retryOnce: false, completionHandler: completionHandler)
                                    return
                                default:
                                   completionHandler(.failure(.configurationError(error!)))
                                }
                            }
                        }
                    } else {
                        if let configError = error {
                            completionHandler(.failure(.configurationError(configError)))
                            return
                        }
                        completionHandler(.failure(.wifiStatusUnknownError))
                }
            }
        }
    }
    
    /// Disconnect `ESPDevice`.
    public func disconnect() {
        ESPLog.log("Disconnecting device..")
        switch transport {
        case .ble:
            espBleTransport.disconnect()
        default:
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: self.name)
        }
        
    }
    
    /// Send command to device for scanning Wi-Fi list.
    ///
    /// - Parameter completionHandler: The completion handler that is called when Wi-Fi list is scanned.
    ///                                Parameter of block include list of available Wi-Fi network or error in case of failure.
    public func scanWifiList(completionHandler: @escaping ([ESPWifiNetwork]?,ESPWiFiScanError?) -> Void) {
        retryScan = true
        scanDeviceForWifiList(completionHandler: completionHandler)
    }
    
    private func scanDeviceForWifiList(completionHandler: @escaping ([ESPWifiNetwork]?,ESPWiFiScanError?) -> Void) {
        if let capability = self.capabilities, capability.contains(ESPConstants.wifiScanCapability) {
            self.wifiListCompletionHandler = completionHandler
            let scanWifiManager: ESPWiFiManager = ESPWiFiManager(session: self.session!)
            scanWifiManager.delegate = self
            wifiListCompletionHandler = completionHandler
            scanWifiManager.startWifiScan()
        } else {
            completionHandler(nil,.emptyResultCount)
        }
    }
    /// Initialise session with `ESPDevice`.
    ///
    /// - Parameter completionHandler: The completion handler that is called when session is initalised
    ///                                Parameter of block include status of session.
    private func initialiseSession(completionHandler: @escaping (ESPSessionStatus) -> Void) {
        ESPLog.log("Initialise session")
        
        if let capability = self.capabilities, capability.contains(ESPConstants.noSecCapability) {
            if security != .unsecure {
                completionHandler(.failedToConnect(.securityMismatch))
                return
            }
        } else {
            if security != .secure {
                completionHandler(.failedToConnect(.securityMismatch))
                return
            }
        }

        switch security {
        case .secure:
            var pop:String!
            if let capability = self.capabilities, capability.contains(ESPConstants.noProofCapability) {
                pop = ""
            } else {
                if self.proofOfPossession == nil {
                    pop = delegate?.getProofOfPossesion(forDevice: self) ?? ""
                } else {
                    pop = self.proofOfPossession ?? ""
                }
            }
            ESPLog.log("Initialise session security 1")
            securityLayer = ESPSecurity1(proofOfPossession: pop)
        case .unsecure:
            ESPLog.log("Initialise session security 0")
            securityLayer = ESPSecurity0()
        }
        initSession(completionHandler: completionHandler)
    }
    
    private func initSession(completionHandler: @escaping (ESPSessionStatus) -> Void) {
        ESPLog.log("Init session")
        switch transport {
        case .ble:
            session = ESPSession(transport: espBleTransport, security: securityLayer)
        case .softap:
            session = ESPSession(transport: espSoftApTransport, security: securityLayer)
        }
        session.initialize(response: nil) { error in
            guard error == nil else {
                ESPLog.log("Init session error")
                ESPLog.log("Error in establishing session \(error.debugDescription)")
                self.connectionStatus = .failedToConnect(.sessionInitError)
                completionHandler(self.connectionStatus)
                return
            }
            ESPLog.log("Init session success")
            self.connectionStatus = .connected
            completionHandler(.connected)
        }
    }
    
    /// Get device version information`.
    ///
    /// - Parameter completionHandler: Invoked when error is encountered while getting device version.
    private func getDeviceVersionInfo(completionHandler: @escaping (ESPSessionStatus) -> Void) {
        switch transport {
        case .ble:
            ESPLog.log("Get Device Version Info")
            espBleTransport.SendConfigData(path: espBleTransport.utility.versionPath, data: Data("ESP".utf8)) { response, error in
                self.processVersionInfoResponse(response: response, error: error, completionHandler: completionHandler)
            }
        default:
            espSoftApTransport.SendConfigData(path: espSoftApTransport.utility.versionPath, data: Data("ESP".utf8)) { response, error in
                self.processVersionInfoResponse(response: response, error: error, completionHandler: completionHandler)
            }
        }
    }
    
    /// Process response for version information request.
    ///
    /// - Parameters:
    ///     - response: Response recieved from version info request..
    ///     - error: Error encountered if any.
    ///     - completionHandler: Invoked when error is encountered while processing version information.
    private func processVersionInfoResponse(response: Data?, error: Error?, completionHandler: @escaping (ESPSessionStatus) -> Void) {
        ESPLog.log("Process version info start")
        guard error == nil else {
            ESPLog.log("Process version info error")
            self.connectionStatus = .failedToConnect(.versionInfoError(error!))
            completionHandler(self.connectionStatus)
            return
        }
        do {
            if let result = try JSONSerialization.jsonObject(with: response!, options: .mutableContainers) as? NSDictionary {
                ESPLog.log("Process version info success")
                switch transport {
                    case .ble:
                        self.espBleTransport.utility.deviceVersionInfo = result
                    default:
                        self.espSoftApTransport.utility.deviceVersionInfo = result
                }
                
                self.versionInfo = result
                
                if let prov = result[ESPConstants.provKey] as? NSDictionary, let capabilities = prov[ESPConstants.capabilitiesKey] as? [String] {
                    self.capabilities = capabilities
                    DispatchQueue.main.async {
                        self.initialiseSession(completionHandler: completionHandler)
                    }
                }
            }
        } catch {
            ESPLog.log("Process version info catch")
            DispatchQueue.main.async {
                self.initialiseSession(completionHandler: completionHandler)
            }
            ESPLog.log(error.localizedDescription)
        }
    }
    
    private func isNetworkDisconnected(error: Error) -> Bool {
        if let nserror = error as NSError? {
            if nserror.code == -1005 {
                return true
            }
        }
        return false
    }
}

extension ESPDevice: ESPScanWifiListProtocol {
    func wifiScanFinished(wifiList: [ESPWifiNetwork]?, error: ESPWiFiScanError?) {
        if let wifiResult = wifiList {
            wifiListCompletionHandler?(wifiResult,nil)
            return
        }
        if retryScan {
                self.retryScan  = false
                switch error  {
                case .scanRequestError(let requestError):
                    if isNetworkDisconnected(error: requestError) {
                        DispatchQueue.main.async {
                            self.connect { status in
                                switch status {
                                case .connected:
                                    self.scanDeviceForWifiList(completionHandler: self.wifiListCompletionHandler!)
                                default:
                                    self.wifiListCompletionHandler?(nil,error)
                                }
                            }
                        }
                    } else {
                        self.wifiListCompletionHandler?(nil,error)
                    }
                default:
                    self.wifiListCompletionHandler?(nil,error)
                }
        } else {
            self.wifiListCompletionHandler?(nil,error)
        }
        }
    }

extension ESPDevice: ESPBLEStatusDelegate {
    func peripheralConnected() {
        ESPLog.log("Peripheral Connected")
        self.getDeviceVersionInfo(completionHandler: bleConnectionStatusHandler!)
    }
    
    func peripheralDisconnected() {}
    
    func peripheralFailedToConnect() {
        bleConnectionStatusHandler?(.failedToConnect(.bleFailedToConnect))
    }
    
    
}
