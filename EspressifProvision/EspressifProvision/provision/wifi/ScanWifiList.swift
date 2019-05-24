//
//  ScanWifiList.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 23/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

protocol ScanWifiListProtocol {
    func wifiScanFinished(wifiList: [String: Int32]?, error: Error?)
}

enum CustomError: Error {
    case emptyConfigData
    case emptyResultCount
}

class ScanWifiList {
    private let transport: Transport
    private let security: Security

    var delegate: ScanWifiListProtocol?

    init(session: Session) {
        transport = session.transport
        security = session.security
    }

    func startWifiScan() {
        do {
            let payloadData = try createStartScanRequest()
            if let data = payloadData {
                transport.SendConfigData(path: Provision.PROVISIONING_SCAN_PATH, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.wifiScanFinished(wifiList: nil, error: error)
                        return
                    }
                    self.processStartScan(responseData: response!)
                    self.getWiFiScanStatus()
                }
            } else {
                delegate?.wifiScanFinished(wifiList: nil, error: CustomError.emptyConfigData)
            }
        } catch {
            delegate?.wifiScanFinished(wifiList: nil, error: error)
        }
    }

    private func processStartScan(responseData: Data) {
        let decryptedResponse = (security.encrypt(data: responseData))!
        do {
            _ = try Espressif_WiFiScanPayload(serializedData: decryptedResponse)
        } catch {
            delegate?.wifiScanFinished(wifiList: nil, error: error)
        }
    }

    private func getWiFiScanStatus() {
        do {
            let payloadData = try createWifiScanConfigRequest()
            if let data = payloadData {
                transport.SendConfigData(path: Provision.PROVISIONING_SCAN_PATH, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.wifiScanFinished(wifiList: nil, error: error)
                        return
                    }
                    let scanCount = self.processGetWiFiScanStatus(responseData: response!)
                    if scanCount > 0 {
                        self.getScannedWiFiListResponse(count: scanCount)
                    } else {
                        self.delegate?.wifiScanFinished(wifiList: nil, error: CustomError.emptyResultCount)
                    }
                }
            }
        } catch {
            delegate?.wifiScanFinished(wifiList: nil, error: error)
        }
    }

    func processGetWiFiScanStatus(responseData: Data) -> UInt32 {
        let resultCount: UInt32 = 0
        var scanFinished = false
        if let decryptedResponse = security.decrypt(data: responseData) {
            do {
                let payload = try Espressif_WiFiScanPayload(serializedData: decryptedResponse)
                let response = payload.respScanStatus
                scanFinished = response.scanFinished
                return response.resultCount
            } catch {
                delegate?.wifiScanFinished(wifiList: nil, error: error)
            }
        }
        return resultCount
    }

    func getScannedWiFiListResponse(count: UInt32) {
        do {
            let payloadData = try createWifiListConfigRequest(count: count)
            if let data = payloadData {
                transport.SendConfigData(path: Provision.PROVISIONING_SCAN_PATH, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.wifiScanFinished(wifiList: nil, error: error)
                        return
                    }
                    self.getScannedWifiSSIDs(response: response!)
                }
            } else {
                delegate?.wifiScanFinished(wifiList: nil, error: CustomError.emptyConfigData)
            }
        } catch {
            delegate?.wifiScanFinished(wifiList: nil, error: error)
        }
    }

    private func getScannedWifiSSIDs(response: Data) {
        do {
            if let decryptedResponse = try security.decrypt(data: response) {
                let payload = try Espressif_WiFiScanPayload(serializedData: decryptedResponse)
                let responseList = payload.respScanResult
                var result: [String: Int32] = [:]
                for index in 0 ... responseList.entries.count - 1 {
                    let ssid = String(decoding: responseList.entries[index].ssid, as: UTF8.self)
                    let rssi = responseList.entries[index].rssi
                    if let val = result[ssid] {
                        if rssi > val {
                            result[ssid] = rssi
                        }
                    } else {
                        result[ssid] = rssi
                    }
                }
                delegate?.wifiScanFinished(wifiList: result, error: nil)
            }
        } catch {
            delegate?.wifiScanFinished(wifiList: nil, error: error)
        }
    }

    private func createStartScanRequest() throws -> Data? {
        var configRequest = Espressif_CmdScanStart()
        configRequest.blocking = true
        configRequest.passive = false
        configRequest.groupChannels = 0
        configRequest.periodMs = 120
        let msgType = Espressif_WiFiScanMsgType.typeCmdScanStart
        var payload = Espressif_WiFiScanPayload()
        payload.msg = msgType
        payload.cmdScanStart = configRequest
        return try security.encrypt(data: payload.serializedData())
    }

    private func createWifiScanConfigRequest() throws -> Data? {
        let configRequest = Espressif_CmdScanStatus()
        let msgType = Espressif_WiFiScanMsgType.typeCmdScanStatus
        var payload = Espressif_WiFiScanPayload()
        payload.msg = msgType
        payload.cmdScanStatus = configRequest
        return try security.encrypt(data: payload.serializedData())
    }

    private func createWifiListConfigRequest(count: UInt32) throws -> Data? {
        var configRequest = Espressif_CmdScanResult()
        configRequest.startIndex = 0
        configRequest.count = count
        var payload = Espressif_WiFiScanPayload()
        payload.msg = Espressif_WiFiScanMsgType.typeCmdScanResult
        payload.cmdScanResult = configRequest
        return try security.encrypt(data: payload.serializedData())
    }
}
