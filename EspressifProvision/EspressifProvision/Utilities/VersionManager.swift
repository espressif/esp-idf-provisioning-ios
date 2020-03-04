//
//  VersionManager.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 10/12/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import Foundation

class VersionManager {
    /// A singleton class that manages Version related info of app
    static let shared = VersionManager()

    let currentAppVersion = "1.0"
    let currentAPIVersion = "v1"

    private let supportedVersionURL = "https://yv4hu5b4oj.execute-api.us-east-1.amazonaws.com/dev/getapiversions"
    private var appStoreURL = "itms-apps://"

    private var mainWindow: UIWindow?
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        return window
    }()

    private init() {}

    private func checkAppStore(callback: ((_ versionAvailable: Bool?, _ version: String?) -> Void)? = nil) {
        let ourBundleId = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String
        AF.request("https://itunes.apple.com/lookup?bundleId=com.espressif.provbleavs").responseJSON { response in
            var isNew: Bool?
            var versionStr: String?

            switch response.result {
            case let .success(value):
                if let json = value as? NSDictionary,
                    let results = json["results"] as? NSArray,
                    let entry = results.firstObject as? NSDictionary,
                    let appVersion = entry["version"] as? String,
                    let ourVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    if let storeURL = entry["trackViewUrl"] as? String {
                        self.appStoreURL = storeURL
                    }
                    isNew = ourVersion != appVersion
                    versionStr = appVersion
                }
                callback?(isNew, versionStr)
            case let .failure(error):
                print(error)
            }
        }
    }

    private func checkIfAPIVersionIsSupported(callback: @escaping (Bool) -> Void) {
        AF.request(supportedVersionURL).responseJSON { response in
            switch response.result {
            case let .success(value):
                if let json = value as? [String: Any], let supportedVersion = json["supported_versions"] as? [String] {
                    if supportedVersion.contains(self.currentAPIVersion) {
                        callback(true)
                        return
                    }
                }
            case let .failure(error):
                print(error)
            }
            callback(false)
        }
    }

    func checkForAppUpdate() {
        checkAppStore { isAvailable, _ in
            if let available = isAvailable {
                if available {
                    self.checkIfAPIVersionIsSupported { isSupported in
                        if isSupported {
                            let ignoreAction = UIAlertAction(title: "Ignore", style: .default) { _ in
                            }
                            let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
                                self.goToAppStore()
                            }
                            let remindAction = UIAlertAction(title: "Remind me", style: .default) { _ in
                            }
                            self.showAlert(title: "Update", message: "A new version of this app is available on App Store to download.", actions: [updateAction, ignoreAction, remindAction])
                        } else {
                            let updateAction = UIAlertAction(title: "Update", style: .default) { _ in
                                self.goToAppStore()
                            }
                            self.showAlert(title: "Update", message: "A new version of this app is available on App Store to download.", actions: [updateAction])
                        }
                    }
                }
            }
        }
    }

    private func goToAppStore() {
        if let url = URL(string: self.appStoreURL) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for item in actions {
            alertController.addAction(item)
        }
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            // topController should now be your topmost view controller
            topController.present(alertController, animated: true, completion: nil)
        }
    }
}
