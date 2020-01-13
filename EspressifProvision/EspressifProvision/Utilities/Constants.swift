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
    static let githubURL = "https://rainmaker-staging.auth.us-east-1.amazoncognito.com/oauth2/authorize"
    static let redirectURL = "com.espressif.rainmaker.intsoftap://success"
    static let clientID = "78suluee2rmlltshrt2v4lvuo0"
    static let idProvider = "Github"

    // AWS cognito APIs
    static let addDevice = Constants.baseURL + "user/nodes/mapping"
    static let getUserId = Constants.baseURL + "user"
    static let getNodes = Constants.baseURL + "user/nodes/mapping"
    static let getNodeConfig = Constants.baseURL + "user/nodes/config"
//    static let addDeviceToUser = "https://wb9f74l5i7.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let checkStatus = Constants.baseURL + "user/nodes/mapping"

    static let updateThingsShadow = Constants.baseURL + "user/nodes/dynamic_params"
    static let getDeviceShadow = Constants.baseURL + "user/nodes/dynamic_params"

    static let newDeviceAdded = "com.espressif.newDeviceAdded"
    static let prefixKey = "com.espressif.prefix"
    static let userIDKey = "com.espressif.userid"

    static func log(message: String) {
        print(message)
    }
}
