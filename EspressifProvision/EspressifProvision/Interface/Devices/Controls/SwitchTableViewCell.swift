//
//  SwitchTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    @IBOutlet var backView: UIView!
    @IBOutlet var controlName: UILabel!
    @IBOutlet var toggleSwitch: UISwitch!
    @IBOutlet var controlStateLabel: UILabel!

    var attributeKey = ""
    var param: Param!
    var device: Device!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clear

        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true

        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func switchStateChanged(_ sender: UISwitch) {
        if Utility.isConnected(view: parentViewController!.view) {
            if sender.isOn {
                controlStateLabel.text = "On"
            } else {
                controlStateLabel.text = "Off"
            }
            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: sender.isOn]])
        }
    }
}
