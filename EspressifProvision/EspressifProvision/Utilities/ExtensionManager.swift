//
//  ExtensionManager.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 29/12/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

extension UISegmentedControl {
    func removeBorder() {
        let backgroundImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: bounds.size)
        setBackgroundImage(backgroundImage, for: .normal, barMetrics: .default)
        setBackgroundImage(backgroundImage, for: .selected, barMetrics: .default)
        setBackgroundImage(backgroundImage, for: .highlighted, barMetrics: .default)

        let deviderImage = UIImage.getColoredRectImageWith(color: UIColor.clear.cgColor, andSize: CGSize(width: 1.0, height: bounds.size.height))
        setDividerImage(deviderImage, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
        let defaultAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor(red: 90.0 / 255.0, green: 38.0 / 255.0, blue: 192.0 / 255.0, alpha: 1.0),
        ]
        setTitleTextAttributes(defaultAttributes, for: .normal)
        setTitleTextAttributes(defaultAttributes, for: .selected)
    }

    func addUnderlineForSelectedSegment() {
        removeBorder()
        let underlineWidth: CGFloat = bounds.size.width / CGFloat(numberOfSegments)
        let underlineHeight: CGFloat = 4.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition + (underlineWidth - 100) / 2.0, y: underLineYPosition, width: 100, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = UIColor(red: 83 / 255, green: 48 / 255, blue: 185 / 255, alpha: 1.0)
        underline.tag = 1
        addSubview(underline)
    }

    func changeUnderlinePosition() {
        guard let underline = self.viewWithTag(1) else { return }
        let underlineFinalXPosition = (bounds.width / CGFloat(numberOfSegments)) * CGFloat(selectedSegmentIndex)
        let underlineWidth: CGFloat = bounds.size.width / CGFloat(numberOfSegments)
        UIView.animate(withDuration: 0.1, animations: {
            underline.frame.origin.x = underlineFinalXPosition + (underlineWidth - 100) / 2.0
        })
    }
}

extension UIImage {
    class func getColoredRectImageWith(color: CGColor, andSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let graphicsContext = UIGraphicsGetCurrentContext()
        graphicsContext?.setFillColor(color)
        let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        graphicsContext?.fill(rectangle)
        let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rectangleImage!
    }
}

extension UITextField {
    func setBottomBorder(color: CGColor = UIColor(red: 255.0 / 255.0, green: 97.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0).cgColor) {
        borderStyle = .none
        layer.backgroundColor = UIColor.clear.cgColor

        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: frame.height - 1, width: frame.width, height: 1.0)
        bottomLine.backgroundColor = color
        borderStyle = UITextField.BorderStyle.none
        layer.addSublayer(bottomLine)
    }
}
