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
//        let serverTrustPolicy: [String: ServerTrustEvaluating] = ["" : .pinPublicKeys( kSecPublicKeyAttrs: ServerTrustEvaluating)]
//        let configuration = URLSessionConfiguration.default
        let certificate = [NetworkManager.certificate(filename: "amazonRootCA")]
        let trustManager = ServerTrustManager(evaluators: [
            "api.staging.rainmaker.espressif.com": PinnedCertificatesTrustEvaluator(certificates: certificate), "rainmaker-staging.auth.us-east-1.amazoncognito.com": PinnedCertificatesTrustEvaluator(certificates: certificate), "rainmaker-prod.auth.us-east-1.amazoncognito.com": PinnedCertificatesTrustEvaluator(certificates: certificate), "api.rainmaker.espressif.com": PinnedCertificatesTrustEvaluator(certificates: certificate),
        ])
        session = Session(serverTrustManager: trustManager)
        try! print(trustManager.serverTrustEvaluator(forHost: "api.staging.rainmaker.espressif.com") ?? "")
    }

    private static func certificate(filename: String) -> SecCertificate {
        let filePath = Bundle.main.path(forResource: filename, ofType: "der")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let certificate = SecCertificateCreateWithData(nil, data as CFData)!

        return certificate
    }

    // MARK: - Node APIs

    /// Get list of nodes associated with the user
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node list is recieved
    func getNodeList(completionHandler: @escaping ([Node]?, Error?) -> Void) {
        User.shared.getAccessToken(completionHandler: { accessToken in
            if accessToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": accessToken!]
                let url = Constants.getNodes
                self.session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    print(response)
                    switch response.result {
                    case let .success(value):
                        if let json = value as? [String: Any], let tempArray = json["nodes"] as? [String] {
                            var nodeList: [Node] = []
                            // Start a service group to schedule fetching of node related information
                            // Configuration and status information for each node will be fetched on background thread
                            let serviceGroup = DispatchGroup()

                            for item in tempArray {
                                serviceGroup.enter()
                                // Fetch node config
                                self.getNodeConfig(nodeID: item, headers: headers, completionHandler: { node, _ in
                                    if let newNode = node {
                                        // Insert node with only one device in the first index of the array to allow ease in rendering
                                        if newNode.devices?.count == 1 {
                                            nodeList.insert(newNode, at: 0)
                                        } else {
                                            nodeList.append(newNode)
                                        }

                                        // Get device thing shadow
                                        self.getDeviceThingShadow(nodeID: item) { response in
                                            if let image = response, let devices = node?.devices {
                                                print(image)
                                                for device in devices {
                                                    // Parse and fill device params and attributes
                                                    if let deviceName = device.name, let attrbutes = image[deviceName] as? [String: Any] {
                                                        if let params = device.params {
                                                            for index in params.indices {
                                                                if let reportedValue = attrbutes[params[index].name ?? ""] {
                                                                    params[index].value = reportedValue
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            // Node related information is recieved so leave service group
                                            serviceGroup.leave()
                                        }
                                    }
                                })
                            }
                            // When node list is exhausted then call completionHandler with node list as parameter
                            serviceGroup.notify(queue: .main) {
                                completionHandler(nodeList, nil)
                            }
                        } else {
                            completionHandler(nil, CustomError.emptyNodeList)
                        }
                    case let .failure(error):
                        print(error)
                        completionHandler(nil, NetworkError.emptyToken)
                    }
                }
            } else {
                completionHandler(nil, NetworkError.emptyToken)
            }
        })
    }

    /// Get node config json
    ///
    /// - Parameters:
    ///   - completionHandler: handler called when response to get node config is recieved
    func getNodeConfig(nodeID: String, headers: HTTPHeaders, completionHandler: @escaping (Node?, Error?) -> Void) {
        let url = Constants.getNodeConfig + "?nodeid=" + nodeID
        session.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            switch response.result {
            case let .success(value):
                if let json = value as? [String: Any] {
                    self.getNodeStatus(node: JSONParser.parseNodeData(data: json, nodeID: nodeID), completionHandler: completionHandler)
                } else {
                    completionHandler(nil, CustomError.emptyConfigData)
                }
            case let .failure(error):
                print(error)
                completionHandler(nil, CustomError.emptyConfigData)
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
                    print(response)
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
    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, Error?) -> Void) {
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
                            print("Add device successfull)")
                            // Get request id for add device request
                            // This request id will be used for getting the status of add request
                            print("JSON: \(json)")
                            if let requestId = json[Constants.requestID] {
                                completionHandler(requestId, nil)
                                return
                            }
                        }
                    case let .failure(error):
                        // Check for any error on response
                        print("Add device error \(error)")
                        completionHandler(nil, error)
                        return
                    }

                    completionHandler(nil, CustomError.emptyConfigData)
                }
            } else {
                completionHandler(nil, NetworkError.emptyToken)
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
                        if let json = value as? [String: String], let status = json["request_status"] as? String {
                            print(json)
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
        if let nodeid = nodeID {
            User.shared.getAccessToken(completionHandler: { idToken in
                if idToken != nil {
                    let url = Constants.updateThingsShadow + "?nodeid=" + nodeid
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                    self.session.request(url, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        print(parameter)
                        switch response.result {
                        case let .success(value):
                            if let json = value as? [String: Any] {
                                print(json)
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
