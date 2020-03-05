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
import Reachability
import UIKit

class Utility {
    static var deviceNamePrefix = UserDefaults.standard.value(forKey: Constants.prefixKey) as? String ?? (Bundle.main.infoDictionary?[Constants.deviceNamePrefix] as? String ?? Constants.devicePrefixDefault)
    static let allowPrefixFilter = Bundle.main.infoDictionary?[Constants.allowFilteringByPrefix] as? Bool ?? false
    static let baseUrl = Bundle.main.infoDictionary?[Constants.wifiBaseUrl] as? String ?? Constants.wifiBaseUrlDefault
    static let reachability = try! Reachability()

    var deviceName = ""
    var configPath: String = Constants.configPath
    var versionPath: String = Constants.versionPath
    var scanPath: String = Constants.scanPath
    var sessionPath: String = Constants.sessionPath
    var associationPath: String = Constants.associationPath
    var peripheralConfigured = false
    var sessionCharacteristic: CBCharacteristic!
    var configUUIDMap: [String: CBCharacteristic] = [:]
    var deviceVersionInfo: NSDictionary?
    var currentSSID = ""

    /// Method to process descriptor values read from BLE devices
    ///
    /// - Parameters:
    ///   - descriptor: Contains BLE charactersitic and path value supported by BLE device
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

    /// This method can be invoked from any ViewController and will present MBProgressHUD loader with the given message
    ///
    /// - Parameters:
    ///   - message: Text to be showed inside the loader
    ///   - view: View in which loader is added
    class func showLoader(message: String, view: UIView) {
        DispatchQueue.main.async {
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

    class func isConnected(view _: UIView) -> Bool {
        if let currentWindow = UIApplication.shared.keyWindow {
            for subView in currentWindow.subviews {
                if subView.isKind(of: NoInternetConnection.self) {
                    subView.removeFromSuperview()
                }
            }
            do {
                try reachability.startNotifier()
            } catch {
                return true
            }
            if reachability.connection == .unavailable {
                let noConnectionView = NoInternetConnection.instanceFromNib()
                noConnectionView.frame = UIScreen.main.bounds
                currentWindow.addSubview(noConnectionView)
                return false
            }
            return true
        }
        return false
    }
}
