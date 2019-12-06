//
//  LanguageListTableViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 20/11/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class LanguageListTableViewController: UITableViewController {
    var configureDevice: ConfigureDevice!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return configureDevice.languages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "languageListCell", for: indexPath)
        cell.textLabel?.text = configureDevice.languages[indexPath.row]
        if configureDevice.alexaDevice.language?.rawValue == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row != configureDevice.alexaDevice.language?.rawValue {
            Constants.showLoader(message: "Setting language", view: view)
            configureDevice.setDeviceLanguage(value: indexPath.row) { result in
                DispatchQueue.main.async {
                    Constants.hideLoader(view: self.view)
                    if result {
                        tableView.cellForRow(at: IndexPath(row: self.configureDevice.alexaDevice.language?.rawValue ?? 0, section: 0))?.accessoryType = .none
                        self.configureDevice.alexaDevice.language = Avs_Locale(rawValue: indexPath.row)
                        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 60.0
    }
}
