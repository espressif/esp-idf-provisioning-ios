// Copyright 2020 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  ProvisionViewController.swift
//  ESPProvisionSample
//

import CoreBluetooth
import Foundation
import MBProgressHUD
import UIKit
import ESPProvision

// Class that shows Wi-Fi network list and takes Wi-Fi credentials from user.
class ProvisionViewController: UIViewController {
    @IBOutlet var passphraseTextfield: UITextField!
    @IBOutlet var ssidTextfield: UITextField!
    @IBOutlet var provisionButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    var activityView: UIActivityIndicatorView?
    var wifiDetailList: [ESPWifiNetwork] = []
    var alertTextField: UITextField?
    var showPasswordImageView: UIImageView!
    var espDevice: ESPDevice!
    var passphrase = ""
    var ssid = ""

    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerLabel.text = "To continue setup of your device \(espDevice.name), please provide your Home Network's credentials."
        // Remove back button, user will have the option to cancel the provisioning.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Setup show/hide password feature for passphrase textfield.
        showPasswordImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPassword))
        tap.numberOfTapsRequired = 1
        showPasswordImageView.isUserInteractionEnabled = true
        showPasswordImageView.contentMode = .scaleAspectFit
        showPasswordImageView.addGestureRecognizer(tap)

        
        configurePassphraseTextField()

        // Add keyboard notification for texfield inputs
        passphraseTextfield.addTarget(self, action: #selector(passphraseEntered), for: .editingDidEndOnExit)
        ssidTextfield.addTarget(self, action: #selector(ssidEntered), for: .editingDidEndOnExit)
        provisionButton.isUserInteractionEnabled = false

        // Setup table view
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        scanDeviceForWiFiList()
    }

    // MARK: - IBActions
    
    @IBAction func rescanWiFiList(_: Any) {
        scanDeviceForWiFiList()
    }
    
    // Cancel current device provisioning
    @IBAction func cancelClicked(_: Any) {
        espDevice.disconnect()
        navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func provisionButtonClicked(_: Any) {
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            ssid.count > 0, passphrase.count > 0 else {
            return
        }
        provisionDevice(ssid: ssid, passphrase: passphrase)
    }
    
    // MARK: - Provision

    // Start provisioning
    func provisionDevice(ssid: String, passphrase: String) {
        self.ssid = ssid
        self.passphrase = passphrase
        showStatusScreen()
    }

    // Scan device for available Wi-Fi networks.
    func scanDeviceForWiFiList() {
        Utility.showLoader(message: "Scanning for Wi-Fi", view: view)
        espDevice.scanWifiList { wifiList, _ in
            DispatchQueue.main.async {
                self.tableView.isHidden = false
                self.headerView.isHidden = false
                if let list = wifiList {
                    self.wifiDetailList = list.sorted { $0.rssi > $1.rssi }
                }
                self.tableView.reloadData()
                Utility.hideLoader(view: self.view)
            }
        }
    }

    @objc func passphraseEntered() {
        passphraseTextfield.resignFirstResponder()
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        if ssid.count > 0, passphrase.count > 0 {
            provisionButton.isUserInteractionEnabled = true
            provisionDevice(ssid: ssid, passphrase: passphrase)
        }
    }

    @objc func ssidEntered() {
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        if ssid.count > 0, passphrase.count > 0 {
            provisionButton.isUserInteractionEnabled = true
        }
        passphraseTextfield.becomeFirstResponder()
    }

    // Set Wi-Fi signal and security image based on rssi value and security.
    func setWifiIconImageFor(cell: WifiListTableViewCell, network: ESPWifiNetwork) {
        let rssi = network.rssi
        if rssi > Int32(-50) {
            cell.signalImageView.image = UIImage(named: "wifi_symbol_strong")
        } else if rssi > Int32(-60) {
            cell.signalImageView.image = UIImage(named: "wifi_symbol_good")
        } else if rssi > Int32(-67) {
            cell.signalImageView.image = UIImage(named: "wifi_symbol_fair")
        } else {
            cell.signalImageView.image = UIImage(named: "wifi_symbol_weak")
        }
        if network.auth != .open {
            cell.authenticationImageView.isHidden = false
        } else {
            cell.authenticationImageView.isHidden = true
        }
    }

    // Method to join hidden networks which are not visible on Wi-Fi list
    func joinOtherNetwork() {
        let input = UIAlertController(title: "", message: nil, preferredStyle: .alert)

        input.addTextField { textField in
            textField.placeholder = "Network Name"
            self.addHeightConstraint(textField: textField)
        }

        input.addTextField { textField in
            self.configurePasswordTextfield(textField: textField)
            self.addHeightConstraint(textField: textField)
        }
        input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        }))
        input.addAction(UIAlertAction(title: "Connect", style: .default, handler: { [weak input] _ in
            let ssidTextField = input?.textFields![0]
            let passphrase = input?.textFields![1]

            if let ssid = ssidTextField?.text, ssid.count > 0 {
                self.provisionDevice(ssid: ssid, passphrase: passphrase?.text ?? "")
            }
        }))
        DispatchQueue.main.async {
            self.present(input, animated: true, completion: nil)
        }
    }

    // MARK: - UIConfiguration
    
    func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    func configurePasswordTextfield(textField: UITextField) {
        alertTextField = textField
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        showPasswordImageView.image = UIImage(named: "show_password")
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: showPasswordImageView.frame.width + 10, height: showPasswordImageView.frame.height))
        rightView.addSubview(showPasswordImageView)
        textField.rightView = rightView
        textField.rightViewMode = .always
    }

    func configurePassphraseTextField() {
        alertTextField = passphraseTextfield
        passphraseTextfield.placeholder = "Password"
        passphraseTextfield.isSecureTextEntry = true
        showPasswordImageView.image = UIImage(named: "show_password")
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: showPasswordImageView.frame.width + 10, height: showPasswordImageView.frame.height))
        rightView.addSubview(showPasswordImageView)
        passphraseTextfield.rightView = rightView
        passphraseTextfield.rightViewMode = .always
    }
    
    @objc func showPassword() {
        if let secureEntry = self.alertTextField?.isSecureTextEntry {
            alertTextField?.togglePasswordVisibility()
            if secureEntry {
                showPasswordImageView.image = UIImage(named: "hide_password")
            } else {
                showPasswordImageView.image = UIImage(named: "show_password")
            }
        }
    }

    // MARK: - Helper Methods
    
    func showStatusScreen() {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let statusVC = self.storyboard?.instantiateViewController(withIdentifier: "statusVC") as! StatusViewController
            statusVC.ssid = self.ssid
            statusVC.passphrase = self.passphrase
            statusVC.espDevice = self.espDevice
            self.navigationController?.pushViewController(statusVC, animated: true)
        }
    }
}

extension ProvisionViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row >= wifiDetailList.count {
            joinOtherNetwork()
        } else {
            let wifiNetwork = wifiDetailList[indexPath.row]
            ssid = wifiNetwork.ssid

            if wifiNetwork.auth != .open {
                let input = UIAlertController(title: ssid, message: nil, preferredStyle: .alert)

                input.addTextField { textField in
                    self.configurePasswordTextfield(textField: textField)
                    self.addHeightConstraint(textField: textField)
                }
                input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

                }))
                input.addAction(UIAlertAction(title: "Provision", style: .default, handler: { [weak input] _ in
                    let textField = input?.textFields![0]
                    guard let passphrase = textField?.text else {
                        return
                    }
                    if passphrase.count > 0 {
                        self.provisionDevice(ssid: self.ssid, passphrase: passphrase)
                    }
                }))
                present(input, animated: true, completion: nil)
            } else {
                provisionDevice(ssid: ssid, passphrase: "")
            }
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension ProvisionViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return wifiDetailList.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wifiListCell", for: indexPath) as! WifiListTableViewCell
        if indexPath.row >= wifiDetailList.count {
            cell.ssidLabel.text = "Join Other Network"
            cell.authenticationImageView.isHidden = true
            cell.signalImageView.isHidden = true
        } else {
            cell.signalImageView.isHidden = false
            cell.ssidLabel.text = wifiDetailList[indexPath.row].ssid
            setWifiIconImageFor(cell: cell, network: wifiDetailList[indexPath.row])
        }
        return cell
    }
}

