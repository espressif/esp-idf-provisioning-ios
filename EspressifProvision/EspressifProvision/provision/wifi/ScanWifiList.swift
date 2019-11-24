//
//  ScanWifiList.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 23/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

protocol ScanWifiListProtocol {
    func wifiScanFinished(wifiList: [String: Espressif_WiFiScanResult]?, error: Error?)
}

enum CustomError: Error {
    case emptyConfigData
    case emptyResultCount
}

class ScanWifiList {
    private let transport: Transport
    private let security: Security
    private var scanResult: [String: Espressif_WiFiScanResult] = [:]

    var delegate: ScanWifiListProtocol?

    init(session: Session) {
        transport = session.transport
        security = session.security
    }

    func startWifiScan() {
        do {
            let payloadData = try createStartScanRequest()
            if let data = payloadData, let scanPath = transport.utility.scanPath {
                transport.SendConfigData(path: scanPath, data: data) { response, error in
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
            if let data = payloadData, let scanPath = transport.utility.scanPath {
                transport.SendConfigData(path: scanPath, data: data) { response, error in
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

    func getScannedWiFiListResponse(count: UInt32, startIndex: UInt32 = 0) {
        do {
            var lastFetch = false
            var fetchCount: UInt32 = 4
            if startIndex + 4 >= count {
                fetchCount = count - startIndex
                lastFetch = true
            }
            let payloadData = try createWifiListConfigRequest(startIndex: startIndex, count: fetchCount)
            if let data = payloadData, let scanPath = transport.utility.scanPath {
                transport.SendConfigData(path: scanPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.wifiScanFinished(wifiList: nil, error: error)
                        return
                    }
                    self.getScannedWifiSSIDs(response: response!, fetchFinish: lastFetch)
                    if startIndex + fetchCount < count {
                        self.getScannedWiFiListResponse(count: count, startIndex: startIndex + 4)
                    }
                }
            } else {
                delegate?.wifiScanFinished(wifiList: nil, error: CustomError.emptyConfigData)
            }
        } catch {
            delegate?.wifiScanFinished(wifiList: nil, error: error)
        }
    }

    private func getScannedWifiSSIDs(response: Data, fetchFinish: Bool) {
        do {
            if let decryptedResponse = try security.decrypt(data: response) {
                let payload = try Espressif_WiFiScanPayload(serializedData: decryptedResponse)
                let responseList = payload.respScanResult
                for index in 0 ... responseList.entries.count - 1 {
                    let ssid = String(decoding: responseList.entries[index].ssid, as: UTF8.self)
                    let rssi = responseList.entries[index].rssi
                    if let val = scanResult[ssid] {
                        if rssi > val.rssi {
                            scanResult[ssid] = val
                        }
                    } else {
                        scanResult[ssid] = responseList.entries[index]
                    }
                }
                if fetchFinish {
                    delegate?.wifiScanFinished(wifiList: scanResult, error: nil)
                }
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

    private func createWifiListConfigRequest(startIndex: UInt32, count: UInt32) throws -> Data? {
        var configRequest = Espressif_CmdScanResult()
        configRequest.startIndex = startIndex
        configRequest.count = count
        var payload = Espressif_WiFiScanPayload()
        payload.msg = Espressif_WiFiScanMsgType.typeCmdScanResult
        payload.cmdScanResult = configRequest
        return try security.encrypt(data: payload.serializedData())
    }
}
