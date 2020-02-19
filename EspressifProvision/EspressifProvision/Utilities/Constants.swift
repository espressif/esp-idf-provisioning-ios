//
//  Constants.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 06/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AWSCognitoIdentityProvider
import Foundation
import Keys

struct Constants {
    // API version for the current network request
    static let apiVersion = "v1"

    // User-Defined keys
    static let deviceNamePrefix = "DeviceNamePrefix"
    static let allowFilteringByPrefix = "AllowFilteringByPrefix"
    static let wifiBaseUrl = "WifiBaseUrl"

    // User-Defined Values
    static let devicePrefixDefault = "PROV_"
    static let wifiBaseUrlDefault = "192.168.4.1:80"

    // Device path parameters
    static let configPath = "prov-config"
    static let versionPath = "proto-ver"
    static let scanPath = "prov-scan"
    static let sessionPath = "prov-session"
    static let associationPath = "cloud_user_assoc"

    // Segue identifiers
    static let deviceTraitListVCIdentifier = "deviceTrailListVC"
    static let nodeDetailSegue = "nodeDetailSegue"
    static let claimVCIdentifier = "claimVC"

    // JSON keys
    static let userID = "user_id"
    static let requestID = "request_id"

    static let usernameKey = "espusername"
    static let scanCharacteristic = "scan"
    static let sessionCharacterstic = "session"
    static let configCharacterstic = "config"
    static let versionCharacterstic = "ver"
    static let associationCharacterstic = "assoc"
    static let deviceInfoStoryboardID = "versionInfo"

    // Device version info
    static let provKey = "prov"
    static let capabilitiesKey = "cap"
    static let wifiScanCapability = "wifi_scan"
    static let noProofCapability = "no_pop"

    // Amazon Cognito setup configuration
    static let CognitoIdentityUserPoolRegion: AWSRegionType = .USEast1

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
    static let baseURL = Bundle.main.infoDictionary!["BASE_API_URL_ENDPOINT"] as? String ?? ""
    static let githubURL = Bundle.main.infoDictionary!["GITHUB_URL"] as? String ?? ""
    static let redirectURL = Bundle.main.infoDictionary!["REDIRECT_URL"] as? String ?? ""
    static let clientID = Bundle.main.infoDictionary!["APP_CLIENT_ID"] as? String ?? ""
    static let idProvider = "Github"

    // AWS cognito APIs
    static let addDevice = Constants.baseURL + Constants.apiVersion + "/user/nodes/mapping"
    static let getUserId = Constants.baseURL + Constants.apiVersion + "/user"
    static let getNodes = Constants.baseURL + Constants.apiVersion + "/user/nodes"
    static let getNodeConfig = Constants.baseURL + Constants.apiVersion + "/user/nodes/config"
    static let getNodeStatus = Constants.baseURL + Constants.apiVersion + "/user/nodes/status"
//    static let addDeviceToUser = "https://wb9f74l5i7.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let checkStatus = Constants.baseURL + Constants.apiVersion + "/user/nodes/mapping"

    static let updateThingsShadow = Constants.baseURL + Constants.apiVersion + "/user/nodes/params"
    static let getDeviceShadow = Constants.baseURL + Constants.apiVersion + "/user/nodes/params"

    // UserDefault keys
    static let newDeviceAdded = "com.espressif.newDeviceAdded"
    static let prefixKey = "com.espressif.prefix"
    static let userInfoKey = "com.espressif.userinfo"
    static let idTokenKey = "com.espressif.idToken"
    static let refreshTokenKey = "com.espressif.refreshToken"
    static let accessTokenKey = "com.espressif.accessToken"
    static let expireTimeKey = "com.espressif.expiresIn"
    static let loginIdKey = "com.espressif.loginIdKey"
    static let appThemeKey = "com.espressif.appTheme"
    static let appBGKey = "com.espressif.appbg"

    static let cognito = "Cognito"
    static let github = "Github"

    // Theme Color
    static let backgroundColor = Bundle.main.infoDictionary!["APP_THEME_COLOR"] as? String

    static let tokenURL = "https://rainmaker-staging.auth.us-east-1.amazoncognito.com/oauth2/token"

    static let uiViewUpdateNotification = "com.espressif.updateuiview"

    static let boolTypeValidValues: [String: Bool] = ["true": true, "false": false, "yes": true, "no": false, "0": false, "1": true]

    static func log(message: String) {
        print(message)
    }
}

struct Keys {
    let clientID: String
    let clientSecret: String
    let poolID: String

    init(clientID: String, clientSecret: String, poolID: String) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.poolID = poolID
    }

    static var current: Keys {
        let keys = EspressifProvisionKeys()
        #if PROD
            return Keys(clientID: keys.userPoolAppClientId, clientSecret: keys.userPoolAppClientSecret, poolID: keys.userPoolId)
        #else
            return Keys(clientID: keys.staging_UserPoolAppClientId, clientSecret: keys.staging_UserPoolAppClientSecret, poolID: keys.staging_UserPoolId)
        #endif
    }
}
