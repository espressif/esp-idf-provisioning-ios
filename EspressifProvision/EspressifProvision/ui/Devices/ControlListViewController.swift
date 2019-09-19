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

import UIKit

class ControlListViewController: UIViewController {
    var device: Device?

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.title = "Controls"
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "SliderTableViewCell", bundle: nil), forCellReuseIdentifier: "SliderTableViewCell")
        tableView.register(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
        tableView.register(UINib(nibName: "GenericControlTableViewCell", bundle: nil), forCellReuseIdentifier: "genericControlCell")

        let colors = Colors()
        view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.controlLayer
        backgroundLayer!.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    @objc func setBrightness(_: UISlider) {}

    func getTableViewCellBasedOn(dynamicAttribute: DynamicAttribute, indexPath: IndexPath) -> UITableViewCell {
        if dynamicAttribute.uiType == "esp-ui-slider" || dynamicAttribute.bounds != nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SliderTableViewCell", for: indexPath) as! SliderTableViewCell
            if let bounds = dynamicAttribute.bounds {
                if dynamicAttribute.dataType?.lowercased() == "float" {
                    cell.minLabel.text = "\(bounds["min"] as? Float ?? 0)"
                    cell.maxLabel.text = "\(bounds["max"] as? Float ?? 0)"
                } else if dynamicAttribute.dataType?.lowercased() == "int" {
                    cell.minLabel.text = "\(bounds["min"] as? Int ?? 0)"
                    cell.maxLabel.text = "\(bounds["max"] as? Int ?? 0)"
                }
            }
            return cell
        } else if dynamicAttribute.uiType == "esp-ui-toggle" || dynamicAttribute.dataType?.lowercased() == "bool" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
            cell.controlName.text = dynamicAttribute.name
            cell.controlValue.text = dynamicAttribute.value as? String
            return cell
        }
    }
}

extension ControlListViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 12.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 12))
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
}

extension ControlListViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }

    func numberOfSections(in _: UITableView) -> Int {
        return (device?.dynamicParams?.count ?? 0) + (device?.staticParams?.count ?? 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= device?.dynamicParams?.count ?? 0 {
            let staticControl = device?.staticParams![indexPath.section - (device?.dynamicParams?.count ?? 0)]
            let cell = tableView.dequeueReusableCell(withIdentifier: "genericControlCell", for: indexPath) as! GenericControlTableViewCell
            cell.controlName.text = staticControl?.name
            cell.controlValue.text = staticControl?.value as? String
            return cell
        } else {
            let control = device?.dynamicParams![indexPath.section]
            return getTableViewCellBasedOn(dynamicAttribute: control!, indexPath: indexPath)
        }
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 70.0
    }
}
