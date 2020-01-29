//
//  SettingsPageViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 30/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import JWTDecode
import UIKit

class SettingsPageViewController: UIViewController {
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var changePasswordView: UIView!
    var username = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        if let idToken = User.shared.idToken {
            do {
                let json = try decode(jwt: idToken)
                if let email = json.body["email"] as? String {
                    emailLabel.text = email
                }
                username = json.body["cognito:username"] as? String ?? ""
            } catch {
                print("error parsing email")
            }
        }
        if let loginWith = UserDefaults.standard.value(forKey: Constants.loginIdKey) as? String {
            if loginWith == Constants.github {
                changePasswordView.isHidden = true
            }
        }
//        profileImage.image = imageWith(name: "V")
//        headerView.layer.masksToBounds = false
//        headerView.layer.shadowOffset = CGSize(width: 1, height: 1)
//        headerView.layer.shadowRadius = 0.5
//        headerView.layer.shadowColor = UIColor.gray.cgColor
//        headerView.layer.shadowOpacity = 1.0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @IBAction func signOut(_: Any) {
//        User.shared.associatedDevices = nil
        User.shared.idToken = nil
        User.shared.currentUser()?.signOut()
        UserDefaults.standard.removeObject(forKey: Constants.userIDKey)
        UserDefaults.standard.removeObject(forKey: Constants.refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: Constants.idTokenKey)
        UserDefaults.standard.removeObject(forKey: Constants.loginIdKey)
        User.shared.userID = nil
        User.shared.associatedNodeList = nil
        navigationController?.popViewController(animated: true)
        refresh()
    }

    func refresh() {
        User.shared.currentUser()?.getDetails().continueOnSuccessWith { (_) -> AnyObject? in
            DispatchQueue.main.async {}
            return nil
        }
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    func imageWith(name: String?) -> UIImage? {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let nameLabel = UILabel(frame: frame)
        nameLabel.textAlignment = .center
        nameLabel.backgroundColor = .white
        nameLabel.textColor = .lightGray
        nameLabel.font = UIFont.boldSystemFont(ofSize: 40)
        nameLabel.text = name
        UIGraphicsBeginImageContext(frame.size)
        if let currentContext = UIGraphicsGetCurrentContext() {
            nameLabel.layer.render(in: currentContext)
            let nameImage = UIGraphicsGetImageFromCurrentImageContext()
            return nameImage
        }
        return nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "changePasswordSegue" {
            let changePasswordVC = segue.destination as! ChangePasswordViewController
            changePasswordVC.username = username
        }
    }
}
