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
    var previewLayer: AVCaptureVideoPreviewLayer!
    var provisionConfig: [String: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showAlertWith(message: "")
            return
        }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showAlertWith(message: "")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showAlertWith(message: "")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        let pathBigRect = UIBezierPath(rect: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        let pathSmallRect = UIBezierPath(rect: CGRect(x: view.center.x - view.bounds.width / 3, y: view.center.y - view.bounds.width / 3, width: view.bounds.width / 1.5, height: view.bounds.width / 1.5))

        pathBigRect.append(pathSmallRect)
        pathBigRect.usesEvenOddFillRule = true

        let fillLayer = CAShapeLayer()
        fillLayer.path = pathBigRect.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        fillLayer.fillColor = UIColor.black.cgColor
        fillLayer.opacity = 0.4
        view.layer.addSublayer(fillLayer)

        captureSession.startRunning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
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
        print(code)
        if let jsonArray = try? JSONSerialization.jsonObject(with: Data(code.utf8), options: []) as? [String: String] {
            print(jsonArray) // use the json here
            if let ssid = jsonArray["name"], let pop = jsonArray["pop"], let transport = jsonArray["transport"] {
                let password = jsonArray["password"] ?? ""
                if transport == "softap" {
                    Utility.showLoader(message: "Applying configuration", view: view)
                    connectToSoftApUsingCredentials(ssid: ssid, password: password, pop: pop)
                } else {
                    retry(message: "QR code is not valid. Please try again.")
                }
            } else {
                retry(message: "QR code is not valid. Please try again.")
            }
        } else {
            retry(message: "QR code is not valid. Please try again.")
            print("bad json")
        }
    }

    func retry(message: String) {
        Utility.hideLoader(view: view)
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
                    print("already associated")
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
