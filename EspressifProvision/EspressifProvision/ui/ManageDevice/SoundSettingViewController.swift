//
//  SoundSettingViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 18/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class SoundSettingViewController: UIViewController {
    var configureDevice: ConfigureDevice!

    @IBOutlet var endOfRequestSwitch: UISwitch!
    @IBOutlet var startOfRequestSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startOfRequestSwitch.setOn(configureDevice.alexaDevice.startToneEnabled ?? false, animated: false)
        endOfRequestSwitch.setOn(configureDevice.alexaDevice.endToneEnabled ?? false, animated: false)
    }

    @IBAction func setDeviceStartTone(_ sender: UISwitch) {
        DispatchQueue.main.async {
            Constants.showLoader(message: "Applying configuration", view: self.view)
        }
        configureDevice.setDeviceStartTone(value: sender.isOn) { result in
            DispatchQueue.main.async {
                Constants.hideLoader(view: self.view)
                if result {
                    self.configureDevice.alexaDevice.startToneEnabled = sender.isOn
                } else {
                    sender.setOn(!sender.isOn, animated: true)
                }
            }
        }
    }

    @IBAction func setDeviceEndTone(_ sender: UISwitch) {
        DispatchQueue.main.async {
            Constants.showLoader(message: "Applying configuration", view: self.view)
        }
        configureDevice.setDeviceEndTone(value: sender.isOn) { result in
            DispatchQueue.main.async {
                Constants.hideLoader(view: self.view)
                if result {
                    self.configureDevice.alexaDevice.endToneEnabled = sender.isOn
                } else {
                    sender.setOn(!sender.isOn, animated: true)
                }
            }
        }
    }
}
