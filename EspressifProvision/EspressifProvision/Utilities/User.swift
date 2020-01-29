//
//  User.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import AWSCognitoIdentityProvider
import Foundation
import JWTDecode

class User {
    static let shared = User()
    var userID: String?
    var pool: AWSCognitoIdentityUserPool!
    var idToken: String?
    var refreshToken: String?
    var associatedNodeList: [Node]?
    var username = ""
    var password = ""
    var automaticLogin = false
    var updateDeviceList = false
    var currentAssociationInfo: AssociationConfig?
    private init() {
        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: Constants.CognitoIdentityUserPoolRegion, credentialsProvider: nil)

        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: Constants.CognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: Constants.CognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: Constants.CognitoIdentityUserPoolId)

        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)

        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
//        associatedDevices = []
//        associatedDevices?.append(Device(name: "Test Device 1", device_id: "fafafe", type: nil))
//        associatedDevices?.append(Device(name: "Test Device 2", device_id: "fafafe", type: nil))
//        associatedDevices?.append(Device(name: "Test Device 3", device_id: "fafafe", type: nil))
    }

    func currentUser() -> AWSCognitoIdentityUser? {
        return pool.currentUser()
    }

    func associateNodeWithUser(session: Session, delegate: DeviceAssociationProtocol) {
        currentAssociationInfo = AssociationConfig()
        currentAssociationInfo?.uuid = UUID().uuidString
        let deviceAssociation = DeviceAssociation(session: session, secretId: currentAssociationInfo!.uuid)
        deviceAssociation.associateDeviceWithUser()
        deviceAssociation.delegate = delegate
    }

    func getAccessToken(completionHandler: @escaping (String?) -> Void) {
        if let loginWith = UserDefaults.standard.value(forKey: Constants.loginIdKey) as? String {
            if loginWith == Constants.cognito {
                if idToken == nil, let user = currentUser(), user.isSignedIn {
                    user.getSession().continueOnSuccessWith(block: { (task) -> Any? in
                        completionHandler(task.result?.idToken?.tokenString)
                    })
                } else {
                    completionHandler(idToken)
                }
            } else {
                let idTokenGithub = UserDefaults.standard.value(forKey: Constants.idTokenKey) as? String
                if let refreshTokenInfo = UserDefaults.standard.value(forKey: Constants.refreshTokenKey) as? [String: Any] {
                    let saveDate = refreshTokenInfo["time"] as! Date
                    let difference = Date().timeIntervalSince(saveDate)
                    let expire = refreshTokenInfo["expire_in"] as! Int
                    if Int(difference) > expire {
                        do {
                            let json = try decode(jwt: idTokenGithub!)
                            print(json)
                            if let username = json.body["cognito:username"] as? String {
                                let parameter = ["user_name": username, "refreshtoken": refreshTokenInfo["token"] as! String]
                                let header: HTTPHeaders = ["Content-Type": "application/json"]
                                let url = Constants.baseURL + "login"
                                NetworkManager.shared.genericRequest(url: url, method: .post, parameters: parameter, encoding: JSONEncoding.default, headers: header) { response in
                                    if let json = response {
                                        if let idToken = json["idtoken"] as? String {
                                            var refreshTokenUpdate = refreshTokenInfo
                                            refreshTokenUpdate["time"] = Date()
                                            UserDefaults.standard.setValue(refreshTokenUpdate, forKey: Constants.refreshTokenKey)
                                            User.shared.idToken = idToken
                                            completionHandler(idToken)
                                            return
                                        }
                                    }
                                    completionHandler(nil)
                                }
                            }

                        } catch {
                            print("unable to decode token")
                            completionHandler(nil)
                        }
                    } else {
                        completionHandler(idTokenGithub)
                    }
                }
            }
        } else {
            completionHandler(nil)
        }
    }
}
