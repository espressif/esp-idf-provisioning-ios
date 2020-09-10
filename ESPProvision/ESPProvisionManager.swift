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
//  ESPProvision.swift
//  ESPProvision
//

import Foundation
import UIKit
import CoreBluetooth
import AVFoundation

/// Supported mode of communication with device.
public enum ESPTransport {
    /// Communicate using bluetooth.
    case ble
    /// Communicate using Soft Access Point.
    case softap
}

/// Security options on data transmission.
public enum ESPSecurity: Int {
    /// Unsecure data transmission.
    case unsecure = 0
    /// Data is encrypted before transmission.
    case secure  = 1
}

/// The `ESPProvisionManager` class is a singleton class. It provides methods for getting `ESPDevice` object.
/// Provide option to
public class ESPProvisionManager: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    private var espDevices:[ESPDevice] = []
    private var espBleTransport:ESPBleTransport!
    private var devicePrefix = ""
    private var transport:ESPTransport = .ble
    private var security: ESPSecurity = .secure
    private var searchCompletionHandler: (([ESPDevice]?,ESPDeviceCSSError?) -> Void)?
    private var scanCompletionHandler: ((ESPDevice?,ESPDeviceCSSError?) -> Void)?
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// Member to access singleton object of class.
    public static let shared = ESPProvisionManager()
    
    private override init() {
        
    }
    
    /// Search for `ESPDevice` using bluetooth scan.
    /// SoftAp search is not yet supported in iOS
    ///
    /// - Parameters:
    ///   - devicePrefix: Prefix of found device should match with devicePrefix.
    ///   - transport: Mode of transport.
    ///   - security: Security mode for communication.
    ///   - completionHandler: The completion handler is called when search for devices is complete. Result
    ///                        of search is returned as parameter of this function. When search is successful
    ///                        array of found devices are returned. When search fails then reaon for failure is
    ///                        returned as `ESPDeviceCSSError`.
    public func searchESPDevices(devicePrefix: String,transport: ESPTransport, security:ESPSecurity = .secure, completionHandler: @escaping ([ESPDevice]?,ESPDeviceCSSError?) -> Void) {
        
        ESPLog.log("Search ESPDevices called.")
        
        // Store handler to call when search is complete
        self.scanCompletionHandler = nil
        self.searchCompletionHandler = completionHandler
        
        // Store configuration related properties
        self.transport = transport
        self.devicePrefix = devicePrefix
        self.security = security
        
        switch transport {
            case .ble:
                espBleTransport = ESPBleTransport(scanTimeout: 5.0, deviceNamePrefix: devicePrefix)
                espBleTransport.scan(delegate: self)
            case .softap:
                ESPLog.log("ESP SoftAp Devices search is not yet supported in iOS.")
                completionHandler(nil,.softApSearchNotSupported)
        }
        
    }
    
    /// Scan for `ESPDevice` using QR code.
    ///
    /// - Parameters:
    ///   - scanView: Camera preview layer will be added as subview of this `UIView` parameter.
    ///   - completionHandler: The completion handler is called when scan method is completed. Result
    ///                        of scan is returned as parameter of this function. When scan is successful
    ///                        found device is returned. When scan fails then reaon for failure is
    ///                        returned as `ESPDeviceCSSError`.
    public func scanQRCode(scanView: UIView, completionHandler: @escaping (ESPDevice?,ESPDeviceCSSError?) -> Void) {
        ESPLog.log("Checking Camera Permission..")
        getAuthorizationStatus { authorized,error in
            if authorized {
                ESPLog.log("Scanning QR Code..")
                self.searchCompletionHandler = nil
                self.scanCompletionHandler = completionHandler
                self.startCaptureSession(scanView: scanView)
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    /// Stop camera session that is capturing QR code. Call this method when your `Scan View` goes out of scope.
    ///
    public func stopScan() {
        ESPLog.log("Stopping Camera Session..")
        if self.captureSession != nil {
            self.captureSession.stopRunning()
        }
    }
    
    /// Refresh device list with current transport and security settings.
    ///
    /// - Parameter completionHandler: The completion handler is called when refresh is completed. Result
    ///                                of refresh is returned as parameter of this function.
    public func refreshDeviceList(completionHandler: @escaping ([ESPDevice]?,ESPDeviceCSSError?) -> Void) {
        searchESPDevices(devicePrefix: self.devicePrefix, transport: self.transport, security: self.security, completionHandler: completionHandler)
    }
    
    /// Get authorization status of Camera.
    ///
    /// - Parameter completionHandler: Invoked when camera permission status is determined. Returns `true`
    ///                                when camera access is granted 'false' otherwise.
    private func getAuthorizationStatus(completionHandler: @escaping (Bool,ESPDeviceCSSError?) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            ESPLog.log("Camera Access Allowed")
            completionHandler(true,nil)
        case .notDetermined:
            ESPLog.log("Camera Access Not Determined. Requesting access..")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    ESPLog.log("Camera Access Granted")
                    completionHandler(false,.cameraAccessDenied)
                    return
                }
                ESPLog.log("Camera Access Denied")
                completionHandler(true,nil)
            }
        case .denied, .restricted:
            ESPLog.log("Camera Access Denied")
            completionHandler(false,.cameraAccessDenied)
        default:
            ESPLog.log("Camera Access Not Available")
            completionHandler(false,.cameraNotAvailable)
        }
    }
    
    /// Start capturing camera inputs.
    ///
    /// - Parameter scanView: Super view of camera preview layer.
    private func startCaptureSession(scanView: UIView) {
        DispatchQueue.main.async {
            self.captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                ESPLog.log("Video capture not available.")
                self.scanCompletionHandler?(nil,.cameraNotAvailable)
                return
            }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                ESPLog.log("Video input not available.")
                self.scanCompletionHandler?(nil,.avCaptureDeviceInputError)
                return
            }

            if self.captureSession.canAddInput(videoInput) {
                self.captureSession.addInput(videoInput)
            } else {
                ESPLog.log("Video input error.")
                self.scanCompletionHandler?(nil,.videoInputError)
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                ESPLog.log("Video output error.")
                self.scanCompletionHandler?(nil,.videoOutputError)
                return
            }

            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer?.frame = scanView.layer.bounds
            self.previewLayer?.videoGravity = .resizeAspectFill
            scanView.layer.addSublayer(self.previewLayer!)

            ESPLog.log("Camera session started...")
            self.captureSession.startRunning()
        }
    }
    
    public func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            captureSession.stopRunning()
            parseQrCode(code: stringValue)
            ESPLog.log("Recieved QR code response.")
        }
    }
    
    /// Parse scanned QR code data.
    ///
    /// - Parameter code: Scanned string.
    private func parseQrCode(code: String) {
        
        ESPLog.log("Parsing QR code response...code:\(code)")
        
        if let jsonArray = try? JSONSerialization.jsonObject(with: Data(code.utf8), options: []) as? [String: String] {
            if let deviceName = jsonArray["name"], let transportInfo = jsonArray["transport"] {
                if (transportInfo.lowercased() == "softap" || transportInfo.lowercased() == "ble"){
                    let transport:ESPTransport = transportInfo.lowercased() == "softap" ? .softap:.ble
                    let security:ESPSecurity = jsonArray["security"] ?? "1" == "0" ? .unsecure:.secure
                    let pop = jsonArray["pop"] ?? ""
                    switch transport {
                    case .ble:
                        createESPDevice(deviceName: deviceName, transport: transport, security: security, proofOfPossession: pop, completionHandler: self.scanCompletionHandler!)
                    default:
                        createESPDevice(deviceName: deviceName, transport: transport, security: security, proofOfPossession: pop, softAPPassword: jsonArray["password"] ?? "", completionHandler: self.scanCompletionHandler!)
                        
                    }
                    return
                }
            }
        }
        ESPLog.log("Invalid QR code.")
        scanCompletionHandler?(nil,.invalidQRCode)
    }
        
    /// Manually create `ESPDevice` object.
    ///
    /// - Parameters:
    ///   - deviceName: Name of `ESPDevice`.
    ///   - transport: Mode of transport.
    ///   - security: Security mode for communication.
    ///   - completionHandler: The completion handler is invoked with parameters containing newly created device object.
    ///                        Error in case where method fails to return a device object.
    public func createESPDevice(deviceName: String, transport: ESPTransport, security: ESPSecurity = .secure, proofOfPossession:String? = nil, softAPPassword:String? = nil, completionHandler: @escaping (ESPDevice?,ESPDeviceCSSError?) -> Void) {
        
        ESPLog.log("Creating ESPDevice...")
        
        switch transport {
        case .ble:
            self.searchCompletionHandler = nil
            self.scanCompletionHandler = completionHandler
            self.security = security
            espBleTransport = ESPBleTransport(scanTimeout: 5.0, deviceNamePrefix: deviceName, proofOfPossession: proofOfPossession)
            espBleTransport.scan(delegate: self)
        default:
            let newDevice = ESPDevice(name: deviceName, security: security, transport: transport,proofOfPossession: proofOfPossession, softAPPassword: softAPPassword)
            ESPLog.log("SoftAp device created successfully.")
            completionHandler(newDevice, nil)
        }
    }
    
    /// Method to enable/disable library logs.
    ///
    /// - Parameter enable: Bool to enable/disable console logs`.
    public func enableLogs(_ enable: Bool) {
        ESPLog.isLogEnabled = enable
    }
}

extension ESPProvisionManager: ESPBLETransportDelegate {
    func peripheralsFound(peripherals: [String:CBPeripheral]) {
        
        ESPLog.log("Ble devices found :\(peripherals)")
        
        espDevices.removeAll()
        for key in peripherals.keys {
           let newESPDevice = ESPDevice(name: key, security: self.security, transport: .ble, proofOfPossession: espBleTransport.proofOfPossession)
            newESPDevice.peripheral = peripherals[key]
            newESPDevice.espBleTransport = espBleTransport
            espDevices.append(newESPDevice)
        }
        self.searchCompletionHandler?(espDevices,nil)
        self.scanCompletionHandler?(espDevices.first,nil)
    }

    func peripheralsNotFound(serviceUUID _: UUID?) {
        
        ESPLog.log("No ble devices found.")
        
        self.searchCompletionHandler?(nil,.espDeviceNotFound)
        self.scanCompletionHandler?(nil,.espDeviceNotFound)
    }

    func peripheralConfigured(peripheral _: CBPeripheral) {}

    func peripheralNotConfigured(peripheral _: CBPeripheral) {}

    func peripheralDisconnected(peripheral: CBPeripheral, error _: Error?) {}

    func bluetoothUnavailable() {}
}
