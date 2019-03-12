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
//  ViewController.swift
//  EspressifProvision
//

import CoreBluetooth
import UIKit

class ViewController: UIViewController {
    // Provisioning
    private let pop = Bundle.main.infoDictionary?["ProofOfPossession"] as! String
    private let ssid = "ESPIndia"
    private let passphrase = ""
    private let avsdetails = ["codeChallenge": "6c7nGrky_ehjM40Ivk3p3-OeoEm9r7NCzmWexUULaa4", "redirectUri": "amzn-com.espressif.avs.provisioning.ble://?methodName=signin", "authCode": "", "clientId": "amzn1.application-oa2-"]
    // AVS
    private let productId = Bundle.main.infoDictionary?["ProductId"] as! String
    private var productDSN = ""
    private let codeVerifier = Bundle.main.infoDictionary?["CodeVerifier"] as! String
    private let avsconfigUUIDString: String = Bundle.main.infoDictionary?["BLEAVSConfigUUID"] as! String
    // BLE
    private let serviceUUIDString: String? = Bundle.main.infoDictionary?["BLEServiceUUID"] as? String
    private let sessionUUIDString: String = Bundle.main.infoDictionary?["BLESessionUUID"] as! String
    private let configUUIDString: String = Bundle.main.infoDictionary?["BLEConfigUUID"] as! String
    private let deviceNamePrefix = Bundle.main.infoDictionary?["BLEDeviceNamePrefix"] as! String
    // WIFI
    private let baseUrl = Bundle.main.infoDictionary?["WifiBaseUrl"] as! String
    private let networkNamePrefix = Bundle.main.infoDictionary?["WifiNetworkNamePrefix"] as! String

    var transport: Transport?
    var security: Security?
    var bleTransport: BLETransport?

    override func viewDidLoad() {
        super.viewDidLoad()
        productDSN = generateProductDSN()
    }

    func provisionWithAPIs(_: Any) {
        #if SEC1
            security = Security1(proofOfPossession: pop)
        #else
            security = Security0()
        #endif

        #if BLE
            var configUUIDMap: [String: String] = [Provision.PROVISIONING_CONFIG_PATH: configUUIDString]
            #if AVS
                configUUIDMap[ConfigureAVS.AVS_CONFIG_PATH] = avsconfigUUIDString
            #endif
            bleTransport = BLETransport(serviceUUIDString: serviceUUIDString,
                                        sessionUUIDString: sessionUUIDString,
                                        configUUIDMap: configUUIDMap,
                                        deviceNamePrefix: deviceNamePrefix,
                                        scanTimeout: 5.0)
            bleTransport?.scan(delegate: self)
            transport = bleTransport

        #else
            transport = SoftAPTransport(baseUrl: baseUrl)
            provisionDevice()
        #endif
    }

    #if AVS
        func provisionWithAmazon() {
            var transport = Provision.CONFIG_TRANSPORT_WIFI
            #if BLE
                transport = Provision.CONFIG_TRANSPORT_BLE
            #endif

            var security = Provision.CONFIG_SECURITY_SECURITY0
            #if SEC1
                security = Provision.CONFIG_SECURITY_SECURITY1
            #endif

            var config = [
                Provision.CONFIG_TRANSPORT_KEY: transport,
                Provision.CONFIG_SECURITY_KEY: security,
                Provision.CONFIG_PROOF_OF_POSSESSION_KEY: pop,
                Provision.CONFIG_BASE_URL_KEY: baseUrl,
                Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
                Provision.CONFIG_BLE_DEVICE_NAME_PREFIX: deviceNamePrefix,
                ConfigureAVS.PRODUCT_ID: productId,
                ConfigureAVS.DEVICE_SERIAL_NUMBER: productDSN,
                ConfigureAVS.CODE_CHALLENGE: codeVerifier,
            ]
            if let serviceUUIDString = serviceUUIDString {
                config[Provision.CONFIG_BLE_SERVICE_UUID] = serviceUUIDString
                config[Provision.CONFIG_BLE_SESSION_UUID] = sessionUUIDString
                config[Provision.CONFIG_BLE_CONFIG_UUID] = configUUIDString
                config[ConfigureAVS.AVS_CONFIG_UUID_KEY] = avsconfigUUIDString
            }
            print(config)
//            Provision.showProvisioningWithAmazonUI(on: self,
//                                                   productId: productId,
//                                                   productDSN: productDSN,
//                                                   codeVerifier: codeVerifier,
//                                                   config: config)
            Provision.showProvisioningUI(on: self, config: config)
        }
    #endif

    @IBAction func provisionButtonClicked(_: Any) {
        #if AVS
            provisionWithAmazon()
        #else

            let transport = Provision.CONFIG_TRANSPORT_WIFI
            #if BLE
                transport = Provision.CONFIG_TRANSPORT_BLE
            #endif

            let security = Provision.CONFIG_SECURITY_SECURITY0
            #if SEC1
                security = Provision.CONFIG_SECURITY_SECURITY1
            #endif

            var config = [
                Provision.CONFIG_TRANSPORT_KEY: transport,
                Provision.CONFIG_SECURITY_KEY: security,
                Provision.CONFIG_PROOF_OF_POSSESSION_KEY: pop,
                Provision.CONFIG_BASE_URL_KEY: baseUrl,
                Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
                Provision.CONFIG_BLE_DEVICE_NAME_PREFIX: deviceNamePrefix,
            ]
            if let serviceUUIDString = serviceUUIDString {
                config[Provision.CONFIG_BLE_SERVICE_UUID] = serviceUUIDString
                config[Provision.CONFIG_BLE_SESSION_UUID] = sessionUUIDString
                config[Provision.CONFIG_BLE_CONFIG_UUID] = configUUIDString
            }

            Provision.showProvisioningUI(on: self, config: config)
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

//    #if AVS
//        private func configureAWSLogin(session newSession: Session,
//                                       completionHandler: @escaping (Error?) -> Void) {
//            let configureAVS = ConfigureAVS(session: newSession)
//
//            DispatchQueue.main.async {
//                ConfigureAVS.loginWithAmazon(completionHandler: { awsInfo, error in
//                    guard error == nil, awsInfo != nil else {
//                        return
//                    }
//
//                    let authCode = awsInfo![ConfigureAVS.AUTH_CODE]
//                    let redirectUri = awsInfo![ConfigureAVS.REDIRECT_URI]
//                    let codeVerifier = awsInfo![ConfigureAVS.CODE_VERIFIER]
//                    let clientId = awsInfo![ConfigureAVS.CLIENT_ID]
//
//                    if let authCode = authCode,
//                        let clientId = clientId,
//                        let redirectUri = redirectUri,
//                        let codeVerifier = codeVerifier {
//                        configureAVS.configureAmazonLogin(cliendId: clientId,
//                                                          authCode: authCode,
//                                                          redirectUri: redirectUri) { _, error in
//                            if let error = error {
//                                print("Error in configuring AVS : \(error)")
//                            } else {
//                                print("AVS configured \(authCode)")
//                            }
//
//                            completionHandler(error)
//                        }
//                    }
//
//                })
//            }
//        }
//    #endif

    private func provisionDevice() {
        print("provisionDevice in ViewController")
        if let transport = transport, let security = security {
            let newSession = Session(transport: transport,
                                     security: security)

            newSession.initialize(response: nil) { error in
                guard error == nil else {
                    print("Error in establishing session \(error.debugDescription)")
                    return
                }

                let provision = Provision(session: newSession)

                provision.configureWifiAvs(ssid: self.ssid,
                                           passphrase: self.passphrase,
                                           avs: self.avsdetails) { status, error in
                    guard error == nil else {
                        print("Error in configuring wifi : \(error.debugDescription)")
                        return
                    }

                    if status == Espressif_Status.success {
//                        #if AVS
//                            self.configureAWSLogin(session: newSession) { _ in
//                                self.applyConfigurations(provision: provision)
//                            }
//                        #else
                        self.applyConfigurations(provision: provision)
//                        #endif
                    }
                }
            }
        }
    }

    private func applyConfigurations(provision: Provision) {
        provision.applyConfigurations(completionHandler: { status, error in
            guard error == nil else {
                print("Error in applying configurations : \(error.debugDescription)")
                return
            }
            print("Configurations applied ! \(status)")
        },
                                      wifiStatusUpdatedHandler: { wifiState, failReason, error in
            let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as? SuccessViewController
            if let successVC = successVC {
                if error != nil {
                    successVC.statusText = "Error in getting wifi state : \(error.debugDescription)"
                } else if wifiState == Espressif_WifiStationState.connected {
                    successVC.statusText = "Device has been successfully provisioned!"
                } else if wifiState == Espressif_WifiStationState.disconnected {
                    successVC.statusText = "Please check the device indicators for Provisioning status."
                } else {
                    successVC.statusText = "Device provisioning failed.\nReason : \(failReason).\nPlease try again"
                }
                self.navigationController?.present(successVC, animated: true, completion: nil)
            }
        })
    }

    private func generateProductDSN() -> String {
        return UUID().uuidString
    }

    func showError(errorMessage: String) {
        let alertMessage = errorMessage
        let alertController = UIAlertController(title: "Provision device", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

#if BLE
    extension ViewController: BLETransportDelegate {
        func peripheralsFound(peripherals: [CBPeripheral]) {
            bleTransport?.connect(peripheral: peripherals[0], withOptions: nil)
        }

        func peripheralsNotFound(serviceUUID: UUID?) {
            showError(errorMessage: "No peripherals found for service UUID : \(String(describing: serviceUUID?.uuidString))")
        }

        func peripheralConfigured(peripheral _: CBPeripheral) {
            provisionDevice()
        }

        func peripheralNotConfigured(peripheral _: CBPeripheral) {
            showError(errorMessage: "Device cannot be configured")
        }

        func peripheralDisconnected(peripheral _: CBPeripheral, error: Error?) {
            showError(errorMessage: "Error in connection : \(String(describing: error))")
        }
    }
#endif
