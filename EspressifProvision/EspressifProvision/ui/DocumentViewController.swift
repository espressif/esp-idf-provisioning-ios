//
//  DocumentViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 31/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit
import WebKit

class DocumentViewController: UIViewController {
    var documentLink: String!
    @IBOutlet var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: URL(string: documentLink)!))
        // Do any additional setup after loading the view.
    }

    @IBAction func closeWebView(_: Any) {
        dismiss(animated: true, completion: nil)
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
