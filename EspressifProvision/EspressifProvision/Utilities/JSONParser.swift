//
//  JSONParser.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 18/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

struct JSONParser {
    /// Returns array of objects of Node  type
    ///
    /// Method to fetch accessToken of the signed-in user.
    /// Applicable when user is logged in with cognito id.
    ///
    /// - Parameters:
    ///   - data: node information in the form of JSON.
    static func parseNodeArray(data: [[String: Any]]) -> [Node]? {
        var nodeList: [Node] = []
        for node_details in data {
            var result: [Device] = []
            // Saving node related information
            let node = Node()
            node.node_id = node_details["id"] as? String

            if let config = node_details["config"] as? [String: Any] {
                if let nodeInfo = config["info"] as? [String: String] {
                    node.info = Info(name: nodeInfo["name"], fw_version: nodeInfo["fw_version"], type: nodeInfo["type"])
                }
                node.config_version = config["config_version"] as? String
                if let attributeList = config["attributes"] as? [[String: Any]] {
                    node.attributes = []
                    for attributeItem in attributeList {
                        let attribute = Attribute()
                        attribute.name = attributeItem["name"] as? String
                        attribute.value = attributeItem["value"] as? String
                        node.attributes?.append(attribute)
                    }
                }

                if let devices = config["devices"] as? [[String: Any]] {
                    for item in devices {
                        let newDevice = Device()
                        newDevice.name = item["name"] as? String
                        newDevice.type = item["type"] as? String
                        newDevice.primary = item["primary"] as? String
                        newDevice.node = node
                        if let dynamicParams = item["params"] as? [[String: Any]] {
                            newDevice.params = []
                            for attr in dynamicParams {
                                let dynamicAttr = Param()
                                if let attrName = attr["name"] as? String {
                                    dynamicAttr.name = attrName
                                } else {
                                    dynamicAttr.name = attr["name"] as? String
                                }
                                dynamicAttr.uiType = attr["ui_type"] as? String
                                dynamicAttr.dataType = attr["data_type"] as? String
                                dynamicAttr.properties = attr["properties"] as? [String]
                                dynamicAttr.bounds = attr["bounds"] as? [String: Any]
                                dynamicAttr.type = attr["type"] as? String
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
            }

            if let statusInfo = node_details["status"] as? [String: Any], let connectivity = statusInfo["connectivity"] as? [String: Any], let status = connectivity["connected"] as? Bool {
                node.isConnected = status
                node.timestamp = connectivity["timestamp"] as? Int ?? 0
            }

            if let paramInfo = node_details["params"] as? [String: Any], let devices = node.devices {
                for device in devices {
                    if let deviceName = device.name, let attributes = paramInfo[deviceName] as? [String: Any] {
                        if let params = device.params {
                            for index in params.indices {
                                if let reportedValue = attributes[params[index].name ?? ""] {
                                    params[index].value = reportedValue
                                }
                            }
                        }
                    }
                }
            }
            if node.devices?.count == 1 {
                nodeList.insert(node, at: 0)
            } else {
                nodeList.append(node)
            }
        }
        if nodeList.isEmpty {
            return nil
        }
        return nodeList
    }
}
