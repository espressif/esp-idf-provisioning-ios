//
//  DeviceInfoViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 11/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class DeviceInfoViewController: UIViewController {
    var utility: Utility?

    @IBOutlet var deviceName: UILabel!
    @IBOutlet var versionText: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        versionText.text = utility?.deviceVersionInfo?.description
        deviceName.text = utility?.deviceName
    }
}
