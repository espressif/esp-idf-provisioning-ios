// Copyright 2020 Espressif Systems
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
//  ScannerViewController.swift
//  ESPProvisionSample
//

import AVFoundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit
import CoreLocation
import ESPProvision

// Class that manages QRCode scanning and provides way to switch to manual provisioning.
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    let locationManager = CLLocationManager()
    
    @IBOutlet var scannerView: UIView!
    @IBOutlet var addManuallyButton: UIButton!
    @IBOutlet var scannerHeading: UILabel!
    @IBOutlet var scannerDescription: UILabel!

    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Check for device type to ask for location permission
        // Location permission is needed to get SSID of connected Wi-Fi network.
        switch Utility.shared.espAppSettings.deviceType {
        case .both,.softAp:
            getLocationPermission()
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanQrCode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ESPProvisionManager.shared.stopScan()
    }
    
    // MARK: - IBActions
    
    @IBAction func cancelClickecd(_: Any) {
        navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func manualFlowClicked(_ sender: Any) {
        switch Utility.shared.espAppSettings.deviceType {
        case .both:
            let deviceTypeVC = self.storyboard?.instantiateViewController(withIdentifier: "deviceTypeVC") as! DeviceTypeViewController
            navigationController?.pushViewController(deviceTypeVC, animated: false)
        case .ble:
            let bleLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "bleLandingVC") as! BLELandingViewController
            navigationController?.pushViewController(bleLandingVC, animated: false)
        case .softAp:
            let softAPLandingVC = self.storyboard?.instantiateViewController(withIdentifier: "softAPLandingVC") as! SoftAPLandingViewController
            navigationController?.pushViewController(softAPLandingVC, animated: false)
        }
    }

    // MARK: - Scan
    
    // Scan QR code to search for available device
    func scanQrCode() {
        ESPProvisionManager.shared.scanQRCode(scanView: scannerView) { espDevice, _ in
            DispatchQueue.main.async {
                if let device = espDevice {
                    if self.isDeviceSupported(device: device) {
                        Utility.showLoader(message: "Connecting to device", view: self.view)
                        switch device.transport {
                            case .ble:
                                self.connectDevice(espDevice: device)
                            case .softap:
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.connectDevice(espDevice: device)
                            }
                        }
                    } else {
                       self.retry(message: "Device type not supported. Please choose another device and try again.")
                    }
                } else {
                    self.retry(message: "Device could not be scanned. Please try again")
                }
            }
        } scanStatus: { status in
            switch status {
            case .readingCode:
                Utility.showLoader(message: "Reading QR code", view: self.view)
            case .searchingBLE(let device):
                Utility.showLoader(message: "Searching BLE device: \(device)", view: self.view)
            case .joiningSoftAP(let device):
                Utility.showLoader(message: "Joining network: \(device)", view: self.view)
            default:
                break
            }
        }
    }
    
    // Helper method to check whether app supports the scanned device.
    func isDeviceSupported(device: ESPDevice) -> Bool {
        switch Utility.shared.espAppSettings.deviceType {
        case .both:
            return true
        case .softAp:
            if device.transport == .softap {
                return true
            }
        case .ble:
            if device.transport == .ble {
                return true
            }
        }
        return false
    }

    // Connect device automatically when valid QR code is scanned and device instance is returned.
    func connectDevice(espDevice: ESPDevice) {
        espDevice.security = Utility.shared.espAppSettings.securityMode
        espDevice.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.goToProvision(device: espDevice)
                }
                print("Connected to device")
            default:
                DispatchQueue.main.async {
                    switch status {
                    case .failedToConnect(let error):
                        self.retry(message: error.description)
                    default:
                        self.retry(message: "Device could not be connected. Please try again")
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods
    
    func retry(message: String) {
        Utility.hideLoader(view: view)
        addManuallyButton.isEnabled = true
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.scanQrCode()
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func goToProvision(device: ESPDevice) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.espDevice = device
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }
    
    func getLocationPermission()  {
        let locStatus = CLLocationManager.authorizationStatus()
        switch locStatus {
           case .notDetermined:
              locationManager.requestWhenInUseAuthorization()
           return
           case .denied, .restricted:
              let alert = UIAlertController(title: "Location Services are disabled", message: "Please enable Location Services in your Settings", preferredStyle: .alert)
              let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
              alert.addAction(okAction)
              present(alert, animated: true, completion: nil)
           case .authorizedAlways, .authorizedWhenInUse:
           break
        @unknown default:
            print("unknown")
        }
    }
}

extension ScannerViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void)  {
        completionHandler("")
    }
    
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        completionHandler(Utility.shared.espAppSettings.username)
    }
}
