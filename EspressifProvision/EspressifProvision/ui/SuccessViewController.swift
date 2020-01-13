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
    var deviceID: String?
    var requestID: String?
    var success = false
    var sessionInit = true

//    @IBOutlet var successLabel: UILabel!
    @IBOutlet var popCheckImage: UIImageView!
    @IBOutlet var wifiCheckImage: UIImageView!
    @IBOutlet var assocPushedCheckImage: UIImageView!
    @IBOutlet var deviceAssocCheckImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
//        if let statusText = statusText {
//            successLabel.text = statusText
//        }
        if sessionInit {
            popCheckImage.image = UIImage(named: "checkbox_checked")
        } else {
            popCheckImage.image = UIImage(named: "checkbox_unchecked")
        }
        if success {
            wifiCheckImage.image = UIImage(named: "checkbox_checked")
        } else {
            wifiCheckImage.image = UIImage(named: "checkbox_unchecked")
        }
        assocPushedCheckImage.image = UIImage(named: "checkbox_unchecked")
        if let associatioInfo = User.shared.currentAssociationInfo {
            if associatioInfo.associationInfoDelievered {
                assocPushedCheckImage.image = UIImage(named: "checkbox_checked")
            }
        }
        if success, let associatioInfo = User.shared.currentAssociationInfo, associatioInfo.associationInfoDelievered {
            // DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            User.shared.sendRequestToAddDevice(count: 7)
            // }
        } else {
            User.shared.currentAssociationInfo = AssociationConfig()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    @IBAction func goToFirstView(_: Any) {
        let destinationVC = navigationController?.viewControllers.first as! DevicesViewController
        destinationVC.checkDeviceAssociation = true
        destinationVC.deviceID = deviceID
        destinationVC.requestID = requestID
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)

//        if segue.identifier == "goToFirstScreen" {
//            if let destinationVC = segue.destination as? ViewController {
//                destinationVC.checkDeviceAssociation = true
//                destinationVC.deviceID = deviceID
//                destinationVC.requestID = requestID
//            }
//        }
    }
}
