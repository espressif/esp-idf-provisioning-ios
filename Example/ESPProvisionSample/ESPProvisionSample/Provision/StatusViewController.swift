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
//  StatusViewController.swift
//  ESPProvisionSample
//

import ESPProvision
import Foundation
import UIKit

// Class that applies Wi-Fi credentials to device and show provisioning status.
class StatusViewController: UIViewController {
    var ssid: String!
    var passphrase: String!
    var threadOpetationalDataset: Data!
    var step1Failed = false
    var espDevice: ESPDevice!
    var message = ""

    @IBOutlet var step1Image: UIImageView!
    @IBOutlet var step2Image: UIImageView!
    @IBOutlet weak var sendingCredsLabel: UILabel!
    @IBOutlet weak var confirmNetworkConnectionLabel: UILabel!
    @IBOutlet var step1Indicator: UIActivityIndicatorView!
    @IBOutlet var step2Indicator: UIActivityIndicatorView!
    @IBOutlet var step1ErrorLabel: UILabel!
    @IBOutlet var step2ErrorLabel: UILabel!
    @IBOutlet var finalStatusLabel: UILabel!
    @IBOutlet var okayButton: UIButton!

    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = threadOpetationalDataset {
            self.sendingCredsLabel.text = "Sending Thread credentials."
            self.confirmNetworkConnectionLabel.text = "Confirming Thread connection."
        }
        if step1Failed {
            step1FailedWithMessage(message: message)
        } else {
            startProvisioning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    // MARK: - IBActions
    
    @IBAction func goToFirstView(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - Provisioning
    
    func startProvisioning() {
        step1Image.isHidden = true
        step1Indicator.isHidden = false
        step1Indicator.startAnimating()

        espDevice.provision(ssid: self.ssid, passPhrase: self.passphrase, threadOperationalDataset: self.threadOpetationalDataset) { status in
            DispatchQueue.main.async {
                switch status {
                case .success:
                    self.step2Indicator.stopAnimating()
                    self.step2Image.image = UIImage(named: "checkbox_checked")
                    self.step2Image.isHidden = false
                    self.provisionFinsihedWithStatus(message: "Device has been successfully provisioned!")
                case let .failure(error):
                    switch error {
                    case .configurationError:
                        self.step1FailedWithMessage(message: "Failed to apply network configuration to device")
                    case .sessionError:
                        self.step1FailedWithMessage(message: "Session is not established")
                    case .wifiStatusDisconnected:
                        self.step2FailedWithMessage(error: error)
                    default:
                        self.step2FailedWithMessage(error: error)
                    }
                case .configApplied:
                    self.step2applyConfigurations()
                }
            }
        }
    }

    func step2applyConfigurations() {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "checkbox_checked")
            self.step1Image.isHidden = false
            self.step2Image.isHidden = true
            self.step2Indicator.isHidden = false
            self.step2Indicator.startAnimating()
        }
    }

    func step1FailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.step1Indicator.stopAnimating()
            self.step1Image.image = UIImage(named: "error_icon")
            self.step1Image.isHidden = false
            self.step1ErrorLabel.text = message
            self.step1ErrorLabel.isHidden = false
            self.provisionFinsihedWithStatus(message: "Reboot your board and try again.")
        }
    }

    func step2FailedWithMessage(error: ESPProvisionError) {
        DispatchQueue.main.async {
            self.step2Indicator.stopAnimating()
            self.step2Image.image = UIImage(named: "error_icon")
            self.step2Image.isHidden = false
            var errorMessage = ""
            switch error {
            case .wifiStatusUnknownError, .wifiStatusDisconnected, .wifiStatusNetworkNotFound, .wifiStatusAuthenticationError:
                errorMessage = error.description
            case .wifiStatusError:
                errorMessage = "Unable to fetch Wi-Fi state."
            default:
                errorMessage = "Unknown error."
            }
            self.step2ErrorLabel.text = errorMessage
            self.step2ErrorLabel.isHidden = false
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }

    func provisionFinsihedWithStatus(message: String) {
        self.espDevice.disconnect()
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        finalStatusLabel.text = message
        finalStatusLabel.isHidden = false
    }
}

