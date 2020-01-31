//
//  DevicesCollectionViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 16/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class DevicesCollectionViewCell: UICollectionViewCell {
    var device: Device!
    var switchValue = false
    var switchActionButton: () -> Void = {}
    @IBOutlet var primaryValue: UILabel!
    @IBOutlet var deviceImageView: UIImageView!
    @IBOutlet var deviceName: UILabel!
    @IBOutlet var switchButton: UIButton!
    @IBOutlet var statusView: UIView!
    @IBAction func switchButtonPressed(_: Any) {
        switchValue = !switchValue
        NetworkManager.shared.updateThingShadow(nodeID: device.node_id!, parameter: [device.name ?? "": ["esp.param.output": switchValue]])

        if switchValue {
            switchButton.setImage(UIImage(named: "switch_icon_enabled_on"), for: .normal)
            switchButton.alpha = 1.0
        } else {
            switchButton.alpha = 0.3
        }
    }
}
