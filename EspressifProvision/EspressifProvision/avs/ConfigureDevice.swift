//
//  ConfigureDevice.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 23/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

protocol GetDeviceInfoDelegate {
    func deviceInfoFetched(alexaDevice: AlexaDevice?)
}

class ConfigureDevice {
    var getInfoTimer = Timer()
    var setDeviceInfoTimer = Timer()
    var delegate: GetDeviceInfoDelegate?
    let security: Security
    let transport: Transport
    var notificationhandler: (Bool) -> Void = { _ in }

    var alexaDevice: AlexaDevice
    private var session: Session
    let languages = ["Deutsche", "English (Australia)", "English (Canada)", "English (United Kingdom)", "English (India)", "English (United States)", "Español (España)", "Español (México)", "Español (United States)", "Français (Canada)", "Français (France)", "हिन्दी", "Italiano (Italia)", "日本語", "Português"]

    init(session: Session, device: AlexaDevice) {
        self.session = session
        security = session.security
        transport = session.transport
        alexaDevice = device
    }

    ///
    /// Fetch information from device like device name, volume, language etc.
    ///
    func getDeviceInfo() {
        // Running timer in main thread
        // If device info is not fetched within 5 sec, then request is considered as failed
        DispatchQueue.main.async {
            self.getInfoTimer.invalidate()
            self.getInfoTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.getInfoTimeOut), userInfo: nil, repeats: false)
            do {
                if let message = try self.createGetDeviceInfoConfig() {
                    self.transport.SendConfigData(path: self.transport.utility.avsConfigPath, data: message) { response, error in
                        if self.getInfoTimer.isValid {
                            self.getInfoTimer.invalidate()
                            if response != nil, error == nil {
                                self.processDeviceInfoResponse(response: response)
                            } else {
                                self.delegate?.deviceInfoFetched(alexaDevice: nil)
                            }
                        }
                    }
                }
            } catch {
                self.getInfoTimeOut()
            }
        }
    }

    /// Send data related to device name change
    ///
    /// - Parameters:
    ///   - withName: desired name for Device
    ///   - completionHandler: handler called when data is successfully sent and response is recieved
    func setDeviceName(withName: String, completionHandler: @escaping (Bool) -> Void) {
        setDeviceInfoTimer.invalidate()
        setDeviceInfoTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(setDeviceInfoTimeOut), userInfo: nil, repeats: false)
        var changenameRequest = Avs_CmdSetUserVisibleName()
        changenameRequest.name = withName
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSetUserVisibleName
        payload.cmdUserVisibleName = changenameRequest
        notificationhandler = completionHandler
        do {
            let message = try session.security.encrypt(data: payload.serializedData())
            transport.SendConfigData(path: transport.utility.avsConfigPath, data: message!) { response, error in
                if self.setDeviceInfoTimer.isValid {
                    self.setDeviceInfoTimer.invalidate()
                    if response != nil, error == nil {
                        self.processDeviceNameChangeResponse(response: response!, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        } catch {
            completionHandler(false)
        }
    }

    /// Send data related to volume change request
    ///
    /// - Parameters:
    ///   - volume: desired volume for Device
    ///   - completionHandler: handler called when data is successfully sent and response is recieved
    func setDeviceVolume(volume: UInt32, completionHandler: @escaping (Bool) -> Void) {
        setDeviceInfoTimer.invalidate()
        setDeviceInfoTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(setDeviceInfoTimeOut), userInfo: nil, repeats: false)
        var changeVolumeRequest = Avs_CmdSetVolume()
        changeVolumeRequest.level = volume
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSetVolume
        payload.cmdSetVolume = changeVolumeRequest
        notificationhandler = completionHandler
        do {
            let message = try session.security.encrypt(data: payload.serializedData())
            transport.SendConfigData(path: transport.utility.avsConfigPath, data: message!) { response, error in
                if self.setDeviceInfoTimer.isValid {
                    self.setDeviceInfoTimer.invalidate()
                    if response != nil, error == nil {
                        self.processDeviceNameChangeResponse(response: response!, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        } catch {
            completionHandler(false)
        }
    }

    /// Send data related to start of request
    ///
    /// - Parameters:
    ///   - value: desired value for start tone
    ///   - completionHandler: handler called when data is successfully sent and response is recieved
    func setDeviceStartTone(value: Bool, completionHandler: @escaping (Bool) -> Void) {
        setDeviceInfoTimer.invalidate()
        setDeviceInfoTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(setDeviceInfoTimeOut), userInfo: nil, repeats: false)
        var audioCueRequest = Avs_CmdSetSORAudioCue()
        audioCueRequest.audioCue = value
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSetEoraudioCue
        payload.cmdSorAudioCue = audioCueRequest
        notificationhandler = completionHandler
        do {
            let message = try session.security.encrypt(data: payload.serializedData())
            transport.SendConfigData(path: transport.utility.avsConfigPath, data: message!) { response, error in
                if self.setDeviceInfoTimer.isValid {
                    self.setDeviceInfoTimer.invalidate()
                    if response != nil, error == nil {
                        self.processDeviceStartToneResponse(response: response!, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        } catch {
            completionHandler(false)
        }
    }

    /// Send data related to end of request
    ///
    /// - Parameters:
    ///   - value: desired value for end tone
    ///   - completionHandler: handler called when data is successfully sent and response is recieved
    func setDeviceEndTone(value: Bool, completionHandler: @escaping (Bool) -> Void) {
        setDeviceInfoTimer.invalidate()
        setDeviceInfoTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(setDeviceInfoTimeOut), userInfo: nil, repeats: false)
        var audioCueRequest = Avs_CmdSetEORAudioCue()
        audioCueRequest.audioCue = value
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSetEoraudioCue
        payload.cmdEorAudioCue = audioCueRequest
        notificationhandler = completionHandler
        do {
            let message = try session.security.encrypt(data: payload.serializedData())
            transport.SendConfigData(path: transport.utility.avsConfigPath, data: message!) { response, error in
                if self.setDeviceInfoTimer.isValid {
                    self.setDeviceInfoTimer.invalidate()
                    if response != nil, error == nil {
                        self.processDeviceEndToneResponse(response: response!, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        } catch {
            completionHandler(false)
        }
    }

    /// Send data related to device language setting
    ///
    /// - Parameters:
    ///   - value: Enum value for assistant language
    ///   - completionHandler: handler called when data is successfully sent and response is recieved
    func setDeviceLanguage(value: Int, completionHandler: @escaping (Bool) -> Void) {
        setDeviceInfoTimer.invalidate()
        setDeviceInfoTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(setDeviceInfoTimeOut), userInfo: nil, repeats: false)
        var langChangeRequest = Avs_CmdSetAssistantLang()
        langChangeRequest.assistantLang = Avs_Locale(rawValue: value)!
        var payload = Avs_AVSConfigPayload()
        payload.msg = Avs_AVSConfigMsgType.typeCmdSetAssistantLang
        payload.cmdAssistantLang = langChangeRequest
        notificationhandler = completionHandler
        do {
            let message = try session.security.encrypt(data: payload.serializedData())
            transport.SendConfigData(path: transport.utility.avsConfigPath, data: message!) { response, error in
                if self.setDeviceInfoTimer.isValid {
                    self.setDeviceInfoTimer.invalidate()
                    if response != nil, error == nil {
                        self.processDeviceEndToneResponse(response: response!, completionHandler: completionHandler)
                    } else {
                        completionHandler(false)
                    }
                }
            }
        } catch {
            completionHandler(false)
        }
    }

    /// Process responses recieved on setting device end tone
    ///
    /// - Parameters:
    ///   - response: resposne data to parse
    ///   - completionHandler: handler called when response is successfully parsed
    func processDeviceEndToneResponse(response: Data, completionHandler: @escaping (Bool) -> Void) {
        let decryptedResponse = security.decrypt(data: response)!
        do {
            let payload = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
            let result = payload.respEorAudioCue
            completionHandler(result.status == Avs_AVSConfigStatus.success)
        } catch {
            completionHandler(false)
        }
    }

    /// Process responses recieved on setting device start tone
    ///
    /// - Parameters:
    ///   - response: resposne data to parse
    ///   - completionHandler: handler called when response is successfully parsed
    func processDeviceStartToneResponse(response: Data, completionHandler: @escaping (Bool) -> Void) {
        let decryptedResponse = security.decrypt(data: response)!
        do {
            let payload = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
            let result = payload.respSorAudioCue
            completionHandler(result.status == Avs_AVSConfigStatus.success)
        } catch {
            completionHandler(false)
        }
    }

    /// Process responses recieved on setting device name
    ///
    /// - Parameters:
    ///   - response: resposne data to parse
    ///   - completionHandler: handler called when response is successfully parsed
    func processDeviceNameChangeResponse(response: Data, completionHandler: @escaping (Bool) -> Void) {
        let decryptedResponse = security.decrypt(data: response)!
        do {
            let payload = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
            let result = payload.respUserVisibleName
            completionHandler(result.status == Avs_AVSConfigStatus.success)
        } catch {
            completionHandler(false)
        }
    }

    /// Process responses recieved on setting device volume
    ///
    /// - Parameters:
    ///   - response: resposne data to parse
    ///   - completionHandler: handler called when response is successfully parsed
    func processVolumeChangeResponse(response: Data, completionHandler: @escaping (Bool) -> Void) {
        let decryptedResponse = security.decrypt(data: response)!
        do {
            let payload = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
            let result = payload.respSetVolume
            completionHandler(result.status == Avs_AVSConfigStatus.success)
        } catch {
            completionHandler(false)
        }
    }

    /// Process responses recieved on setting device language
    ///
    /// - Parameters:
    ///   - response: resposne data to parse
    ///   - completionHandler: handler called when response is successfully parsed
    func processlanguageChangeResponse(response: Data, completionHandler: @escaping (Bool) -> Void) {
        let decryptedResponse = security.decrypt(data: response)!
        do {
            let payload = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
            let result = payload.respAssistantLang
            completionHandler(result.status == Avs_AVSConfigStatus.success)
        } catch {
            completionHandler(false)
        }
    }

    /// Timeout method for getting device info
    ///
    @objc private func getInfoTimeOut() {
        getInfoTimer.invalidate()
        delegate?.deviceInfoFetched(alexaDevice: nil)
    }

    /// Timeout method for setting device info
    ///
    @objc private func setDeviceInfoTimeOut() {
        setDeviceInfoTimer.invalidate()
        notificationhandler(false)
    }

    /// Process responses recieved on getting device info
    ///
    /// - Parameters:
    ///   - response: resposne data to parse
    private func processDeviceInfoResponse(response: Data?) {
        guard let response = response else {
            delegate?.deviceInfoFetched(alexaDevice: nil)
            return
        }
        let decryptedResponse = security.decrypt(data: response)!
        do {
            let payload = try Avs_AVSConfigPayload(serializedData: decryptedResponse)
            let result = payload.respGetDeviceInfo
            let genericInfo = result.genericInfo
            let specificInfo = result.avsspecificInfo
            if result.status == Avs_AVSConfigStatus.success {
                alexaDevice.deviceName = genericInfo.userVisibleName
                alexaDevice.connectedWifi = genericInfo.wiFi
                alexaDevice.fwVersion = genericInfo.fwVersion
                alexaDevice.mac = genericInfo.mac
                alexaDevice.serialNumber = genericInfo.serialNum
                alexaDevice.startToneEnabled = specificInfo.soraudioCue
                alexaDevice.endToneEnabled = specificInfo.eoraudioCue
                alexaDevice.volume = specificInfo.volume
                alexaDevice.language = specificInfo.assistantLang
                delegate?.deviceInfoFetched(alexaDevice: alexaDevice)
            } else {
                delegate?.deviceInfoFetched(alexaDevice: nil)
            }
        } catch {
            delegate?.deviceInfoFetched(alexaDevice: nil)
            print(error)
        }
    }

    private func createGetDeviceInfoConfig() throws -> Data? {
        var deviceInfoRequest = Avs_CmdGetDeviceInfo()
        deviceInfoRequest.dummy = 123
        let msgType = Avs_AVSConfigMsgType.typeCmdGetDeviceInfo
        var payload = Avs_AVSConfigPayload()
        payload.msg = msgType
        payload.cmdGetDeviceInfo = deviceInfoRequest
        return try session.security.encrypt(data: payload.serializedData())
    }
}
