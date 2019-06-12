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
//  BLETransport.swift
//  EspressifProvision
//

import CoreBluetooth
import Foundation

class BLETransport: NSObject, Transport {
    var utility: Utility

    private var transportToken = DispatchSemaphore(value: 1)
    private var isBLEEnabled = false
    private var scanTimeout = 5.0
    private var readCounter = 0

    var centralManager: CBCentralManager!
    var espressifPeripherals: [CBPeripheral] = []
    var currentPeripheral: CBPeripheral?
    var currentService: CBService?

    var peripheralCanRead: Bool = true
    var peripheralCanWrite: Bool = false

    var currentRequestCompletionHandler: ((Data?, Error?) -> Void)?

    public var delegate: BLETransportDelegate?

    /// Create BLETransport implementation
    ///
    /// - Parameters:
    ///   - serviceUUIDString: string representation of the BLE Service UUID
    ///   - sessionUUIDString: string representation of the BLE Session characteristic UUID
    ///   - configUUIDMap: map of config paths and string representations of the BLE characteristic UUID
    ///   - deviceNamePrefix: device name prefix
    ///   - scanTimeout: timeout in seconds for which BLE scan should happen
    init(scanTimeout: TimeInterval) {
        self.scanTimeout = scanTimeout
        utility = Utility()
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// BLE implementation of Transport protocol
    ///
    /// - Parameters:
    ///   - data: data to be sent
    ///   - completionHandler: handler called when data is sent
    func SendSessionData(data: Data,
                         completionHandler: @escaping (Data?, Error?) -> Void) {
        guard peripheralCanWrite, peripheralCanRead,
            let espressifPeripheral = currentPeripheral else {
            completionHandler(nil, TransportError.deviceUnreachableError("BLE device unreachable"))
            return
        }

        transportToken.wait()
        espressifPeripheral.writeValue(data, for: utility.sessionCharacteristic, type: .withResponse)
        currentRequestCompletionHandler = completionHandler
    }

    /// BLE implemenation of the Transport protocol
    ///
    /// - Parameters:
    ///   - path: path of the config endpoint
    ///   - data: config data to be sent
    ///   - completionHandler: handler called when data is sent
    func SendConfigData(path: String,
                        data: Data,
                        completionHandler: @escaping (Data?, Error?) -> Void) {
        guard peripheralCanWrite, peripheralCanRead,
            let espressifPeripheral = currentPeripheral else {
            completionHandler(nil, TransportError.deviceUnreachableError("BLE device unreachable"))
            return
        }

        transportToken.wait()
        if let characteristic = utility.configUUIDMap[path] {
            espressifPeripheral.writeValue(data, for: characteristic, type: .withResponse)
            currentRequestCompletionHandler = completionHandler
        } else {
            transportToken.signal()
        }
    }

    /// Connect to a BLE peripheral device.
    ///
    /// - Parameters:
    ///   - peripheral: The peripheral device
    ///   - options: An optional dictionary specifying connection behavior options.
    ///              Sent as is to the CBCentralManager.connect function
    func connect(peripheral: CBPeripheral, withOptions options: [String: Any]?) {
        if let currentPeripheral = currentPeripheral {
            centralManager.cancelPeripheralConnection(currentPeripheral)
        }
        currentPeripheral = peripheral
        centralManager.connect(currentPeripheral!, options: options)
        currentPeripheral?.delegate = self
    }

    /// Disconnect from the current connected peripheral
    func disconnect() {
        if let currentPeripheral = currentPeripheral {
            centralManager.cancelPeripheralConnection(currentPeripheral)
        }
    }

    /// Scan for BLE devices
    ///
    /// - Parameter delegate: delegate which will receive resulting events
    func scan(delegate: BLETransportDelegate) {
        self.delegate = delegate

        if isBLEEnabled {
            _ = Timer.scheduledTimer(timeInterval: scanTimeout,
                                     target: self,
                                     selector: #selector(stopScan(timer:)),
                                     userInfo: nil,
                                     repeats: true)
            centralManager.scanForPeripherals(withServices: nil)
        }
    }

    @objc func stopScan(timer: Timer) {
        centralManager.stopScan()
        timer.invalidate()
        if espressifPeripherals.count > 0 {
            delegate?.peripheralsFound(peripherals: espressifPeripherals)
            espressifPeripherals.removeAll()
        } else {
            delegate?.peripheralsNotFound(serviceUUID: UUID(uuidString: ""))
        }
    }

    func isDeviceConfigured() -> Bool {
        return utility.peripheralConfigured ?? false
    }
}

extension BLETransport: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("Bluetooth state unknown")
        case .resetting:
            print("Bluetooth state resetting")
        case .unsupported:
            print("Bluetooth state unsupported")
        case .unauthorized:
            print("Bluetooth state unauthorized")
        case .poweredOff:
            if let currentPeripheral = currentPeripheral {
                delegate?.peripheralDisconnected(peripheral: currentPeripheral, error: nil)
            }
            print("Bluetooth state off")
        case .poweredOn:
            print("Bluetooth state on")
            isBLEEnabled = true
            _ = Timer.scheduledTimer(timeInterval: scanTimeout,
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
        if let peripheralName = peripheral.name {
            if peripheralName.hasPrefix(Utility.deviceNamePrefix) {
                if !(espressifPeripherals.filter { $0.name == peripheralName }.count > 0) {
                    espressifPeripherals.append(peripheral)
                }
            }
        }
    }

    func centralManager(_: CBCentralManager, didConnect _: CBPeripheral) {
        if let deviceName = currentPeripheral?.name {
            utility.deviceName = deviceName
        }
        currentPeripheral?.discoverServices(nil)
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.peripheralDisconnected(peripheral: peripheral, error: error)
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.peripheralDisconnected(peripheral: peripheral, error: error)
    }
}

extension BLETransport: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        guard let services = peripheral.services else { return }
        currentPeripheral = peripheral
        currentService = services[0]
        if let currentService = currentService {
            currentPeripheral?.discoverCharacteristics(nil, for: currentService)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
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
        guard error == nil else {
            currentRequestCompletionHandler?(nil, error)
            return
        }

        peripheral.readValue(for: characteristic)
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
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
        transportToken.signal()
    }

    func peripheral(_: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error _: Error?) {
        for descriptor in characteristic.descriptors! {
            currentPeripheral?.readValue(for: descriptor)
        }
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error _: Error?) {
        utility.processDescriptor(descriptor: descriptor)
        readCounter -= 1
        if readCounter < 1 {
            if utility.peripheralConfigured {
                delegate?.peripheralConfigured(peripheral: currentPeripheral!)
            }
        }
    }
}

/// Delegate which will receive events relating to BLE device scanning
protocol BLETransportDelegate {
    /// Peripheral devices found with matching Service UUID
    /// Callers should call the BLETransport.connect method with
    /// one of the peripherals found here
    ///
    /// - Parameter peripherals: peripheral devices array
    func peripheralsFound(peripherals: [CBPeripheral])

    /// No peripherals found with matching Service UUID
    ///
    /// - Parameter serviceUUID: the service UUID provided at the time of creating the BLETransport object
    func peripheralsNotFound(serviceUUID: UUID?)

    /// Peripheral device configured.
    /// This tells the caller that the connected BLE device is now configured
    /// and can be provisioned
    ///
    /// - Parameter peripheral: peripheral that has been connected to
    func peripheralConfigured(peripheral: CBPeripheral)

    /// Peripheral device could not be configured.
    /// This tells the called that the connected device cannot be configured for provisioning
    /// - Parameter peripheral: peripheral that has been connected to
    func peripheralNotConfigured(peripheral: CBPeripheral)

    /// Peripheral device disconnected
    ///
    /// - Parameters:
    ///   - peripheral: peripheral device
    ///   - error: error
    func peripheralDisconnected(peripheral: CBPeripheral, error: Error?)
}
