//
//  Device.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

import Foundation

class Device: Equatable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.attributes == rhs.attributes && lhs.params == rhs.params && lhs.name == rhs.name
    }

    var name: String?
    var type: String?
    var attributes: [Attribute]?
    var params: [Param]?
    weak var node: Node?
    var primary: String?

    func getDeviceName() -> String? {
        if let deviceNameParam = self.params?.first(where: { param -> Bool in
            param.type == Constants.deviceNameParam
        }) {
            if let name = deviceNameParam.value as? String {
                return name
            }
        }
        return name
    }
}
