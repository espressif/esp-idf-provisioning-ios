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
//  ThreadSuccessViewController.swift
//  ESPRainMaker
//

import ESPProvision
import Foundation
import UIKit

@available(iOS 16.4, *)
class ThreadSuccessViewController: UIViewController {
    
    static let storyboardId = "ThreadSuccessViewController"
    
    @IBOutlet weak var step1Image: UIImageView!
    @IBOutlet weak var step2Image: UIImageView!
    @IBOutlet weak var step3Image: UIImageView!
    @IBOutlet weak var step4Image: UIImageView!
    @IBOutlet weak var step5Image: UIImageView!
    
    @IBOutlet weak var step1Error: UILabel!
    @IBOutlet weak var step2Error: UILabel!
    @IBOutlet weak var step3Error: UILabel!
    @IBOutlet weak var step4Error: UILabel!
    @IBOutlet weak var step5Error: UILabel!
    
    @IBOutlet weak var step1Description: UILabel!
    @IBOutlet weak var step2Description: UILabel!
    @IBOutlet weak var step3Description: UILabel!
    @IBOutlet weak var step4Description: UILabel!
    @IBOutlet weak var step5Description: UILabel!
    
    @IBOutlet weak var activityIndicator1: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicator2: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicator3: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicator4: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicator5: UIActivityIndicatorView!
    
    @IBOutlet var finalStatusLabel: UILabel!
    @IBOutlet var okayButton: UIButton!
    
    @IBOutlet weak var step1ImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var step1ImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var step1ImageBottomConstraint: NSLayoutConstraint!
    
    var espDevice: ESPDevice!
    var shouldScanThreadNetworks: Bool = true
    
    var count: Int = 0
    var addDeviceStatusTimeout: Timer?
    
    var nodeDetailsFetched = false
    var nodeIsConnected = false
    var setupTimeout = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUIForScanThreadNetworks()
        self.invokeProvisioningWorkflow()
    }
    
    @IBAction func goToFirstView(_: Any) {
        let destinationVC = navigationController?.viewControllers.first as! DevicesViewController
        destinationVC.checkDeviceAssociation = true
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
    
    /// Invoke provisioning workflow
    func invokeProvisioningWorkflow() {
        if shouldScanThreadNetworks {
            self.scanThreadNetwork()
        } else {
            self.performActiveThreadNetworkProv(espDevice: self.espDevice) { threadOperationalDataset in
                if let data = threadOperationalDataset {
                    self.applyThreadDataset(threadOperationalDataset: data)
                }
            }
        }
    }
    
    /// Start scanning thread networks
    func scanThreadNetwork() {
        self.startUIUpdateForThreadNetworkScanning()
        self.espDevice.scanThreadList { threadList, threadError in
            guard let threadList = threadList else {
                var failureMessage = ""
                if let threadError = threadError {
                    failureMessage = threadError.localizedDescription
                    self.updateUIForNetworkScanFailure(message: failureMessage)
                }
                return
            }
            self.updateUIForThreadNetworkScanSuccess()
            self.provFetchMultipleThreadNetworks(espDevice: self.espDevice, threadList: threadList) { threadOperationalDataset in
                if let data = threadOperationalDataset {
                    self.applyThreadDataset(threadOperationalDataset: data)
                }
            }
        }
    }
    
    /// Apply thread dataset to the esp device
    /// - Parameter threadOperationalDataset: thread operational dataser
    func applyThreadDataset(threadOperationalDataset: Data) {
        self.updateApplyConfigurationUI()
        self.provision(threadOperationalDataset: threadOperationalDataset) { status in
            self.handleUIForStatusUpdate(status: status)
        }
    }
    
    /// Start provisioning
    /// - Parameters:
    ///   - threadOperationalDataset: thread operational dataset
    ///   - completionHandler: completion handler
    func provision(threadOperationalDataset: Data, completionHandler: @escaping (ESPProvisionStatus) -> Void) {
        espDevice.provision(ssid: nil, passPhrase: nil, threadOperationalDataset: threadOperationalDataset) { status in
            completionHandler(status)
        }
    }
    
    /// Handle UI for status update
    /// - Parameter status: ESPProvisionStatus
    func handleUIForStatusUpdate(status: ESPProvisionStatus) {
        switch status {
        case .success:
            self.sendRequestToAddDeviceAndUpdateUI { requestId, errorMessage in
                guard let requestId = requestId else {
                    self.sendRequestToAddDeviceFailed(errorMessage: errorMessage)
                    return
                }
                self.updateConfirmNodeAssociationUI(requestID: requestId)
            }
        case let .failure(error):
            switch error {
            case .configurationError:
                self.updateApplyConfigurationUIFailure(message: "Failed to apply network configuration to device")
            case .sessionError:
                self.updateApplyConfigurationUIFailure(message: "Session is not established")
            case .threadStatusDettached:
                self.sendRequestToAddDeviceAndUpdateUI { requestId, errorMessage in
                    guard let requestId = requestId else {
                        self.sendRequestToAddDeviceFailed(errorMessage: errorMessage)
                        return
                    }
                    self.updateConfirmNodeAssociationUI(requestID: requestId)
                }
            default:
                self.updateApplyConfigurationUIFailure(message: "Session is not established")
            }
        case .configApplied:
            self.updateApplyConfigurationUISuccess()
        }
    }
    
    //MARK: UI updates
    func updateUIForScanThreadNetworks() {
        if !self.shouldScanThreadNetworks {
            DispatchQueue.main.async {
                self.step1Image.isHidden = true
                self.activityIndicator1.isHidden = true
                self.step1Error.isHidden = true
                self.step1Description.isHidden = true
                self.step1ImageBottomConstraint.constant = -24.0
            }
        }
    }
    
    /// Update OK button status with message
    /// - Parameter message: message
    func provisionFinsihedWithStatus(message: String) {
        okayButton.isEnabled = true
        okayButton.alpha = 1.0
        finalStatusLabel.text = message
        finalStatusLabel.isHidden = false
    }
}

