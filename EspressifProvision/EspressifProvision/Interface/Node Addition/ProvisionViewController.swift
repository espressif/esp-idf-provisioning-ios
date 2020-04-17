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
    var session: ESPSession?
    var capabilities: [String]?
    var alertTextField: UITextField?
    var showPasswordImageView: UIImageView!
    var connectAutomatically = false
    var isScanFlow = false
    var ssid = ""
    var passphrase = ""
    var pop = ""
    @IBOutlet var headerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Do any additional setup after loading the view, typically from a nib.
        showPasswordImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPassword))
        tap.numberOfTapsRequired = 1
        showPasswordImageView.isUserInteractionEnabled = true
        showPasswordImageView.contentMode = .scaleAspectFit
        showPasswordImageView.addGestureRecognizer(tap)

        configurePassphraseTextField()

        passphraseTextfield.addTarget(self, action: #selector(passphraseEntered), for: .editingDidEndOnExit)
        ssidTextfield.addTarget(self, action: #selector(ssidEntered), for: .editingDidEndOnExit)
        provisionButton.isUserInteractionEnabled = false
        if let bleTransport = transport as? BLETransport {
            print("Inside PVC", bleTransport.currentPeripheral!)
        }

        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        if transport == nil {
            transport = SoftAPTransport(baseUrl: Utility.baseUrl)
        }
        if isScanFlow {
            getDeviceVersionInfo()
        } else {
            initialiseSession()
        }
    }

    private func showBusy(isBusy: Bool) {
        if isBusy {
            activityView = UIActivityIndicatorView(style: .gray)
            activityView?.center = view.center
            activityView?.startAnimating()

            view.addSubview(activityView!)
        } else {
            activityView?.removeFromSuperview()
        }

        provisionButton.isUserInteractionEnabled = !isBusy
    }

    @IBAction func rescanWiFiList(_: Any) {
        scanDeviceForWiFiList()
    }

    private func provisionDevice(ssid: String, passphrase: String) {
        showLoader(message: "")

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
        let securityVersion = Provision.CONFIG_SECURITY_SECURITY1

        if securityVersion == Provision.CONFIG_SECURITY_SECURITY1 {
            if let capability = self.capabilities, capability.contains(Constants.noProofCapability) {
                provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY] = ""
                security = Security1(proofOfPossession: provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY]!)
                initSession()
            } else if connectAutomatically {
                security = Security1(proofOfPossession: pop)
                initSession()
            } else {
                DispatchQueue.main.async {
                    self.provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY] = self.pop
                    self.security = Security1(proofOfPossession: self.provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY]!)
                    self.initSession()
                }
            }
        } else {
            security = Security0()
            initSession()
        }
    }

    func initSession() {
        session = ESPSession(transport: transport!,
                             security: security!)
        session!.initialize(response: nil) { error in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }

            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                self.showStatusScreen(step1Failed: true)
                return
            }
            if let capability = self.capabilities, capability.contains(Constants.wifiScanCapability) {
                self.scanDeviceForWiFiList()
            } else {
                self.showTextFieldUI()
            }
        }
    }

    func scanDeviceForWiFiList() {
        if session!.isEstablished {
            DispatchQueue.main.async {
                self.showLoader(message: "Scanning for Wi-Fi")
                let scanWifiManager: ScanWifiList = ScanWifiList(session: self.session!)
                scanWifiManager.delegate = self
                scanWifiManager.startWifiScan()
            }
        }
    }

    func initialiseSessionAndConfigure(ssid: String, passPhrase: String) {
        if transport!.isDeviceConfigured() {
            if session!.isEstablished {
                self.ssid = ssid
                passphrase = passPhrase
                User.shared.associateNodeWithUser(session: session!, delegate: self)
            } else {
                showError(errorMessage: "Session is not established")
            }
        } else {
            showError(errorMessage: "Peripheral device could not be configured.")
        }
    }

    @IBAction func cancelClicked(_: Any) {
        transport?.disconnect()
        navigationController?.popToRootViewController(animated: false)
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

    func getDeviceVersionInfo() {
        showLoader(message: "Connecting Device")
        transport?.SendConfigData(path: (transport?.utility.versionPath)!, data: Data("ESP".utf8), completionHandler: { response, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
                self.showConnectionFailure()
                return
            }
            do {
                if let result = try JSONSerialization.jsonObject(with: response!, options: .mutableContainers) as? NSDictionary {
                    self.transport?.utility.deviceVersionInfo = result
                    if let prov = result[Constants.provKey] as? NSDictionary, let capabilities = prov[Constants.capabilitiesKey] as? [String] {
                        self.capabilities = capabilities
                        self.initialiseSession()
                    }
                }
            } catch {
                self.initialiseSession()
                print(error)
            }
        })
    }

    func showError(errorMessage: String) {
        let alertMessage = errorMessage
        let alertController = UIAlertController(title: "Provision device", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func showLoader(message: String) {
        DispatchQueue.main.async {
            let loader = MBProgressHUD.showAdded(to: self.view, animated: true)
            loader.mode = MBProgressHUDMode.indeterminate
            loader.label.text = message
            loader.backgroundView.blurEffectStyle = .dark
            loader.bezelView.backgroundColor = UIColor.white
        }
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
            self.provisionButton.isHidden = false
            self.headerView.isHidden = true
        }
    }

    private func joinOtherNetwork() {
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

    func showStatusScreen(step1Failed: Bool = false) {
        DispatchQueue.main.async {
            let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as! SuccessViewController
            successVC.session = self.session!
            successVC.transport = self.transport!
            successVC.ssid = self.ssid
            successVC.passphrase = self.passphrase
            successVC.step1Failed = step1Failed
            self.navigationController?.pushViewController(successVC, animated: true)
        }
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

    private func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    private func configurePasswordTextfield(textField: UITextField) {
        alertTextField = textField
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        showPasswordImageView.image = UIImage(named: "show_password")
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: showPasswordImageView.frame.width + 10, height: showPasswordImageView.frame.height))
        rightView.addSubview(showPasswordImageView)
        textField.rightView = rightView
        textField.rightViewMode = .always
    }

    private func configurePassphraseTextField() {
        alertTextField = passphraseTextfield
        passphraseTextfield.placeholder = "Password"
        passphraseTextfield.isSecureTextEntry = true
        showPasswordImageView.image = UIImage(named: "show_password")
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: showPasswordImageView.frame.width + 10, height: showPasswordImageView.frame.height))
        rightView.addSubview(showPasswordImageView)
        passphraseTextfield.rightView = rightView
        passphraseTextfield.rightViewMode = .always
    }

    private func showConnectionFailure() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Failure", message: "Connection to device failed.\n Please make sure you are connected to the Wi-Fi network of device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
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

    func bluetoothUnavailable() {}
}

extension ProvisionViewController: ScanWifiListProtocol {
    func wifiScanFinished(wifiList: [String: Espressif_WiFiScanResult]?, error _: Error?) {
        ssidList.removeAll()
        if wifiList?.count != 0, wifiList != nil {
            wifiDetailList = wifiList!
            let sortedList = (wifiList?.sorted(by: { $0.value.rssi > $1.value.rssi }))!
            for item in sortedList {
                ssidList.append(item.key)
            }
        }
        DispatchQueue.main.async {
            self.tableView.isHidden = false
            self.ssidTextfield.isHidden = true
            self.passphraseTextfield.isHidden = true
            self.headerView.isHidden = false
            self.tableView.reloadData()
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}

extension ProvisionViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row >= ssidList.count {
            joinOtherNetwork()
        } else {
            let ssid = ssidList[indexPath.row]

            if wifiDetailList[ssid]?.auth != Espressif_WifiAuthMode.open {
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
                        self.provisionDevice(ssid: ssid, passphrase: passphrase)
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
        return ssidList.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wifiListCell", for: indexPath) as! WifiListTableViewCell
        if indexPath.row >= ssidList.count {
            cell.ssidLabel.text = "Join Other Network"
            cell.signalImageView.image = UIImage(named: "add_icon")
        } else {
            cell.ssidLabel.text = ssidList[indexPath.row]
            setWifiIconImageFor(cell: cell, ssid: ssidList[indexPath.row])
        }
        return cell
    }
}

extension ProvisionViewController: BLEStatusProtocol {
    func peripheralDisconnected() {
        MBProgressHUD.hide(for: view, animated: true)
        if !(session?.isEstablished ?? false) {
            showStatusScreen(step1Failed: true)
        }
    }
}

extension ProvisionViewController: DeviceAssociationProtocol {
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?) {
        User.shared.currentAssociationInfo!.associationInfoDelievered = success
        if success {
            if let deviceSecret = nodeID {
                User.shared.currentAssociationInfo!.nodeID = deviceSecret
            }
            showStatusScreen()
        }
    }
}
