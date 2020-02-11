//
//  JSONParser.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 18/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

struct JSONParser {
    static func parseNodeData(data: [String: Any], nodeID: String) -> Node {
        var result: [Device] = []
        // Saving node related information
        let node = Node()
        node.node_id = nodeID
        if let nodeInfo = data["info"] as? [String: String] {
            node.info = Info(name: nodeInfo["name"], fw_version: nodeInfo["fw_version"], type: nodeInfo["type"])
        }
        node.config_version = data["config_version"] as? String
        node.primary = data["primary"] as? String
        if let attributeList = data["attributes"] as? [[String: Any]] {
            node.attributes = []
            for attributeItem in attributeList {
                let attribute = Attribute()
                attribute.name = attributeItem["name"] as? String
                attribute.value = attributeItem["value"] as? String
                node.attributes?.append(attribute)
            }
        }

        if let deviceList = data["devices"] as? [[String: Any]] {
            for item in deviceList {
                let newDevice = Device()
                newDevice.name = item["name"] as? String
                newDevice.type = item["type"] as? String
                newDevice.node = node
                if let dynamicParams = item["params"] as? [[String: Any]] {
                    newDevice.params = []
                    for attr in dynamicParams {
                        let dynamicAttr = Params()
                        if let attrName = attr["name"] as? String {
                            dynamicAttr.name = attrName
                        } else {
                            dynamicAttr.name = attr["name"] as? String
                        }
                        dynamicAttr.uiType = attr["ui-type"] as? String
                        dynamicAttr.dataType = attr["data_type"] as? String
                        dynamicAttr.properties = attr["properties"] as? [String]
                        dynamicAttr.bounds = attr["bounds"] as? [String: Any]
                        newDevice.params?.append(dynamicAttr)
                    }
                }
                if let staticParams = item["attributes"] as? [[String: Any]] {
                    newDevice.attributes = []
                    for attr in staticParams {
                        let staticAttr = Attribute()
                        staticAttr.name = attr["name"] as? String
                        staticAttr.value = attr["value"] as? String
                        newDevice.attributes?.append(staticAttr)
                    }
                }
                result.append(newDevice)
            }
        }
        node.devices = result
        return node
    }
}
