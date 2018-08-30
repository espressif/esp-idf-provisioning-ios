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
#if AVS
    import Foundation
    import UIKit

    class LoginWithAmazonViewController: UIViewController {
        var provisionConfig: [String: String] = [:]

        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view, typically from a nib.
        }

        @IBAction func onAmazonLoginClicked(_: Any) {
            ConfigureAVS.loginWithAmazon(productId: provisionConfig[ConfigureAVS.PRODUCT_ID]!,
                                         deviceSerialNumber: provisionConfig[ConfigureAVS.DEVICE_SERIAL_NUMBER]!,
                                         codeVerifier: provisionConfig[ConfigureAVS.CODE_VERIFIER]!) { results, error in
                if error != nil {
                    print(error.debugDescription)
                } else if let results = results {
                    var config = self.provisionConfig
                    results.forEach { config[$0] = $1 }
                    DispatchQueue.main.async {
                        let transportVersion = config[Provision.CONFIG_TRANSPORT_KEY]
                        if let transportVersion = transportVersion, transportVersion == Provision.CONFIG_TRANSPORT_BLE {
                            let provisionLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "bleLanding") as! BLELandingViewController
                            provisionLandingVC.provisionConfig = config
                            self.navigationController?.pushViewController(provisionLandingVC, animated: true)
                        } else {
                            let provisionLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
                            provisionLandingVC.provisionConfig = config
                            self.navigationController?.pushViewController(provisionLandingVC, animated: true)
                        }
                    }
                }
            }
        }
    }
#endif
