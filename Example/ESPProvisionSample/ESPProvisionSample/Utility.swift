// Copyright 2020 Espressif Systems
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
//  Constants.swift
//  ESPProvisionSample
//
import Foundation
import MBProgressHUD
import ESPProvision
import UIKit

enum DeviceType: Int, CaseIterable {
    case both = 0
    case ble
    case softAp
    
    var value: String {
        switch self {
        case .both:
            return "Both"
        case .ble:
            return "BLE"
        case .softAp:
            return "SoftAP"
        }
    }
    
}

class Utility {
    
    /// Member to access singleton object of class.
    static let shared = Utility()
    
    var deviceNamePrefix = UserDefaults.standard.value(forKey: "com.espressif.prefix") as? String ?? (Bundle.main.infoDictionary?["BLEDeviceNamePrefix"] as? String ?? "PROV_")
    var espAppSettings:ESPAppSettings
    
    
    init() {
        espAppSettings = ESPAppSettings(appAllowsQrCodeScan: true, appSettingsEnabled: true, deviceType: .both, securityMode: .secure2, allowPrefixSearch: true)
        if let json = UserDefaults.standard.value(forKey: "com.espressif.example") as? [String: Any] {
            espAppSettings.allowPrefixSearch = json["allowPrefixSearch"] as? Bool ?? true
            espAppSettings.appAllowsQrCodeScan = json["allowQrCodeScan"] as? Bool ?? true
            espAppSettings.appSettingsEnabled = json["appSettingsEnabled"] as? Bool ?? true
            espAppSettings.username = json["username"] as? String ?? ""
            espAppSettings.deviceType = DeviceType(rawValue: json["deviceType"] as? Int ?? 0) ?? .both
            espAppSettings.securityMode = ESPSecurity(rawValue: json["securityMode"] as? Int ?? 2)
        } else {
            if let settingInfo  = Bundle.main.infoDictionary?["ESP Application Setting"] as? [String:String] {
                if let allowPrefix = settingInfo["ESP Allow Prefix Search"] {
                    espAppSettings.allowPrefixSearch = allowPrefix.lowercased() == "no" ? false:true
                }
                if let appAllowsQrCodeScan = settingInfo["ESP Allow QR Code Scan"] {
                    espAppSettings.appAllowsQrCodeScan = appAllowsQrCodeScan.lowercased() == "no" ? false:true
                }
                if let appSettingsEnabled = settingInfo["ESP Enable Setting"] {
                    espAppSettings.appSettingsEnabled = appSettingsEnabled.lowercased() == "no" ? false:true
                }
                if let securityMode = settingInfo["ESP Securtiy Mode"] {
                    switch securityMode.lowercased() {
                    case "unsecure": espAppSettings.securityMode = .unsecure
                    default: espAppSettings.securityMode = .secure2
                    }
                }
                if let deviceType = settingInfo["ESP Device Type"] {
                    if deviceType.lowercased() == "softap" {
                        espAppSettings.deviceType = .softAp
                    } else if deviceType.lowercased() == "ble" {
                        espAppSettings.deviceType = .ble
                    } else {
                        espAppSettings.deviceType = .both
                    }
                }
                if let username = settingInfo["ESP Device Username"] {
                    espAppSettings.username = username
                }
            }
        }
    }
    
    func saveAppSettings() {
        let json:[String: Any] = ["allowQrCodeScan":espAppSettings.appAllowsQrCodeScan,"appSettingsEnabled":espAppSettings.appSettingsEnabled,"deviceType":espAppSettings.deviceType.rawValue,"allowPrefixSearch":espAppSettings.allowPrefixSearch,"securityMode":espAppSettings.securityMode.rawValue,"username":espAppSettings.username]
        UserDefaults.standard.set(json, forKey: "com.espressif.example")
    }
    
    /// This method can be invoked from any ViewController and will present MBProgressHUD loader with the given message
    ///
    /// - Parameters:
    ///   - message: Text to be showed inside the loader
    ///   - view: View in which loader is added
    class func showLoader(message: String, view: UIView) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: view, animated: true)
            let loader = MBProgressHUD.showAdded(to: view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.isUserInteractionEnabled = false
        }
    }

    /// This method hide the MBProgressHUD loader and can be invoked from any ViewController
    ///
    class func hideLoader(view: UIView) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: view, animated: true)
        }
    }
    
    class func showAlertWith(message: String = "", viewController: UIViewController) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UITextField {
    func togglePasswordVisibility() {
        isSecureTextEntry = !isSecureTextEntry

        if let existingText = text, isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             continues typing unless we intervene. This is prevented by first
             deleting the existing text and then recovering the original text. */
            deleteBackward()

            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        /* Reset the selected text range since the cursor can end up in the wrong
         position after a toggle because the text might vary in width */
        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }
}
