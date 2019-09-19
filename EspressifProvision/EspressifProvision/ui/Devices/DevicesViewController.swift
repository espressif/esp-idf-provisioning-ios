//
//  DevicesViewController.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 11/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class DevicesViewController: UIViewController {
    var currentNode: Node!
    let storyBoard = UIStoryboard(name: "DeviceDetail", bundle: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Devices"

        let colors = Colors()
        view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.devicesBgLayer
        backgroundLayer!.frame = view.frame
        view.layer.insertSublayer(backgroundLayer!, at: 0)
    }
}

extension DevicesViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentDevice = currentNode.devices?[indexPath.row]
        let controlListVC = storyboard?.instantiateViewController(withIdentifier: "controlListVC") as! ControlListViewController
        controlListVC.device = currentDevice
        navigationController?.pushViewController(controlListVC, animated: true)
    }
}

extension DevicesViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return currentNode.devices?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "deviceCollectionViewCell", for: indexPath) as! DevicesCollectionViewCell
        cell.deviceName.text = currentNode.devices?[indexPath.row].name
        if currentNode.devices?[indexPath.row].type == "esp.device.lightbulb" {
            cell.deviceImageView.image = UIImage(named: "light_bulb")
        } else if currentNode.devices?[indexPath.row].type == "esp.device.switch" {
            cell.deviceImageView.image = UIImage(named: "switch")
        } else {
            cell.deviceImageView.image = UIImage(named: "generic_device")
        }
        return cell
    }
}

extension DevicesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: 125.0, height: 125.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        let leftInset = (collectionView.layer.frame.size.width - CGFloat(250.0 + 25.0)) / 2
        let rightInset = leftInset

        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
}
