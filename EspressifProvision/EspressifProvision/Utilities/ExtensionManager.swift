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
        let underlineWidth: CGFloat = UIScreen.main.bounds.size.width / CGFloat(numberOfSegments)
        let underlineHeight: CGFloat = 4.0
        let underlineXPosition = CGFloat(selectedSegmentIndex * Int(underlineWidth))
        let underLineYPosition = bounds.size.height - 1.0
        let underlineFrame = CGRect(x: underlineXPosition + (underlineWidth - 100) / 2.0, y: underLineYPosition, width: 100, height: underlineHeight)
        let underline = UIView(frame: underlineFrame)
        underline.backgroundColor = UIColor(red: 83 / 255, green: 48 / 255, blue: 185 / 255, alpha: 1.0)
        underline.tag = 1
        addSubview(underline)
    }

    func changeUnderlineColor(color: UIColor) {
        guard let underline = self.viewWithTag(1) else { return }
        underline.backgroundColor = color
    }

    func changeUnderlinePosition() {
        guard let underline = self.viewWithTag(1) else { return }
        let underlineFinalXPosition = (UIScreen.main.bounds.size.width / CGFloat(numberOfSegments)) * CGFloat(selectedSegmentIndex)
        let underlineWidth: CGFloat = UIScreen.main.bounds.size.width / CGFloat(numberOfSegments)
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

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

extension UITextField {
    func togglePasswordVisibility() {
        isSecureTextEntry = !isSecureTextEntry

        if let existingText = text, isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             continues typing unless we intervene. This is prevented by first
             deleting the existing text and then recovering the original text. */
            deleteBackward()

            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        /* Reset the selected text range since the cursor can end up in the wrong
         position after a toggle because the text might vary in width */
        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}

extension UserDefaults {
    func set(_ color: UIColor?, forKey defaultName: String) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard let color = color, color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        else {
            removeObject(forKey: defaultName)
            return
        }
        let count = MemoryLayout<CGFloat>.size
        set(Data(bytes: &red, count: count) +
            Data(bytes: &green, count: count) +
            Data(bytes: &blue, count: count) +
            Data(bytes: &alpha, count: count), forKey: defaultName)
    }

    func color(forKey defaultName: String) -> UIColor? {
        guard let data = data(forKey: defaultName) else {
            return nil
        }
        let size = MemoryLayout<CGFloat>.size
        return UIColor(red: data[size * 0 ..< size * 1].withUnsafeBytes { $0.load(as: CGFloat.self) },
                       green: data[size * 1 ..< size * 2].withUnsafeBytes { $0.load(as: CGFloat.self) },
                       blue: data[size * 2 ..< size * 3].withUnsafeBytes { $0.load(as: CGFloat.self) },
                       alpha: data[size * 3 ..< size * 4].withUnsafeBytes { $0.load(as: CGFloat.self) })
    }
}

extension UserDefaults {
    var backgroundColor: UIColor? {
        get {
            return color(forKey: Constants.appThemeKey)
        }
        set {
            set(newValue, forKey: Constants.appThemeKey)
        }
    }

    func imageForKey(key: String) -> UIImage? {
        var image: UIImage?
        if let imageData = data(forKey: key) {
            image = NSKeyedUnarchiver.unarchiveObject(with: imageData) as? UIImage
        }
        return image
    }

    func setImage(image: UIImage?, forKey key: String) {
        var imageData: NSData?
        if let image = image {
            imageData = NSKeyedArchiver.archivedData(withRootObject: image) as NSData?
        }
        set(imageData, forKey: key)
    }
}

extension Int {
    func getShortDate() -> String {
        let date = Date(timeIntervalSince1970: Double(self) / 1000.0)
        let dataFormatter = DateFormatter()
        dataFormatter.timeZone = .current
        if Calendar.current.isDateInToday(date) {
            dataFormatter.dateFormat = "HH:mm"
            return dataFormatter.string(from: date)
        }
        dataFormatter.dateFormat = "dd/MM/yy, HH:mm"
        return dataFormatter.string(from: date)
    }
}
