//
//  Utility.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 03/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import CoreBluetooth
import Foundation
import MBProgressHUD
import UIKit

class Utility {
    static var deviceNamePrefix = UserDefaults.standard.value(forKey: Constants.prefixKey) as? String ?? (Bundle.main.infoDictionary?["BLEDeviceNamePrefix"] as? String ?? "PROV_")
    static let allowPrefixFilter = Bundle.main.infoDictionary?["AllowFilteringByPrefix"] as? Bool ?? false
    static let baseUrl = Bundle.main.infoDictionary?["WifiBaseUrl"] as? String ?? "192.168.4.1:80"

    var deviceName = "ESP Device"
    var configPath: String = "prov-config"
    var versionPath: String = "proto-ver"
    var scanPath: String = "prov-scan"
    var sessionPath: String = "prov-session"
    var associationPath: String = "cloud_user_assoc"
    var peripheralConfigured = false
    var sessionCharacteristic: CBCharacteristic!
    var configUUIDMap: [String: CBCharacteristic] = [:]
    var deviceVersionInfo: NSDictionary?

    func processDescriptor(descriptor: CBDescriptor) {
        if let value = descriptor.value as? String {
            if value.contains(Constants.scanCharacteristic) {
                scanPath = value
                configUUIDMap.updateValue(descriptor.characteristic, forKey: scanPath)
            } else if value.contains(Constants.sessionCharacterstic) {
                sessionPath = value
                peripheralConfigured = true
                sessionCharacteristic = descriptor.characteristic
                configUUIDMap.updateValue(descriptor.characteristic, forKey: sessionPath)
            } else if value.contains(Constants.configCharacterstic) {
                configPath = value
                configUUIDMap.updateValue(descriptor.characteristic, forKey: configPath)
            } else if value.contains(Constants.versionCharacterstic) {
                versionPath = value
                configUUIDMap.updateValue(descriptor.characteristic, forKey: versionPath)
            } else if value.contains(Constants.associationCharacterstic) {
                associationPath = value
                configUUIDMap.updateValue(descriptor.characteristic, forKey: associationPath)
            }
        }
    }

    class func showLoader(message: String, view: UIView) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.isUserInteractionEnabled = false
        }
    }

    class func hideLoader(view: UIView) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: view, animated: true)
        }
    }
}
