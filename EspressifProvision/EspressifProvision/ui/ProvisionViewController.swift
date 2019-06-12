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
//  ProvisionViewController.swift
//  EspressifProvision
//

import CoreBluetooth
import Foundation
import MBProgressHUD
import UIKit

class ProvisionViewController: UIViewController {
    @IBOutlet var passphraseTextfield: UITextField!
    @IBOutlet var ssidTextfield: UITextField!
    @IBOutlet var provisionButton: UIButton!
    @IBOutlet var tableView: UITableView!

    var provisionConfig: [String: String] = [:]
    var transport: Transport?
    var security: Security?
    var bleTransport: BLETransport?
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?
    var provision: Provision!
    var ssidList: [String] = []
    var wifiDetailList: [String: Espressif_WiFiScanResult] = [:]
    var versionInfo: String?
    var session: Session?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        passphraseTextfield.addTarget(self, action: #selector(passphraseEntered), for: .editingDidEndOnExit)
        ssidTextfield.addTarget(self, action: #selector(ssidEntered), for: .editingDidEndOnExit)
        provisionButton.isUserInteractionEnabled = false
        if let bleTransport = transport as? BLETransport {
            print("Inside PVC", bleTransport.currentPeripheral!)
        }
        tableView.tableFooterView = UIView()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(showDeviceVersion))
        let securityVersion = provisionConfig[Provision.CONFIG_SECURITY_KEY]
        let pop = provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY]

        if securityVersion == Provision.CONFIG_SECURITY_SECURITY1 {
            security = Security1(proofOfPossession: pop!)
        } else {
            security = Security0()
        }
        initialiseSession()
        scanDeviceForWiFiList()
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

        provisionButton.isUserInteractionEnabled = !isBusy
    }

    private func provisionDevice(ssid: String, passphrase: String) {
        showBusy(isBusy: true)

        let baseUrl = provisionConfig[Provision.CONFIG_BASE_URL_KEY]
        let transportVersion = provisionConfig[Provision.CONFIG_TRANSPORT_KEY]
        if transport != nil {
            // transport is BLETransport set from BLELandingVC
            if let bleTransport = transport as? BLETransport {
                bleTransport.delegate = self
            }

            initialiseSessionAndConfigure(ssid: ssid, passPhrase: passphrase)
        } else if transportVersion == Provision.CONFIG_TRANSPORT_WIFI {
            transport = SoftAPTransport(baseUrl: baseUrl!)
            initialiseSessionAndConfigure(ssid: ssid, passPhrase: passphrase)
        } else if transport == nil {
            bleTransport = BLETransport(scanTimeout: 2.0)
            bleTransport?.scan(delegate: self)
            transport = bleTransport
        }
    }

    private func initialiseSession() {
        session = Session(transport: transport!,
                          security: security!)
        session!.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                return
            }
            self.getDeviceVersionInfo()
        }
    }

    func scanDeviceForWiFiList() {
        if session!.isEstablished {
            DispatchQueue.main.async {
                self.showLoader(message: "Scanning for Wifi")
                let scanWifiManager: ScanWifiList = ScanWifiList(session: self.session!)
                scanWifiManager.delegate = self
                scanWifiManager.startWifiScan()
            }
        }
    }

    func initialiseSessionAndConfigure(ssid: String, passPhrase: String) {
        if transport!.isDeviceConfigured() {
            if session!.isEstablished {
                let provision = Provision(session: session!)

                provision.configureWifi(ssid: ssid,
                                        passphrase: passPhrase) { status, error in
                    guard error == nil else {
                        print("Error in configuring wifi : \(error.debugDescription)")
                        return
                    }
                    if status == Espressif_Status.success {
                        self.applyConfigurations(provision: provision)
                    }
                }
            } else {
                print("Session is not established")
            }
        } else {
            showError(errorMessage: "Peripheral device could not be configured.")
        }
    }

    func getDeviceVersionInfo() {
        if session!.isEstablished {
            transport?.SendConfigData(path: (transport?.utility.versionPath)!, data: Data("ESP".utf8), completionHandler: { response, error in
                guard error == nil else {
                    print("Error reading device version info")
                    return
                }
                do {
                    if let result = try JSONSerialization.jsonObject(with: response!, options: .mutableContainers) as? NSDictionary {
                        self.transport?.utility.deviceVersionInfo = result
                        if let prov = result[Constants.provKey] as? NSDictionary, let capabilities = prov[Constants.capabilitiesKey] as? [String] {
                            if capabilities.contains(Constants.wifiScanCapability) {
                                self.scanDeviceForWiFiList()
                            } else {
                                self.showTextFieldUI()
                            }
                        }
                    }
                } catch {
                    self.showTextFieldUI()
                    print(error)
                }
            })
        }
    }

    @objc func showDeviceVersion() {
        let deviceVersionVC = storyboard?.instantiateViewController(withIdentifier: Constants.deviceInfoStoryboardID) as! DeviceInfoViewController
        deviceVersionVC.utility = transport!.utility
        navigationController?.pushViewController(deviceVersionVC, animated: true)
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

    @IBAction func provisionButtonClicked(_: Any) {
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            ssid.count > 0, passphrase.count > 0 else {
            return
        }
        provisionDevice(ssid: ssid, passphrase: passphrase)
    }

    private func applyConfigurations(provision: Provision) {
        provision.applyConfigurations(completionHandler: { status, error in
            guard error == nil else {
                self.showError(errorMessage: "Error in applying configurations : \(error.debugDescription)")
                return
            }
            print("Configurations applied ! \(status)")
        },
                                      wifiStatusUpdatedHandler: { wifiState, failReason, error in
            DispatchQueue.main.async {
                self.showBusy(isBusy: false)
                let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as? SuccessViewController
                if let successVC = successVC {
                    if error != nil {
                        successVC.statusText = "Error in getting wifi state : \(error.debugDescription)"
                    } else if wifiState == Espressif_WifiStationState.connected {
                        successVC.statusText = "Device has been successfully provisioned!"
                    } else if wifiState == Espressif_WifiStationState.disconnected {
                        successVC.statusText = "Please check the device indicators for Provisioning status."
                    } else {
                        successVC.statusText = "Device provisioning failed.\nReason : \(failReason).\nPlease try again"
                    }
                    self.navigationController?.present(successVC, animated: true, completion: nil)
                    self.provisionButton.isUserInteractionEnabled = true
                }
            }
        })
    }

    func showError(errorMessage: String) {
        let alertMessage = errorMessage
        let alertController = UIAlertController(title: "Provision device", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func showLoader(message: String) {
        let loader = MBProgressHUD.showAdded(to: view, animated: true)
        loader.mode = MBProgressHUDMode.indeterminate
        loader.label.text = message
    }

    func setWifiIconImageFor(cell: WifiListTableViewCell, ssid: String) {
        let rssi = wifiDetailList[ssid]?.rssi ?? -70
        if rssi > Int32(-50) {
            cell.signalImageView.image = UIImage(named: "wifi_symbol_strong")
        } else if rssi > Int32(-60) {
            cell.signalImageView?.image = UIImage(named: "wifi_symbol_good")
        } else if rssi > Int32(-67) {
            cell.signalImageView?.image = UIImage(named: "wifi_symbol_fair")
        } else {
            cell.signalImageView?.image = UIImage(named: "wifi_symbol_weak")
        }
        if wifiDetailList[ssid]?.auth != Espressif_WifiAuthMode.open {
            cell.authenticationImageView.image = UIImage(named: "wifi_security")
            cell.authenticationImageView.isHidden = false
        } else {
            cell.authenticationImageView.isHidden = true
        }
    }

    func showTextFieldUI() {
        DispatchQueue.main.async {
            self.tableView.isHidden = true
            self.ssidTextfield.isHidden = false
            self.passphraseTextfield.isHidden = false
        }
    }
}

extension ProvisionViewController: BLETransportDelegate {
    func peripheralsFound(peripherals: [CBPeripheral]) {
        bleTransport?.connect(peripheral: peripherals[0], withOptions: nil)
    }

    func peripheralsNotFound(serviceUUID _: UUID?) {
        showError(errorMessage: "No peripherals found!")
    }

    func peripheralConfigured(peripheral _: CBPeripheral) {}

    func peripheralNotConfigured(peripheral _: CBPeripheral) {
        showError(errorMessage: "Peripheral device could not be configured.")
    }

    func peripheralDisconnected(peripheral: CBPeripheral, error _: Error?) {
        showError(errorMessage: "Peripheral device disconnected")
    }
}

extension ProvisionViewController: ScanWifiListProtocol {
    func wifiScanFinished(wifiList: [String: Espressif_WiFiScanResult]?, error: Error?) {
        if wifiList?.count != 0, wifiList != nil {
            wifiDetailList = wifiList!
            ssidList = Array(wifiList!.keys)
            DispatchQueue.main.async {
                self.tableView.isHidden = false
                self.ssidTextfield.isHidden = true
                self.passphraseTextfield.isHidden = true
                self.tableView.reloadData()
            }
        } else {
            showTextFieldUI()
            if error != nil {
                print("Unable to fetch wifi list :\(String(describing: error))")
            }
        }
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

extension ProvisionViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let ssid = ssidList[indexPath.row]

        if wifiDetailList[ssid]?.auth != Espressif_WifiAuthMode.open {
            let input = UIAlertController(title: ssid, message: nil, preferredStyle: .alert)

            input.addTextField { textField in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
            }

            input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
                let textField = input?.textFields![0]
                guard let passphrase = textField?.text else {
                    return
                }
                if passphrase.count > 0 {
                    self.provisionDevice(ssid: ssid, passphrase: passphrase)
                }
            }))
            input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in

            }))
            present(input, animated: true, completion: nil)
        } else {
            provisionDevice(ssid: ssid, passphrase: "")
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension ProvisionViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return ssidList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wifiListCell", for: indexPath) as! WifiListTableViewCell
        cell.ssidLabel.text = ssidList[indexPath.row]
        setWifiIconImageFor(cell: cell, ssid: ssidList[indexPath.row])
        return cell
    }
}
