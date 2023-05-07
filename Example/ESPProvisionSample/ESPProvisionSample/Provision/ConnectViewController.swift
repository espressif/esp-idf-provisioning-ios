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
//  ConnectViewController.swift
//  ESPProvisionSample
//

import ESPProvision
import UIKit

// Class to let user enter the POP and establish connection with the device.
class ConnectViewController: UIViewController {
    
    @IBOutlet var popTextField: UITextField!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    
    var capabilities: [String]?
    var espDevice: ESPDevice!
    var username = ""
    var password = ""
    var pop = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = "Enter proof of possession PIN for \n" + espDevice.name
    }

    // MARK: - IBActions
    
    // On click of cancel button, terminate the provisioning and go to first screen.
    @IBAction func cancelClicked(_: Any) {
        espDevice.disconnect()
        navigationController?.popToRootViewController(animated: true)
    }

    // On click of next button, establish session with device using connect API.
    @IBAction func nextBtnClicked(_: Any) {
        pop = popTextField.text ?? ""
        Utility.showLoader(message: "Connecting to device", view: view)
        espDevice.security = Utility.shared.espAppSettings.securityMode
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                switch status {
                case .connected:
                    self.goToProvision()
                case let .failedToConnect(error):
                    self.showStatusScreen(error: error)
                default:
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    // Show status screen, called when device connection fails.
    func showStatusScreen(error: ESPSessionError) {
            let statusVC = self.storyboard?.instantiateViewController(withIdentifier: "statusVC") as! StatusViewController
            statusVC.espDevice = self.espDevice
            statusVC.step1Failed = true
            statusVC.message = error.description
            self.navigationController?.pushViewController(statusVC, animated: true)

    }

    // Go to provision screen, called when device is connected.
    func goToProvision() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.espDevice = self.espDevice
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }

    // MARK: - Helper Methods
    
    func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }
}

extension ConnectViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        completionHandler(pop)
    }

    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        completionHandler(Utility.shared.espAppSettings.username)
    }
}
