//
//  DeviceDetailViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 30/05/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import MBProgressHUD
import UIKit

class DeviceDetailViewController: UIViewController {
    var loginStatus = false
    var device: AlexaDevice?
    var avsConfig: ConfigureAVS?
    @IBOutlet var signedInViewContainer: UIView!
    @IBOutlet var signedOutViewContainer: UIView!
    @IBOutlet var learnMoreTextView: UITextView!

    override func viewDidLoad() {
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: 50, height: 40))

        label.text = device?.friendlyname
        label.numberOfLines = 2
        label.textColor = .black
        label.sizeToFit()
        label.textAlignment = .center

        navigationItem.title = device?.friendlyname

        // Do any additional setup after loading the view, typically from a nib.
        let attributedString = NSMutableAttributedString(string: "To learn more and access additional features, download the Alexa app")
        let url = URL(string: "alexa://")!
        var redirectURL = url
        if !UIApplication.shared.canOpenURL(url) {
            redirectURL = URL(string: "https://apps.apple.com/in/app/amazon-alexa/id944011620")!
        }

        attributedString.setAttributes([.link: redirectURL], range: NSRange(location: attributedString.length - 9, length: 9))
        learnMoreTextView.attributedText = attributedString
        learnMoreTextView.isUserInteractionEnabled = true
        learnMoreTextView.isEditable = false

        // Set how links should appear: blue and underlined
        learnMoreTextView.linkTextAttributes = [
            .foregroundColor: UIColor.blue,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        learnMoreTextView.textAlignment = .center
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        updateUIView()
    }

    @IBAction func signInAmazon(_: Any) {
        Constants.showLoader(message: "Signing In", view: view)
        let transport = SoftAPTransport(baseUrl: device!.hostAddress! + ":80")
        let security = Security0()
        let session = Session(transport: transport, security: security)
        session.initialize(response: nil) { error in
            guard error == nil else {
                print("Error in establishing session \(error.debugDescription)")
                MBProgressHUD.hide(for: self.view, animated: true)
                return
            }
            if session.isEstablished {
                let prov = Provision(session: session)
                _ = prov.getAVSDeviceDetails(completionHandler: { _, error in
                    guard error == nil else {
                        print(error!)
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        ConfigureAVS.loginWithAmazon(completionHandler: { avsDetails, error in
                            if error == nil {
                                prov.putAVSDeviceDetails(config: avsDetails!, completionHandler: {
                                    DispatchQueue.main.async {
                                        self.loginStatus = true
                                        self.updateUIView()
                                    }
                                })
                            }
                            MBProgressHUD.hide(for: self.view, animated: true)
                        })
                    }
                })
            } else {
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
        }
    }

    @objc func signOut() {
        Constants.showLoader(message: "Signing Out", view: view)
        avsConfig?.signOut(completionHandler: { status in
            if !status {
                DispatchQueue.main.async {
                    self.loginStatus = false
                    UIView.animate(withDuration: 0.4, animations: {
                        self.updateUIView()
                    })
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
        })
    }

    func updateUIView() {
        if loginStatus {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOut))
            navigationItem.rightBarButtonItem?.tintColor = UIColor.white
            signedInViewContainer.isHidden = false
            signedOutViewContainer.isHidden = true
        } else {
            signedInViewContainer.isHidden = true
            signedOutViewContainer.isHidden = false
            navigationItem.rightBarButtonItem = nil
        }
    }
}
