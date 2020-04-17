//
//  APIClient.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 01/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import Foundation
import JWTDecode

class NetworkManager {
    /// A singleton class that manages Network call for this application
    static let shared = NetworkManager()
    var session: Session!

    private init() {
        // Validate api calls with server certificate
        let certificate = [NetworkManager.certificate(filename: "amazonRootCA")]
        let trustManager = ServerTrustManager(evaluators: [
            "api.staging.rainmaker.espressif.com": PinnedCertificatesTrustEvaluator(certificates: certificate), "rainmaker-staging.auth.us-east-1.amazoncognito.com": PinnedCertificatesTrustEvaluator(certificates: certificate), "rainmaker-prod.auth.us-east-1.amazoncognito.com": PinnedCertificatesTrustEvaluator(certificates: certificate), "api.rainmaker.espressif.com": PinnedCertificatesTrustEvaluator(certificates: certificate),
        ])
        session = Session(serverTrustManager: trustManager)
    }

    /// Method to get security certificate from bundle resource
    ///
    /// - Parameters:
    ///   - filename: name of the certificate file
    private static func certificate(filename: String) -> SecCertificate {
        let filePath = Bundle.main.path(forResource: filename, ofType: "der")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!

        return certificate
    }

    // MARK: - Node APIs

    /// Method to fetch node and devices associated with the user
    ///
    /// - Parameters:
    ///   - completionHandler: after response is parsed this block will be called with node array and error(if any) as argument
    func getNodes(completionHandler: @escaping ([Node]?, ESPNetworkError?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                let url = Constants.getNodes + "?node_details=true"
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any] {
                            if let nodeArray = json["node_details"] as? [[String: Any]] {
                                completionHandler(JSONParser.parseNodeArray(data: nodeArray), nil)
                                return
                            } else if let status = json["status"] as? String, let description = json["description"] as? String {
                                if status == "failure" {
                                    completionHandler(nil, ESPNetworkError.serverError(description))
                                    return
                                }
                            }
                        }
                        completionHandler(nil, nil)
                        return
                    case let .failure(error):
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                completionHandler(nil, .emptyToken)
            }
        })
    }

    /// Get node info like device list, param list and online/offline status
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node info is recieved
    func getNodeInfo(nodeId: String, completionHandler: @escaping (Node?, ESPNetworkError?) -> Void) {
        User.shared.getAccessToken { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                let url = Constants.getNodes + "?node_id=" + nodeId
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any] {
                            if let nodeArray = json["node_details"] as? [[String: Any]] {
                                if let node = JSONParser.parseNodeArray(data: nodeArray)?[0] {
                                    completionHandler(node, nil)
                                    return
                                }
                                completionHandler(nil, ESPNetworkError.emptyConfigData)
                                return
                            } else if let status = json["status"] as? String, let description = json["description"] as? String {
                                if status == "failure" {
                                    completionHandler(nil, ESPNetworkError.serverError(description))
                                    return
                                }
                            }
                        }
                        completionHandler(nil, ESPNetworkError.emptyConfigData)
                        return
                    case let .failure(error):
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }
                }
            } else {
                completionHandler(nil, ESPNetworkError.emptyToken)
            }
        }
    }

    /// Method to fetch online/offline status of associated nodes
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node status is recieved
    func getNodeStatus(node: Node, completionHandler: @escaping (Node?, Error?) -> Void) {
        User.shared.getAccessToken { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                let url = Constants.getNodeStatus + "?nodeid=" + (node.node_id ?? "")
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    // Parse the connected status of the node
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any], let connectivity = json["connectivity"] as? [String: Any] {
                            if let status = connectivity["connected"] as? Bool {
                                let newNode = node
                                newNode.isConnected = status
                                completionHandler(newNode, nil)
                                return
                            }
                        }
                    case let .failure(error):
                        print(error)
                    }
                    completionHandler(node, nil)
                }
            } else {
                completionHandler(node, nil)
            }
        }
    }

    // MARK: - Device Association

    /// Method to send request of adding device to currently active user
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to add device to user is recieved with id of the request
    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, ESPNetworkError?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                self.session.sessionConfiguration.timeoutIntervalForResource = 5
                self.session.sessionConfiguration.timeoutIntervalForRequest = 5
                self.session.request(Constants.addDevice, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    self.session.sessionConfiguration.timeoutIntervalForResource = 60
                    self.session.sessionConfiguration.timeoutIntervalForRequest = 60
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: String] {
                            // Get request id for add device request
                            // This request id will be used for getting the status of add request
                            if let requestId = json[Constants.requestID] {
                                completionHandler(requestId, nil)
                                return
                            } else if let status = json["status"], let description = json["description"] {
                                if status == "failure" {
                                    completionHandler(nil, ESPNetworkError.serverError(description))
                                    return
                                }
                            }
                        }
                    case let .failure(error):
                        // Check for any error on response
                        completionHandler(nil, ESPNetworkError.serverError(error.localizedDescription))
                        return
                    }

                    completionHandler(nil, ESPNetworkError.emptyConfigData)
                }
            } else {
                completionHandler(nil, ESPNetworkError.emptyToken)
            }
        })
    }

    /// Method to fetch device assoication staus
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which association status is fetched
    ///   - completionHandler: handler called when response to deviceAssociationStatus is recieved
    func deviceAssociationStatus(nodeID: String, requestID: String, completionHandler: @escaping (String) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let url = Constants.checkStatus + "?node_id=" + nodeID
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                self.session.request(url + "&request_id=" + requestID + "&user_request=true", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: String], let status = json["request_status"] {
                            completionHandler(status)
                            return
                        }
                    case let .failure(error):
                        print(error)
                    }
                    completionHandler("error")
                }
            } else {
                completionHandler("error")
            }
        })
    }

    // MARK: - Thing Shadow

    /// Method to update device thing shadow
    /// Any changes of the device params from the app trigger this method
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is updated
    ///   - completionHandler: handler called when response to updateThingShadow is recieved
    func updateThingShadow(nodeID: String?, parameter: [String: Any]) {
        NotificationCenter.default.post(Notification(name: Notification.Name(Constants.paramUpdateNotification)))
        if let nodeid = nodeID {
            User.shared.getAccessToken(completionHandler: { idToken in
                if idToken != nil {
                    let url = Constants.updateThingsShadow + "?nodeid=" + nodeid
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                    self.session.request(url, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        switch response.result {
                        case let .success(value):
                            if let json = value as? [String: Any] {
                                return
                            }
                        case let .failure(error):
                            print(error)
                        }
                    }
                } else {}
            })
        }
    }

    /// Method to get device thing shadow
    /// Gives the current status of the device params for a node
    ///
    /// - Parameters:
    ///   - nodeID: Id of the node for which thing shadow is requested
    ///   - completionHandler: handler called when response to getDeviceThingShadow is recieved
    func getDeviceThingShadow(nodeID: String, completionHandler: @escaping ([String: Any]?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let url = Constants.getDeviceShadow + "?nodeid=" + nodeID
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any] {
                            completionHandler(json)
                            return
                        }
                    case let .failure(error):
                        print(error)
                    }
                    completionHandler(nil)
                }
            } else {
                completionHandler(nil)
            }
        })
    }

    // MARK: - Generic Request

    /// Method to make generic api request
    ///
    /// - Parameters:
    ///   - url: URL of the api
    ///   - method: HTTPMethod like post, get, etc.
    ///   - parameters: Parameter to be included in the api call
    ///   - encoding: ParameterEncoding
    ///   - header: HTTp headers
    ///   - completionHandler: Callback invoked after api response is recieved
    func genericRequest(url: URLConvertible, method: HTTPMethod, parameters: Parameters, encoding: ParameterEncoding, headers: HTTPHeaders, completionHandler: @escaping ([String: Any]?) -> Void) {
        session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseJSON { response in
            switch response.result {
            case let .success(value):
                if let json = value as? [String: Any] {
                    completionHandler(json)
                    return
                }
            case let .failure(error):
                print(error)
            }
            completionHandler(nil)
        }
    }
}
