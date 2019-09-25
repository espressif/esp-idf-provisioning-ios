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
    static let CognitoIdentityUserPoolId = "us-east-1_GpR1ECivd"
    static let CognitoIdentityUserPoolAppClientId = "4h7n9e7cq56jvbr10pfdscp9ho"
    static let CognitoIdentityUserPoolAppClientSecret = "1k45fn6jnm1fkv3svdvhcqn9dbleje2gme7e92fmavin9ht8lp9"

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"

    // AWS cognito APIs
    static let addDevice = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device/"
    static let getUserId = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/customer/users/"
    static let getDevices = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device/"
    static let addDeviceToUser = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device/"
    static let checkStatus = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device?"

    static let toggleDevice = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/updatethingshadow"

    static let newDeviceAdded = "com.espressif.newDeviceAdded"
    static let prefixKey = "com.espressif.prefix"
}
