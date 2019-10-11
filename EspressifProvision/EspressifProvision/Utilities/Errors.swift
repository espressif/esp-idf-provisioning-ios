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
}

enum NetworkError: Error {
    case keyNotPresent
    case emptyToken
}
