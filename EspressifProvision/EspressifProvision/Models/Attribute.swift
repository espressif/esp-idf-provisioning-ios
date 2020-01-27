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

class StaticAttribute: Attribute, Equatable {
    static func == (lhs: StaticAttribute, rhs: StaticAttribute) -> Bool {
        let lhsValue = lhs.value as? String
        let rhsValue = rhs.value as? String
        return lhsValue == rhsValue
    }
}

class DynamicAttribute: Attribute, Equatable {
    static func == (lhs: DynamicAttribute, rhs: DynamicAttribute) -> Bool {
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
        return false
    }

    var uiType: String?
    var properties: [String]?
    var bounds: [String: Any]?
    var attributeKey: String?
    var dataType: String?
}
