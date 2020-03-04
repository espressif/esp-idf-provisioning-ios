//
//  UserInfo.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 04/02/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import Foundation

enum ServiceProvider: String {
    case other
    case cognito
}

struct UserInfo {
    // UserInfo keys
    static let usernameKey = "username"
    static let emailKey = "email"
    static let userIdKey = "userID"
    static let providerKey = "provider"

    var username: String
    var email: String
    var userID: String
    var loggedInWith: ServiceProvider

    /// Create UserInfo object derived from persistent storage
    ///
    /// - Returns:
    ///   - Userinfo object that contains information about the currently signed-in user
    static func getUserInfo() -> UserInfo {
        var userInfo = UserInfo(username: "", email: "", userID: "", loggedInWith: .cognito)
        if let json = UserDefaults.standard.value(forKey: Constants.userInfoKey) as? [String: Any] {
            userInfo.username = json[UserInfo.usernameKey] as? String ?? ""
            userInfo.email = json[UserInfo.emailKey] as? String ?? ""
            userInfo.userID = json[UserInfo.userIdKey] as? String ?? ""
            let loggedIn = json[UserInfo.providerKey] as? String ?? ServiceProvider.cognito.rawValue
            userInfo.loggedInWith = ServiceProvider(rawValue: loggedIn)!
        }
        return userInfo
    }

    /// Save Userinfo of currently signed-in user into persistent storage.
    /// This info is required when new app session is started.
    ///
    func saveUserInfo() {
        let json: [String: Any] = [UserInfo.usernameKey: self.username, UserInfo.emailKey: self.email, UserInfo.userIdKey: self.userID, UserInfo.providerKey: self.loggedInWith.rawValue]
        UserDefaults.standard.set(json, forKey: Constants.userInfoKey)
    }
}
