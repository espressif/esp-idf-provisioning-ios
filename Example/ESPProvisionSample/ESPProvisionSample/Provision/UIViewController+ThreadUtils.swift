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
//  UIViewController+ThreadUtils.swift
//  ESPProvisionSample
//

import ESPProvision
import ThreadNetwork
import UIKit

struct ESPProvMessages {
    static let noScannedNetworks = "Unable to find any thread networks."
    static let noThreadBRDescription = "Please ensure that you have added a Thread Border Router to your Apple Id."
    static let noMatchingThreadDescription = "The preferred credentials on the app don't match any of the scanned thread networks. Please ensure your home hub is powered on and connected."
    static let upgradeOSVersionMsg = "You must upgrade to iOS 16.4 or above in order to avail this feature."
}

extension UIViewController {
    
    /// Show thread network selection screen
    /// - Parameters:
    ///   - shouldScanThreadNetworks: should scan thread networks
    ///   - device: esp device
    func showThreadNetworkSelectionVC(shouldScanThreadNetworks: Bool = true, device: ESPDevice) {
        DispatchQueue.main.async {
            if #available(iOS 16.4, *) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let threadNetworkSelectionVC = storyboard.instantiateViewController(withIdentifier: ThreadNetworkSelectionVC.storyboardId) as! ThreadNetworkSelectionVC
                threadNetworkSelectionVC.espDevice = device
                threadNetworkSelectionVC.shouldScanThreadNetworks = shouldScanThreadNetworks
                self.navigationController?.pushViewController(threadNetworkSelectionVC, animated: true)
            } else {
                self.alertUser(title: "Error", message: ESPProvMessages.noThreadBRDescription, buttonTitle: "OK") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    /// Provision using thread
    /// - Parameter device: esp device
    func provisionWithThread(device: ESPDevice, completion: @escaping (Data, String) -> Void) {
        device.scanThreadList { threadList, error in
            guard let threadList = threadList else {
                return
            }
            self.provUsingMultipleThreadNetworks(threadList: threadList) { tOD, networkName in
                if let thOpDataset = tOD {
                    completion(thOpDataset, networkName)
                }
            }
        }
    }
    
    /// Provision with active thread network
    /// - Parameter device: device
    func provisionWithActiveNetwork(device: ESPDevice, completion: @escaping (Data, String) -> Void) {
        self.performActiveThreadNetworkProv(espDevice: device) { tOD, networkName in
            if let thOpDataset = tOD {
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                }
                completion(thOpDataset, networkName)
            }
        }
    }
    
    /// Provision using multiple thread networks
    /// - Parameter threadList: thread list
    func provUsingMultipleThreadNetworks(threadList: [ESPThreadNetwork], completion: @escaping (Data?, String) -> Void) {
        if #available(iOS 16.4, *) {
            ThreadCredentialsManager.shared.fetchThreadCredentials { credentials in
                DispatchQueue.main.async {
                    Utility.hideLoader(view: self.view)
                }
                if let credentials = credentials {
                    let thNetwork = self.getMatchingThreadCredential(threadList: threadList, credentials: credentials)
                    if let network = thNetwork.0, let networkKey = thNetwork.1 {
                        let dataset = self.getThreadOpeartionalDataset(threadNetwork: network, networkKey: networkKey)
                        let threadOperationalDataset = Data(hex: dataset)
                        let networkName = network.networkName
                        completion(threadOperationalDataset, networkName)
                    } else {
                        DispatchQueue.main.async {
                            self.alertUser(title: "Error", message: ESPProvMessages.noMatchingThreadDescription, buttonTitle: "OK") {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.alertUser(title: "Error", message: ESPProvMessages.noThreadBRDescription, buttonTitle: "OK") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.alertUser(title: "Error", message: ESPProvMessages.upgradeOSVersionMsg, buttonTitle: "OK") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    /// Perform thread provisioning using the active store operational datraset of iOS
    func performActiveThreadNetworkProv(espDevice: ESPDevice, _ completion: @escaping (Data?, String) -> Void) {
        if #available(iOS 16.4, *) {
            ThreadCredentialsManager.shared.fetchThreadCredentials { cred in
                if let cred = cred, let networkKey = cred.networkKey, let networkName = cred.networkName {
                    let dataset = self.getThreadOpeartionalDatasetFromTHCredentials(threadNetwork: cred, networkKey: networkKey.hexadecimalString)
                    let threadOperationalDataset = Data(hex: dataset)
                    completion(threadOperationalDataset, networkName)
                } else {
                    DispatchQueue.main.async {
                        self.alertUser(title: "Error", message: ESPProvMessages.noThreadBRDescription, buttonTitle: "OK") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.alertUser(title: "Error", message: ESPProvMessages.upgradeOSVersionMsg, buttonTitle: "OK") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    /// Get thread network from list matching stored iOS thread credential
    /// - Parameters:
    ///   - threadList: thread list
    ///   - credentials: credentails
    /// - Returns: matching thread network
    @available(iOS 15.0, *)
    func getMatchingThreadCredential(threadList: [ESPThreadNetwork], credentials: THCredentials) -> (ESPThreadNetwork?, String?) {
        for threadNetwork in threadList {
            if let networkName = credentials.networkName, threadNetwork.networkName == networkName, let netKey = credentials.networkKey {
                let networkKey = netKey.hexadecimalString
                return (threadNetwork, networkKey)
            }
        }
        return (nil, nil)
    }
    
    /// Get thread operational dataset from ESPThrad network and network key
    /// - Parameters:
    ///   - threadNetwork: thread network
    ///   - networkKey: network key
    /// - Returns: thread operational dataset to be sent to the device.
    func getThreadOpeartionalDataset(threadNetwork: ESPThreadNetwork, networkKey: String) -> String {
        var threadOperationalDatasetHexString = "00030000"
        threadOperationalDatasetHexString += String(format: "%02x", threadNetwork.channel)
        threadOperationalDatasetHexString += "0208"
        threadOperationalDatasetHexString +=  threadNetwork.extPanID.hexadecimalString
        threadOperationalDatasetHexString += "0510"
        threadOperationalDatasetHexString += networkKey
        threadOperationalDatasetHexString += "0102"
        threadOperationalDatasetHexString += String(format: "%04x", threadNetwork.panID)
        return threadOperationalDatasetHexString
    }
    
    /// Get thread operational dataset to be sent from iOS app to ESP device
    /// - Parameters:
    ///   - threadNetwork: thread network
    ///   - networkKey: network key
    /// - Returns: operational dataset
    @available(iOS 16.4, *)
    func getThreadOpeartionalDatasetFromTHCredentials(threadNetwork: THCredentials, networkKey: String) -> String {
        if let extendedPANId = threadNetwork.extendedPANID, let panId = threadNetwork.panID {
            var threadOperationalDatasetHexString = "00030000"
            threadOperationalDatasetHexString += String(format: "%02x", threadNetwork.channel)
            threadOperationalDatasetHexString += "0208"
            threadOperationalDatasetHexString +=  extendedPANId.hexadecimalString
            threadOperationalDatasetHexString += "0510"
            threadOperationalDatasetHexString += networkKey
            threadOperationalDatasetHexString += "0102"
            threadOperationalDatasetHexString += panId.hexadecimalString
            return threadOperationalDatasetHexString
        }
        return ""
    }
    
    /// Show alert to user
    /// - Parameters:
    ///   - title: alert title
    ///   - message: alert message
    ///   - buttonTitle: button title
    ///   - callback: callback
    func alertUser(title: String, message: String, buttonTitle: String, callback: @escaping () -> Void) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: buttonTitle, style: .default, handler: {_ in
            callback()
        })
        alertController.addAction(dismissAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Navigate to status screen
    /// - Parameters:
    ///   - espDevice: espDevice
    ///   - ssid: ssid
    ///   - passphrase: passphrase
    ///   - threadOperationalDataset: thread operational dataser
    ///   - error: error
    func showStatusScreen(espDevice: ESPDevice, ssid: String = "", passphrase: String = "", threadOperationalDataset: Data? = nil, error: ESPSessionError? = nil) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
        }
        let statusVC = self.storyboard?.instantiateViewController(withIdentifier: "statusVC") as! StatusViewController
        statusVC.espDevice = espDevice
        guard let error = error else {
            DispatchQueue.main.async {
                statusVC.ssid = ssid
                statusVC.passphrase = passphrase
                statusVC.threadOpetationalDataset = threadOperationalDataset
                self.navigationController?.pushViewController(statusVC, animated: true)
            }
            return
        }
        DispatchQueue.main.async {
            statusVC.step1Failed = true
            statusVC.message = error.description
            self.navigationController?.pushViewController(statusVC, animated: true)
        }
    }
}
