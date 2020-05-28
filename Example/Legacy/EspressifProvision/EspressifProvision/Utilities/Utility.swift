//
//  Utility.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 03/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import CoreBluetooth
import Foundation

class Utility {
    static var deviceNamePrefix = UserDefaults.standard.value(forKey: Constants.prefixKey) as? String ?? (Bundle.main.infoDictionary?["BLEDeviceNamePrefix"] as? String ?? "PROV_")
    static let allowPrefixFilter = Bundle.main.infoDictionary?["AllowFilteringByPrefix"] as? Bool ?? false
    static let baseUrl = Bundle.main.infoDictionary?["WifiBaseUrl"] as? String ?? "192.168.4.1:80"

    var deviceName = ""
    var configPath = "prov-config"
    var versionPath = "proto-ver"
    var scanPath: String?
    var sessionPath = "prov-session"
    var peripheralConfigured = false
    var sessionCharacteristic: CBCharacteristic!
    var configUUIDMap: [String: CBUUID] = [:]
    var deviceVersionInfo: NSDictionary?

    init() {
        configUUIDMap[configPath] = CBUUID(string: "ff52")
        configUUIDMap[sessionPath] = CBUUID(string: "ff51")
    }

    func processDescriptor(descriptor: CBDescriptor) {
        if let value = descriptor.value as? String {
            if value.contains(Constants.scanCharacteristic) {
                scanPath = value
                configUUIDMap.updateValue(descriptor.characteristic.uuid, forKey: scanPath!)
            } else if value.contains(Constants.sessionCharacterstic) {
                sessionPath = value
                peripheralConfigured = true
                sessionCharacteristic = descriptor.characteristic
                configUUIDMap.updateValue(descriptor.characteristic.uuid, forKey: sessionPath)
            } else if value.contains(Constants.configCharacterstic) {
                configPath = value
                configUUIDMap.updateValue(descriptor.characteristic.uuid, forKey: configPath)
            } else if value.contains(Constants.versionCharacterstic) {
                versionPath = value
                configUUIDMap.updateValue(descriptor.characteristic.uuid, forKey: versionPath)
            }
        }
    }
}
