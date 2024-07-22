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
//  ThreadSuccessViewController+SetupNode.swift
//  ESPRainMaker
//

import UIKit
import ESPProvision

@available(iOS 16.4, *)
extension ThreadSuccessViewController {
    
    func step5SetupNode(nodeID: String) {
        DispatchQueue.main.async {
            self.step5Image.isHidden = true
            self.activityIndicator5.isHidden = false
            self.activityIndicator5.startAnimating()
            self.setupTimeout = Timer(timeInterval: 35.0, target: self, selector: #selector(self.setupTimeOut), userInfo: nil, repeats: false)
            self.getNodeDetails(nodeID: nodeID)
            self.getNodeStatus(nodeID: nodeID)
        }
    }

    @objc func getNodeStatus(nodeID: String) {
        let node = Node()
        node.node_id = nodeID
        NetworkManager.shared.getNodeStatus(node: node) { newNode, _ in
            if let responseNode = newNode {
                if responseNode.isConnected {
                    self.nodeIsConnected = true
                    self.check5thStepStatus()
                    return
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.getNodeStatus(nodeID: nodeID)
            }
        }
    }

    func getNodeDetails(nodeID: String) {
        NetworkManager.shared.getNodeInfo(nodeId: nodeID) { node, _ in
            DispatchQueue.main.async {
                self.nodeDetailsFetched = true
                if let newNode = node {
                    for service in newNode.services ?? [] {
                        if service.type?.lowercased() == Constants.timezoneServiceName {
                            if let param = service.params?.first(where: { $0.type?.lowercased() == Constants.timezoneServiceParam }) {
                                let timezone = param.value as? String
                                if timezone == nil || timezone!.isEmpty {
                                    DeviceControlHelper.shared.updateParam(nodeID: nodeID, parameter: [service.name ?? "Time": [param.name ?? "": TimeZone.current.identifier]], delegate: nil)
                                }
                            }
                        }
                    }
                }
                self.check5thStepStatus()
            }
        }
    }

    @objc func setupTimeOut() {
        DispatchQueue.main.async {
            self.step5Image.isHidden = false
            self.activityIndicator5.isHidden = true
            self.activityIndicator5.stopAnimating()
            if self.nodeDetailsFetched, self.nodeIsConnected {
                self.step5Image.image = UIImage(named: "checkbox_checked")
            } else {
                self.step5Image.image = UIImage(named: "warning_icon")
                self.step5Error.isHidden = false
                self.step5Error.text = "Failed to setup node."
            }
            self.provisionFinsihedWithStatus(message: "Device Added Successfully!!")
        }
    }

    func check5thStepStatus() {
        DispatchQueue.main.async {
            if self.nodeDetailsFetched, self.nodeIsConnected {
                self.step5Image.image = UIImage(named: "checkbox_checked")
                self.step5Image.isHidden = false
                self.activityIndicator5.isHidden = true
                self.activityIndicator5.stopAnimating()
                self.provisionFinsihedWithStatus(message: "Device Added Successfully!!")
            }
        }
    }
}
