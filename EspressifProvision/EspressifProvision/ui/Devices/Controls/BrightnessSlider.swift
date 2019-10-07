//
//  BrightnessSlider.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 04/10/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import UIKit

class BrightnessSlider: UISlider {
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */

    @IBInspectable open var trackWidth: CGFloat = 2 {
        didSet { setNeedsDisplay() }
    }

    open override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let defaultBounds = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultBounds.origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height / 2 - trackWidth / 2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let defaultBounds = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let thumbOffsetToApplyOnEachSide: CGFloat = defaultBounds.size.width / 2.0
        let minOffsetToAdd = -thumbOffsetToApplyOnEachSide
        let maxOffsetToAdd = thumbOffsetToApplyOnEachSide
        let offsetForValue = minOffsetToAdd + (maxOffsetToAdd - minOffsetToAdd) * CGFloat(value / (maximumValue - minimumValue))
        var origin = defaultBounds.origin
        origin.x += offsetForValue
        return CGRect(
            x: origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height / 2 - trackWidth / 2,
            width: defaultBounds.size.width,
            height: trackWidth
        )
    }
}
