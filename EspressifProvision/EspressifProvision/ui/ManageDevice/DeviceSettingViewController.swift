//
//  DeviceSettingViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 12/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import PickerView
import UIKit

class DeviceSettingViewController: UIViewController {
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var languageLabel: UILabel!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var volumeLabel: UILabel!
    @IBOutlet var pickerView: UIPickerView!

    var configureDevice: ConfigureDevice!
    var session: Session!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        deviceNameLabel.text = configureDevice.alexaDevice.deviceName ?? ""
        volumeSlider.value = Float(configureDevice.alexaDevice.volume ?? 0)
        volumeLabel.text = "\(configureDevice.alexaDevice.volume ?? 0)"
        languageLabel.text = configureDevice.languages[configureDevice.alexaDevice.language?.rawValue ?? 0]
    }

    func showDeviceDetails(device: AlexaDevice, avsConfig: ConfigureAVS, loginStatus: Bool = false) {
        DispatchQueue.main.async {
            let deviceDetailVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.deviceDetailVCIndentifier) as! DeviceDetailViewController
            deviceDetailVC.avsConfig = avsConfig
            deviceDetailVC.loginStatus = loginStatus
            deviceDetailVC.session = self.session
            deviceDetailVC.device = device
            self.navigationController?.pushViewController(deviceDetailVC, animated: true)
        }
    }

    private func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    // MARK: IBAction Methods

    @IBAction func setDeviceName(_: Any) {
        let input = UIAlertController(title: "Device name", message: nil, preferredStyle: .alert)

        input.addTextField { textField in
            textField.text = self.configureDevice.alexaDevice.deviceName ?? ""
            textField.delegate = self
            self.addHeightConstraint(textField: textField)
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

        }))
        input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
            let textField = input?.textFields![0]
            if let name = textField?.text {
                if name != self.configureDevice.alexaDevice.deviceName, name != "" {
                    Constants.showLoader(message: "Setting device name", view: self.view)
                    self.configureDevice.setDeviceName(withName: name) { result in
                        DispatchQueue.main.async {
                            Constants.hideLoader(view: self.view)
                            if result {
                                self.deviceNameLabel.text = name
                                self.configureDevice.alexaDevice.deviceName = name
                            }
                        }
                    }
                }
            }
        }))
        present(input, animated: true, completion: nil)
    }

    @IBAction func setDeviceVolume(_ sender: UISlider) {
        Constants.showLoader(message: "Setting device volume", view: view)
        let volume = UInt32(sender.value)
        configureDevice.setDeviceVolume(volume: volume) { result in
            DispatchQueue.main.async {
                Constants.hideLoader(view: self.view)
                if result {
                    self.volumeLabel.text = "\(volume)"
                    self.configureDevice.alexaDevice.volume = volume
                }
                self.volumeSlider.value = Float(self.configureDevice.alexaDevice.volume ?? 0)
            }
        }
    }

    @IBAction func setSoundClicked(_: Any) {
        let soundSettingVC = storyboard?.instantiateViewController(withIdentifier: Constants.soundSettingVCIdentifier) as! SoundSettingViewController
        soundSettingVC.configureDevice = configureDevice
        navigationController?.pushViewController(soundSettingVC, animated: true)
    }

    @IBAction func setLanguageClicked(_: Any) {
        let languageListVC = storyboard?.instantiateViewController(withIdentifier: Constants.languageListVCIdentifier) as! LanguageListTableViewController
        languageListVC.configureDevice = configureDevice
        navigationController?.pushViewController(languageListVC, animated: true)
    }

    @IBAction func aboutBtnClicked(_: Any) {
        let aboutVC = storyboard?.instantiateViewController(withIdentifier: Constants.aboutVCIdentifier) as! AboutViewController
        aboutVC.device = configureDevice.alexaDevice
        navigationController?.pushViewController(aboutVC, animated: true)
    }

    @IBAction func manageAccountClicked(_: Any) {
        let avsConfig = ConfigureAVS(session: session)
        avsConfig.isLoggedIn(completionHandler: { status in
            self.showDeviceDetails(device: self.configureDevice.alexaDevice, avsConfig: avsConfig, loginStatus: status)
        })
    }
}

// MARK: UITextFieldDelegate

/*
 Over riding UITextField method in order to restrict the textfield to 22 characters only.
 */
extension DeviceSettingViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 22
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
}
