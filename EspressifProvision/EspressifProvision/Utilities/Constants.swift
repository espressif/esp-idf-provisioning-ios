//
//  Constants.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import MBProgressHUD
import UIKit

struct Constants {
    static let scanCharacteristic = "scan"
    static let sessionCharacterstic = "session"
    static let configCharacterstic = "config"
    static let versionCharacterstic = "ver"
    static let avsConfigCharacterstic = "avsconfig"
    static let deviceInfoStoryboardID = "versionInfo"

    // Device version info
    static let provKey = "prov"
    static let capabilitiesKey = "cap"
    static let wifiScanCapability = "wifi_scan"
    static let noProofCapability = "no_pop"

    static let friendlynameKey = "friendlyname"
    static let versionKey = "version"
    static let UUIDKey = "uuid"

    // Reuse identifier
    static let deviceListCellReuseIdentifier = "deviceListCell"
    static let deviceDetailVCIndentifier = "deviceDetailVC"
    static let deviceSettingVCIndentifier = "deviceSettingVC"
    static let soundSettingVCIdentifier = "soundSettingVC"
    static let aboutVCIdentifier = "aboutVC"
    static let languageListVCIdentifier = "languageListVC"

    // Method to show loader on any view
    static func showLoader(message: String, view: UIView, disableUserInteraction: Bool = false) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.isUserInteractionEnabled = disableUserInteraction
        }
    }

    // Method to hide loader from any view
    static func hideLoader(view: UIView) {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: view, animated: true)
        }
    }
}
