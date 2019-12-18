// Copyright 2018 Espressif Systems (Shanghai) PTE LTD
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
//  EspressifProvision
//
import CoreBluetooth
import Foundation
import MBProgressHUD
import UIKit

protocol BLEStatusProtocol {
    func peripheralDisconnected()
}

class BLELandingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var provisionConfig: [String: String] = [:]
    var bleTransport: BLETransport?
    var peripherals: [CBPeripheral]?
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?
    var delegate: BLEStatusProtocol?
    var bleConnectTimer = Timer()
    var bleDeviceConnected = false

    @IBOutlet var tableview: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Scan for bluetooth devices
        bleTransport = BLETransport(scanTimeout: 5.0)
        bleTransport?.scan(delegate: self)
        showBusy(isBusy: true, message: "Searching")

        tableview.tableFooterView = UIView()
        tableview.backgroundColor = UIColor.white
    }

    @IBAction func rescanBLEDevices(_: Any) {
        bleTransport?.disconnect()
        peripherals?.removeAll()
        tableview.reloadData()
        bleTransport?.scan(delegate: self)
        showBusy(isBusy: true, message: "Searching")
    }

    ///
    /// Go to loging page when bluetooth device is successfully configured
    ///
    func bleDeviceConfigured() {
        showBusy(isBusy: false)
        let loginAVS = storyboard?.instantiateViewController(withIdentifier: "loginWithAmazon") as! LoginWithAmazonViewController
        loginAVS.provisionConfig = provisionConfig
        loginAVS.transport = bleTransport
        navigationController?.pushViewController(loginAVS, animated: true)
    }

    ///
    /// Show alert if ble device is not configured
    ///
    func bleDeviceNotConfigured(title: String, message: String) {
        bleDeviceConnected = true
        showBusy(isBusy: false)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: // TableView Methods

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        guard let peripherals = self.peripherals else {
            return 0
        }
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bleDeviceCell", for: indexPath) as! BLEDeviceListViewCell
        if let peripheral: CBPeripheral = self.peripherals?[indexPath.row] {
            cell.deviceName.text = peripheral.name
        }

        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let peripheral = self.peripherals?[indexPath.row] {
            showBusy(isBusy: true)
            bleTransport?.connect(peripheral: peripheral, withOptions: nil)
            bleDeviceConnected = false
            bleConnectTimer.invalidate()
            bleConnectTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(bleConnectionTimeout), userInfo: nil, repeats: false)
        }
    }

    private func showBusy(isBusy: Bool, message: String = "") {
        DispatchQueue.main.async {
            if isBusy {
                let loader = MBProgressHUD.showAdded(to: self.view, animated: true)
                loader.mode = MBProgressHUDMode.indeterminate
                loader.label.text = message
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
    }

    @objc func bleConnectionTimeout() {
        if !bleDeviceConnected {
            bleTransport?.disconnect()
            bleConnectTimer.invalidate()
            bleDeviceNotConfigured(title: "Error!", message: "Communication failed. Device may not be supported. ")
        }
    }
}

extension BLELandingViewController: BLETransportDelegate {
    func peripheralsFound(peripherals: [CBPeripheral]) {
        showBusy(isBusy: false)
        self.peripherals = peripherals
        tableview.reloadData()
    }

    func peripheralsNotFound(serviceUUID _: UUID?) {
        showBusy(isBusy: false)
    }

    func peripheralConfigured(peripheral _: CBPeripheral) {
        bleDeviceConnected = true
        bleDeviceConfigured()
    }

    func peripheralNotConfigured(peripheral _: CBPeripheral) {
        bleDeviceNotConfigured(title: "Configure BLE device", message: "Could not configure the selected bluetooth device")
    }

    func peripheralDisconnected(peripheral: CBPeripheral, error _: Error?) {
        showBusy(isBusy: false)

        if delegate == nil {
            let alertMessage = "Peripheral device disconnected"
            let alertController = UIAlertController(title: "Provision device", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            delegate?.peripheralDisconnected()
        }
    }

    func bluetoothUnavailable() {
        DispatchQueue.main.async {
            let alertMessage = "Turn on your Phone's Bluetooth to allow search for discoverable device's"
            let alertController = UIAlertController(title: "Error", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

// MARK: UITextFieldDelegate

extension BLELandingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        rescanBLEDevices(self)
        return false
    }
}
