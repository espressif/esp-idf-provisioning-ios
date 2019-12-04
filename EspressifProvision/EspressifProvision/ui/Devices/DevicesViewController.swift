//
//  DevicesViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 11/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AWSAuthCore
import AWSCognitoIdentityProvider
import Foundation
import MBProgressHUD
import Reachability
import UIKit

class DevicesViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addButton: UIButton!

//    var currentNode: Node!
    let controlStoryBoard = UIStoryboard(name: "DeviceDetail", bundle: nil)
    private let refreshControl = UIRefreshControl()

    // WIFI
    private let baseUrl = Bundle.main.infoDictionary?["WifiBaseUrl"] as! String
    private let networkNamePrefix = Bundle.main.infoDictionary?["WifiNetworkNamePrefix"] as! String

    var response: AWSCognitoIdentityUserGetDetailsResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var checkDeviceAssociation = false
    var deviceID: String?
    var requestID: String?

    let reachability = try! Reachability()

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 300, right: 0)

        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        if user == nil {
            user = pool?.currentUser()
        }
        if let username = UserDefaults.standard.value(forKey: Constants.usernameKey) as? String {
            User.shared.username = username
        }
        if let userID = UserDefaults.standard.value(forKey: Constants.userIDKey) as? String {
            User.shared.userID = userID
        }

        refresh()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceList), name: Notification.Name(Constants.newDeviceAdded), object: nil)
        refreshControl.addTarget(self, action: #selector(refreshDeviceList), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        collectionView.refreshControl = refreshControl

        navigationItem.title = "Devices"

        let colors = Colors()
        view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.devicesBgLayer
        backgroundLayer!.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
        addButton.layer.masksToBounds = false
        addButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        addButton.layer.shadowRadius = 0.5
        addButton.layer.shadowColor = UIColor.darkGray.cgColor
        addButton.layer.shadowOpacity = 1.0

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
        collectionView.reloadData()
        if User.shared.associatedDevices == nil {
            Utility.showLoader(message: "Fetching Device List", view: view)
            refreshDeviceList()
        }
        if User.shared.updateDeviceList {
            refreshDeviceList()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
    }

    func refresh() {
        user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async {
                self.response = task.result
            }
            return nil
        }
    }

    @objc func refreshDeviceList() {
        if reachability.connection != .unavailable {
            User.shared.updateDeviceList = false
            NetworkManager.shared.getDeviceList { devices, _ in
                Utility.hideLoader(view: self.view)
                self.refreshControl.endRefreshing()
                User.shared.associatedDevices = devices
                self.collectionView.reloadData()
            }
        } else {
            Utility.hideLoader(view: view)
            refreshControl.endRefreshing()
        }
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
            Provision.CONFIG_BASE_URL_KEY: baseUrl,
            Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
        ]
        Provision.showProvisioningUI(on: self, config: config)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "scanQRCode" {
            if let scannerVC = segue.destination as? ScannerViewController {
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
                    Provision.CONFIG_BASE_URL_KEY: baseUrl,
                    Provision.CONFIG_WIFI_AP_KEY: networkNamePrefix,
                ]
                scannerVC.provisionConfig = config
            }
        }
    }
}

extension DevicesViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentDevice = User.shared.associatedDevices?[indexPath.row]
        let controlListVC = controlStoryBoard.instantiateViewController(withIdentifier: "controlListVC") as! ControlListViewController
        controlListVC.device = currentDevice
        navigationController?.pushViewController(controlListVC, animated: true)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return User.shared.associatedDevices?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceCollectionViewCell", for: indexPath) as! DevicesCollectionViewCell
        cell.deviceName.text = User.shared.associatedDevices?[indexPath.row].name
        if User.shared.associatedDevices?[indexPath.row].type == "esp.device.lightbulb" {
            cell.deviceImageView.image = UIImage(named: "light_bulb")
        } else if User.shared.associatedDevices?[indexPath.row].type == "esp.device.switch" {
            cell.deviceImageView.image = UIImage(named: "switch")
        } else {
            cell.deviceImageView.image = UIImage(named: "generic_device")
        }
        cell.infoButtonAction = { [unowned self] in
            let storyboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
            let nodeDetailVC = storyboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
            if let currentDevice = User.shared.associatedDevices?[indexPath.row], let node = User.shared.associatedNodes[currentDevice.node_id!] {
                nodeDetailVC.currentNode = node
                self.navigationController?.pushViewController(nodeDetailVC, animated: true)
            }
        }
        return cell
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: 125.0, height: 125.0)
    }
}
