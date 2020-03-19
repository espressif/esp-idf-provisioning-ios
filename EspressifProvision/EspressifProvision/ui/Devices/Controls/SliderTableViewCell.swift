//
//  SliderTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 12/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import MBProgressHUD
import UIKit

class SliderTableViewCell: UITableViewCell {
    @IBOutlet var sliderValue: UILabel!
    @IBOutlet var slider: BrightnessSlider!
    @IBOutlet var backView: UIView!
    @IBOutlet var title: UILabel!

    var paramName: String!
    var device: Device!
    var dataType: String!

    override func awakeFromNib() {
        super.awakeFromNib()
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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if Utility.isConnected(view: parentViewController!.view) {
            if dataType.lowercased() == "int" {
                sliderValue.text = paramName + ": \(Int(slider.value))"
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(sender.value)]])
            } else {
                sliderValue.text = paramName + ": \(slider.value)"
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: sender.value]])
            }
        }
    }
}
