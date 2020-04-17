//
//  Control.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

class Attribute: Equatable {
    var name: String?
    var value: Any?

    static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        let lhsValue = lhs.value as? String
        let rhsValue = rhs.value as? String
        return lhsValue == rhsValue && lhs.name == rhs.name
    }
}

class Param: Attribute {
    static func == (lhs: Param, rhs: Param) -> Bool {
        if lhs.name == rhs.name {
            if lhs.dataType == rhs.dataType {
                if lhs.dataType?.lowercased() == "int" {
                    let lhsValue = lhs.value as? Int
                    let rhsValue = rhs.value as? Int
                    return lhsValue == rhsValue
                } else if lhs.dataType?.lowercased() == "float" {
                    let lhsValue = lhs.value as? Float
                    let rhsValue = rhs.value as? Float
                    return lhsValue == rhsValue
                } else {
                    let lhsValue = lhs.value as? String
                    let rhsValue = rhs.value as? String
                    return lhsValue == rhsValue
                }
            }
        }
        return false
    }

    var uiType: String?
    var properties: [String]?
    var bounds: [String: Any]?
    var attributeKey: String?
    var dataType: String?
    var type: String?
}
