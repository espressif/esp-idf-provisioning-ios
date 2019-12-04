//
//  StaticControlTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 03/12/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class StaticControlTableViewCell: UITableViewCell {
    @IBOutlet var backView: UIView!
    @IBOutlet var controlNameLabel: UILabel!
    @IBOutlet var controlValueLabel: UILabel!

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
}
