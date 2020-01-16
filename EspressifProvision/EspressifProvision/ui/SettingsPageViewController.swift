//
//  SettingsPageViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 30/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class SettingsPageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
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
        User.shared.userID = nil
        dismiss(animated: true) {
            self.refresh()
        }
    }

    func refresh() {
        User.shared.currentUser()?.getDetails().continueOnSuccessWith { (_) -> AnyObject? in
            DispatchQueue.main.async {}
            return nil
        }
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
}
