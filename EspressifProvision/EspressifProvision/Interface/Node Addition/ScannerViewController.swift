//
//  ScannerViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 26/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AVFoundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    var provisionConfig: [String: String] = [:]
    @IBOutlet var scannerView: UIView!
    @IBOutlet var addManuallyButton: PrimaryButton!
    @IBOutlet var scannerHeading: UILabel!
    @IBOutlet var scannerDescription: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        getAuthorizationStatus { authorized in
            DispatchQueue.main.async {
                if authorized {
                    self.scannerHeading.text = "Looking for QR Code"
                    self.scannerDescription.text = "Please position the camera to point at the QR Code."
                    self.startCaptureSession()
                } else {
                    self.scannerHeading.text = "Camera Access Denied"
                    self.scannerDescription.text = "Go to iPhone Settings -> ESP RainMaker -> Enable Camera in order to scan QR code"
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = scannerView.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        getAuthorizationStatus { authorized in
            DispatchQueue.main.async {
                if authorized {
                    if self.captureSession?.isRunning == false {
                        self.captureSession.startRunning()
                    }
                } else {}
            }
        }
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func startCaptureSession() {
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                self.showAlertWith(message: "Camera is not available in this device.")
                return
            }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            } else {
                self.showAlertWith(message: "Camera is not available in this device.")
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                self.showAlertWith(message: "Camera is not available in this device.")
                return
            }

            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer?.frame = self.scannerView.layer.bounds
            self.previewLayer?.videoGravity = .resizeAspectFill
            self.scannerView.layer.addSublayer(self.previewLayer!)

            self.captureSession.startRunning()
        }
    }

    func getAuthorizationStatus(completionHandler: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            completionHandler(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    completionHandler(false)
                    return
                }
                completionHandler(true)
            }
        case .denied, .restricted:
            completionHandler(false)
        default:
            completionHandler(false)
        }
    }

    @IBAction func cancelClickecd(_: Any) {
        navigationController?.popToRootViewController(animated: false)
    }

    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        captureSession.startRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            captureSession.stopRunning()
            parseQrCode(code: stringValue)
        }
    }

    func parseQrCode(code: String) {
        if let jsonArray = try? JSONSerialization.jsonObject(with: Data(code.utf8), options: []) as? [String: String] {
            if let ssid = jsonArray["name"], let pop = jsonArray["pop"], let transport = jsonArray["transport"] {
                let password = jsonArray["password"] ?? ""
                if transport == "softap" {
                    Utility.showLoader(message: "Connecting to Device", view: view)
                    addManuallyButton.isEnabled = false
                    connectToSoftApUsingCredentials(ssid: ssid, password: password, pop: pop)
                } else {
                    retry(message: "QR code is not valid. Please try again.")
                }
            } else {
                retry(message: "QR code is not valid. Please try again.")
            }
        } else {
            retry(message: "QR code is not valid. Please try again.")
        }
    }

    func retry(message: String) {
        Utility.hideLoader(view: view)
        addManuallyButton.isEnabled = true
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: { _ in
            DispatchQueue.main.async {
                self.captureSession.startRunning()
            }
        }))
        present(alertController, animated: true, completion: nil)
    }

    func connectToSoftApUsingCredentials(ssid: String, password: String = "", pop: String = "") {
        var hotSpotConfig: NEHotspotConfiguration
        if password == "" {
            hotSpotConfig = NEHotspotConfiguration(ssid: ssid)
        } else {
            hotSpotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        }
        hotSpotConfig.joinOnce = false
        NEHotspotConfigurationManager.shared.apply(hotSpotConfig) { error in
            if error != nil {
                if error?.localizedDescription == "already associated." {
                    self.goToProvision(pop: pop)
                } else {
                    DispatchQueue.main.async {
                        Utility.hideLoader(view: self.view)
                        self.captureSession.startRunning()
                    }
                }
            } else {
                if self.verifyConnection(ssid: ssid) {
                    self.goToProvision(pop: pop)
                } else {
                    self.retry(message: "Unable to connect to the device. Please try again.")
                }
            }
        }
    }

    func verifyConnection(ssid: String) -> Bool {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    if let currentSSID = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                        if currentSSID == ssid {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    func goToProvision(pop: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Utility.hideLoader(view: self.view)
            let provisionVC = self.storyboard?.instantiateViewController(withIdentifier: "provision") as! ProvisionViewController
            provisionVC.connectAutomatically = true
            provisionVC.isScanFlow = true
            provisionVC.pop = pop
            provisionVC.provisionConfig = self.provisionConfig
            self.navigationController?.pushViewController(provisionVC, animated: true)
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
    func showAlertWith(message: String = "") {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
