//
//  Colors.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 16/09/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Foundation
import UIKit

class Colors {
    var gl: CAGradientLayer!
    var bg: CAGradientLayer!
    var hvl: CAGradientLayer!
    var backGroundLayer: CAGradientLayer!
    var devicesBgLayer: CAGradientLayer!
    var controlLayer: CAGradientLayer!
    var signUPLayer: CAGradientLayer!
    var successLayer: CAGradientLayer!

    init() {
        let colorTop = UIColor(red: 243.0 / 255.0, green: 104.0 / 255.0, blue: 101.0 / 255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 172.0 / 255.0, green: 14.0 / 255.0, blue: 13.0 / 255.0, alpha: 1.0).cgColor

        let bgcolorTop = UIColor(red: 241.0 / 255.0, green: 220.0 / 255.0, blue: 220.0 / 255.0, alpha: 1.0).cgColor
        let bgcolorBottom = UIColor(red: 249.0 / 255.0, green: 156.0 / 255.0, blue: 156.0 / 255.0, alpha: 1.0).cgColor

        let hvcolorTop = UIColor(red: 255.0 / 255.0, green: 201.0 / 255.0, blue: 202.0 / 255.0, alpha: 1.0).cgColor
        let hvcolorBottom = UIColor(red: 255.0 / 255.0, green: 97.0 / 255.0, blue: 99.0 / 255.0, alpha: 1.0).cgColor

        let backGroundLayerTop = UIColor(red: 68.0 / 255.0, green: 181.0 / 255.0, blue: 181.0 / 255.0, alpha: 1.0).cgColor
        let backGroundLayerBottom = UIColor(red: 239.0 / 255.0, green: 88.0 / 255.0, blue: 87.0 / 255.0, alpha: 1.0).cgColor

        let devicesBgLayerTop = UIColor(red: 255.0 / 255.0, green: 204.0 / 255.0, blue: 14.0 / 255.0, alpha: 1.0).cgColor
        let devicesBgLayerMiddle = UIColor(red: 255.0 / 255.0, green: 72.0 / 255.0, blue: 114.0 / 255.0, alpha: 1.0).cgColor
        let devicesBgLayerBottom = UIColor(red: 166.0 / 255.0, green: 17.0 / 255.0, blue: 138.0 / 255.0, alpha: 1.0).cgColor

        let controlLayerTop = UIColor(red: 194.0 / 255.0, green: 94.0 / 255.0, blue: 164.0 / 255.0, alpha: 1.0).cgColor
        let controlLayerMiddle = UIColor(red: 115.0 / 255.0, green: 86.0 / 255.0, blue: 166.0 / 255.0, alpha: 1.0).cgColor
        let controlLayerBottom = UIColor(red: 61.0 / 255.0, green: 85.0 / 255.0, blue: 166.0 / 255.0, alpha: 1.0).cgColor

        let signUpLayerTop = UIColor(red: 245.0 / 255.0, green: 181.0 / 255.0, blue: 54.0 / 255.0, alpha: 1.0).cgColor
        let signUpLayerBottom = UIColor(red: 244.0 / 255.0, green: 106.0 / 255.0, blue: 13.0 / 255.0, alpha: 1.0).cgColor

        let sucessLayerTop = UIColor(red: 189.0 / 255.0, green: 233.0 / 255.0, blue: 112.0 / 255.0, alpha: 1.0).cgColor
        let sucessLayerBottom = UIColor(red: 42.0 / 255.0, green: 124.0 / 255.0, blue: 50.0 / 255.0, alpha: 1.0).cgColor

        hvl = CAGradientLayer()
        hvl.colors = [hvcolorTop, hvcolorBottom]
        hvl.locations = [0.0, 1.0]
        bg = CAGradientLayer()
        bg.colors = [bgcolorTop, bgcolorBottom]
        bg.locations = [0.0, 1.0]
        gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.0, 1.0]
        backGroundLayer = CAGradientLayer()
        backGroundLayer.colors = [backGroundLayerTop, backGroundLayerBottom]
        backGroundLayer.locations = [0.0, 1.0]
        devicesBgLayer = CAGradientLayer()
        devicesBgLayer.colors = [devicesBgLayerTop, devicesBgLayerMiddle, devicesBgLayerBottom]
        devicesBgLayer.locations = [0.0, 0.5, 1.0]
        controlLayer = CAGradientLayer()
        controlLayer.colors = [controlLayerTop, controlLayerMiddle, controlLayerBottom]
        controlLayer.locations = [0.0, 0.5, 1.0]
        signUPLayer = CAGradientLayer()
        signUPLayer.colors = [signUpLayerTop, signUpLayerBottom]
        signUPLayer.locations = [0.0, 1.0]
        successLayer = CAGradientLayer()
        successLayer.colors = [sucessLayerTop, sucessLayerBottom]
        successLayer.locations = [0.0, 1.0]
    }
}
