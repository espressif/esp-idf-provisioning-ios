//
//  Error.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 09/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

enum CustomError: Error {
    case emptyConfigData
    case emptyResultCount
    case emptyToken
    case userIDNotPresent
    case emptyNodeList
}

enum InputValidationError: String {
    case outOfBound = "Input value is out of bound"
    case invalid = "Input value is inavlid"
    case other = "Unrecognized error"
}

enum ESPNetworkError: Error {
    case keyNotPresent
    case emptyToken
    case serverError(_ description: String = "Oops!! Something went bad. Please try again after sometime")
    case emptyConfigData

    var description: String {
        switch self {
        case let .serverError(description):
            return description
        case .keyNotPresent:
            return "Key not present."
        case .emptyToken:
            return "No access token found. Please signout and login then try again!!"
        case .emptyConfigData:
            return "Node info is not present"
        default:
            return "Oops!! Something went bad. Please try again after sometime"
        }
    }
}
