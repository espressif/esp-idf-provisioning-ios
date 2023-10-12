// Copyright 2023 Espressif Systems
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
//  ViewController.swift
//  ESPProvisionSPMSample
//

import UIKit
class ViewController: UIViewController {

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    @IBOutlet weak var centerImage: UIImageView!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        appVersionLabel.text = "App Version - v" + appVersion + " (\(espGitVersion))"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Utility.shared.espAppSettings.appSettingsEnabled {
            settingsButton.isHidden = false
        } else {
            settingsButton.isHidden = true
        }
        switch Utility.shared.espAppSettings.deviceType {
        case .both:
            centerImage.image = UIImage(named: "main_logo")
        case .ble:
            centerImage.image = UIImage(named: "ble_main_logo")
        case .softAp:
            centerImage.image = UIImage(named: "softap_main_logo")
        }
    
    }
    
    @IBAction func addNewDevice(_ sender: Any) {
        if Utility.shared.espAppSettings.appAllowsQrCodeScan {
            let scannerVC = self.storyboard?.instantiateViewController(withIdentifier: "scannerVC") as! ScannerViewController
            navigationController?.pushViewController(scannerVC, animated: false)
        } else {
            switch Utility.shared.espAppSettings.deviceType {
            case .both:
                let deviceTypeVC = self.storyboard?.instantiateViewController(withIdentifier: "deviceTypeVC") as! DeviceTypeViewController
                navigationController?.pushViewController(deviceTypeVC, animated: false)
            case .ble:
                let bleLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
                navigationController?.pushViewController(bleLandingVC, animated: false)
            case .softAp:
                let softAPLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "softAPLandingVC") as! SoftAPLandingViewController
                navigationController?.pushViewController(softAPLandingVC, animated: false)
            }
        }
    }
}

