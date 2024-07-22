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
//  ESPBLETransport.swift
//  ESPProvision
//

import CoreBluetooth
import Foundation


/// The `ESPBLEStatusDelegate` protocol define methods that provide information
/// of current BLE device connection status
protocol ESPBLEStatusDelegate {
    
    /// Peripheral is connected successfully.
    func peripheralConnected()
    
    /// Failed to connect with peripheral.
    ///
    /// - Parameter peripheral: CBPeripheral for which callback is recieved.
    func peripheralFailedToConnect(peripheral: CBPeripheral?, error: Error?)

    /// Peripheral device disconnected
    ///
    /// - Parameters:
    ///   - peripheral: CBPeripheral for which callback is recieved.
    ///   - error: Error description
    func peripheralDisconnected(peripheral: CBPeripheral, error: Error?)
    
}

/// Delegate which will receive events relating to BLE device scanning
protocol ESPBLETransportDelegate {
    /// Peripheral devices found with matching Service UUID
    /// Callers should call the BLETransport.connect method with
    /// one of the peripherals found here
    ///
    /// - Parameter peripherals: peripheral devices array
    func peripheralsFound(peripherals: [String:ESPDevice])

    /// No peripherals found with matching Service UUID
    ///
    /// - Parameter serviceUUID: the service UUID provided at the time of creating the BLETransport object
    func peripheralsNotFound(serviceUUID: UUID?)

}

/// The `ESPBleTransport` class conforms and implememnt methods of `ESPCommunicable` protocol.
/// This class provides methods for sending configuration and session related data to  `ESPDevice`.
class ESPBleTransport: NSObject, ESPCommunicable {
    
    /// Instance of 'ESPUtility' class.
    var utility: ESPUtility

    private var isBLEEnabled = false
    private var scanTimeout = 5.0
    private var readCounter = 0
    private var deviceNamePrefix:String!
    
    /// Stores Proof of Possesion for a device.
    var proofOfPossession:String?
    /// Store username for device
    var username:String?
    /// Store network for device
    var network: ESPNetworkType?

    
    var centralManager: CBCentralManager!
    var espressifPeripherals: [String:ESPDevice] = [:]
    var currentPeripheral: CBPeripheral?
    var currentService: CBService?
    var bleConnectTimer = Timer()
    var bleScanTimer: Timer?
    var bleDeviceConnected = false

    var peripheralCanRead: Bool = true
    var peripheralCanWrite: Bool = false

    var currentRequestCompletionHandler: ((Data?, Error?) -> Void)?

    public var delegate: ESPBLETransportDelegate?
    var bleStatusDelegate: ESPBLEStatusDelegate?

    /// Create BLETransport object.
    ///
    /// - Parameters:
    ///   - deviceNamePrefix: Device name prefix.
    ///   - scanTimeout: Timeout in seconds for which BLE scan should happen.
    init(scanTimeout: TimeInterval, deviceNamePrefix: String, proofOfPossession:String? = nil, username: String? = nil, network: ESPNetworkType? = nil) {
        ESPLog.log("Initalising BLE transport class with scan timeout \(scanTimeout)")
        self.scanTimeout = scanTimeout
        self.deviceNamePrefix = deviceNamePrefix
        self.proofOfPossession = proofOfPossession
        self.username = username
        self.network = network
        utility = ESPUtility()
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// BLE implementation of `ESPCommunicable` protocol.
    ///
    /// - Parameters:
    ///   - data: Data to be sent.
    ///   - sessionPath: Not required.
    ///   - completionHandler: Handler called when data is sent.
    func SendSessionData(data: Data, sessionPath: String?, completionHandler: @escaping (Data?, Error?) -> Void) {
        ESPLog.log("Sending session data.")
        guard peripheralCanWrite, peripheralCanRead,
            let espressifPeripheral = currentPeripheral else {
            completionHandler(nil, ESPTransportError.deviceUnreachableError("BLE device unreachable"))
            return
        }
        
        espressifPeripheral.writeValue(data, for: utility.sessionCharacteristic, type: .withResponse)
        currentRequestCompletionHandler = completionHandler
    }

    /// BLE implemenation of the `ESPCommunicable` protocol
    ///
    /// - Parameters:
    ///   - path: Path of the configuration endpoint.
    ///   - data: Data to be sent.
    ///   - completionHandler: Handler called when data is sent.
    func SendConfigData(path: String,
                        data: Data,
                        completionHandler: @escaping (Data?, Error?) -> Void) {
        ESPLog.log("Sending configration data to path \(path)")
        guard peripheralCanWrite, peripheralCanRead,
            let espressifPeripheral = currentPeripheral else {
            completionHandler(nil, ESPTransportError.deviceUnreachableError("BLE device unreachable"))
            return
        }
        
        if let characteristic = utility.configUUIDMap[path] {
            espressifPeripheral.writeValue(data, for: characteristic, type: .withResponse)
            currentRequestCompletionHandler = completionHandler
        } else {
            completionHandler(nil,NSError(domain: "com.espressif.ble", code: 1, userInfo: [NSLocalizedDescriptionKey:"BLE characteristic does not exist."]))
        }
    }

    /// Connect to a BLE peripheral device.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral device
    ///   - options: An optional dictionary specifying connection behavior options.
    ///              Sent as is to the CBCentralManager.connect function.
    func connect(peripheral: CBPeripheral, withOptions options: [String: Any]?, delegate: ESPBLEStatusDelegate) {
        ESPLog.log("Connecting peripheral device...")
        self.bleStatusDelegate = delegate
        if let currentPeripheral = currentPeripheral {
            centralManager.cancelPeripheralConnection(currentPeripheral)
        }
        currentPeripheral = peripheral
        centralManager.connect(currentPeripheral!, options: options)
        currentPeripheral?.delegate = self
        bleDeviceConnected = false
        bleConnectTimer.invalidate()
        ESPLog.log("Initiating timeout for connection completion.")
        bleConnectTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(bleConnectionTimeout), userInfo: nil, repeats: false)
    }
    
    /// This method is invoked on timeout of connection with BLE device.
    @objc func bleConnectionTimeout() {
        if !bleDeviceConnected {
            ESPLog.log("Peripheral connection timeout occured.")
            self.disconnect()
            bleConnectTimer.invalidate()
            bleStatusDelegate?.peripheralFailedToConnect(peripheral: nil, error: NSError(domain: "com.espressif.ble", code: 2, userInfo: [NSLocalizedDescriptionKey:"Connection timeout. Unable to read BLE characteristic on time."]))
        }
    }

    /// Disconnect from the current connected peripheral.
    func disconnect() {
        if let currentPeripheral = currentPeripheral {
            ESPLog.log("Cancelling peripheral connection.")
            centralManager.cancelPeripheralConnection(currentPeripheral)
        }
    }

    /// Scan for BLE devices.
    ///
    /// - Parameter delegate: Delegate which will receive resulting events.
    func scan(delegate: ESPBLETransportDelegate) {
        
        ESPLog.log("Ble scan started...")
        
        self.delegate = delegate

        if isBLEEnabled {
            bleScanTimer?.invalidate()
            bleScanTimer = Timer.scheduledTimer(timeInterval: scanTimeout,
                                     target: self,
                                     selector: #selector(stopScan(timer:)),
                                     userInfo: nil,
                                     repeats: true)
            centralManager.scanForPeripherals(withServices: nil)
        }
    }

    /// Stop scan when timer runs off.
    @objc func stopScan(timer: Timer) {
        
        ESPLog.log("Ble scan stopped.")
        
        centralManager.stopScan()
        timer.invalidate()
        if espressifPeripherals.count > 0 {
            delegate?.peripheralsFound(peripherals: espressifPeripherals)
            espressifPeripherals.removeAll()
        } else {
            delegate?.peripheralsNotFound(serviceUUID: UUID(uuidString: ""))
        }
    }
    
    // Stop scan and invalidate timer
    func stopSearch() {
        ESPLog.log("Ble search stopped.")
        centralManager.stopScan()
        bleScanTimer?.invalidate()
        espressifPeripherals.removeAll()
        delegate?.peripheralsNotFound(serviceUUID: UUID(uuidString: ""))
    }

    /// BLE implementation of `ESPCommunicable` protocol.
    func isDeviceConfigured() -> Bool {
        ESPLog.log("Device configured status: \(utility.peripheralConfigured)")
        return utility.peripheralConfigured
    }
}

// MARK: CBCentralManagerDelegate

extension ESPBleTransport: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            ESPLog.log("Bluetooth state unknown")
        case .resetting:
            ESPLog.log("Bluetooth state resetting")
        case .unsupported:
            ESPLog.log("Bluetooth state unsupported")
        case .unauthorized:
            ESPLog.log("Bluetooth state unauthorized")
        case .poweredOff:
            ESPLog.log("Bluetooth state off")
        case .poweredOn:
            ESPLog.log("Bluetooth state on")
            isBLEEnabled = true
            bleScanTimer = Timer.scheduledTimer(timeInterval: scanTimeout,
                                     target: self,
                                     selector: #selector(stopScan(timer:)),
                                     userInfo: nil,
                                     repeats: true)
            centralManager.scanForPeripherals(withServices: nil)
        @unknown default: break
        }
    }

    func centralManager(_: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData data: [String: Any],
                        rssi _: NSNumber) {
        ESPLog.log("Peripheral devices discovered.\(data.debugDescription)")
        if let peripheralName = data["kCBAdvDataLocalName"] as? String ?? peripheral.name  {
            if peripheralName.lowercased().hasPrefix(deviceNamePrefix.lowercased()) {
                let newEspDevice  = ESPDevice(name: peripheralName, security: .secure, transport: .ble, advertisementData: data)
                espressifPeripherals[peripheralName] = newEspDevice
                newEspDevice.peripheral = peripheral
            }
        }
    }

    func centralManager(_: CBCentralManager, didConnect _: CBPeripheral) {
        ESPLog.log("Connected to peripheral. Discover services.")
        currentPeripheral?.discoverServices(nil)
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        ESPLog.log("Fail to connect to peripheral.")
        bleStatusDelegate?.peripheralFailedToConnect(peripheral: peripheral, error: error)
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        ESPLog.log("Disconnected with peripheral")
        bleStatusDelegate?.peripheralDisconnected(peripheral: peripheral, error: error)
    }
}

// MARK: CBPeripheralDelegate

extension ESPBleTransport: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        ESPLog.log("Peripheral did discover services.")
        guard let services = peripheral.services else { return }
        currentPeripheral = peripheral
        currentService = services[0]
        if let currentService = currentService {
            currentPeripheral?.discoverCharacteristics(nil, for: currentService)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
        
        ESPLog.log("Peripheral did discover chatacteristics.")
        guard let characteristics = service.characteristics else { return }

        peripheralCanWrite = true
        readCounter = characteristics.count
        for characteristic in characteristics {
            if !characteristic.properties.contains(.read) {
                peripheralCanRead = false
            }
            if !characteristic.properties.contains(.write) {
                peripheralCanWrite = false
            }
            currentPeripheral?.discoverDescriptors(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        ESPLog.log("Writing value for characterisitic \(characteristic)")
        guard error == nil else {
            currentRequestCompletionHandler?(nil, error)
            return
        }

        peripheral.readValue(for: characteristic)
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        ESPLog.log("Updating value for characterisitic \(characteristic)")
        guard error == nil else {
            currentRequestCompletionHandler?(nil, error)
            return
        }

        if let currentRequestCompletionHandler = currentRequestCompletionHandler {
            DispatchQueue.global().async {
                currentRequestCompletionHandler(characteristic.value, nil)
            }
            self.currentRequestCompletionHandler = nil
        }
    }

    func peripheral(_: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error _: Error?) {
        ESPLog.log("Did sicover descriptor for characterisitic: \(characteristic)")
        for descriptor in characteristic.descriptors! {
            currentPeripheral?.readValue(for: descriptor)
        }
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error _: Error?) {
        ESPLog.log("Did update value for descriptor: \(descriptor)")
        utility.processDescriptor(descriptor: descriptor)
        readCounter -= 1
        if readCounter < 1 {
            if utility.peripheralConfigured {
                bleConnectTimer.invalidate()
                bleStatusDelegate?.peripheralConnected()
            }
        }
    }
}
