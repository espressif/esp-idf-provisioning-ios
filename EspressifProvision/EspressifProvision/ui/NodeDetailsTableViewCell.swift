//
//  NodeDetailsTableViewCell.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 17/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class NodeDetailsTableViewCell: UITableViewCell {

    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
