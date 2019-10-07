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

    init(session: Session, secretId: String) {
        transport = session.transport
        security = session.security
        secretKey = secretId
    }

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

    private func createAssociationConfigRequest() throws -> Data? {
        var configRequest = Cloud_CmdGetSetDetails()
        configRequest.secretKey = secretKey
//        User.shared.userID = "GMNd8jhD6qR5sqxd9TFtEg"
        configRequest.userID = User.shared.userID!
        var payload = Cloud_CloudConfigPayload()
        payload.msg = Cloud_CloudConfigMsgType.typeCmdGetSetDetails
        payload.cmdGetSetDetails = configRequest
        return try security.encrypt(data: payload.serializedData())
    }
}
