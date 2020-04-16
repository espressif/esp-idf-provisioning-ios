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
    @IBOutlet var controlValueLabel: UILabel!
    @IBOutlet var editButton: UIButton!
    var controlValue: String?
    var attributeKey = ""
    var dataType: String = "String"
    var device: Device!
    var boolTypeValidValues: [String: Int] = ["true": 1, "false": 0, "yes": 1, "no": 0, "0": 0, "1": 1]
    var attribute: Param?

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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func editButtonTapped(_: Any) {
        if Utility.isConnected(view: parentViewController!.view) {
            var input: UIAlertController!
            if attribute?.type == "esp.param.name" {
                input = UIAlertController(title: attributeKey, message: "Enter device name of length 1-32 characters", preferredStyle: .alert)
            } else {
                input = UIAlertController(title: attributeKey, message: "Enter new value", preferredStyle: .alert)
            }
            input.addTextField { textField in
                textField.text = self.controlValue ?? ""
                self.addHeightConstraint(textField: textField)
            }

            input.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
            }))
            input.addAction(UIAlertAction(title: "Update", style: .default, handler: { [weak input] _ in
                let valueTextField = input?.textFields![0]
                self.controlValue = valueTextField?.text
                self.doneButtonAction()
            }))
            parentViewController?.present(input, animated: true, completion: nil)
        }
    }

    private func addHeightConstraint(textField: UITextField) {
        let heightConstraint = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
        textField.addConstraint(heightConstraint)
        textField.font = UIFont(name: textField.font!.fontName, size: 18)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Failure!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        parentViewController?.present(alert, animated: true, completion: nil)
    }

    @objc func valueUpdated() {}

    @objc func doneButtonAction() {
        if let value = controlValue {
            if dataType.lowercased() == "int" {
                if let intValue = Int(value) {
                    if let bounds = attribute?.bounds, let max = bounds["max"] as? Int, let min = bounds["min"] as? Int {
                        if intValue >= min, intValue <= max {
                            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: intValue]])
                            controlValueLabel.text = value
                        } else {
                            showAlert(message: "Value out of bound.")
                        }
                    } else {
                        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: intValue]])
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid integer value.")
                }
            } else if dataType.lowercased() == "float" {
                if let floatValue = Float(value) {
                    if let bounds = attribute?.bounds, let max = bounds["max"] as? Float, let min = bounds["min"] as? Float {
                        if floatValue >= min, floatValue <= max {
                            NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: floatValue]])
                            controlValueLabel.text = value
                        } else {
                            showAlert(message: "Value out of bound.")
                        }
                    } else {
                        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: floatValue]])
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid float value.")
                }
            } else if dataType.lowercased() == "bool" {
                if boolTypeValidValues.keys.contains(value) {
                    let validValue = boolTypeValidValues[value]!
                    if validValue == 0 {
                        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: false]])
                        controlValueLabel.text = value
                    } else {
                        NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: true]])
                        controlValueLabel.text = value
                    }
                } else {
                    showAlert(message: "Please enter a valid boolean value.")
                }
            } else {
                if attribute?.type == "esp.param.name" {
                    if value.count < 1 || value.count > 32 || value.isEmpty || value.trimmingCharacters(in: .whitespaces).isEmpty {
                        showAlert(message: "Please enter a valid device name within a range of 1-32 characters")
                        return
                    }
                }
                NetworkManager.shared.updateThingShadow(nodeID: device.node?.node_id, parameter: [device.name ?? "": [attributeKey: controlValue]])
                controlValueLabel.text = value
            }
            attribute?.value = controlValue as Any
        }
    }
}
