//
//  DevicesCollectionViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 16/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class DevicesCollectionViewCell: UICollectionViewCell {
    @IBOutlet var bgView: UIView!
    var device: Device!
    var switchValue = false
    var switchActionButton: () -> Void = {}
    @IBOutlet var primaryValue: UILabel!
    @IBOutlet var deviceImageView: UIImageView!
    @IBOutlet var deviceName: UILabel!
    @IBOutlet var switchButton: UIButton!
    @IBOutlet var statusView: UIView!
    @IBOutlet var offlineLabel: UILabel!
    @IBAction func switchButtonPressed(_: Any) {
        switchValue = !switchValue
        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [device.primary ?? "": switchValue]])

        if switchValue {
            switchButton.setImage(UIImage(named: "switch_icon_enabled_on"), for: .normal)
        } else {
            switchButton.setImage(UIImage(named: "switch_icon_enabled_off"), for: .normal)
        }
    }

    func refresh() {
        device = nil
        switchValue = false
        primaryValue.text = ""
        deviceImageView.image = UIImage(named: "dummy_device_icon")
        deviceName.text = ""
        statusView.isHidden = true
    }
}
