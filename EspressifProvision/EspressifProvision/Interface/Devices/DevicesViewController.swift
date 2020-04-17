//
//  DevicesViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 11/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import AWSAuthCore
import AWSCognitoIdentityProvider
import Foundation
import JWTDecode
import MBProgressHUD
import Reachability
import UIKit

class DevicesViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var initialView: UIView!
    @IBOutlet var pickerView: UIView!
    @IBOutlet var emptyListIcon: UIImageView!
    @IBOutlet var infoLabel: UILabel!

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
    var flag = false

    let reachability = try! Reachability()

    override func viewDidLoad() {
        super.viewDidLoad()

        pickerView.layer.cornerRadius = 10.0
        pickerView.layer.borderWidth = 1.0
        pickerView.layer.borderColor = UIColor(hexString: "#F2F1FC").cgColor
        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
        if user == nil {
            user = pool?.currentUser()
        }
        if let userInfo = UserDefaults.standard.value(forKey: Constants.userInfoKey) as? [String: Any] {
            Utility.showLoader(message: "Fetching Device List", view: view)
            refreshDeviceList()
        } else {
            refresh()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refreshDeviceList), name: Notification.Name(Constants.newDeviceAdded), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
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
        singleDeviceNodeCount = 0
        if let nodeList = User.shared.associatedNodeList {
            for item in nodeList {
                if item.devices?.count == 1 {
                    singleDeviceNodeCount += 1
                }
            }
        }
        collectionView.reloadData()
        if User.shared.updateUserInfo {
            Utility.showLoader(message: "Fetching Device List", view: view)
            User.shared.updateUserInfo = false
            User.shared.getcognitoIdToken { idToken in
                if idToken != nil {
                    self.getUserInfo(token: idToken!, provider: .cognito)
                } else {
                    Utility.hideLoader(view: self.view)
                }
            }
        } else if User.shared.updateDeviceList {
            Utility.showLoader(message: "Fetching Device List", view: view)
            refreshDeviceList()
        }
        if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
            initialView.isHidden = false
            collectionView.isHidden = true
            addButton.isHidden = true
        }
        flag = false
    }

    func getUserInfo(token: String, provider: ServiceProvider) {
        do {
            let json = try decode(jwt: token)
            User.shared.userInfo.username = json.body["cognito:username"] as? String ?? ""
            User.shared.userInfo.email = json.body["email"] as? String ?? ""
            User.shared.userInfo.userID = json.body["custom:user_id"] as? String ?? ""
            User.shared.userInfo.loggedInWith = provider
            User.shared.userInfo.saveUserInfo()
        } catch {
            print("error parsing token")
        }
        refreshDeviceList()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
        pickerView.isHidden = true
        addButton.setImage(UIImage(named: "add_icon"), for: .normal)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc func appEnterForeground() {
        Utility.showLoader(message: "Fetching Device List", view: view)
        refreshDeviceList()
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
        if Utility.isConnected(view: view) {
            Utility.showLoader(message: "Fetching Device List", view: view)
            refreshDeviceList()
        }
    }

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
        }
    }

    @objc func refreshDeviceList() {
        if Utility.isConnected(view: view) {
            collectionView.isUserInteractionEnabled = false
            User.shared.updateDeviceList = false
            NetworkManager.shared.getNodes { nodes, error in
                Utility.hideLoader(view: self.view)
                self.refreshControl.endRefreshing()
                if error != nil {
                    self.unhideInitialView(error: error)
                    return
                }
                User.shared.associatedNodeList = nodes
                if nodes == nil || nodes?.count == 0 {
                    self.unhideInitialView(error: nil)
                } else {
                    self.initialView.isHidden = true
                    self.collectionView.isHidden = false
                    self.addButton.isHidden = false
                    self.singleDeviceNodeCount = 0
                    for item in User.shared.associatedNodeList! {
                        if item.devices?.count == 1 {
                            self.singleDeviceNodeCount += 1
                        }
                    }
                    self.collectionView.reloadData()
                }
                self.collectionView.isUserInteractionEnabled = true
            }
        } else {
            Utility.hideLoader(view: view)
            refreshControl.endRefreshing()
            if User.shared.associatedNodeList?.count == 0 || User.shared.associatedNodeList == nil {
                initialView.isHidden = false
                collectionView.isHidden = true
                addButton.isHidden = true
            }
        }
    }

    func unhideInitialView(error: ESPNetworkError?) {
        DispatchQueue.main.async {
            if error == nil {
                self.infoLabel.text = "No Device Added"
                self.emptyListIcon.image = UIImage(named: "no_device_icon")
                self.infoLabel.textColor = .black
            } else {
                self.infoLabel.text = "No devices to show\n" + (error?.description ?? "Something went wrong!!")
                self.emptyListIcon.image = UIImage(named: "api_error_icon")
                self.infoLabel.textColor = .red
            }
            self.initialView.isHidden = false
            self.collectionView.isHidden = true
            self.addButton.isHidden = true
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
                return User.shared.associatedNodeList![indexPath.row].devices![0]
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
        if flag {
            return
        }
        flag = true
        Utility.showLoader(message: "", view: view)
        let currentDevice = getDeviceAt(indexPath: indexPath)
        let currentNode = getNodeAt(indexPath: indexPath)
        let deviceTraitsVC = controlStoryBoard.instantiateViewController(withIdentifier: Constants.deviceTraitListVCIdentifier) as! DeviceTraitListViewController
        deviceTraitsVC.device = currentDevice

        Utility.hideLoader(view: view)
        navigationController?.pushViewController(deviceTraitsVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0, singleDeviceNodeCount > 0 {
            return CGSize(width: 0, height: 68.0)
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
        cell.refresh()
        var device = getDeviceAt(indexPath: indexPath)
        cell.deviceName.text = device.getDeviceName()
        cell.device = device
        cell.switchButton.isHidden = true
        cell.primaryValue.isHidden = true

        cell.layer.backgroundColor = UIColor.white.cgColor
        cell.layer.shadowColor = UIColor.lightGray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0.5, height: 1.0)
        cell.layer.shadowRadius = 0.5
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false

        if device.node?.isConnected ?? false {
            cell.statusView.isHidden = true
        } else {
            cell.statusView.isHidden = false
            cell.offlineLabel.text = "Offline at " + (device.node?.timestamp.getShortDate() ?? "")
        }

        var primaryKeyFound = false

        if let primary = device.primary {
            if let primaryParam = device.params?.first(where: { param -> Bool in
                param.name == primary
            }) {
                primaryKeyFound = true
                if primaryParam.dataType?.lowercased() == "bool" {
                    if device.node?.isConnected ?? false, primaryParam.properties?.contains("write") ?? false {
                        cell.switchButton.alpha = 1.0
                        cell.switchButton.backgroundColor = UIColor.white
                        cell.switchButton.isEnabled = true
                        cell.switchButton.isHidden = false
                        cell.switchButton.setImage(UIImage(named: "switch_icon_enabled_off"), for: .normal)
                        if let value = primaryParam.value as? Bool {
                            if value {
                                cell.switchButton.setImage(UIImage(named: "switch_icon_enabled_on"), for: .normal)
                                cell.switchValue = true
                            }
                        }
                    } else {
                        cell.switchButton.isHidden = false
                        cell.switchButton.isEnabled = false
                        cell.switchButton.backgroundColor = UIColor(hexString: "#E5E5E5")
                        cell.switchButton.alpha = 0.4
                        cell.switchButton.setImage(UIImage(named: "switch_icon_disabled"), for: .normal)
                    }
                } else if primaryParam.dataType?.lowercased() == "string" {
                    cell.switchButton.isHidden = true
                    cell.primaryValue.text = primaryParam.value as? String ?? ""
                    cell.primaryValue.isHidden = false
                } else {
                    cell.switchButton.isHidden = true
                    if let value = primaryParam.value {
                        cell.primaryValue.text = "\(value)"
                        cell.primaryValue.isHidden = false
                    }
                }
            }
            if !primaryKeyFound {
                if let staticParams = device.attributes {
                    for item in staticParams {
                        if item.name == primary {
                            if let value = item.value as? String {
                                primaryKeyFound = true
                                cell.primaryValue.text = value
                                cell.primaryValue.isHidden = false
                            }
                        }
                    }
                }
            }
        }

        if let deviceType = device.type {
            var deviceImage: UIImage!
            switch deviceType {
            case "esp.device.switch":
                deviceImage = UIImage(named: "switch_device_icon")
            case "esp.device.lightbulb":
                deviceImage = UIImage(named: "light_bulb_icon")
            case "esp.device.fan":
                deviceImage = UIImage(named: "fan_icon")
            case "esp.device.thermostat":
                deviceImage = UIImage(named: "thermostat_icon")
            case "esp.device.temperature-sensor":
                deviceImage = UIImage(named: "temperature_sensor_icon")
            case "esp.device.lock":
                deviceImage = UIImage(named: "lock_icon")
            case "esp.device.sensor":
                deviceImage = UIImage(named: "sensor_icon")
            default:
                deviceImage = UIImage(named: "dummy_device_icon")
            }
            cell.deviceImageView.image = deviceImage
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "deviceListCollectionReusableView", for: indexPath) as! DeviceListCollectionReusableView
        let node = getNodeAt(indexPath: indexPath)
        if singleDeviceNodeCount > 0 {
            if indexPath.section == 0 {
                headerView.headerLabel.isHidden = true
                headerView.infoButton.isHidden = true
                headerView.statusIndicator.isHidden = true
                return headerView
            }
        }
        headerView.headerLabel.isHidden = false
        headerView.infoButton.isHidden = false
        headerView.statusIndicator.isHidden = false
        headerView.headerLabel.text = node.info?.name ?? "Node"
        headerView.delegate = self
        headerView.nodeID = node.node_id ?? ""
        if node.isConnected {
            headerView.statusIndicator.backgroundColor = UIColor.green
        } else {
            headerView.statusIndicator.backgroundColor = UIColor.lightGray
        }
        return headerView
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        var cellWidth: CGFloat = 0
        if width > 450 {
            cellWidth = (width - 60) / 3.0
        } else {
            cellWidth = (width - 30) / 2.0
        }
        return CGSize(width: cellWidth, height: 110.0)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        if UIScreen.main.bounds.width > 450 {
            return 15.0
        }
        return 10.0
    }
}

extension DevicesViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func popoverPresentationControllerDidDismissPopover(_: UIPopoverPresentationController) {}

    func popoverPresentationControllerShouldDismissPopover(_: UIPopoverPresentationController) -> Bool {
        return false
    }
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

class Colors {
    var gl: CAGradientLayer!

    init() {
        let colorTop = UIColor.clear.cgColor
        let colorBottom = UIColor.black.cgColor

        gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.0, 1.0]
    }
}

@IBDesignable
class GradientView: UIView {
    @IBInspectable var firstColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }

    @IBInspectable var secondColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }

    @IBInspectable var isHorizontal: Bool = true {
        didSet {
            updateView()
        }
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    func updateView() {
        let layer = self.layer as! CAGradientLayer
        layer.colors = [firstColor, secondColor].map { $0.cgColor }
        if isHorizontal {
            layer.startPoint = CGPoint(x: 0, y: 0.5)
            layer.endPoint = CGPoint(x: 1, y: 0.5)
        } else {
            layer.startPoint = CGPoint(x: 0.75, y: 0)
            layer.endPoint = CGPoint(x: 0.75, y: 1)
        }
    }
}
