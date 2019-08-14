//
//  Constants.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import MBProgressHUD
import UIKit

struct Constants {
    static let friendlynameKey = "friendlyname"
    static let UUIDKey = "uuid"

    // Reuse identifier
    static let deviceListCellReuseIdentifier = "deviceListCell"
    static let deviceDetailVCIndentifier = "deviceDetailVC"

    static func showLoader(message: String, view: UIView) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
        }
    }

    static func hideLoader(view: UIView) {
        MBProgressHUD.hide(for: view, animated: true)
    }
}
