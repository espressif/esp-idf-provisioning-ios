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
    @IBOutlet var initialView: UIView!
    @IBOutlet var pickerView: UIView!

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
    var singleDeviceNodeCount = 0

    let reachability = try! Reachability()

    override func viewDidLoad() {
        super.viewDidLoad()

        pickerView.layer.cornerRadius = 10.0
        pickerView.layer.borderWidth = 1.0
        pickerView.layer.borderColor = UIColor(hexString: "#F2F1FC").cgColor
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
//        collectionView.collectionViewLayout = DeviceCollectionViewLayout()
        if user == nil {
            user = pool?.currentUser()
        }
        if let username = UserDefaults.standard.value(forKey: Constants.usernameKey) as? String {
            User.shared.username = username
        }
        if let userID = UserDefaults.standard.value(forKey: Constants.userIDKey) as? String {
            User.shared.userID = userID
        }

        if (UserDefaults.standard.value(forKey: Constants.loginIdKey) as? String) == nil {
            refresh()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceList), name: Notification.Name(Constants.newDeviceAdded), object: nil)
        refreshControl.addTarget(self, action: #selector(refreshDeviceList), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        collectionView.refreshControl = refreshControl
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
        collectionView.reloadData()
        if User.shared.associatedNodeList == nil {
            Utility.showLoader(message: "Fetching Device List", view: view)
            refreshDeviceList()
        }
        if User.shared.updateDeviceList {
            refreshDeviceList()
        }
        if User.shared.associatedNodeList?.count == 0 {
            initialView.isHidden = false
            collectionView.isHidden = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
        pickerView.isHidden = true
        addButton.setImage(UIImage(named: "add_icon"), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    func refresh() {
        user?.getDetails().continueOnSuccessWith { (task) -> AnyObject? in
            DispatchQueue.main.async {
                self.response = task.result
            }
            return nil
        }
    }

    @IBAction func refreshClicked(_: Any) {
        Utility.showLoader(message: "Fetching Device List", view: view)
        refreshDeviceList()
    }

    @objc func refreshDeviceList() {
        if reachability.connection != .unavailable {
            User.shared.updateDeviceList = false
            NetworkManager.shared.getNodeList { nodes, _ in
                Utility.hideLoader(view: self.view)
                self.refreshControl.endRefreshing()
//                let device1 = Device(name: "Light Bulb1", type: "switch", node_id: "Test 1", staticParams: nil, dynamicParams: nil)
//                let device2 = Device(name: "Light Bulb2", type: "switch", node_id: "Test 2", staticParams: nil, dynamicParams: nil)
//                let device3 = Device(name: "Light Bulb3", type: "switch", node_id: "Test 3", staticParams: nil, dynamicParams: nil)
//                let node1 = Node(node_id: "Test 1", config_version: "1.0", info: nil, devices: [device1], attributes: nil)
//                let node2 = Node(node_id: "Test 2", config_version: "1.0", info: nil, devices: [device2], attributes: nil)
//                let node3 = Node(node_id: "Test 3", config_version: "1.0", info: nil, devices: [device1, device2, device3], attributes: nil)
//                let node4 = Node(node_id: "Test 4", config_version: "1.0", info: nil, devices: [device1, device2, device3, device1, device2], attributes: nil)
//                User.shared.associatedNodeList = [node1, node2, node3, node4]
                User.shared.associatedNodeList = nodes
                if nodes == nil || nodes?.count == 0 {
                    self.initialView.isHidden = false
                    self.collectionView.isHidden = true
                } else {
                    self.initialView.isHidden = true
                    self.collectionView.isHidden = false
                    self.singleDeviceNodeCount = 0
                    for item in User.shared.associatedNodeList! {
                        if item.devices?.count == 1 {
                            self.singleDeviceNodeCount += 1
                        }
                    }
                    self.collectionView.reloadData()
                }
            }
        } else {
            Utility.hideLoader(view: view)
            refreshControl.endRefreshing()
        }
    }

    @IBAction func addButtonClicked(_: Any) {
//        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        actionSheet.addAction(UIAlertAction(title: "Add using QR code", style: .default, handler: nil))
//        actionSheet.addAction(UIAlertAction(title: "Add manually", style: .default, handler: nil))
//        let popover = actionSheet.popoverPresentationController
//        popover?.sourceView = addButton
//        present(actionSheet, animated: false, completion: nil)
        if pickerView.isHidden {
            pickerView.isHidden = false
            addButton.setImage(UIImage(named: "cross_icon"), for: .normal)
        } else {
            pickerView.isHidden = true
            addButton.setImage(UIImage(named: "add_icon"), for: .normal)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
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
        } else if segue.identifier == "popoverMenu" {
            preparePopover(contentController: segue.destination, sender: sender as! UIView, delegate: self)
        }
    }

    func preparePopover(contentController: UIViewController,
                        sender: UIView,
                        delegate: UIPopoverPresentationControllerDelegate?) {
        contentController.modalPresentationStyle = .popover
        contentController.popoverPresentationController!.sourceView = sender
        contentController.popoverPresentationController!.sourceRect = sender.bounds
        contentController.preferredContentSize = CGSize(width: 182.0, height: 112.0)
        contentController.popoverPresentationController!.delegate = delegate
    }

    func getDeviceAt(indexPath: IndexPath) -> Device {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return User.shared.associatedNodeList![indexPath.section].devices![0]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index].devices![indexPath.row]
    }

    func getNodeAt(indexPath: IndexPath) -> Node {
        var index = indexPath.section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return User.shared.associatedNodeList![indexPath.section]
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index]
    }
}

extension DevicesViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentDevice = getDeviceAt(indexPath: indexPath)
        let controlListVC = controlStoryBoard.instantiateViewController(withIdentifier: "controlListVC") as! ControlListViewController
        controlListVC.device = currentDevice
        navigationController?.pushViewController(controlListVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0, singleDeviceNodeCount > 0 {
            return CGSize(width: 0, height: 0)
        }
        return CGSize(width: collectionView.bounds.width, height: 68.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var index = section
        if singleDeviceNodeCount > 0 {
            if index == 0 {
                return singleDeviceNodeCount
            }
            index = index + singleDeviceNodeCount - 1
        }
        return User.shared.associatedNodeList![index].devices?.count ?? 0
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        var count = User.shared.associatedNodeList?.count ?? 0
        if count == 0 {
            return count
        }
        if singleDeviceNodeCount > 0 {
            return count - singleDeviceNodeCount + 1
        }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceCollectionViewCell", for: indexPath) as! DevicesCollectionViewCell
        cell.deviceName.text = getDeviceAt(indexPath: indexPath).name

        cell.layer.backgroundColor = UIColor.white.cgColor
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 1.0, height: 2.0)
        cell.layer.shadowRadius = 1.0
        cell.layer.shadowOpacity = 1.0
        cell.layer.masksToBounds = false
//        if indexPath.row == 1 {
//            cell.switchButton.isHidden = true
//        }
//        if indexPath.row == 2 {
//            cell.switchButton.isHidden = true
//            cell.statusLabel.isHidden = true
//        }
//        if indexPath.row == 3 {
//            cell.statusLabel.isHidden = true
//            cell.switchButton.backgroundColor = UIColor.lightGray
//        }
//        if indexPath.row == 4 {
//            cell.switchButton.isHidden = true
//            cell.tempLabel.isHidden = false
//            cell.deviceImageView.image = UIImage(named: "thermo_test")
//            cell.statusLabel.isHidden = true
//        }
//        if indexPath.row == 5 {
//            cell.deviceImageView.image = UIImage(named: "bulb_test_1")
//        }
//        cell.layer.cornerRadius = 14.0
//        cell.layer.borderWidth = 2.0
//        cell.layer.borderColor = UIColor(hexString: "#8181A8").cgColor
//        if User.shared.associatedDevices?[indexPath.row].type == "esp.device.lightbulb" {
//            cell.deviceImageView.image = UIImage(named: "light_bulb")
//        } else if User.shared.associatedDevices?[indexPath.row].type == "esp.device.switch" {
//            cell.deviceImageView.image = UIImage(named: "switch")
//        } else {
//            cell.deviceImageView.image = UIImage(named: "generic_device")
//        }
//        cell.infoButtonAction = { [unowned self] in
//            let storyboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
//            let nodeDetailVC = storyboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
//            if let currentDevice = User.shared.associatedDevices?[indexPath.row], let node = User.shared.associatedNodes[currentDevice.node_id!] {
//                nodeDetailVC.currentNode = node
//                self.navigationController?.pushViewController(nodeDetailVC, animated: true)
//            }
//        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "deviceListCollectionReusableView", for: indexPath) as! DeviceListCollectionReusableView
        headerView.headerLabel.text = getNodeAt(indexPath: indexPath).info?.name ?? "Node"
        headerView.delegate = self
        headerView.nodeID = getNodeAt(indexPath: indexPath).node_id ?? ""
        return headerView
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 30) / 2.0
        return CGSize(width: width, height: width * (2 / 4))
    }
}

extension DevicesViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_: UIPopoverPresentationController) {}
}

extension DevicesViewController: DeviceListHeaderProtocol {
    func deviceInfoClicked(nodeID: String) {
        if let node = User.shared.associatedNodeList?.first(where: { item -> Bool in
            item.node_id == nodeID
        }) {
            let deviceStoryboard = UIStoryboard(name: "DeviceDetail", bundle: nil)
            let destination = deviceStoryboard.instantiateViewController(withIdentifier: "nodeDetailsVC") as! NodeDetailsViewController
            destination.currentNode = node
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}
