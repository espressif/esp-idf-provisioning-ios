//
//  FoundPeripheral.swift
//  ESPProvision
//
//  Created by Robert Hartman on 2/15/21.
//

import Foundation
import CoreBluetooth

struct FoundPeripheral {
    let cbPeripheral: CBPeripheral
    let advertisementData: [String: Any]
    let rssi: NSNumber
}
