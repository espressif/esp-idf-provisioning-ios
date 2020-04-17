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
    var userInfo = UserInfo.getUserInfo()
    var pool: AWSCognitoIdentityUserPool!
    var accessToken: String?
    var associatedNodeList: [Node]?
    var username = ""
    var password = ""
    var automaticLogin = false
    var updateDeviceList = false
    var currentAssociationInfo: AssociationConfig?
    var updateUserInfo = false

    private init() {
        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: Constants.CognitoIdentityUserPoolRegion, credentialsProvider: nil)

        let currentKeys = Keys.current

        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: currentKeys.clientID!,
                                                                        clientSecret: currentKeys.clientSecret,
                                                                        poolId: currentKeys.poolID!)

        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)

        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        accessToken = UserDefaults.standard.value(forKey: Constants.accessTokenKey) as? String
    }

    /// Get current signed-in user detail of cognito user
    ///
    func currentUser() -> AWSCognitoIdentityUser? {
        return pool.currentUser()
    }

    /// Method to configure and send association related information to the connected device
    ///
    /// - Parameters:
    ///   - session: Current established session with the device for sending information.
    ///   - delegate: Object that will recieve notification whether the info was delivered successfully
    func associateNodeWithUser(session: ESPSession, delegate: DeviceAssociationProtocol) {
        currentAssociationInfo = AssociationConfig()
        currentAssociationInfo?.uuid = UUID().uuidString
        let deviceAssociation = DeviceAssociation(session: session, secretId: currentAssociationInfo!.uuid)
        deviceAssociation.associateDeviceWithUser()
        deviceAssociation.delegate = delegate
    }

    /// Method to fetch accessToken of the signed-in user.
    /// Used for authenticating APIs calls made by the user.
    ///
    /// - Parameters:
    ///   - completionHandler: callback invoked with accessToken as parameter.
    func getAccessToken(completionHandler: @escaping (String?) -> Void) {
        if User.shared.userInfo.loggedInWith == .cognito {
            if let user = currentUser() {
                user.getSession().continueOnSuccessWith(block: { (task) -> Any? in
                    completionHandler(task.result?.accessToken?.tokenString)
                })
            } else {
                completionHandler(nil)
            }
        } else {
            if let refreshTokenInfo = UserDefaults.standard.value(forKey: Constants.refreshTokenKey) as? [String: Any] {
                let saveDate = refreshTokenInfo["time"] as! Date
                let difference = Date().timeIntervalSince(saveDate)
                let expire = refreshTokenInfo["expire_in"] as! Int
                if Int(difference) > expire {
                    let parameter = ["user_name": User.shared.userInfo.username, "refreshtoken": refreshTokenInfo["token"] as! String]
                    let header: HTTPHeaders = ["Content-Type": "application/json"]
                    let url = Constants.baseURL + Constants.apiVersion + "/login"
                    NetworkManager.shared.genericRequest(url: url, method: .post, parameters: parameter, encoding: JSONEncoding.default, headers: header) { response in
                        if let json = response {
                            if let accessToken = json["accesstoken"] as? String {
                                var refreshTokenUpdate = refreshTokenInfo
                                refreshTokenUpdate["time"] = Date()
                                UserDefaults.standard.setValue(refreshTokenUpdate, forKey: Constants.refreshTokenKey)
                                UserDefaults.standard.set(accessToken, forKey: Constants.accessTokenKey)
                                User.shared.accessToken = accessToken
                                completionHandler(accessToken)
                                return
                            }
                        }
                        completionHandler(nil)
                    }
                } else {
                    completionHandler(User.shared.accessToken)
                }
            }
        }
    }

    /// Method to fetch accessToken of the signed-in user.
    /// Applicable when user is logged in with cognito id.
    ///
    func getcognitoIdToken(completionHandler: @escaping (String?) -> Void) {
        if let user = currentUser() {
            user.getSession().continueOnSuccessWith(block: { (task) -> Any? in
                completionHandler(task.result?.idToken?.tokenString)
            })
        } else {
            completionHandler(nil)
        }
    }
}
