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

    override func viewDidLoad() {
        navigationItem.title = "Devices"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        ssdpDiscovery.delegate = self
        tableView.tableFooterView = UIView()
        tableView.isHidden = true
        Constants.showLoader(message: "Scanning devices", view: view)
        searchLocalDevices()
    }

    @IBAction func scanDevicesAgain(_: Any) {
        retry = 3
        Constants.showLoader(message: "Scanning devices", view: view)
        searchLocalDevices()
    }

    @objc func searchLocalDevices() {
        ssdpDiscovery.discoverService(forDuration: timeInterval, searchTarget: searchTarget)
    }

    func parseResponse(header: String) -> [String: String] {
        var dictionary: [String: String] = [:]
        for item in header.components(separatedBy: "::") {
            let value = item.components(separatedBy: ":")
            dictionary.updateValue(value[1], forKey: value[0])
        }
        return dictionary
    }

    @objc func checkNeedForReDiscovery() {
        if retry != 0 {
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

    func showDeviceDetails(device: AlexaDevice, avsConfig: ConfigureAVS, loginStatus: Bool = false) {
        DispatchQueue.main.async {
            let deviceDetailVC = self.storyboard?.instantiateViewController(withIdentifier: Constants.deviceDetailVCIndentifier) as! DeviceDetailViewController
            deviceDetailVC.avsConfig = avsConfig
            deviceDetailVC.loginStatus = loginStatus
            deviceDetailVC.device = device
            self.navigationController?.pushViewController(deviceDetailVC, animated: true)
        }
    }
}

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
        print(error)
    }

    func ssdpDiscoveryDidStart(_: SSDPDiscovery) {}

    func ssdpDiscoveryDidFinish(_: SSDPDiscovery) {
        performSelector(onMainThread: #selector(checkNeedForReDiscovery), with: nil, waitUntilDone: true)
    }
}

extension ScannedLocalDevicesVC: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60.0
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alexaDevice = alexaDevices[indexPath.row]
        let transport = SoftAPTransport(baseUrl: alexaDevice.hostAddress! + ":80")
        let security = Security0()
        let session = Session(transport: transport, security: security)
        session.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                return
            }
            let avsConfig = ConfigureAVS(session: session)
            avsConfig.isLoggedIn(completionHandler: { status in
                self.showDeviceDetails(device: alexaDevice, avsConfig: avsConfig, loginStatus: status)
            })
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

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
