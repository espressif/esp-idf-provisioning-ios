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
//  ProvisionLandingViewController.swift
//  EspressifProvision
//

import Foundation
import UIKit

class ProvisionLandingViewController: UIViewController {
    var provisionConfig: [String: String] = [:]
    @IBOutlet var provisionInstructions: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let wifiPrefix = provisionConfig[Provision.CONFIG_WIFI_AP_KEY]
        if let text = provisionInstructions.text, let wifiPrefix = wifiPrefix {
            let nonBoldRange = NSMakeRange(0, text.count)
            provisionInstructions.attributedText = attributedString(from: text + " \(wifiPrefix)",
                                                                    nonBoldRange: nonBoldRange)
        }
    }

    @IBAction func connectClicked(_: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                _ = UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if let vc = segue.destination as? ProvisionViewController {
            vc.provisionConfig = provisionConfig
        }
    }

    func attributedString(from string: String, nonBoldRange: NSRange?) -> NSAttributedString {
        let attrs = [
            kCTFontAttributeName: UIFont.boldSystemFont(ofSize: 20),
            kCTForegroundColorAttributeName: UIColor.black,
        ]
        let nonBoldAttribute = [
            kCTFontAttributeName: UIFont.systemFont(ofSize: 20),
        ]
        let attrStr = NSMutableAttributedString(string: string, attributes: attrs as [NSAttributedString.Key: Any])
        if let range = nonBoldRange {
            attrStr.setAttributes(nonBoldAttribute as [NSAttributedString.Key: Any], range: range)
        }
        return attrStr
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
