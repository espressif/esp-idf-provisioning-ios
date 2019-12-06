//
//  AppInfoViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 06/12/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class AppInfoViewController: UIViewController {
    // App version info
    @IBOutlet var appVersionLabel: UILabel!
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        appVersionLabel.text = "App Version: \(appVersion)"
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
