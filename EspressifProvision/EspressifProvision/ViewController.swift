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
    private let passphrase = "5=ChotaCoke"
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
    }

    func provisionWithAPIs(_: Any) {
        #if SEC1
            security = Security1(proofOfPossession: pop)
        #else
            security = Security0()
        #endif

        #if BLE
            let configUUIDMap: [String: String] = [Provision.PROVISIONING_CONFIG_PATH: configUUIDString]
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

    @IBAction func provisionButtonClicked(_: Any) {
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
        ]
        if let serviceUUIDString = serviceUUIDString {
            config[Provision.CONFIG_BLE_SERVICE_UUID] = serviceUUIDString
            config[Provision.CONFIG_BLE_SESSION_UUID] = sessionUUIDString
            config[Provision.CONFIG_BLE_CONFIG_UUID] = configUUIDString
        }

        Provision.showProvisioningUI(on: self, config: config)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func provisionDevice() {
        if let transport = transport, let security = security {
            let newSession = Session(transport: transport,
                                     security: security)

            newSession.initialize(response: nil) { error in
                guard error == nil else {
                    print("Error in establishing session \(error.debugDescription)")
                    return
                }

                let provision = Provision(session: newSession)

                provision.configureWifi(ssid: self.ssid,
                                        passphrase: self.passphrase) { status, error in
                    guard error == nil else {
                        print("Error in configuring wifi : \(error.debugDescription)")
                        return
                    }

                    if status == Espressif_Status.success {
                        self.applyConfigurations(provision: provision)
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
