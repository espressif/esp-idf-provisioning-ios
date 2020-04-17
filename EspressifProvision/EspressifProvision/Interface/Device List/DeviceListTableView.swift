//
//  DeviceListTableView.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 02/08/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class DeviceListTableView: UITableView {
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height

    override func reloadData() {
        super.reloadData()
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    override var intrinsicContentSize: CGSize {
        let height = min(contentSize.height, maxHeight)
        return CGSize(width: contentSize.width, height: height + 50)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}
