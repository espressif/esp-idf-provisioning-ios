// Copyright 2024 Espressif Systems
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
//  ThreadSuccessViewController+NodeAssocation.swift
//  ESPRainMaker
//

import UIKit
import ESPProvision

@available(iOS 16.4, *)
extension ThreadSuccessViewController {
    
    func updateConfirmNodeAssociationUI(requestID: String) {
        DispatchQueue.main.async {
            self.okayButton.isEnabled = true
            self.okayButton.alpha = 1.0
            self.step4Image.isHidden = true
            self.activityIndicator4.isHidden = false
            self.activityIndicator4.startAnimating()
        }
        checkDeviceAssoicationStatus(nodeID: User.shared.currentAssociationInfo!.nodeID, requestID: requestID)
    }
    
    func checkDeviceAssoicationStatus(nodeID: String, requestID: String) {
        fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
    }
    
    func deviceAssociationFailedWithMessage(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator4.stopAnimating()
            self.step4Image.image = UIImage(named: "error_icon")
            self.step4Image.isHidden = false
            self.step4Error.text = message
            self.step4Error.isHidden = false
            self.espDevice.disconnect()
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }
    
    func fetchDeviceAssociationStatus(nodeID: String, requestID: String) {
        NetworkManager.shared.deviceAssociationStatus(nodeID: nodeID, requestID: requestID) { status in
            if status == "confirmed" {
                User.shared.updateDeviceList = true
                self.activityIndicator4.stopAnimating()
                self.step4Image.image = UIImage(named: "checkbox_checked")
                self.step4Image.isHidden = false
                self.addDeviceStatusTimeout?.invalidate()
                self.step5SetupNode(nodeID: nodeID)
            } else if status == "timedout" {
                self.deviceAssociationFailedWithMessage(message: "Node addition not confirmed")
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
                }
            }
        }
    }
}
