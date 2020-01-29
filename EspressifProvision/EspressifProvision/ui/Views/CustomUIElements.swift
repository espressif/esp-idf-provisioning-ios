//
//  TopBarView.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class TopBarView: UIView {
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let bgColor = Constants.backgroundColor {
            backgroundColor = UIColor(hexString: bgColor)
        }
    }
}

class PrimaryButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let bgColor = Constants.backgroundColor {
            backgroundColor = UIColor(hexString: bgColor)
        }
    }
}
