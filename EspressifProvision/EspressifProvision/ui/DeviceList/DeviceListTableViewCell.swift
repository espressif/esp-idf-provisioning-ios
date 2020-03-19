//
//  DeviceListTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 04/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class DeviceListTableViewCell: UITableViewCell {
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var backView: UIView!

    var node: Node?

    override func awakeFromNib() {
        backgroundColor = UIColor.clear

        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true

        let shadowSize: CGFloat = 5.0
        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
    }

    @IBAction func toggle(_: UISwitch) {}
}
