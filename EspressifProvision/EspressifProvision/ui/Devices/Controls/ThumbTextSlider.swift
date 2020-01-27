//
//  ThumbTextSlider.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 21/01/20.
//  Copyright © 2020 Espressif. All rights reserved.
//

import UIKit

class ThumbTextSlider: UISlider {
    var thumbTextLabel: UILabel = UILabel()
    @IBInspectable var trackHeight: CGFloat = 3

    @IBInspectable var thumbRadius: CGFloat = 40

    // Custom thumb view which will be converted to UIImage
    // and set as thumb. You can customize it's colors, border, etc.
    private lazy var thumbView: UIView = {
        let thumb = UIView()
        thumb.backgroundColor = UIColor(hexString: "#5330b9") //thumbTintColor
        thumb.layer.borderWidth = 0.4
        thumb.layer.borderColor = UIColor.darkGray.cgColor
        return thumb
    }()

    private var thumbFrame: CGRect {
        return thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        thumbTextLabel.frame = thumbFrame
        thumbTextLabel.textColor = UIColor.white
        thumbTextLabel.text = "\(Int(value))"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let thumb = thumbImage(radius: thumbRadius)
        setThumbImage(thumb, for: .normal)
        thumbTextLabel.textAlignment = .center
        thumbTextLabel.layer.zPosition = layer.zPosition + 1
        addSubview(thumbTextLabel)
    }

    private func thumbImage(radius: CGFloat) -> UIImage {
        // Set proper frame
        // y: radius / 2 will correctly offset the thumb

        thumbView.frame = CGRect(x: 0, y: radius / 2, width: radius, height: radius)
        thumbView.layer.cornerRadius = radius / 2

        // Convert thumbView to UIImage
        // See this: https://stackoverflow.com/a/41288197/7235585

        let renderer = UIGraphicsImageRenderer(bounds: thumbView.bounds)
        return renderer.image { rendererContext in
            thumbView.layer.render(in: rendererContext.cgContext)
        }
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        // Set custom track height
        // As seen here: https://stackoverflow.com/a/49428606/7235585
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = trackHeight
        return newRect
    }
}
