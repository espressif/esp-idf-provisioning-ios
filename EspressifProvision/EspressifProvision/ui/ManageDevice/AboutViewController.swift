//
//  AboutViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 19/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var wifiLabel: UILabel!
    @IBOutlet var ipAddressLabel: UILabel!
    @IBOutlet var macLabel: UILabel!
    @IBOutlet var serialNumberLabel: UILabel!
    @IBOutlet var firmwareVersionLabel: UILabel!

    var device: AlexaDevice!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        deviceNameLabel.text = device.deviceName ?? ""
        wifiLabel.text = device.connectedWifi ?? ""
        ipAddressLabel.text = device.hostAddress ?? ""
        macLabel.text = device.mac ?? ""
        serialNumberLabel.text = device.serialNumber ?? ""
        firmwareVersionLabel.text = device.fwVersion ?? ""
    }
}
