//
//  ControlsViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 13/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

//
//  LightViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 12/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import MBProgressHUD
import UIKit

class ControlListViewController: UIViewController {
    var device: Device?
    var pollingTimer: Timer!

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.title = "Controls"
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")
        tableView.register(UINib(nibName: "GenericSliderTableViewCell", bundle: nil), forCellReuseIdentifier: "GenericSliderTableViewCell")
        tableView.register(UINib(nibName: "StaticControlTableViewCell", bundle: nil), forCellReuseIdentifier: "staticControlTableViewCell")
        titleLabel.text = device?.name ?? "Details"
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UITableView.automaticDimension
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        tableView.contentInset = insets
        showLoader(message: "Getting info")
        updateDeviceAttributes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pollingTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pollingTimer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appEnterForeground() {
        print("foreground")
        pollingTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(fetchNodeInfo), userInfo: nil, repeats: true)
    }

    @objc func appEnterBackground() {
        print("appEnterBackground")
        pollingTimer.invalidate()
    }

    @objc func fetchNodeInfo() {
        updateDeviceAttributes()
    }

    func updateDeviceAttributes() {
        NetworkManager.shared.getDeviceThingShadow(nodeID: (device?.node?.node_id)!) { response in
            if let image = response {
//                if let dynamicParams = self.device?.dynamicParams {
//                    for item in dynamicParams {
//                        if let prop = image[response] {
//
//                        }
//                    }
//                }
                if let deviceName = self.device?.name, let attrbutes = image[deviceName] as? [String: Any] {
                    if let dynamicParams = self.device?.params {
                        for index in dynamicParams.indices {
                            if let reportedValue = attrbutes[dynamicParams[index].name ?? ""] {
                                dynamicParams[index].value = reportedValue
                            }
                        }
                    }
                }
//                if let dynamicParams = self.device?.dynamicParams {
//                    for index in dynamicParams.indices {
//                        if let reportedValue = image[dynamicParams[index].name ?? ""] {
//                            dynamicParams[index].value = reportedValue
//                        }
//                    }
//                }
//                if let staticParams = self.device?.staticParams {
//                    for index in staticParams.indices {
//                        if let reportedValue = image[staticParams[index].name ?? ""] {
//                            staticParams[index].value = reportedValue
//                        }
//                    }
//                }
            }
            Utility.hideLoader(view: self.view)
            self.tableView.reloadData()
        }
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

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    @objc func setBrightness(_: UISlider) {}

    func getTableViewGenericCell(attribute: Params, indexPath: IndexPath) -> GenericControlTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
        cell.controlName.text = attribute.name
        if let value = attribute.value {
            cell.controlValue = "\(value)"
        }
        cell.controlValueLabel.text = cell.controlValue
        if attribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
            cell.editButton.isHidden = false
        } else {
            cell.editButton.isHidden = true
        }
        if let data_type = attribute.dataType {
            cell.dataType = data_type
        }
        cell.device = device
        if let attributeName = attribute.name {
            cell.attributeKey = attributeName
        }
        cell.attribute = attribute
        return cell
    }

    func getTableViewCellBasedOn(dynamicAttribute: Params, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == "esp-ui-slider" {
            if let dataType = dynamicAttribute.dataType?.lowercased(), dataType == "int" || dataType == "float" {
                if let bounds = dynamicAttribute.bounds {
                    let maxValue = bounds["max"] as? Float ?? 100
                    let minValue = bounds["min"] as? Float ?? 0
                    if minValue < maxValue {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "GenericSliderTableViewCell", for: indexPath) as! GenericSliderTableViewCell
                        if let bounds = dynamicAttribute.bounds {
                            cell.slider.minimumValue = bounds["min"] as? Float ?? 0
                            cell.slider.maximumValue = bounds["max"] as? Float ?? 100
                        }
                        if dynamicAttribute.dataType!.lowercased() == "int" {
                            let value = Int(dynamicAttribute.value as? Float ?? 100)
                            cell.minLabel.text = "\(Int(cell.slider.minimumValue))"
                            cell.maxLabel.text = "\(Int(cell.slider.maximumValue))"
                            cell.slider.value = Float(value)
                        } else {
                            cell.minLabel.text = "\(cell.slider.minimumValue)"
                            cell.maxLabel.text = "\(cell.slider.maximumValue)"
                            cell.slider.value = dynamicAttribute.value as? Float ?? 100
                        }
                        cell.device = device
                        cell.dataType = dynamicAttribute.dataType
                        if let attributeName = dynamicAttribute.name {
                            cell.paramName = attributeName
                        }
                        if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
                            cell.slider.isEnabled = true
                        } else {
                            cell.slider.isEnabled = false
                        }
                        cell.title.text = dynamicAttribute.name ?? ""
                        return cell
                    }
                }
            }
        } else if dynamicAttribute.uiType == "esp-ui-toggle", dynamicAttribute.dataType?.lowercased() == "bool" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            cell.controlName.text = dynamicAttribute.name?.deletingPrefix(device!.name!)
            cell.device = device
            if let attributeName = dynamicAttribute.name {
                cell.attributeKey = attributeName
            }
            if let switchState = dynamicAttribute.value as? Bool {
                if switchState {
                    cell.controlStateLabel.text = "On"
                } else {
                    cell.controlStateLabel.text = "Off"
                }
                cell.toggleSwitch.setOn(switchState, animated: true)
            }
            if dynamicAttribute.properties?.contains("write") ?? false, device!.node?.isConnected ?? false {
                cell.toggleSwitch.isEnabled = true
            } else {
                cell.toggleSwitch.isEnabled = false
            }

            return cell
        }

        return getTableViewGenericCell(attribute: dynamicAttribute, indexPath: indexPath)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == Constants.nodeDetailSegue {
            let destination = segue.destination as! NodeDetailsViewController
            if let i = User.shared.associatedNodeList!.firstIndex(where: { $0.node_id == self.device?.node?.node_id }) {
                destination.currentNode = User.shared.associatedNodeList![i]
            }
        }
    }
}

extension ControlListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 40.0
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeaderView = SectionHeaderView.instanceFromNib()
        if section >= device?.params?.count ?? 0 {
            let staticControl = device?.attributes![section - (device?.params?.count ?? 0)]
            sectionHeaderView.sectionTitle.text = staticControl?.name!.deletingPrefix(device!.name!)
        } else {
            let control = device?.params![section]
            sectionHeaderView.sectionTitle.text = control?.name!.deletingPrefix(device!.name!)
        }
        return sectionHeaderView
    }
}

extension ControlListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return (device?.params?.count ?? 0) + (device?.attributes?.count ?? 0)
    }

    func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= device?.params?.count ?? 0 {
            let staticControl = device?.attributes![indexPath.section - (device?.params?.count ?? 0)]
            let cell = tableView.dequeueReusableCell(withIdentifier: "staticControlTableViewCell", for: indexPath) as! StaticControlTableViewCell
            cell.controlNameLabel.text = staticControl?.name ?? ""
            cell.controlValueLabel.text = staticControl?.value as? String ?? ""
            return cell

        } else {
            let control = device?.params![indexPath.section]
            return getTableViewCellBasedOn(dynamicAttribute: control!, indexPath: indexPath)
        }
    }

//    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
}

class SectionHeaderView: UIView {
    @IBOutlet var sectionTitle: UILabel!

    class func instanceFromNib() -> SectionHeaderView {
        return UINib(nibName: "ControlSectionHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SectionHeaderView
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count + 1))
    }
}
