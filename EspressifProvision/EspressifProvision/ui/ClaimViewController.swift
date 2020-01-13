//
//  ClaimViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 10/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class ClaimViewController: UIViewController {
    @IBOutlet var popTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func cancelClicked(_: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        let destination = segue.destination as! ProvisionViewController
        destination.pop = popTextField.text ?? "abcd1234"
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
