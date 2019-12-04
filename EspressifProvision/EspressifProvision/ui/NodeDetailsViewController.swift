//
//  NodeDetailsViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 17/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class NodeDetailsViewController: UIViewController {
    var currentNode: Node!
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var nodeIDLabel: UILabel!
    @IBOutlet var configVersionLabel: UILabel!
    @IBOutlet var fwVersionLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceNameLabel.text = currentNode.info?.name ?? ""
        nodeIDLabel.text = currentNode.node_id ?? ""
        configVersionLabel.text = currentNode.config_version ?? ""
        fwVersionLabel.text = currentNode.info?.fw_version ?? ""
        typeLabel.text = currentNode.info?.type ?? ""
        // Do any additional setup after loading the view.
    }

    @IBAction func deleteNode(_: Any) {
        Utility.showLoader(message: "Deleting node", view: view)
        let parameters = ["user_id": User.shared.userID, "node_id": currentNode.node_id!, "secret_key": "", "operation": "remove"]
        NetworkManager.shared.addDeviceToUser(parameter: parameters as! [String: String]) { _, error in
            if error != nil {
                User.shared.associatedNodes.removeValue(forKey: self.currentNode.node_id!)
                User.shared.associatedDevices?.removeAll(where: { device -> Bool in
                    device.node_id == self.currentNode.node_id
                })
            }
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.navigationController?.popViewController(animated: true)
            }
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
}

// extension NodeDetailsViewController: UITableViewDataSource {
//
//
// }
//
// extension NodeDetailsViewController: UITableViewDelegate {
//
// }
