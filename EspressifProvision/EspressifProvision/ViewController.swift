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
    private let scanUUIDString: String? = Bundle.main.infoDictionary?["BLEScanUUID"] as? String
    // WIFI
    private let baseUrl = Bundle.main.infoDictionary?["WifiBaseUrl"] as! String
    private let networkNamePrefix = Bundle.main.infoDictionary?["WifiNetworkNamePrefix"] as! String

    var transport: Transport?
    var security: Security?
    var bleTransport: BLETransport?

    override func viewDidLoad() {
        super.viewDidLoad()
        productDSN = generateProductDSN()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem?.image = UIImage(named: "info_icon")
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
                Provision.CONFIG_BASE_URL_KEY: baseUrl,
                Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
                Provision.CONFIG_BLE_DEVICE_NAME_PREFIX: deviceNamePrefix,
                ConfigureAVS.PRODUCT_ID: productId,
                ConfigureAVS.DEVICE_SERIAL_NUMBER: productDSN,
                ConfigureAVS.CODE_CHALLENGE: codeVerifier,
            ]
            config[ConfigureAVS.AVS_CONFIG_UUID_KEY] = avsconfigUUIDString
            print(config)
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
                config[Provision.CONFIG_BLE_SCAN_UUID] = scanUUIDString
            }

            Provision.showProvisioningUI(on: self, config: config)
        #endif
    }

    private func generateProductDSN() -> String {
        return UUID().uuidString
    }
}
