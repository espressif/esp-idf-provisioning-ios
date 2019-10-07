//
//  APIClient.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 01/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import Foundation

class NetworkManager {
    static let shared = NetworkManager()

    private init() {}

    func getUserId(completionHandler: @escaping (String?, Error?) -> Void) {
        if let userID = User.shared.userID {
            completionHandler(userID, nil)
        } else {
            User.shared.getAccessToken(completionHandler: { idToken in
                if idToken != nil {
                    User.shared.idToken = idToken
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                    Alamofire.request(Constants.getUserId + Constants.CognitoIdentityUserPoolId + "?user_name=" + User.shared.username, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        if let json = response.result.value as? [String: String] {
                            print("JSON: \(json)")
                            if let userid = json["user_id"] {
                                User.shared.userID = userid
                                UserDefaults.standard.set(userid, forKey: Constants.userIDKey)
                                completionHandler(userid, nil)
                                return
                            }
                        }
                        completionHandler(nil, CustomError.emptyResultCount)
                    }
                } else {
                    completionHandler(nil, CustomError.emptyToken)
                }
            })
        }
    }

    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, Error?) -> Void) {
        User.shared.getAccessToken(completionHandler: { idToken in
            if idToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                Alamofire.request(Constants.addDevice + Constants.CognitoIdentityUserPoolId, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if let error = response.result.error {
                        completionHandler(nil, error)
                        return
                    }
                    if let json = response.result.value as? [String: String] {
                        print("JSON: \(json)")
                        if let requestId = json["request_id"] {
                            completionHandler(requestId, nil)
                            return
                        }
                    }
                    completionHandler(nil, CustomError.emptyResultCount)
                }
            } else {
                completionHandler(nil, CustomError.emptyResultCount)
            }
        })
    }

    func getDeviceList(completionHandler: @escaping ([Device]?, Error?) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        let url = Constants.getNodes + Constants.CognitoIdentityUserPoolId + "?userid=" + userID!
//                        let mockURL = "https://7k721rna08.execute-api.us-east-1.amazonaws.com/mock/nodes"
                        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            var nodeList: [Node] = []
                            print(response)
                            if let json = response.result.value as? [String: Any], let tempArray = json["nodes"] as? [String] {
                                var deviceList: [Device] = []
                                let serviceGroup = DispatchGroup()
                                for item in tempArray {
                                    var node = Node()
                                    node.node_id = item
                                    serviceGroup.enter()
                                    self.getNodeConfig(nodeID: item, headers: headers, completionHandler: { device, _ in
                                        if let devices = device {
                                            deviceList.append(contentsOf: devices)
                                        }
                                        serviceGroup.leave()
                                    })
                                }
                                serviceGroup.notify(queue: .main) {
                                    completionHandler(deviceList, nil)
                                }
                            } else {
                                completionHandler(nil, nil)
                            }
                        }
                    } else {
                        completionHandler(nil, CustomError.emptyToken)
                    }
                })
            } else {
                completionHandler(nil, CustomError.emptyToken)
            }
        }
    }

    func getNodeConfig(nodeID: String, headers: HTTPHeaders, completionHandler: @escaping ([Device]?, Error?) -> Void) {
        let url = Constants.getNodeConfig + Constants.CognitoIdentityUserPoolId + "?nodeid=" + nodeID
//        let mockURL = "https://7k721rna08.execute-api.us-east-1.amazonaws.com/mock/nodes/config"
//        if let path = Bundle.main.path(forResource: "DeviceDetails", ofType: "json") {
//            do {
//                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
//                if let jsonResult = jsonResult as? [String: Any] {
//                    // do stuff
//                    completionHandler(JSONParser.parseNodeData(data: jsonResult, nodeID: nodeID), nil)
//                }
//            } catch {
//                // handle error
//            }
//        }
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            if let json = response.result.value as? [String: Any] {
                completionHandler(JSONParser.parseNodeData(data: json, nodeID: nodeID), nil)
            } else {
                completionHandler(nil, nil)
            }
        }
    }

    func deviceAssociationStatus(deviceID: String, requestID: String, completionHandler: @escaping (Bool) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let url = Constants.checkStatus + Constants.CognitoIdentityUserPoolId + "?userid=" + userID! + "&node_id=" + deviceID
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
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
            } else {
                completionHandler(false)
            }
        }
    }

    func updateThingShadow(nodeID: String, parameter: [String: Any]) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let url = Constants.updateThingsShadow + Constants.CognitoIdentityUserPoolId + "?nodeid=" + nodeID
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        Alamofire.request(url, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            print(parameter)
                            print(response.result.value)
                        }
                    } else {}
                })
            }
        }
    }

    func getDeviceThingShadow(nodeID: String, completionHandler: @escaping ([String: Any]?) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let url = Constants.getDeviceShadow + Constants.CognitoIdentityUserPoolId + "?nodeid=" + nodeID
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            if let json = response.result.value as? [String: Any] {
                                completionHandler(json)
                            }
                            print(response.result.value)
                            completionHandler(nil)
                        }
                    } else {
                        completionHandler(nil)
                    }
                })
            } else {
                completionHandler(nil)
            }
        }
    }
}
