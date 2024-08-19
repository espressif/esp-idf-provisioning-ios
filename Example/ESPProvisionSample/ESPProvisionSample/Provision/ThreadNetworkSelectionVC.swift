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
//  ThreadNetworkSelectionVC.swift
//  ESPProvisionSample
//

import UIKit
import ThreadNetwork
import ESPProvision

@available(iOS 15.0, *)
class ThreadNetworkSelectionVC: UIViewController {
    
    var shouldScanThreadNetworks: Bool = true
    static let storyboardId = "ThreadNetworkSelectionVC"
    var espDevice: ESPDevice!
    @IBOutlet var nextButton: UIButton!
    var threadOperationalDataset: Data!
    @IBOutlet weak var availableThreadNetwork: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.threadOperationalDataset = nil
        if #available(iOS 16.4, *) {
            self.getThreadData()
        } else {
            self.alertUser(title: "Error", message: ESPProvMessages.upgradeOSVersionMsg, buttonTitle: "OK") {}
        }
    }
    
    @available(iOS 16.4, *)
    func getThreadData() {
        if self.shouldScanThreadNetworks {
            DispatchQueue.main.async {
                Utility.showLoader(message: "Scanning thread networks...", view: self.view)
            }
            self.provisionWithThread(device: self.espDevice) { tOD, networkName in
                self.threadOperationalDataset = tOD
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.nextButton.alpha = 1.0
                    self.availableThreadNetwork.text = "Available Thread Network:\n\(networkName)\nDo you wish to proceed?"
                }
            }
        } else {
            DispatchQueue.main.async {
                Utility.showLoader(message: "Fetching thread dataset...", view: self.view)
            }
            self.provisionWithActiveNetwork(device: self.espDevice) { tOD, networkName in
                self.threadOperationalDataset = tOD
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.nextButton.alpha = 1.0
                    self.availableThreadNetwork.text = "Available Thread Network:\n\(networkName)\nDo you wish to proceed?"
                }
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.espDevice.disconnect()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if #available(iOS 16.4, *) {
            if let tOD = self.threadOperationalDataset {
                self.showStatusScreen(espDevice: self.espDevice, threadOperationalDataset: tOD)
            }
        } else {
            self.alertUser(title: "Error", message: ESPProvMessages.upgradeOSVersionMsg, buttonTitle: "OK") {}
        }
    }
}
