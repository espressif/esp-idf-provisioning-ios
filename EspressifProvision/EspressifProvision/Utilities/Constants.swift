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
    static let CognitoIdentityUserPoolId = "us-east-1_M35Yu8neD"
    static let CognitoIdentityUserPoolAppClientId = "5lu0kla1a769f4itp1m9fdoa7v"
    static let CognitoIdentityUserPoolAppClientSecret = "1vcurad1q2uhi32j2qpcmem0qbu6a5lif2heffav8ddf2dusimrf"

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"

    // AWS cognito APIs
    static let addDevice = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let getUserId = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/users/"
    static let getNodes = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let getNodeConfig = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/user/nodes/config/"
//    static let addDeviceToUser = "https://wb9f74l5i7.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"
    static let checkStatus = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/user/nodes/mapping/"

    static let updateThingsShadow = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/user/nodes/dynamic_params/"
    static let getDeviceShadow = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/user/nodes/dynamic_params/"

    static let newDeviceAdded = "com.espressif.newDeviceAdded"
    static let prefixKey = "com.espressif.prefix"
    static let userIDKey = "com.espressif.userid"
}
