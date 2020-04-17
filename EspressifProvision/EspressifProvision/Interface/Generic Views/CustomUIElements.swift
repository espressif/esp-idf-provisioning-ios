//
//  TopBarView.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 28/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class TopBarView: UIView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        borderWidth = 1.0
        borderColor = UIColor.lightGray
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
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
        cornerRadius = 10.0
        borderWidth = 1.0
        borderColor = UIColor.lightGray
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor: UIColor = UIColor(hexString: "#5330b9")
        if let color = AppConstants.shared.appThemeColor {
            backgroundColor = color
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                backgroundColor = UIColor(hexString: bgColor)
                currentBGColor = backgroundColor!
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            setTitleColor(UIColor(hexString: "#5330b9"), for: .normal)
        } else {
            setTitleColor(UIColor.white, for: .normal)
        }
    }
}

class SecondaryButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor: UIColor = UIColor(hexString: "#5330b9")
        if let color = AppConstants.shared.appThemeColor {
            setTitleColor(color, for: .normal)
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                setTitleColor(UIColor(hexString: bgColor), for: .normal)
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            setTitleColor(UIColor(hexString: "#5330b9"), for: .normal)
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

class BarButton: UIButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            setTitleColor(UIColor(hexString: "#5330b9"), for: .normal)
        } else {
            setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1), for: .normal)
        }
    }
}

class BarTitle: UILabel {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        changeTheme()
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: Notification.Name(Constants.uiViewUpdateNotification), object: nil)
    }

    @objc func changeTheme() {
        var currentBGColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        if let color = AppConstants.shared.appThemeColor {
            currentBGColor = color
        } else {
            if let bgColor = Constants.backgroundColor {
                currentBGColor = UIColor(hexString: bgColor)
            }
        }
        if currentBGColor == #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1) {
            textColor = UIColor.black
        } else {
            textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        }
    }
}
