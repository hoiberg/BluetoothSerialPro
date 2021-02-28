//
//  RSSIIndicatorView.swift
//  BluetoothSerialPro
//
//  Created by Alex on 19/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

@IBDesignable
class RSSIIndicatorView: UIView {
    
    @IBInspectable var numberOfBars: CGFloat = 5
    @IBInspectable var lowestHeight: CGFloat = 0.2
    @IBInspectable var barPadding:   CGFloat = 0.05
    @IBInspectable var currentLevel: CGFloat = 2 { didSet { setNeedsDisplay() } }
    @IBInspectable var onColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    @IBInspectable var offColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)

    override func draw(_ rect: CGRect) {
        let width = bounds.width
        let height = bounds.height
        let padding = barPadding * width
        let barWidth = (width - (padding * (numberOfBars-1))) / numberOfBars
        let decrement = (height - (lowestHeight * height)) / (numberOfBars-2)
        let context = UIGraphicsGetCurrentContext()!
        
        for ii in 0 ..< Int(numberOfBars) {
            let i = CGFloat(ii)
            context.setFillColor(i < currentLevel ? onColor.cgColor : offColor.cgColor)
            context.fill(CGRect(x: i*barWidth + i*padding,
                                y: decrement * (numberOfBars - i - 1),
                            width: barWidth,
                           height: height - (decrement * (numberOfBars - i - 1))))
        }
    }
}
