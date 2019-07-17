//
//  DoneViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 16/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class StatusViewController: UIViewController {
    var statusText: String?

    @IBOutlet var successLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let statusText = statusText {
            successLabel.text = statusText
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
}
