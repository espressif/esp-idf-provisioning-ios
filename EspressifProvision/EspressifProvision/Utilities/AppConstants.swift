//
//  AppConstants.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 30/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import Foundation
import UIKit

class AppConstants {
    static let shared = AppConstants()
    var appThemeColor: UIColor?
    var appBGImage: UIImage?

    private init() {
        appThemeColor = UserDefaults.standard.backgroundColor
        appBGImage = UserDefaults.standard.imageForKey(key: Constants.appBGKey)
    }
}
