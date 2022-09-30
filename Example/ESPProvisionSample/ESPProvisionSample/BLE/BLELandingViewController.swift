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
//  BLELandingViewController.swift
//  ESPProvisionSample
//

import CoreBluetooth
import Foundation
import MBProgressHUD
import UIKit
import ESPProvision

protocol BLEStatusProtocol {
    func peripheralDisconnected()
}

class BLELandingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?
    var delegate: BLEStatusProtocol?
    var bleConnectTimer = Timer()
    var bleDeviceConnected = false
    var bleDevices:[ESPDevice]?
    var pop = ""

    @IBOutlet var tableview: UITableView!
    @IBOutlet var prefixTextField: UITextField!
    @IBOutlet var prefixlabel: UILabel!
    @IBOutlet var prefixView: UIView!
    @IBOutlet var textTopConstraint: NSLayoutConstraint!

    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Scan for bluetooth devices

        // UI customization
        prefixlabel.layer.masksToBounds = true
        tableview.tableFooterView = UIView()

        // Adding tap gesture to hide keyboard on outside touch
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // Checking whether filtering by prefix header is allowed
        prefixTextField.text = Utility.shared.deviceNamePrefix
        if Utility.shared.espAppSettings.allowPrefixSearch {
            prefixView.isHidden = false
        } else {
            textTopConstraint.constant = -10
            view.layoutIfNeeded()
        }
        
        scanBleDevices()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - IBActions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func rescanBLEDevices(_: Any) {
        bleDevices?.removeAll()
        tableview.reloadData()
        scanBleDevices()
    }
    
    func scanBleDevices() {
        Utility.showLoader(message: "Searching for BLE Devices..", view: self.view)
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: Utility.shared.deviceNamePrefix, transport: .ble) { bleDevices, error in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.bleDevices = bleDevices
                self.tableview.reloadData()
            }
        }
    }
    
    // MARK: - Notifications
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func keyboardWillDisappear() {
        if let prefix = prefixTextField.text {
            UserDefaults.standard.set(prefix, forKey: "com.espressif.prefix")
            Utility.shared.deviceNamePrefix = prefix
            rescanBLEDevices(self)
        }
    }
    
    // MARK: - Helper Methods
    
    func goToProvision(device: ESPDevice) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.espDevice = device
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }
    
    private func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func connectDevice(device:ESPDevice) {
        device.security = Utility.shared.espAppSettings.securityMode
        device.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.goToProvision(device: device)
                }
            case let .failedToConnect(error):
                DispatchQueue.main.async {
                    var errorDescription = ""
                    switch error {
                    case .securityMismatch, .versionInfoError:
                        errorDescription = error.description
                    default:
                        errorDescription = error.description + "\nCheck if POP is correct."
                    }
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: errorDescription, action: action)
                }
            default:
                DispatchQueue.main.async {
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }
    
    // MARK: - UITableView
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let peripherals = self.bleDevices else {
            return 0
        }
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bleDeviceCell", for: indexPath) as! BLEDeviceListViewCell
        if let peripheral = self.bleDevices?[indexPath.row] {
            cell.deviceName.text = peripheral.name
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        Utility.showLoader(message: "Connecting to device", view: self.view)
        self.connectDevice(device: self.bleDevices![indexPath.row])
    }
    
}

extension BLELandingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}

extension BLELandingViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        goToConnectVC(forDevice: forDevice)
    }
    
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        goToConnectVC(forDevice: forDevice)
    }
    
    func goToConnectVC(forDevice: ESPDevice) {
        let connectVC = self.storyboard?.instantiateViewController(withIdentifier: "connectVC") as! ConnectViewController
        connectVC.espDevice = forDevice
        self.navigationController?.pushViewController(connectVC, animated: true)
    }
}
