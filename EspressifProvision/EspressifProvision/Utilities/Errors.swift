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

enum NetworkError: Error {
    case keyNotPresent
    case emptyToken
}
