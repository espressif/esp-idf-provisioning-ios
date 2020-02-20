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
//  LoginWithAmazonViewController.swift
//  EspressifProvision
//

import Foundation
import UIKit

class LoginWithAmazonViewController: UIViewController {
    var provisionConfig: [String: String] = [:]
    var transport: Transport?
    var security: Security?
    var session: Session?
    var configureAvs: ConfigureAVS?
    var waiter: Bool?
    var deviceDetails: [String] = ["", "", ""]
    var deviceName: String?
    var capabilities: [String]?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.title = deviceName ?? ""

        // Add skip button
        let rightBarButton = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(skipAction))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Initiate session to pass data with device
        Constants.showLoader(message: "", view: view)
        initialiseSession()
    }

    @objc func skipAction() {
        navigateToProvisionVC(result: nil)
    }

    @IBAction func onAmazonLoginClicked(_: Any) {
        Constants.showLoader(message: "Signing in", view: view)

        do {
            getDeviceDetails(tras: transport!, secu: security!) { _ in
                self.callLWA()
            }
        }
    }

    private func getDeviceDetails(tras _: Transport,
                                  secu _: Security,
                                  completionHandler: @escaping (String) -> Swift.Void) {
        let prov = Provision(session: session!)
        deviceDetails = prov.getAVSDeviceDetails(completionHandler: { _, error in
            guard error == nil else {
                print(error!)

                return
            }

            completionHandler("nil")
        })
        return
    }

    private func initialiseSession() {
        DispatchQueue.main.async {
            let input = UIAlertController(title: "Proof of Possession", message: nil, preferredStyle: .alert)

            input.addTextField { textField in
                textField.text = "abcd1234"
            }
            input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
                self.transport?.disconnect()
                self.navigationController?.popViewController(animated: true)
            }))
            input.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak input] _ in
                let textField = input?.textFields![0]
                Utility.pop = textField?.text ?? ""
                self.security = Security1(proofOfPossession: Utility.pop ?? "")
                Constants.hideLoader(view: self.view)
                self.initSession()
            }))
            self.present(input, animated: true, completion: nil)
        }
    }

    func initSession() {
        Constants.showLoader(message: "Initiating Session", view: view)
        session = Session(transport: transport!,
                          security: security!)
        session!.initialize(response: nil) { error in
            DispatchQueue.main.async {
                Constants.hideLoader(view: self.view)
            }
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                self.showStatusScreen()
                return
            }
        }
    }

    func showStatusScreen() {
        DispatchQueue.main.async {
            let statusVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as! StatusViewController
            statusVC.statusText = "Error establishing session.\n Check if Proof of Possession(POP) is correct!"
            self.navigationController?.present(statusVC, animated: true, completion: nil)
        }
    }

    private func navigateToProvisionVC(result: [String: String]?) {
        var config = provisionConfig
        if let results = result {
            results.forEach { config[$0] = $1 }
        }
        DispatchQueue.main.async {
            let transportVersion = config[Provision.CONFIG_TRANSPORT_KEY]
            if let transportVersion = transportVersion, transportVersion == Provision.CONFIG_TRANSPORT_BLE {
                let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
                provisionVC.provisionConfig = config
                provisionVC.avsDetails = result
                provisionVC.transport = self.transport
                provisionVC.security = self.security!
                provisionVC.session = self.session!
                self.navigationController?.pushViewController(provisionVC, animated: true)
            } else {
                let provisionLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "provisionLanding") as! ProvisionLandingViewController
                provisionLandingVC.provisionConfig = config
                self.navigationController?.pushViewController(provisionLandingVC, animated: true)
            }
        }
    }

    public func callLWA() {
        DispatchQueue.main.async {
            ConfigureAVS.loginWithAmazon { results, error in
                Constants.hideLoader(view: self.view)
                if error != nil {
                    print(error.debugDescription)
                } else if let results = results {
                    self.waiter = true
                    self.navigateToProvisionVC(result: results)
                }
            }
        }
    }
}
