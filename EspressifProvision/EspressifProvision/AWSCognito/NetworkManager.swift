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
                    User.shared.username = "nirvaanrocks@gmail.com"
                    User.shared.idToken = idToken
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                    Alamofire.request(Constants.getUserId + Constants.CognitoIdentityUserPoolId + "?user_name=" + User.shared.username, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        if let json = response.result.value as? [String: String] {
                            print("JSON: \(json)")
                            if let userid = json["user_id"] {
                                User.shared.userID = userid
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

    func addDeviceToUser(parameter: [String: String]) {
        User.shared.getAccessToken(completionHandler: { idToken in
            if idToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                Alamofire.request(Constants.addDevice, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    debugPrint(response)
                }
            }
        })
    }

    func getDeviceList(completionHandler: @escaping ([Device]?, Error?) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        Alamofire.request(Constants.getDevices + Constants.CognitoIdentityUserPoolId + "?userid=" + userID!, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            var deviceList: [Device] = []
                            if let tempArray = response.result.value as? [[String: String]] {
                                for item in tempArray {
                                    let device = Device(name: item["name"], device_id: item["device_id"], type: nil)
                                    deviceList.append(device)
                                }
                            }
                            completionHandler(deviceList, nil)
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
}
