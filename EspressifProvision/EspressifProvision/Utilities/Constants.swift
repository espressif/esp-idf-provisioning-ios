//
//  Constants.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 06/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AWSCognitoIdentityProvider
import Foundation

struct Constants {
    // Segue identifiers
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
    static let CognitoIdentityUserPoolId = Bundle.main.infoDictionary!["USER_POOL_ID"] as? String ?? ""
    static let CognitoIdentityUserPoolAppClientId = Bundle.main.infoDictionary!["APP_CLIENT_ID"] as? String ?? ""
    static let CognitoIdentityUserPoolAppClientSecret = Bundle.main.infoDictionary!["APP_CLIENT_SECRET"] as? String ?? ""

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"
    static let baseURL = Bundle.main.infoDictionary!["BASE_API_URL_ENDPOINT"] as? String ?? ""
    static let githubURL = Bundle.main.infoDictionary!["GITHUB_URL"] as? String ?? ""
    static let redirectURL = Bundle.main.infoDictionary!["REDIRECT_URL"] as? String ?? ""
    static let clientID = Bundle.main.infoDictionary!["APP_CLIENT_ID"] as? String ?? ""
    static let idProvider = "Github"

    // AWS cognito APIs
    static let addDevice = Constants.baseURL + "user/nodes/mapping"
    static let getUserId = Constants.baseURL + "user"
    static let getNodes = Constants.baseURL + "user/nodes"
    static let getNodeConfig = Constants.baseURL + "user/nodes/config"
    static let getNodeStatus = Constants.baseURL + "user/nodes/status"
//    static let addDeviceToUser = "https://wb9f74l5i7.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let checkStatus = Constants.baseURL + "user/nodes/mapping"

    static let updateThingsShadow = Constants.baseURL + "user/nodes/params"
    static let getDeviceShadow = Constants.baseURL + "user/nodes/params"

    static let newDeviceAdded = "com.espressif.newDeviceAdded"
    static let prefixKey = "com.espressif.prefix"
    static let userIDKey = "com.espressif.userid"
    static let idTokenKey = "com.espressif.idToken"
    static let refreshTokenKey = "com.espressif.refreshToken"
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

    static func log(message: String) {
        print(message)
    }
}
