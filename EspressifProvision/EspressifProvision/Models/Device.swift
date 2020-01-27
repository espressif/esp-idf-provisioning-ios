//
//  Device.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

import Foundation

struct Device: Equatable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.staticParams == rhs.staticParams && lhs.dynamicParams == rhs.dynamicParams
    }

    var name: String?
    var type: String?
    var node_id: String?
    var staticParams: [StaticAttribute]?
    var dynamicParams: [DynamicAttribute]?
}
