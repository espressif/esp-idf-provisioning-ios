//
//  GenericSliderTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 09/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import MBProgressHUD
import UIKit

class GenericSliderTableViewCell: UITableViewCell {
    @IBOutlet var slider: UISlider!
    @IBOutlet var minLabel: UILabel!
    @IBOutlet var maxLabel: UILabel!
    @IBOutlet var backView: UIView!
    @IBOutlet var title: UILabel!

    var paramName: String = ""
    var device: Device!
    var dataType: String!
    var sliderValue = ""

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
        //        slider.setMinimumTrackImage(UIImage(named: "min_track_image"), for: .normal)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        if Utility.isConnected(view: parentViewController!.view) {
            if dataType.lowercased() == "int" {
                sliderValue = paramName + ": \(Int(slider.value))"
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: Int(sender.value)]])
            } else {
                sliderValue = paramName + ": \(slider.value)"
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [paramName: sender.value]])
            }
        }
    }
}
