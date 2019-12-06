//
//  ScanLocalDevices.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 27/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import MBProgressHUD
import UIKit

class ScannedLocalDevicesVC: UIViewController {
    @IBOutlet var tableView: UITableView!

    let ssdpDiscovery = SSDPDiscovery()
    var timeInterval: Double = 3
    var retry = 3
    var searchTarget = "urn:schemas-espressif-com:service:Alexa:1"
    var alexaDevices: [AlexaDevice] = []
    var configureDevice: ConfigureDevice!
    var session: Session!

    override func viewDidLoad() {
        // Clearing navigation bar back button text
        navigationItem.title = "Devices"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Assigning delegates
        ssdpDiscovery.delegate = self
        tableView.tableFooterView = UIView()
        tableView.isHidden = true

        // Start SSDP discovery for local devices
        Constants.showLoader(message: "Scanning devices", view: view)
        searchLocalDevices()
    }

    /*
     Method to refresh local devices list
     */
    @IBAction func scanDevicesAgain(_: Any) {
        retry = 3
        Constants.showLoader(message: "Scanning devices", view: view)
        searchLocalDevices()
    }

    /*
     Search for local devices using ssdp class
     */
    @objc func searchLocalDevices() {
        ssdpDiscovery.discoverService(forDuration: timeInterval, searchTarget: searchTarget)
    }

    /*
     Check if search for devices should be retried based on number of devices returned
     */
    @objc func checkNeedForReDiscovery() {
        if retry > 0 {
            if alexaDevices.filter({ $0.friendlyname == nil }).count > 0 {
                retry -= 1
                searchLocalDevices()
            } else {
                ssdpDiscovery.stop()
                alexaDevices = alexaDevices.filter { $0.friendlyname != nil }
                MBProgressHUD.hide(for: view, animated: true)
                tableView.isHidden = false
                tableView.reloadData()
            }
        } else {
            alexaDevices = alexaDevices.filter { $0.friendlyname != nil }
            MBProgressHUD.hide(for: view, animated: true)
            tableView.isHidden = false
            tableView.reloadData()
        }
    }

    func parseResponse(header: String) -> [String: String] {
        var dictionary: [String: String] = [:]
        for item in header.components(separatedBy: "::") {
            let value = item.components(separatedBy: ":")
            dictionary.updateValue(value[1], forKey: value[0])
        }
        return dictionary
    }

    /*
     On click of any device, device info will fetched. This will present us with a new screen where all the details of the device will
     be displayed
     */
    func showDeviceDetails(device: AlexaDevice, avsConfig: ConfigureAVS, loginStatus: Bool = false) {
        DispatchQueue.main.async {
            let deviceDetailVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.deviceDetailVCIndentifier) as! DeviceDetailViewController
            deviceDetailVC.avsConfig = avsConfig
            deviceDetailVC.loginStatus = loginStatus
            deviceDetailVC.device = device
            deviceDetailVC.session = self.session
            self.navigationController?.pushViewController(deviceDetailVC, animated: true)
        }
    }
}

// MARK: SSDPDiscoveryDelegate

extension ScannedLocalDevicesVC: SSDPDiscoveryDelegate {
    func ssdpDiscovery(_: SSDPDiscovery, didDiscoverService service: SSDPService) {
        let dictionary = parseResponse(header: service.uniqueServiceName ?? "")
        if dictionary.keys.contains(Constants.UUIDKey) {
            let uuid = dictionary[Constants.UUIDKey]
            let newDevice = AlexaDevice(hostAddr: service.host)
            newDevice.uuid = uuid
            let stDictionary = parseResponse(header: service.searchTarget ?? "")
            if stDictionary.keys.contains(Constants.friendlynameKey) {
                if let found = alexaDevices.firstIndex(where: { $0.uuid == uuid }) {
                    alexaDevices.remove(at: found)
                }
                newDevice.friendlyname = stDictionary[Constants.friendlynameKey]
                alexaDevices.append(newDevice)
            } else {
                if !alexaDevices.contains(where: { $0.uuid == uuid }) {
                    alexaDevices.append(newDevice)
                }
            }
        }
    }

    func ssdpDiscovery(_: SSDPDiscovery, didFinishWithError error: Error) {
        retry = -1
        print(error)
    }

    func ssdpDiscoveryDidStart(_: SSDPDiscovery) {}

    func ssdpDiscoveryDidFinish(_: SSDPDiscovery) {
        performSelector(onMainThread: #selector(checkNeedForReDiscovery), with: nil, waitUntilDone: true)
    }
}

// MARK: UITableViewDelegate

extension ScannedLocalDevicesVC: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        Constants.showLoader(message: "Getting device info", view: view)
        let alexaDevice = alexaDevices[indexPath.row]
        let transport = SoftAPTransport(baseUrl: alexaDevice.hostAddress! + ":80")
        let security = Security0()
        session = Session(transport: transport, security: security)
        session.initialize(response: nil) { error in
            guard error == nil else {
                Constants.hideLoader(view: self.view)
                print("Error in establishing session \(error.debugDescription)")
                return
            }
            self.configureDevice = ConfigureDevice(session: self.session, device: alexaDevice)
            self.configureDevice.delegate = self
            self.configureDevice.getDeviceInfo()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: UITableViewDataSource

extension ScannedLocalDevicesVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.deviceListCellReuseIdentifier, for: indexPath) as! BLEDeviceListViewCell
        cell.deviceName.text = alexaDevices[indexPath.row].friendlyname ?? ""
        return cell
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return alexaDevices.count
    }
}

// MARK: GetDeviceInfoDelegate

extension ScannedLocalDevicesVC: GetDeviceInfoDelegate {
    func deviceInfoFetched(alexaDevice: AlexaDevice?) {
        DispatchQueue.main.async {
            Constants.hideLoader(view: self.view)
            if alexaDevice != nil {
                let deviceSettingVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.deviceSettingVCIndentifier) as! DeviceSettingViewController
                deviceSettingVC.configureDevice = self.configureDevice
                deviceSettingVC.session = self.session
                self.navigationController?.pushViewController(deviceSettingVC, animated: true)
            } else {
                let avsConfig = ConfigureAVS(session: self.session)
                avsConfig.isLoggedIn(completionHandler: { status in
                    self.showDeviceDetails(device: self.configureDevice.alexaDevice, avsConfig: avsConfig, loginStatus: status)
                })
            }
        }
    }
}
