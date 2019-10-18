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
    static let CognitoIdentityUserPoolId = "us-east-1_v8FMdR6gN"
    static let CognitoIdentityUserPoolAppClientId = "7rdse8qf1gkai45t4r8tnarhuv"
    static let CognitoIdentityUserPoolAppClientSecret = "2jn4gd7ma60pi1n6vgd64dihd5l97sba1g32o0u8tb09rt335rg"

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"

    // AWS cognito APIs
    static let addDevice = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let getUserId = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/customer/users/"
    static let getNodes = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let getNodeConfig = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/user/nodes/config/"
//    static let addDeviceToUser = "https://wb9f74l5i7.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let checkStatus = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/user/nodes/"

    static let updateThingsShadow = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/user/nodes/dynamic_params/"
    static let getDeviceShadow = "https://tkjg4kjd5c.execute-api.us-east-1.amazonaws.com/dev/user/nodes/dynamic_params/"

    static let newDeviceAdded = "com.espressif.newDeviceAdded"
    static let prefixKey = "com.espressif.prefix"
    static let userIDKey = "com.espressif.userid"
}
