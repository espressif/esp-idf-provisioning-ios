//
//  Device.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 04/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

struct Node {
    var node_id: String?
    var config_version: String?
    var info: Info?
    var devices: [Device]?
    var attributes: [Attribute]?
}

struct Info {
    var name: String?
    var fw_version: String?
    var type: String?
}
