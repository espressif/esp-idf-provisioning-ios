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
import UIKit

class BLELandingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var provisionConfig: [String: String] = [:]
    var bleTransport: BLETransport?
    var peripherals: [CBPeripheral]?
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?

    @IBOutlet var tableview: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableview.tableFooterView = UIView()
        navigationItem.title = "Connect"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        if let serviceUuid = provisionConfig[Provision.CONFIG_BLE_SERVICE_UUID],
            let deviceNamePrefix = provisionConfig[Provision.CONFIG_BLE_DEVICE_NAME_PREFIX],
            let sessionUuid = provisionConfig[Provision.CONFIG_BLE_SESSION_UUID],
            let configUuid = provisionConfig[Provision.CONFIG_BLE_CONFIG_UUID] {
            var configUUIDMap: [String: String] = [Provision.PROVISIONING_CONFIG_PATH: configUuid, Provision.PROVISIONING_SCAN_PATH: provisionConfig[Provision.CONFIG_BLE_SCAN_UUID]!]
            #if AVS
                let avsconfigUuid = provisionConfig[ConfigureAVS.AVS_CONFIG_UUID_KEY]
                configUUIDMap[ConfigureAVS.AVS_CONFIG_PATH] = avsconfigUuid
            #endif

            bleTransport = BLETransport(serviceUUIDString: serviceUuid,
                                        sessionUUIDString: sessionUuid,
                                        configUUIDMap: configUUIDMap,
                                        deviceNamePrefix: deviceNamePrefix,
                                        scanTimeout: 5.0)
            bleTransport?.scan(delegate: self)
            showBusy(isBusy: true)
        }
    }

    @IBAction func rescanBLEDevices(_: Any) {
        bleTransport?.disconnect()
        peripherals?.removeAll()
        tableview.reloadData()
        bleTransport?.scan(delegate: self)
        showBusy(isBusy: true)
    }

    func bleDeviceConfigured() {
        showBusy(isBusy: false)
        let provisionVC = storyboard?.instantiateViewController(withIdentifier: "loginWithAmazon") as! LoginWithAmazonViewController
        provisionVC.transport = bleTransport
        provisionVC.deviceName = bleTransport?.currentPeripheral?.name
        provisionVC.provisionConfig = provisionConfig
        navigationController?.pushViewController(provisionVC, animated: true)
    }

    func bleDeviceNotConfigured() {
        showBusy(isBusy: false)
        let alertController = UIAlertController(title: "Configure BLE device", message: "Could not configure the selected bluetooth device", preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

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
            bleTransport?.connect(peripheral: peripheral, withOptions: nil)
            print(peripheral)
        }

        showBusy(isBusy: true)
    }

    private func showBusy(isBusy: Bool) {
        if isBusy {
            grayView = UIView(frame: UIScreen.main.bounds)
            grayView?.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
            view.addSubview(grayView!)

            activityView = UIActivityIndicatorView(style: .gray)
            activityView?.center = view.center
            activityView?.startAnimating()

            view.addSubview(activityView!)
        } else {
            grayView?.removeFromSuperview()
            activityView?.removeFromSuperview()
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
        bleDeviceConfigured()
    }

    func peripheralNotConfigured(peripheral _: CBPeripheral) {
        bleDeviceNotConfigured()
    }

    func peripheralDisconnected(peripheral: CBPeripheral, error _: Error?) {}
}
