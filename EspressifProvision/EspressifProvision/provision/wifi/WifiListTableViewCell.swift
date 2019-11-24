//
//  SSIDTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 24/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class WifiListTableViewCell: UITableViewCell {
    @IBOutlet var ssidLabel: UILabel!
    @IBOutlet var signalImageView: UIImageView!
    @IBOutlet var authenticationImageView: UIImageView!
}
