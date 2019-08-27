// Copyright 2018 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  SuccessViewController.swift
//  EspressifProvision
//

import Foundation
import UIKit

class SuccessViewController: UIViewController {
    @IBOutlet var learnMoreTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let attributedString = NSMutableAttributedString(string: "To learn more and access additional features, download the Alexa App")
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

        let righButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(presentVC))

        navigationItem.rightBarButtonItem = righButtonItem
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white

        navigationItem.setHidesBackButton(true, animated: true)

        navigationItem.title = "Things to try"
    }

    @objc func presentVC() {
        performSegue(withIdentifier: "presentFirstVC", sender: nil)
    }
}
