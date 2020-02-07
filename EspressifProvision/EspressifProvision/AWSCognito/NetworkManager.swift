//
//  APIClient.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 01/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import Foundation
import JWTDecode

class NetworkManager {
    /// A singleton class that manages Network call for this application
    static let shared = NetworkManager()

    private init() {}

    // MARK: - Node APIs

    /// Get list of nodes associated with the user
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node list is recieved
    func getNodeList(completionHandler: @escaping ([Node]?, Error?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                let url = Constants.getNodes
                Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    print(response)
                    // Parse response value to get list of nodes
                    if let json = response.result.value as? [String: Any], let tempArray = json["nodes"] as? [String] {
                        var nodeList: [Node] = []
                        // Start a service group to schedule fetching of node related information
                        // Configuration and status information for each node will be fetched on background thread
                        let serviceGroup = DispatchGroup()

                        for item in tempArray {
                            serviceGroup.enter()
                            // Fetch node config
                            self.getNodeConfig(nodeID: item, headers: headers, completionHandler: { node, _ in
                                if let newNode = node {
                                    // Insert node with only one device in the first index of the array to allow ease in rendering
                                    if newNode.devices?.count == 1 {
                                        nodeList.insert(newNode, at: 0)
                                    } else {
                                        nodeList.append(newNode)
                                    }

                                    // Get device thing shadow
                                    self.getDeviceThingShadow(nodeID: item) { response in
                                        if let image = response, let devices = node?.devices {
                                            print(image)
                                            for device in devices {
                                                // Parse and fill device params and attributes
                                                if let deviceName = device.name, let attrbutes = image[deviceName] as? [String: Any] {
                                                    if let params = device.params {
                                                        for index in params.indices {
                                                            if let reportedValue = attrbutes[params[index].name ?? ""] {
                                                                params[index].value = reportedValue
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        // Node related information is recieved so leave service group
                                        serviceGroup.leave()
                                    }
                                }
                            })
                        }
                        // When node list is exhausted then call completionHandler with node list as parameter
                        serviceGroup.notify(queue: .main) {
                            completionHandler(nodeList, nil)
                        }
                    } else {
                        completionHandler(nil, CustomError.emptyNodeList)
                    }
                }
            } else {
                completionHandler(nil, NetworkError.emptyToken)
            }
        })
    }

    /// Get node config json
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node config is recieved
    func getNodeConfig(nodeID: String, headers: HTTPHeaders, completionHandler: @escaping (Node?, Error?) -> Void) {
        let url = Constants.getNodeConfig + "?nodeid=" + nodeID
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            if let json = response.result.value as? [String: Any] {
                self.getNodeStatus(node: JSONParser.parseNodeData(data: json, nodeID: nodeID), completionHandler: completionHandler)
            } else {
                completionHandler(nil, CustomError.emptyConfigData)
            }
        }
    }

    /// Method to fetch online/offline status of associated nodes
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node status is recieved
    func getNodeStatus(node: Node, completionHandler: @escaping (Node?, Error?) -> Void) {
        User.shared.getAccessToken { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                let url = Constants.getNodeStatus + "?nodeid=" + (node.node_id ?? "")
                Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    print(response)
                    // Parse the connected status of the node
                    if let json = response.result.value as? [String: Any] {
                        if let status = json["connected"] as? Bool {
                            let newNode = node
                            newNode.isConnected = status
                            completionHandler(newNode, nil)
                            return
                        }
                    }
                    completionHandler(node, nil)
                }
            } else {
                completionHandler(node, nil)
            }
        }
    }

    // MARK: - Device Association

    /// Method to send request of adding device to currently active user
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to add device to user is recieved with id of the request
    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, Error?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                Alamofire.request(Constants.addDevice, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in

                    // Check for any error on response
                    if let error = response.result.error {
                        print("Add device error \(error)")
                        completionHandler(nil, error)
                        return
                    }
                    print("Add device successfull)")
                    // Get request id for add device request
                    // This request id will be used for getting the status of add request
                    if let json = response.result.value as? [String: String] {
                        print("JSON: \(json)")
                        if let requestId = json[Constants.requestID] {
                            completionHandler(requestId, nil)
                            return
                        }
                    }
                    completionHandler(nil, CustomError.emptyConfigData)
                }
            } else {
                completionHandler(nil, NetworkError.emptyToken)
            }
        })
    }

    /// Method to fetch device assoication staus
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which association status is fetched
    ///   - completionHandler: handler called when response to deviceAssociationStatus is recieved
    func deviceAssociationStatus(nodeID: String, requestID: String, completionHandler: @escaping (Bool) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let url = Constants.checkStatus + "?node_id=" + nodeID
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                Alamofire.request(url + "&request_id=" + requestID + "&user_request=true", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if let json = response.result.value as? [String: String], let status = json["request_status"] as? String {
                        print(json)
                        if status == "confirmed" {
                            completionHandler(true)
                            return
                        }
                    }
                    completionHandler(false)
                }
            } else {
                completionHandler(false)
            }
        })
    }

    // MARK: - Thing Shadow

    /// Method to update device thing shadow
    /// Any changes of the device params from the app trigger this method
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is updated
    ///   - completionHandler: handler called when response to updateThingShadow is recieved
    func updateThingShadow(nodeID: String?, parameter: [String: Any]) {
        if let nodeid = nodeID {
            User.shared.getAccessToken(completionHandler: { idToken in
                if idToken != nil {
                    let url = Constants.updateThingsShadow + "?nodeid=" + nodeid
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                    Alamofire.request(url, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        print(parameter)
                        print(response.result.value)
                    }
                } else {}
            })
        }
    }

    /// Method to get device thing shadow
    /// Gives the current status of the device params for a node
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is requested
    ///   - completionHandler: handler called when response to getDeviceThingShadow is recieved
    func getDeviceThingShadow(nodeID: String, completionHandler: @escaping ([String: Any]?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let url = Constants.getDeviceShadow + "?nodeid=" + nodeID
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if let json = response.result.value as? [String: Any] {
                        completionHandler(json)
                        return
                    }
                    print(response.result.value)
                    completionHandler(nil)
                }
            } else {
                completionHandler(nil)
            }
        })
    }

    // MARK: - Generic Request

    /// Method to make generic api request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - method: HTTPMethod like post, get, etc.
    ///   - parameters: Parameter to be included in the api call
    ///   - encoding: ParameterEncoding
    ///   - header: HTTp headers
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters, encoding: ParameterEncoding, headers: HTTPHeaders, completionHandler: @escaping ([String: Any]?) -> Void) {
        Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseJSON { response in
            if let json = response.result.value as? [String: Any] {
                completionHandler(json)
                return
            }
            completionHandler(nil)
        }
    }
}
