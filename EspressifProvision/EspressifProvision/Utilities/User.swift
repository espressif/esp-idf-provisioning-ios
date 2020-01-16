//
//  User.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/06/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import AWSCognitoIdentityProvider
import Foundation

class User {
    static let shared = User()
    var userID: String?
    var pool: AWSCognitoIdentityUserPool!
    var idToken: String?
    var associatedNodeList: [Node]?
    var associatedNodes: [String: Node] = [:]
    var username = ""
    var password = ""
    var automaticLogin = false
    var updateDeviceList = false
    var addDeviceStatusTimeout: Timer?
    var currentAssociationInfo: AssociationConfig?
    private init() {
        // setup service configuration
        let serviceConfiguration = AWSServiceConfiguration(region: Constants.CognitoIdentityUserPoolRegion, credentialsProvider: nil)

        // create pool configuration
        let poolConfiguration = AWSCognitoIdentityUserPoolConfiguration(clientId: Constants.CognitoIdentityUserPoolAppClientId,
                                                                        clientSecret: Constants.CognitoIdentityUserPoolAppClientSecret,
                                                                        poolId: Constants.CognitoIdentityUserPoolId)

        // initialize user pool client
        AWSCognitoIdentityUserPool.register(with: serviceConfiguration, userPoolConfiguration: poolConfiguration, forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)

        pool = AWSCognitoIdentityUserPool(forKey: Constants.AWSCognitoUserPoolsSignInProviderKey)
//        associatedDevices = []
//        associatedDevices?.append(Device(name: "Test Device 1", device_id: "fafafe", type: nil))
//        associatedDevices?.append(Device(name: "Test Device 2", device_id: "fafafe", type: nil))
//        associatedDevices?.append(Device(name: "Test Device 3", device_id: "fafafe", type: nil))
    }

    func currentUser() -> AWSCognitoIdentityUser? {
        return pool.currentUser()
    }

    func checkDeviceAssoicationStatus(nodeID: String, requestID: String) {
        addDeviceStatusTimeout = Timer.scheduledTimer(timeInterval: 180, target: self, selector: #selector(timeoutFetchingStatus), userInfo: nil, repeats: false)
        fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
    }

    func associateNodeWithUser(session: Session, delegate: DeviceAssociationProtocol) {
        currentAssociationInfo = AssociationConfig()
        currentAssociationInfo?.uuid = UUID().uuidString
        let deviceAssociation = DeviceAssociation(session: session, secretId: currentAssociationInfo!.uuid)
        deviceAssociation.associateDeviceWithUser()
        deviceAssociation.delegate = delegate
    }

    @objc func timeoutFetchingStatus() {
        addDeviceStatusTimeout?.invalidate()
    }

    func fetchDeviceAssociationStatus(nodeID: String, requestID: String) {
        if addDeviceStatusTimeout?.isValid ?? false {
            NetworkManager.shared.deviceAssociationStatus(deviceID: nodeID, requestID: requestID) { status in
                if status {
                    NotificationCenter.default.post(name: Notification.Name(Constants.newDeviceAdded), object: nil)
                    self.updateDeviceList = true
                    self.addDeviceStatusTimeout?.invalidate()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.fetchDeviceAssociationStatus(nodeID: nodeID, requestID: requestID)
                    }
                }
            }
        }
    }

    func getAccessToken(completionHandler: @escaping (String?) -> Void) {
        if idToken == nil, let user = currentUser(), user.isSignedIn {
            user.getSession().continueOnSuccessWith(block: { (task) -> Any? in
                completionHandler(task.result?.idToken?.tokenString)
            })
        } else {
            completionHandler(idToken)
        }
    }

    func sendRequestToAddDevice(count: Int) {
        print("sendRequestToAddDevice")
        let parameters = ["user_id": User.shared.userID, "node_id": currentAssociationInfo!.nodeID, "secret_key": currentAssociationInfo!.uuid, "operation": "add"]
        NetworkManager.shared.addDeviceToUser(parameter: parameters as! [String: String]) { requestID, error in
            print(requestID)
            if error != nil, count > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.sendRequestToAddDevice(count: count - 1)
                }
            } else {
                if let requestid = requestID {
                    print("Check device association status")
                    User.shared.checkDeviceAssoicationStatus(nodeID: self.currentAssociationInfo!.nodeID, requestID: requestid)
                }
            }
        }
    }
}
