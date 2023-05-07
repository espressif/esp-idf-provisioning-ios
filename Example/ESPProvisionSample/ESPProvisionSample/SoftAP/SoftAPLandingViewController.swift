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
//  ProvisionLandingViewController.swift
//  ESPProvisionSample
//

import ESPProvision
import Foundation
import SystemConfiguration.CaptiveNetwork
import UIKit
import CoreLocation

class SoftAPLandingViewController: UIViewController {
    var deviceStatusTimer: Timer?
    var task: URLSessionDataTask?
    var connectedToDevice = false
    var capabilities: [String]?
    
    let locationManager = CLLocationManager()

    @IBOutlet var connectButton: UIButton!

    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        getLocationPermission()
        checkConnectivity()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - IBActions
    
    @IBAction func connectClicked(_: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                _ = UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            }
        }
    }
    
    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func backClicked(_: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Utility
    
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

    func checkConnectivity() {
        connectButton.alpha = 0.5
        connectButton.isEnabled = false
        Utility.showLoader(message: "", view: view)
        getDeviceVersionInfo()
        deviceStatusTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(timeoutFetchingStatus), userInfo: nil, repeats: false)
    }
    
    func getDeviceVersionInfo() {
        SendHTTPData(path: "proto-ver", data: Data("ESP".utf8), completionHandler: { response, error in
            DispatchQueue.main.async {
                if error == nil {
                    if self.deviceStatusTimer!.isValid {
                        self.deviceStatusTimer?.invalidate()
                        self.getESPDevice()
                    }
                } else {
                    Utility.hideLoader(view: self.view)
                    self.timeoutFetchingStatus()
                }
            }
        })
    }

    func connectedNetwork() -> String? {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    if let currentSSID = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                        return currentSSID
                    }
                }
            }
        }
        return nil
    }

    func getESPDevice() {
        if let ssid = connectedNetwork() {
            ESPProvisionManager.shared.createESPDevice(deviceName: ssid, transport: .softap, completionHandler: { device, _ in
                if device != nil {
                    self.connectDevice(device: device!)
                } else {
                    DispatchQueue.main.async {
                        self.retry(message: "Device could not be connected. Please try again")
                    }
                }
            })
        } else {
            DispatchQueue.main.async {
                self.retry(message: "Unable to verify device connection.")
            }
        }
    }
    
    
    // MARK: - Notifications

    @objc func appEnterForeground() {
        checkConnectivity()
    }

    @objc func appEnterBackground() {
        task?.cancel()
    }

    @objc func timeoutFetchingStatus() {
        Utility.hideLoader(view: view)
        deviceStatusTimer?.invalidate()
        connectButton.alpha = 1.0
        connectButton.isEnabled = true
    }

    // MARK: - Helper Methods
    
    private func connectDevice(device:ESPDevice) {
        device.security = Utility.shared.espAppSettings.securityMode
        device.connect(delegate: self) { status in
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
            }
            switch status {
            case .connected:
                DispatchQueue.main.async {
                    self.goToProvision(device: device)
                }
            case let .failedToConnect(error):
                DispatchQueue.main.async {
                    var errorDescription = ""
                    switch error {
                    case .securityMismatch, .versionInfoError:
                        errorDescription = error.description
                    default:
                        errorDescription = error.description + "\nCheck if POP is correct."
                    }
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: errorDescription, action: action)
                }
            default:
                DispatchQueue.main.async {
                    let action = UIAlertAction(title: "Retry", style: .default, handler: nil)
                    self.showAlert(error: "Device disconnected", action: action)
                }
            }
        }
    }
    
    private func goToProvision(device: ESPDevice) {
        DispatchQueue.main.async {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.espDevice = device
            self.navigationController?.pushViewController(provisionVC, animated: true)
        }
    }
    
    private func showAlert(error: String, action: UIAlertAction) {
        let alertController = UIAlertController(title: "Error!", message: error, preferredStyle: .alert)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func retry(message: String) {
        Utility.hideLoader(view: view)
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    private func SendHTTPData(path: String, data: Data, completionHandler: @escaping (Data?, Error?) -> Swift.Void) {
        let url = URL(string: "http://\("192.168.4.1:80")/\(path)")!
        var request = URLRequest(url: url)

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")

        request.httpMethod = "POST"
        request.httpBody = data
        request.timeoutInterval = 2.0
        task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }

            let httpStatus = response as? HTTPURLResponse
            if httpStatus?.statusCode != 200 {
                print("statusCode should be 200, but is \(String(describing: httpStatus?.statusCode))")
            }

            completionHandler(data, nil)
        }
        task?.resume()
    }
    
    
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}

extension SoftAPLandingViewController: ESPDeviceConnectionDelegate {
    func getProofOfPossesion(forDevice: ESPDevice, completionHandler: @escaping (String) -> Void) {
        goToConnectVC(forDevice: forDevice)
    }
    
    func getUsername(forDevice: ESPDevice, completionHandler: @escaping (String?) -> Void) {
        goToConnectVC(forDevice: forDevice)
    }
    
    func goToConnectVC(forDevice: ESPDevice) {
        let connectVC = self.storyboard?.instantiateViewController(withIdentifier: "connectVC") as! ConnectViewController
        connectVC.espDevice = forDevice
        self.navigationController?.pushViewController(connectVC, animated: true)
    }
}
