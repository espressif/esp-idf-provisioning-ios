//
//  JSONParser.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 18/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

struct JSONParser {
    static func parseNodeData(data: [String: Any], nodeID: String) -> [Device] {
        var result: [Device] = []
        if let deviceList = data["devices"] as? [[String: Any]] {
            for item in deviceList {
                var newDevice = Device()
                newDevice.name = item["name"] as? String
                newDevice.type = item["type"] as? String
                newDevice.node_id = nodeID
                if let dynamicParams = item["dynamic_params"] as? [[String: Any]] {
                    newDevice.dynamicParams = []
                    for attr in dynamicParams {
                        let dynamicAttr = DynamicAttribute()
                        if let deviceName = newDevice.name, let attrName = attr["name"] as? String {
                            dynamicAttr.name = deviceName + "." + attrName
                        } else {
                            dynamicAttr.name = attr["name"] as? String
                        }
                        dynamicAttr.uiType = attr["ui-type"] as? String
                        dynamicAttr.dataType = attr["data_type"] as? String
                        dynamicAttr.permission = attr["permissions"] as? [String]
                        dynamicAttr.bounds = attr["bounds"] as? [String: Any]
                        newDevice.dynamicParams?.append(dynamicAttr)
                    }
                }
                if let staticParams = item["static_params"] as? [[String: Any]] {
                    newDevice.staticParams = []
                    for attr in staticParams {
                        let staticAttr = StaticAttribute()
                        staticAttr.name = attr["name"] as? String
                        staticAttr.dataType = attr["data-type"] as? String
                        staticAttr.value = attr["value"] as? String
                        newDevice.staticParams?.append(staticAttr)
                    }
                }
                result.append(newDevice)
            }
        }

        return result
    }
}
