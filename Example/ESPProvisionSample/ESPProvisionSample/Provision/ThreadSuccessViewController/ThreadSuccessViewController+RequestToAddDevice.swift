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
//  ThreadSuccessViewController+RequestToAddDevice.swift
//  ESPRainMaker
//

import UIKit
import ESPProvision

@available(iOS 16.4, *)
extension ThreadSuccessViewController {
    
    func sendRequestToAddDeviceAndUpdateUI(completion: @escaping (String?, String) -> Void) {
        self.updateUIForSendRequestToAddDevice()
        self.sendRequestToAddDevice(completion: completion)
    }
    
    func updateUIForSendRequestToAddDevice() {
        DispatchQueue.main.async {
            self.activityIndicator2.stopAnimating()
            self.step2Image.image = UIImage(named: "checkbox_checked")
            self.step2Image.isHidden = false
            self.step3Image.isHidden = true
            self.activityIndicator3.isHidden = false
            self.activityIndicator3.startAnimating()
            self.count = 5
        }
    }
    
    func sendRequestToAddDeviceFailed(errorMessage: String) {
        DispatchQueue.main.async {
            self.activityIndicator3.stopAnimating()
            self.step3Image.image = UIImage(named: "error_icon")
            self.step3Image.isHidden = false
            self.step3Error.text = errorMessage
            self.step3Error.isHidden = false
            self.espDevice.disconnect()
            self.provisionFinsihedWithStatus(message: "Reset your board to factory defaults and retry.")
        }
    }
    
    //MARK: Network APIs
    func sendRequestToAddDevice(completion: @escaping (String?, String) -> Void) {
        let parameters = ["user_id": User.shared.userInfo.userID, "node_id": User.shared.currentAssociationInfo!.nodeID, "secret_key": User.shared.currentAssociationInfo!.uuid, "operation": "add"]
        NetworkManager.shared.addDeviceToUser(parameter: parameters as! [String: String]) { requestID, error in
            if error != nil, self.count > 0 {
                self.count = self.count - 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.sendRequestToAddDevice(completion: completion)
                }
            } else {
                if let requestid = requestID {
                    self.activityIndicator3.stopAnimating()
                    self.step3Image.image = UIImage(named: "checkbox_checked")
                    self.step3Image.isHidden = false
                    completion(requestid, "")
                } else {
                    let errorMessage = error?.description ?? "Unrecognized error. Please check your internet."
                    completion(nil, errorMessage)
                }
            }
        }
    }
}
