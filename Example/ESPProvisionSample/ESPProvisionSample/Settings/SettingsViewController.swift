// Copyright 2020 Espressif Systems
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
//  SettingsViewController.swift
//  ESPProvisionSample
//

import UIKit
import ESPProvision

// Class to change and manage provisioning settings
class SettingsViewController: UIViewController {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerToolbar: UIToolbar!
    @IBOutlet weak var selectionLabel: UILabel!
    @IBOutlet weak var securityLabel: UILabel!
    @IBOutlet weak var usernamTextField: UITextField!
    @IBOutlet weak var securityToggle: UISwitch!
    @IBOutlet weak var usernameView: UIView!
    
    // MARK: - Overriden Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        selectionLabel.text = Utility.shared.espAppSettings.deviceType.value
        usernamTextField.text = Utility.shared.espAppSettings.username
        switch Utility.shared.espAppSettings.securityMode {
        case .unsecure:
            securityLabel.text = "Unsecured"
            securityToggle.setOn(false, animated: true)
            usernameView.isHidden = true
        default:
            securityLabel.text = "Secured"
            securityToggle.setOn(true, animated: true)
            usernameView.isHidden = false
        }
        
        // Adding tap gesture to hide keyboard on outside touch
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - IBActions
    
    @IBAction func cancel(_ sender: Any) {
        hidePickerView()
    }
    
    @IBAction func done(_ sender: Any) {
        selectionLabel.text = DeviceType.allCases[pickerView.selectedRow(inComponent: 0)].value
        Utility.shared.espAppSettings.deviceType = DeviceType.allCases[pickerView.selectedRow(inComponent: 0)]
        Utility.shared.saveAppSettings()
        hidePickerView()
    }
    
    @IBAction func showPickerView(_ sender: Any) {
        pickerView.selectRow(Utility.shared.espAppSettings.deviceType.rawValue, inComponent: 0, animated: true)
        pickerView.isHidden = false
        pickerToolbar.isHidden = false
    }
    
    @IBAction func togglePressed(_ sender: UISwitch) {
        if sender.isOn {
            Utility.shared.espAppSettings.securityMode = .secure2
            securityLabel.text = "Secured"
            usernameView.isHidden = false
        } else {
            Utility.shared.espAppSettings.securityMode = .unsecure
            securityLabel.text = "Unsecured"
            usernameView.isHidden = true
        }
        Utility.shared.saveAppSettings()
    }
    
    @IBAction func backButtonPresses(_ sender: Any) {
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - Others
    
    func hidePickerView() {
        pickerToolbar.isHidden = true
        pickerView.isHidden = true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillDisappear() {
        if let username = usernamTextField.text {
            Utility.shared.espAppSettings.username = username
            Utility.shared.saveAppSettings()
        }
    }
    
}

extension SettingsViewController: UIPickerViewDelegate  {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return DeviceType.allCases[row].value
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
}

extension SettingsViewController:UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return DeviceType.allCases.count
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}
