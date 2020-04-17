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
//  SuccessViewController.swift
//  EspressifProvision
//

import Foundation
import UIKit

class SuccessViewController: UIViewController {
    var statusText: String?
    var session: ESPSession!
    var deviceID: String?
    var requestID: String?
    var success = false
    var sessionInit = true
    var transport: Transport!
    var ssid: String!
    var passphrase: String!
    var provision: Provision!
    var addDeviceStatusTimeout: Timer?
    var step1Failed = false
    var count: Int = 0

//    @IBOutlet var successLabel: UILabel!
    @IBOutlet var step1Image: UIImageView!
    @IBOutlet var step2Image: UIImageView!
    @IBOutlet var step3Image: UIImageView!
    @IBOutlet var step4Image: UIImageView!
    @IBOutlet var step1Indicator: UIActivityIndicatorView!
    @IBOutlet var step2Indicator: UIActivityIndicatorView!
    @IBOutlet var step3Indicator: UIActivityIndicatorView!
    @IBOutlet var step4Indicator: UIActivityIndicatorView!
    @IBOutlet var step1ErrorLabel: UILabel!
    @IBOutlet var step2ErrorLabel: UILabel!
    @IBOutlet var step3ErrorLabel: UILabel!
    @IBOutlet var step4ErrorLabel: UILabel!
    @IBOutlet var finalStatusLabel: UILabel!
    @IBOutlet var okayButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if step1Failed {
            step1FailedWithMessage(message: "Wrong pop entered!")
        } else {
            startProvisioning()
        }
    }

    func startProvisioning() {
        step1Image.isHidden = true
        step1Indicator.isHidden = false
        step1Indicator.startAnimating()
        provision = Provision(session: session)

        provision.configureWifi(ssid: ssid, passphrase: passphrase) { status, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    print("Error in configuring wifi : \(error.debugDescription)")
                    self.step1FailedWithMessage(message: "Configuration error!")
                    return
                }
                switch status {
                case .success:
                    self.step2applyConfigurations()
                case .invalidSecScheme:
                    self.step1FailedWithMessage(message: "Invalid Scheme")
                case .invalidProto:
                    self.step1FailedWithMessage(message: "Invalid Proto")
                case .tooManySessions:
                    self.step1FailedWithMessage(message: "Too many sessions")
                case .invalidArgument:
                    self.step1FailedWithMessage(message: "Invalid argument")
                case .internalError:
                    self.step1FailedWithMessage(message: "Internal error")
                case .cryptoError:
                    self.step1FailedWithMessage(message: "Crypto error")
                case .invalidSession:
                    self.step1FailedWithMessage(message: "Invalid session")
                case .UNRECOGNIZED:
                    self.step1FailedWithMessage(message: "Unrecognized error")
                }
            }
        }
    }

    private func step2applyConfigurations() {
        provision.applyConfigurations(completionHandler: { _, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    self.step1FailedWithMessage(message: "Configuration error!")
                    return
                }
                self.step1Indicator.stopAnimating()
                self.step1Image.image = UIImage(named: "checkbox_checked")
                self.step1Image.isHidden = false
                self.step2Image.isHidden = true
                self.step2Indicator.isHidden = false
                self.step2Indicator.startAnimating()
            }
        },
                                      wifiStatusUpdatedHandler: { wifiState, failReason, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.step2FailedWithMessage(message: "Unable to get Wi-Fi State")
                } else if wifiState == Espressif_WifiStationState.connected {
                    self.step2Indicator.stopAnimating()
                    self.step2Image.image = UIImage(named: "checkbox_checked")
                    self.step2Image.isHidden = false
                    self.step3SendRequestToAddDevice()
                } else if wifiState == Espressif_WifiStationState.disconnected {
                    self.step2Indicator.stopAnimating()
                    self.step2Image.image = UIImage(named: "warning_icon")
                    self.step2Image.isHidden = false
                    self.step2ErrorLabel.text = "Wi-Fi state disconnected"
                    self.step2ErrorLabel.isHidden = false
                    self.step3SendRequestToAddDevice()
                } else {
                    if failReason == Espressif_WifiConnectFailedReason.authError {
                        self.step2FailedWithMessage(message: "Wi-Fi Authentication failed")
                    } else if failReason == Espressif_WifiConnectFailedReason.networkNotFound {
                        self.step2FailedWithMessage(message: "Network not found")
                    } else {
                        self.step2FailedWithMessage(message: "\(failReason)")
                    }
                }
            }
        })
    }

    private func step3SendRequestToAddDevice() {
        step3Image.isHidden = true
        step3Indicator.isHidden = false
        step3Indicator.startAnimating()
        count = 5
        sendRequestToAddDevice()
    }

    private func step4ConfirmNodeAssociation(requestID: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        step4Image.isHidden = true
        step4Indicator.isHidden = false
        step4Indicator.startAnimating()
        checkDeviceAssoicationStatus(nodeID: User.shared.currentAssociationInfo!.nodeID, requestID: requestID)
    }

    func checkDeviceAssoicationStatus(nodeID: String, requestID: String) {
//        addDeviceStatusTimeout = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timeoutFetchingStatus), userInfo: nil, repeats: false)
        fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
    }

    @objc func timeoutFetchingStatus() {
        step4FailedWithMessage(message: "Node addition not confirmed")
        addDeviceStatusTimeout?.invalidate()
    }

    func fetchDeviceAssociationStatus(nodeID: String, requestID: String) {
        NetworkManager.shared.deviceAssociationStatus(nodeID: nodeID, requestID: requestID) { status in
            if status == "confirmed" {
                NotificationCenter.default.post(name: Notification.Name(Constants.newDeviceAdded), object: nil)
                User.shared.updateDeviceList = true
                self.step4Indicator.stopAnimating()
                self.step4Image.image = UIImage(named: "checkbox_checked")
                self.step4Image.isHidden = false
                self.addDeviceStatusTimeout?.invalidate()
                self.provisionFinsihedWithStatus(message: "Device added successfully!!")
            } else if status == "timedout" {
                self.step4FailedWithMessage(message: "Node addition not confirmed")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    func step1FailedWithMessage(message: String) {
        step1Indicator.stopAnimating()
        step1Image.image = UIImage(named: "error_icon")
        step1Image.isHidden = false
        step1ErrorLabel.text = message
        step1ErrorLabel.isHidden = false
        provisionFinsihedWithStatus(message: "Reboot your board and try again.")
    }

    func step2FailedWithMessage(message: String) {
        step2Indicator.stopAnimating()
        step2Image.image = UIImage(named: "error_icon")
        step2Image.isHidden = false
        step2ErrorLabel.text = message
        step2ErrorLabel.isHidden = false
        provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
    }

    func step3FailedWithMessage(message: String) {
        step3Indicator.stopAnimating()
        step3Image.image = UIImage(named: "error_icon")
        step3Image.isHidden = false
        step3ErrorLabel.text = message
        step3ErrorLabel.isHidden = false
        provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
    }

    func step4FailedWithMessage(message: String) {
        step4Indicator.stopAnimating()
        step4Image.image = UIImage(named: "error_icon")
        step4Image.isHidden = false
        step4ErrorLabel.text = message
        step4ErrorLabel.isHidden = false
        provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
    }

    func provisionFinsihedWithStatus(message: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        finalStatusLabel.text = message
        finalStatusLabel.isHidden = false
    }

    @objc func sendRequestToAddDevice() {
        let parameters = ["user_id": User.shared.userInfo.userID, "node_id": User.shared.currentAssociationInfo!.nodeID, "secret_key": User.shared.currentAssociationInfo!.uuid, "operation": "add"]
        NetworkManager.shared.addDeviceToUser(parameter: parameters as! [String: String]) { requestID, error in
            if error != nil, self.count > 0 {
                self.count = self.count - 1
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.perform(#selector(self.sendRequestToAddDevice), with: nil, afterDelay: 5.0)
                }
            } else {
                if let requestid = requestID {
                    self.step3Indicator.stopAnimating()
                    self.step3Image.image = UIImage(named: "checkbox_checked")
                    self.step3Image.isHidden = false
                    self.step4ConfirmNodeAssociation(requestID: requestid)
                } else {
                    self.step3FailedWithMessage(message: error?.description ?? "Unrecognized error. Please check your internet.")
                }
            }
        }
    }

    @IBAction func goToFirstView(_: Any) {
        let destinationVC = navigationController?.viewControllers.first as! DevicesViewController
        destinationVC.checkDeviceAssociation = true
        destinationVC.deviceID = deviceID
        destinationVC.requestID = requestID
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
}
