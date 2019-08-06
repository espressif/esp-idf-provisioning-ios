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
    var session: Session!
    let uuid = UUID().uuidString

    @IBOutlet var successLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let statusText = statusText {
            successLabel.text = statusText
        }
        let deviceAssociation = DeviceAssociation(session: session, secretId: uuid)
        deviceAssociation.associateDeviceWithUser()
        deviceAssociation.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
}

extension SuccessViewController: DeviceAssociationProtocol {
    func deviceAssociationFinishedWith(success: Bool, deviceID: String?) {
        if success {
            if let deviceSecret = deviceID {
                let parameters = ["user_id": User.shared.userID, "device_id": deviceSecret, "secret_key": uuid, "operation": "add"]
                NetworkManager.shared.addDeviceToUser(parameter: parameters as! [String: String])
            }
        }
    }
}
