//
//  JSONParser.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 18/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

struct JSONParser {
    static func parseNodeData(data: Data) -> [Device] {
        var result: [Device] = []
        do {
            if let parseResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary, let devicesList = parseResult["devices"] as? [[String: Any]] {
                for item in devicesList {
                    var newDevice = Device()
                    newDevice.name = item["name"] as? String
                    newDevice.type = item["type"] as? String
                    if let dynamicParams = item["dynamic_params"] as? [[String: Any]] {
                        newDevice.dynamicParams = []
                        for attr in dynamicParams {
                            let dynamicAttr = DynamicAttribute()
                            dynamicAttr.name = attr["name"] as? String
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
        } catch {
            print("Parsing exception occured")
            return result
        }

        return result
    }
}
