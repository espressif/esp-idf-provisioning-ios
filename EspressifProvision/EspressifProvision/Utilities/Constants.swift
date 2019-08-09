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
    static let CognitoIdentityUserPoolId = "us-east-1_Z9dElN5F5"
    static let CognitoIdentityUserPoolAppClientId = "3jn3h0jeo77vq4tiu2vsos9h0u"
    static let CognitoIdentityUserPoolAppClientSecret = "1ffq8fs6t7f6e4sdjn31c704sqplrj6aainctario5lsric75fqr"

    static let AWSCognitoUserPoolsSignInProviderKey = "UserPool"

    // AWS cognito APIs
    static let addDevice = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device/"
    static let getUserId = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/customer/users/"
    static let getDevices = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device/"
    static let addDeviceToUser = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device/"
    static let checkStatus = "https://61h45uifta.execute-api.us-east-1.amazonaws.com/demo/user/device?"
}
