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

        if User.shared.userInfo.loggedInWith == .github {
            changePasswordView.isHidden = true
        }

        emailLabel.text = User.shared.userInfo.email
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIView), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
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

    @objc func updateUIView() {
        for subview in view.subviews {
            subview.setNeedsDisplay()
            for item in subview.subviews {
                item.setNeedsDisplay()
            }
        }
    }

    @IBAction func signOut(_: Any) {
        User.shared.currentUser()?.signOut()
        UserDefaults.standard.removeObject(forKey: Constants.userInfoKey)
        UserDefaults.standard.removeObject(forKey: Constants.refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: Constants.accessTokenKey)
        User.shared.accessToken = nil
        User.shared.userInfo = UserInfo(username: "", email: "", userID: "", loggedInWith: .cognito)
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

    @IBAction func openPrivacy(_: Any) {
        showDocumentVC(url: "https://espressif.github.io/esp-jumpstart/privacy-policy/")
    }

    @IBAction func openTC(_: Any) {
        showDocumentVC(url: "https://espressif.github.io/esp-jumpstart/privacy-policy/")
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }

    func showDocumentVC(url: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let documentVC = storyboard.instantiateViewController(withIdentifier: "documentVC") as! DocumentViewController
        modalPresentationStyle = .popover
        documentVC.documentLink = url
        present(documentVC, animated: true, completion: nil)
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
