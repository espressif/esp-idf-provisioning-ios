//
//  AlexaDevice.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 27/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

class AlexaDevice: NSObject {
    var modelNumber: String?
    var hostAddress: String?
    var status: String?
    var softwareVersion: String?
    var friendlyname: String?
    var uuid: String?
    var deviceName: String?
    var connectedWifi: String?
    var fwVersion: String?
    var mac: String?
    var serialNumber: String?
    var startToneEnabled: Bool?
    var endToneEnabled: Bool?
    var volume: UInt32?
    var language: Avs_Locale?

    init(hostAddr: String) {
        hostAddress = hostAddr
    }
}
