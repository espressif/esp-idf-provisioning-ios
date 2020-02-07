//
//  UserInfo.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 04/02/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import Foundation

enum ServiceProvider: String {
    case github
    case cognito
}

struct UserInfo {
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
            userInfo.username = json["username"] as? String ?? ""
            userInfo.email = json["email"] as? String ?? ""
            userInfo.userID = json["userID"] as? String ?? ""
            let loggedIn = json["loggedInWith"] as? String ?? "cognito"
            userInfo.loggedInWith = ServiceProvider(rawValue: loggedIn)!
        }
        return userInfo
    }

    /// Save Userinfo of currently signed-in user into persistent storage.
    /// This info is required when new app session is started.
    ///
    func saveUserInfo() {
        let json: [String: Any] = ["username": self.username, "email": self.email, "userID": self.userID, "loggedInWith": self.loggedInWith.rawValue]
        UserDefaults.standard.set(json, forKey: Constants.userInfoKey)
    }
}
