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
        addBottomRoundedEdge(desiredCurve: 1.0)
//        if let color = AppConstants.shared.appThemeColor {
//            backgroundColor = color
//        } else {
//            if let bgColor = Constants.backgroundColor {
//                backgroundColor = UIColor(hexString: bgColor)
//            }
//        }
    }

    override func setNeedsDisplay() {
        if let color = AppConstants.shared.appThemeColor {
            backgroundColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                backgroundColor = UIColor(hexString: bgColor)
            }
        }
    }
}

class PrimaryButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        if let color = AppConstants.shared.appThemeColor {
//            backgroundColor = color
//        } else {
//            if let bgColor = Constants.backgroundColor {
//                backgroundColor = UIColor(hexString: bgColor)
//            }
//        }
    }

    override func setNeedsDisplay() {
        if let color = AppConstants.shared.appThemeColor {
            backgroundColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                backgroundColor = UIColor(hexString: bgColor)
            }
        }
    }
}

class SecondaryButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let color = AppConstants.shared.appThemeColor {
            setTitleColor(color, for: .normal)
        } else {
            if let bgColor = Constants.backgroundColor {
                setTitleColor(UIColor(hexString: bgColor), for: .normal)
            }
        }
    }

    override func setNeedsDisplay() {
        if let color = AppConstants.shared.appThemeColor {
            setTitleColor(color, for: .normal)
        } else {
            if let bgColor = Constants.backgroundColor {
                setTitleColor(UIColor(hexString: bgColor), for: .normal)
            }
        }
    }
}

class BGImageView: UIImageView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .scaleAspectFill
        backgroundColor = .clear
        if let appBGImage = AppConstants.shared.appBGImage {
            image = appBGImage
        }
    }

    override func setNeedsDisplay() {
        if let appBGImage = AppConstants.shared.appBGImage {
            image = appBGImage
        } else {
            image = nil
        }
    }
}
