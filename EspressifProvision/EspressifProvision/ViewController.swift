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
//  ViewController.swift
//  EspressifProvision
//

import AWSAuthCore
import AWSCognitoIdentityProvider
import CoreBluetooth
import MBProgressHUD
import UIKit

class ViewController: UIViewController {
    // Provisioning
    @IBOutlet var titleView: UIView!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var tableView: DeviceListTableView!
    private let pop = Bundle.main.infoDictionary?["ProofOfPossession"] as! String
    private let refreshControl = UIRefreshControl()
    // WIFI
    private let baseUrl = Bundle.main.infoDictionary?["WifiBaseUrl"] as! String
    private let networkNamePrefix = Bundle.main.infoDictionary?["WifiNetworkNamePrefix"] as! String

    var transport: Transport?
    var security: Security?
    var bleTransport: BLETransport?

    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var checkDeviceAssociation = false
    var deviceID: String?
    var requestID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        if user == nil {
            user = pool?.currentUser()
        }
        if let username = UserDefaults.standard.value(forKey: Constants.usernameKey) as? String {
            User.shared.username = username
        }

        refresh()
        tableView.tableFooterView = UIView()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        addButton.layer.masksToBounds = false
        addButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        addButton.layer.shadowRadius = 0.5
        addButton.layer.shadowColor = UIColor.darkGray.cgColor
        addButton.layer.shadowOpacity = 1.0
//        addButton.layer.shadowPath = UIBezierPath(roundedRect: addButton.frame, cornerRadius: 40.0).cgPath

        refreshControl.addTarget(self, action: #selector(refreshDeviceList), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        tableView.refreshControl = refreshControl

        let colors = Colors()
        view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.backGroundLayer
        backgroundLayer!.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)

        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceList), name: Notification.Name(Constants.newDeviceAdded), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if User.shared.associatedDevices == nil {
            showLoader(message: "Fetching Device List")
            refreshDeviceList()
        }
        if User.shared.updateDeviceList {
            refreshDeviceList()
        }
    }

    @objc func refreshDeviceList() {
        User.shared.updateDeviceList = false
        NetworkManager.shared.getDeviceList { devices, _ in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.refreshControl.endRefreshing()
            User.shared.associatedDevices = devices
            self.tableView.reloadData()
        }
    }

    func showLoader(message: String) {
        let loader = MBProgressHUD.showAdded(to: view, animated: true)
        loader.mode = MBProgressHUDMode.indeterminate
        loader.label.text = message
    }

    func resetAttributeValues() {
        user = nil
    }

    func provisionWithAPIs(_: Any) {
        #if SEC1
            security = Security1(proofOfPossession: pop)
        #else
            security = Security0()
        #endif

        #if BLE
            bleTransport = BLETransport(scanTimeout: 5.0)
            bleTransport?.scan(delegate: self)
            transport = bleTransport

        #else
            transport = SoftAPTransport(baseUrl: baseUrl)
        #endif
    }

    @IBAction func provisionButtonClicked(_: Any) {
        var transport = Provision.CONFIG_TRANSPORT_WIFI
        #if BLE
            transport = Provision.CONFIG_TRANSPORT_BLE
        #endif

        var security = Provision.CONFIG_SECURITY_SECURITY0
        #if SEC1
            security = Provision.CONFIG_SECURITY_SECURITY1
        #endif

        let config = [
            Provision.CONFIG_TRANSPORT_KEY: transport,
            Provision.CONFIG_SECURITY_KEY: security,
            Provision.CONFIG_PROOF_OF_POSSESSION_KEY: pop,
            Provision.CONFIG_BASE_URL_KEY: baseUrl,
            Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
        ]
        Provision.showProvisioningUI(on: self, config: config)
    }

    @IBAction func signOut(_: Any) {
        user?.signOut()
        User.shared.userID = nil
        refresh()
    }

    @IBAction func refreshList(_: Any) {
        refreshDeviceList()
    }

    func refresh() {
        user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async {
                self.response = task.result
//                self.title = self.user?.username
            }
            return nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func applyConfigurations(provision: Provision) {
        provision.applyConfigurations(completionHandler: { status, error in
            guard error == nil else {
                print("Error in applying configurations : \(error.debugDescription)")
                return
            }
            print("Configurations applied ! \(status)")
        },
                                      wifiStatusUpdatedHandler: { wifiState, failReason, error in
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
            }
        })
    }

    private func generateProductDSN() -> String {
        return UUID().uuidString
    }

    func showError(errorMessage: String) {
        let alertMessage = errorMessage
        let alertController = UIAlertController(title: "Provision device", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

#if BLE
    extension ViewController: BLETransportDelegate {
        func peripheralsFound(peripherals: [CBPeripheral]) {
            bleTransport?.connect(peripheral: peripherals[0], withOptions: nil)
        }

        func peripheralsNotFound(serviceUUID: UUID?) {
            showError(errorMessage: "No peripherals found for service UUID : \(String(describing: serviceUUID?.uuidString))")
        }

        func peripheralConfigured(peripheral _: CBPeripheral) {}

        func peripheralNotConfigured(peripheral _: CBPeripheral) {
            showError(errorMessage: "Device cannot be configured")
        }

        func peripheralDisconnected(peripheral _: CBPeripheral, error: Error?) {
            showError(errorMessage: "Error in connection : \(String(describing: error))")
        }
    }
#endif

extension ViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return User.shared.associatedDevices?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "deviceListCell", for: indexPath) as! DeviceListTableViewCell
        cell.deviceNameLabel.text = User.shared.associatedDevices![indexPath.section].name
        cell.node = User.shared.associatedDevices![indexPath.section]
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = cell.backView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.backView.insertSubview(blurEffectView, at: 0)
        return cell
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 70.0
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 12.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 12))
        headerView.backgroundColor = UIColor.clear
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let path = Bundle.main.path(forResource: "DeviceDetails", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                User.shared.associatedDevices?[indexPath.section].devices = JSONParser.parseNodeData(data: data)
                let storyboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
                let ivc = storyboard.instantiateViewController(withIdentifier: "devicesVC") as! DevicesViewController
                ivc.currentNode = User.shared.associatedDevices?[indexPath.section]
                navigationController?.pushViewController(ivc, animated: true)

            } catch {
                // handle error
            }
        }
    }
}
