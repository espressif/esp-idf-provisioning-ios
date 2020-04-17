//
//  ClaimViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 10/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class ClaimViewController: UIViewController {
    @IBOutlet var popTextField: UITextField!
    @IBOutlet var headerLabel: UILabel!
    var currentWifiSSID = ""
    var provisionConfig: [String: String] = [:]
    var capabilities: [String]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        headerLabel.text = "Enter your proof of possession PIN for \n" + currentWifiSSID
    }

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        let destination = segue.destination as! ProvisionViewController
        destination.isScanFlow = false
        destination.pop = popTextField.text ?? "abcd1234"
        destination.provisionConfig = provisionConfig
        destination.capabilities = capabilities
    }
}
