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
//  ProvisionViewController.swift
//  EspressifProvision
//

import CoreBluetooth
import Foundation
import UIKit

class ProvisionViewController: UIViewController {
    @IBOutlet var passphraseTextfield: UITextField!
    @IBOutlet var ssidTextfield: UITextField!
    @IBOutlet var provisionButton: UIButton!

    var provisionConfig: [String: String] = [:]
    var transport: Transport?
    var security: Security?
    var bleTransport: BLETransport?
    var activityView: UIActivityIndicatorView?
    var grayView: UIView?
    var avsDetails: [String: String]?
    var provision: Provision!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        passphraseTextfield.addTarget(self, action: #selector(passphraseEntered), for: .editingDidEndOnExit)
        ssidTextfield.addTarget(self, action: #selector(ssidEntered), for: .editingDidEndOnExit)
        provisionButton.isUserInteractionEnabled = false
        if let bleTransport = transport as? BLETransport {
            print("Inside PVC", bleTransport.currentPeripheral!)
        }
        getWifiScanList()
    }

    func getWifiScanList() {
        let pop = provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY]
        let securityVersion = provisionConfig[Provision.CONFIG_SECURITY_KEY]
        if securityVersion == Provision.CONFIG_SECURITY_SECURITY1 {
            security = Security1(proofOfPossession: pop!)
        } else {
            security = Security0()
        }

        if transport != nil {
            // transport is BLETransport set from BLELandingVC
            if let bleTransport = transport as? BLETransport {
                bleTransport.delegate = self
            }
        }

        let newSession = Session(transport: transport!,
                                 security: security!)

        newSession.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                return
            }

            self.provision = Provision(session: newSession)

            self.provision.startWifiScan(completionHandler: { response, error in
                guard error == nil, response != nil else {
                    print(error)
                    return
                }
                do {
                    let payload = try Espressif_WiFiScanPayload(serializedData: response!)
                    let responseList = payload.respScanResult
                    var result: [String] = []
                    for index in 0 ... responseList.entries.count {
                        result.append(String(decoding: responseList.entries[index].ssid, as: UTF8.self))
                    }
                    print(result)
                } catch {}
            })
        }
    }

    private func showBusy(isBusy: Bool) {
        if isBusy {
            grayView = UIView(frame: UIScreen.main.bounds)
            grayView?.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
            view.addSubview(grayView!)

            activityView = UIActivityIndicatorView(style: .gray)
            activityView?.center = view.center
            activityView?.startAnimating()

            view.addSubview(activityView!)
        } else {
            grayView?.removeFromSuperview()
            activityView?.removeFromSuperview()
        }

        provisionButton.isUserInteractionEnabled = !isBusy
    }

    private func provisionDevice() {
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            ssid.count > 0, passphrase.count > 0 else {
            return
        }

        showBusy(isBusy: true)

        let pop = provisionConfig[Provision.CONFIG_PROOF_OF_POSSESSION_KEY]
        let baseUrl = provisionConfig[Provision.CONFIG_BASE_URL_KEY]
        let transportVersion = provisionConfig[Provision.CONFIG_TRANSPORT_KEY]
        let securityVersion = provisionConfig[Provision.CONFIG_SECURITY_KEY]
        let bleDeviceNamePrefix = provisionConfig[Provision.CONFIG_BLE_DEVICE_NAME_PREFIX]
        let bleServiceUuid = provisionConfig[Provision.CONFIG_BLE_SERVICE_UUID]
        let bleSessionUuid = provisionConfig[Provision.CONFIG_BLE_SESSION_UUID]
        let bleConfigUuid = provisionConfig[Provision.CONFIG_BLE_CONFIG_UUID]

        if securityVersion == Provision.CONFIG_SECURITY_SECURITY1 {
            security = Security1(proofOfPossession: pop!)
        } else {
            security = Security0()
        }

        if transport != nil {
            // transport is BLETransport set from BLELandingVC
            if let bleTransport = transport as? BLETransport {
                bleTransport.delegate = self
            }

            initialiseSessionAndConfigure(transport: transport!,
                                          security: security!)
        } else if transportVersion == Provision.CONFIG_TRANSPORT_WIFI {
            transport = SoftAPTransport(baseUrl: baseUrl!)
            initialiseSessionAndConfigure(transport: transport!,
                                          security: security!)
        } else if transport == nil {
            let configUUIDMap: [String: String] = [Provision.PROVISIONING_CONFIG_PATH: bleConfigUuid!]

            bleTransport = BLETransport(serviceUUIDString: bleServiceUuid!,
                                        sessionUUIDString: bleSessionUuid!,
                                        configUUIDMap: configUUIDMap,
                                        deviceNamePrefix: bleDeviceNamePrefix!,
                                        scanTimeout: 5.0)
            bleTransport?.scan(delegate: self)
            transport = bleTransport
        }
    }

    func initialiseSessionAndConfigure(transport: Transport,
                                       security: Security) {
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }

        let newSession = Session(transport: transport,
                                 security: security)

        newSession.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                return
            }

            let provision = Provision(session: newSession)

            provision.configureWifiAvs(ssid: ssid,
                                       passphrase: passphrase,
                                       avs: self.avsDetails!) { status, error in
                guard error == nil else {
                    print("Error in configuring wifi : \(error.debugDescription)")
                    return
                }
                if status == Espressif_Status.success {
                    self.applyConfigurations(provision: provision)
                }
            }
        }
    }

    @objc func passphraseEntered() {
        passphraseTextfield.resignFirstResponder()
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        if ssid.count > 0, passphrase.count > 0 {
            provisionButton.isUserInteractionEnabled = true
            provisionDevice()
        }
    }

    @objc func ssidEntered() {
        guard let ssid = ssidTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines), let passphrase = passphraseTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return
        }
        if ssid.count > 0, passphrase.count > 0 {
            provisionButton.isUserInteractionEnabled = true
        }
        passphraseTextfield.becomeFirstResponder()
    }

    @IBAction func provisionButtonClicked(_: Any) {
        provisionDevice()
    }

    private func applyConfigurations(provision: Provision) {
        provision.applyConfigurations(completionHandler: { status, error in
            guard error == nil else {
                self.showError(errorMessage: "Error in applying configurations : \(error.debugDescription)")
                return
            }
            print("Configurations applied ! \(status)")
        },
                                      wifiStatusUpdatedHandler: { wifiState, failReason, error in
            DispatchQueue.main.async {
                self.showBusy(isBusy: false)
                let successVC = self.storyboard?.instantiateViewController(withIdentifier: "successViewController") as? SuccessViewController
                if let successVC = successVC {
                    if error != nil {
                        successVC.statusText = "Error in getting wifi state : \(error.debugDescription)"
                    } else if wifiState == Espressif_WifiStationState.connected {
                        successVC.statusText = "Device has been successfully provisioned!"
                    } else if wifiState == Espressif_WifiStationState.disconnected {
                        successVC.statusText = "Please check the device indicators for Provisioning status."
                    } else {
                        successVC.statusText = "Device provisioning failed.\nReason : \(failReason).\nPlease try again"
                    }
                    self.navigationController?.present(successVC, animated: true, completion: nil)
                    self.provisionButton.isUserInteractionEnabled = true
                }
            }
        })
    }

    func showError(errorMessage: String) {
        let alertMessage = errorMessage
        let alertController = UIAlertController(title: "Provision device", message: alertMessage, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension ProvisionViewController: BLETransportDelegate {
    func peripheralsFound(peripherals: [CBPeripheral]) {
        bleTransport?.connect(peripheral: peripherals[0], withOptions: nil)
    }

    func peripheralsNotFound(serviceUUID _: UUID?) {
        showError(errorMessage: "No peripherals found!")
    }

    func peripheralConfigured(peripheral _: CBPeripheral) {
        initialiseSessionAndConfigure(transport: transport!, security: security!)
    }

    func peripheralNotConfigured(peripheral _: CBPeripheral) {
        showError(errorMessage: "Peripheral device could not be configured.")
    }

//    func peripheralDisconnected(peripheral: CBPeripheral, error _: Error?) {
//        print("Here")
//        showError(errorMessage: "Peripheral device disconnected")
//    }
    func peripheralDisconnected(peripheral _: CBPeripheral, error: Error?) {
        print(error)
        showError(errorMessage: "Peripheral device disconnected")
    }
}
