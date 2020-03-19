//
//  DeviceAssociation.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation

protocol DeviceAssociationProtocol {
    func deviceAssociationFinishedWith(success: Bool, nodeID: String?)
}

class DeviceAssociation {
    private let transport: Transport
    private let security: Security
    let secretKey: String

    var delegate: DeviceAssociationProtocol?

    /// Create DeviceAssociation object that sends configuration data
    /// Required for sending data related to assoicating device with app user
    ///
    /// - Parameters:
    ///   - session: Initialised session object
    ///   - secretId: a unique key to authenticate user-device mapping
    init(session: ESPSession, secretId: String) {
        transport = session.transport
        security = session.security
        secretKey = secretId
    }

    /// Method to start user device mapping
    /// Info like userID and secretKey are sent from user to device
    ///
    func associateDeviceWithUser() {
        do {
            let payloadData = try createAssociationConfigRequest()
            if let data = payloadData {
                transport.SendConfigData(path: transport.utility.associationPath, data: data) { response, error in
                    guard error == nil, response != nil else {
                        self.delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
                        return
                    }
                    self.processResponse(responseData: response!)
                }
            } else {
                delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
            }
        } catch {
            delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
        }
    }

    /// Prcocess response to check status of mapping
    /// Info like userID and secretKey are sent from user to device
    ///
    /// - Parameters:
    ///   - responseData: Response recieved from device after sending mapping payload
    func processResponse(responseData: Data) {
        let decryptedResponse = (security.encrypt(data: responseData))!
        do {
            let response = try Cloud_CloudConfigPayload(serializedData: decryptedResponse)
            if response.respGetSetDetails.status == .success {
                delegate?.deviceAssociationFinishedWith(success: true, nodeID: response.respGetSetDetails.deviceSecret)
            } else {
                delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
            }
        } catch {
            delegate?.deviceAssociationFinishedWith(success: false, nodeID: nil)
        }
    }

    /// Method to convert device association payload into encrypted data
    /// This info is sent to device
    ///
    private func createAssociationConfigRequest() throws -> Data? {
        var configRequest = Cloud_CmdGetSetDetails()
        configRequest.secretKey = secretKey
        configRequest.userID = User.shared.userInfo.userID
        var payload = Cloud_CloudConfigPayload()
        payload.msg = Cloud_CloudConfigMsgType.typeCmdGetSetDetails
        payload.cmdGetSetDetails = configRequest
        return try security.encrypt(data: payload.serializedData())
    }
}
