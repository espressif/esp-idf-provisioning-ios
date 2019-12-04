//
//  Control.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

class Attribute {
    var name: String?
    var value: Any?
}

class StaticAttribute: Attribute {}

class DynamicAttribute: Attribute {
    var uiType: String?
    var properties: [String]?
    var bounds: [String: Any]?
    var attributeKey: String?
    var dataType: String?
}
