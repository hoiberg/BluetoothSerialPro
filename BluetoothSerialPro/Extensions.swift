//
//  Extensions.swift
//  BluetoothSerialPro
//
//  Created by Alex on 20/02/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit


// ******************************************************
// *********************** General **********************
// ******************************************************

func delay(seconds delay: Double, callback: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: callback)
}


// ******************************************************
// ******************** Notifications *******************
// ******************************************************

extension NotificationCenter {
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?) {
        addObserver(observer, selector: aSelector, name: aName, object: nil)
    }
    
    func post(name aName: NSNotification.Name) {
        post(name: aName, object: nil)
    }
}

extension Notification.Name {
    static let disconnected = Notification.Name("disconnected")
    static let settingsChanged = Notification.Name("settingsChanged")
    static let inputOptionsChanged = Notification.Name("inputOptionsChanged")
    static let displayOptionsChanged = Notification.Name("displayOptionsChanged")
    static let alertsChanged = Notification.Name("alertsChanged")
    static let clearScreen = Notification.Name("clearScreen")
    static let functionsChanged = Notification.Name("functionsChanged")
    static let didSendData = Notification.Name("didSendData")
}


// ******************************************************
// ********************** UIColor ***********************
// ******************************************************

extension UIColor {
    convenience init(hexString: String) {
        let data = hexString.data(withFormat: .hex)
        let red = CGFloat(data[0])/255.0
        let green = CGFloat(data[1])/255.0
        let blue = CGFloat(data[2])/255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
    
    var hexString: String {
        let components = cgColor.components ?? [CGFloat(0), CGFloat(0), CGFloat(0)]
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        return String(format: "%02lX %02lX %02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }
    
    func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: -abs(percentage))
    }
    
    func adjustBrightness(by percentage: CGFloat = 30.0) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b < 1.0 {
                let newB: CGFloat = max(min(b + (percentage/110.0)*b, 1.0), 0,0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - (percentage/80.0)*s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        return self
    }
    
    /* WERKT REDELIJK
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if (self.getRed(&r, green: &g, blue: &b, alpha: &a)) {
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        } else {
            return nil
        }
    }*/
    
    /*// Adjusts brightness of color. WERKT NIET
    /// - parameter by: Value added to brightness (range -1 to +1, e.g. -0.2 makes it a little darker).
    /// - returns: Color adjusten in brightness (or white if it fails)
    func adjust(by p: CGFloat) -> UIColor {
        var h:CGFloat=0, s:CGFloat=0, b:CGFloat=0, a:CGFloat=0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: max(min(b+p, 1.0), 0.0), alpha: a)
        }
        
        return UIColor.white
    }*/

    var isLight: Bool {
        let components = cgColor.components!
        let brightness = CGFloat(components[0] * 299) + CGFloat(components[1] * 587) + CGFloat(components[2] * 114)
        return brightness/1000 < 0.5 ? false : true
    }
}

// ******************************************************
// ********************** UIDevice **********************
// ******************************************************

extension UIDevice {
    class var isPad: Bool {
        return current.userInterfaceIdiom == .pad
    }
    
    class var isPhone: Bool {
        return current.userInterfaceIdiom == .phone
    }
}


// ******************************************************
// ********************** UIButton **********************
// ******************************************************

extension UIButton {
    static fileprivate let minimumHitArea = CGSize(width: 44, height: 44)
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }
        
        let buttonSize = self.bounds.size,
        widthToAdd = max(UIButton.minimumHitArea.width - buttonSize.width, 0),
        heightToAdd = max(UIButton.minimumHitArea.height - buttonSize.height, 0),
        largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)
        
        return (largerFrame.contains(point)) ? self : nil
    }
}



// ******************************************************
// ******************** String Regex ********************
// ******************************************************

extension String {
    func matches(for regex: String, options: NSRegularExpression.Options = []) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: options)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}


// ******************************************************
// ******************* String Padding *******************
// ******************************************************

extension String {
    func leftPad(_ char: Character, minCount: Int) -> String {
        var copy = self
        while copy.count < minCount {
            copy.insert(char, at: startIndex)
        }
        return copy
    }
}


// ******************************************************
// ******************* String to Data *******************
// ******************************************************

extension String {
    enum Format: Int {
        case utf8 = 0
        case hex = 1
        case dec = 2
        case oct = 3
        case bin = 4
    }
    
    func data(withFormat format: Format) -> Data {
        var data = Data()
        switch format {
        case .utf8:
            if let d = self.data(using: .utf8) {
                return d
            } else {
                print("Conversion of string \(self) to data failed")
                return Data()
            }
            
        case .hex:
            matches(for: "[0-9a-f]{1,2}", options: .caseInsensitive).forEach {
                data.append(UInt8($0, radix: 16)!)
            }
            
        case .dec:
            matches(for: "[0-9]{1,3}").forEach {
                if let byte = UInt8($0, radix: 10) {
                    data.append(byte)
                }
            }
            
        case .oct:
            matches(for: "[0-7]{1,3}").forEach {
                if let byte = UInt8($0, radix: 8) {
                    data.append(byte)
                }
            }
            
        case .bin:
            matches(for: "[0-1]{1,8}").forEach {
                data.append(UInt8($0, radix: 2)!)
            }
        }
        
        return data
    }
}


// ******************************************************
// ******************* Data to String *******************
// ******************************************************

extension Data {
    func string(withFormat format: String.Format) -> String {
        if format == .utf8 {
            return String(data: self, encoding: .utf8) ?? "�"
        } else {
            var string = ""
            var index = 0
            
            forEach {
                string.append($0.string(withFormat: format))
                index += 1
                if index < count {
                    string.append(" ")
                }
            }
            
            return string
        }
    }
}


// ******************************************************
// ******************* Byte to String *******************
// ******************************************************

extension UInt8 {
    func string(withFormat format: String.Format) -> String {
        switch format {
        case .utf8:
            return String(bytes: [self], encoding: .utf8) ?? "�"
            
        case .hex:
            return String(self, radix: 16).leftPad("0", minCount: 2).uppercased()
            
        case .dec:
            return String(self, radix: 10).leftPad("0", minCount: 3)
            
        case .oct:
            return String(self, radix: 8).leftPad("0", minCount: 3)
            
        case .bin:
            return String(self, radix: 2).leftPad("0", minCount: 8)
        }
    }
}
