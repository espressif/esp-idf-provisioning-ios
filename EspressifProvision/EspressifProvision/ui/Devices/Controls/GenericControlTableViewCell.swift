//
//  GenericControlTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 18/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class GenericControlTableViewCell: UITableViewCell {
    @IBOutlet var backView: UIView!
    @IBOutlet var controlName: UILabel!
    @IBOutlet var controlValueTextField: UITextField!
    var controlValue: String?
    var attributeKey: String!
    var dataType: String = "String"
    var device: Device!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clear

        backView.layer.borderWidth = 1
        backView.layer.cornerRadius = 10
        backView.layer.borderColor = UIColor.clear.cgColor
        backView.layer.masksToBounds = true

        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false

        controlValueTextField.setBottomBorder(color: UIColor.black.cgColor)

        controlValueTextField.addTarget(self, action: #selector(valueUpdated), for: .editingDidEndOnExit)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @objc func valueUpdated() {
        if let value = controlValueTextField.text {
            controlValueTextField.text = "\(value)"
            controlValue = value
        } else {
            controlValueTextField.text = "\(controlValue!)"
        }
    }

    func addCancelButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(doneButtonAction))

        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()

        controlValueTextField.inputAccessoryView = doneToolbar
    }

    @objc func doneButtonAction() {
        controlValueTextField.resignFirstResponder()
        if let value = controlValue {
            if dataType.lowercased() == "int" {
                NetworkManager.shared.updateThingShadow(nodeID: device.node_id!, parameter: [attributeKey: Int(value)])
            } else if dataType.lowercased() == "float" {
                NetworkManager.shared.updateThingShadow(nodeID: device.node_id!, parameter: [attributeKey: Float(value)])
            } else if dataType.lowercased() == "bool" {
                NetworkManager.shared.updateThingShadow(nodeID: device.node_id!, parameter: [attributeKey: Bool(value)])
            } else {
                NetworkManager.shared.updateThingShadow(nodeID: device.node_id!, parameter: [attributeKey: controlValue])
            }
        }
    }
}
