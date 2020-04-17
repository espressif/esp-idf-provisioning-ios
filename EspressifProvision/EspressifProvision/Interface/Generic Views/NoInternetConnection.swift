//
//  NoInternetConnection.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 23/02/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class NoInternetConnection: UIView {
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */
    class func instanceFromNib() -> NoInternetConnection {
        return UINib(nibName: "NoInternetConnection", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! NoInternetConnection
    }

    @IBAction func retryPressed(_: Any) {
        removeFromSuperview()
    }
}
