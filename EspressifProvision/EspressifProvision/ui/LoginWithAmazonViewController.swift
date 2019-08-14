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
//  LoginWithAmazonViewController.swift
//  EspressifProvision
//

import Foundation
import UIKit

class LoginWithAmazonViewController: UIViewController {
    var provisionConfig: [String: String] = [:]
    var transport: Transport?
    var secu: Security?
    var newSession: Session?
    var bleTransport: BLETransport?
    var configureAvs: ConfigureAVS?
    var waiter: Bool?
    var deviceDetails: [String] = ["", "", ""]
    var deviceName: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.title = deviceName ?? ""
        // Add skip button
        let rightBarButton = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(skipAction))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    @objc func skipAction() {
        configureSession()

        let newSession = Session(transport: transport!,
                                 security: secu!)

        newSession.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                return
            }
            if newSession.isEstablished {
                var prov: Provision
                prov = Provision(session: newSession)

                self.navigateToProvisionVC(result: nil)
            }
        }
    }

    @IBAction func onAmazonLoginClicked(_: Any) {
        Constants.showLoader(message: "Signing in", view: view)

        configureSession()

        do {
            getDeviceDetails(tras: bleTransport!, secu: secu as! Security1) { _ in
                self.callLWA()
            }
        }
    }

    private func getDeviceDetails(tras _: Transport,
                                  secu _: Security1,
                                  completionHandler: @escaping (String) -> Swift.Void) {
        let newSession = Session(transport: transport!,
                                 security: secu!)

        newSession.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                return
            }
            if newSession.isEstablished {
                var prov: Provision
                prov = Provision(session: newSession)
                self.deviceDetails = prov.getAVSDeviceDetails(completionHandler: { _, error in
                    guard error == nil else {
                        print(error!)

                        return
                    }

                    completionHandler("nil")
                })
            }
        }
        return
    }

    private func configureSession() {
        let bleConfigUuid = provisionConfig[Provision.CONFIG_BLE_CONFIG_UUID]
        var configUUIDMap: [String: String] = [Provision.PROVISIONING_CONFIG_PATH: bleConfigUuid!]
        let avsconfigUuid = provisionConfig[ConfigureAVS.AVS_CONFIG_UUID_KEY]
        configUUIDMap[ConfigureAVS.AVS_CONFIG_PATH] = avsconfigUuid

        bleTransport = BLETransport(
            serviceUUIDString: provisionConfig[Provision.CONFIG_BLE_SERVICE_UUID],
            sessionUUIDString: provisionConfig[Provision.CONFIG_BLE_SESSION_UUID]!,

            configUUIDMap: configUUIDMap,
            deviceNamePrefix: provisionConfig[Provision.CONFIG_BLE_DEVICE_NAME_PREFIX]!,
            scanTimeout: 5.0
        )

        let securityVersion = provisionConfig[Provision.CONFIG_SECURITY_KEY]
        let pop = provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY]
        if securityVersion == Provision.CONFIG_SECURITY_SECURITY1 {
            secu = Security1(proofOfPossession: pop!)
        } else {
            secu = Security0()
        }
    }

    private func navigateToProvisionVC(result: [String: String]?) {
        var config = provisionConfig
        if let results = result {
            results.forEach { config[$0] = $1 }
        }
        DispatchQueue.main.async {
            let transportVersion = config[Provision.CONFIG_TRANSPORT_KEY]
            if let transportVersion = transportVersion, transportVersion == Provision.CONFIG_TRANSPORT_BLE {
                let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
                provisionVC.provisionConfig = config
                provisionVC.avsDetails = result
                provisionVC.transport = self.transport
                provisionVC.security = self.secu
                self.navigationController?.pushViewController(provisionVC, animated: true)
            } else {
                let provisionLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
                provisionLandingVC.provisionConfig = config
                self.navigationController?.pushViewController(provisionLandingVC, animated: true)
            }
        }
    }

    public func callLWA() {
        DispatchQueue.main.async {
            ConfigureAVS.loginWithAmazon { results, error in
                Constants.hideLoader(view: self.view)
                if error != nil {
                    print(error.debugDescription)
                } else if let results = results {
                    // Write AVS details to device
//                print(results)
//                self.putAVSDetails(results: results)
                    self.waiter = true
                    self.navigateToProvisionVC(result: results)
                }
            }
        }
    }
}
