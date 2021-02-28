//
//  FormattedTextField.swift
//  BluetoothSerialPro
//
//  Created by Alex on 06/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

@objc
protocol FormattedTextFieldDelegate: AnyObject {
    func formattedTextFieldDidEndEditing(_ formattedTextField: FormattedTextField)
}

@IBDesignable
class FormattedTextField: UIView, UITextFieldDelegate {

   @IBOutlet weak var delegate: FormattedTextFieldDelegate?
    
    var textField: UITextField!
    var button: UIButton!
    
    var selectedFormat = String.Format.hex {
        didSet {
            let theData = textField.text?.data(withFormat: oldValue) ?? Data()
            textField.text = theData.string(withFormat: selectedFormat)
            button.setTitle(["UTF8", "HEX", "DEC", "OCT", "BIN"][selectedFormat.rawValue], for: .normal)
        }
    }
    
    var data: Data {
        get { return textField.text?.data(withFormat: selectedFormat) ?? Data() }
        set { textField.text = newValue.string(withFormat: selectedFormat) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        addSubviews()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        addSubviews()
    }
    
    func addSubviews() {
        textField = UITextField()
        textField.delegate = self
        textField.font = UIFont(name: "Menlo-Regular", size: 17)
        textField.textAlignment = .right
        textField.placeholder = "Enter Value"
        textField.returnKeyType = .done
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        
        button = UIButton(type: .system)
        button.addTarget(self, action: #selector(changeFormat), for: .touchUpInside)
        button.setTitle("HEX", for: .normal)
        button.titleLabel!.font = UIFont(name: "Menlo-Regular", size: 15)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        
        let thc = NSLayoutConstraint(item: textField, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        let tlc = NSLayoutConstraint(item: textField, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0)
        let tvc = NSLayoutConstraint(item: textField, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let tbc = NSLayoutConstraint(item: textField, attribute: .trailing, relatedBy: .equal, toItem: button, attribute: .leading, multiplier: 1.0, constant: -6)
        let bhc = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1.0, constant: 0)
        let bbc = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: button, attribute: .height, multiplier: 1.4, constant: 0)
        let bvc = NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)
        let btc = NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0)
        addConstraints([thc, tlc, tvc, tbc, bhc, bbc, bvc, btc])
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }
        
        if selectedFormat == .utf8 { return true }
        
        var allowed = " ,.-01"
        if selectedFormat == .hex { allowed += "23456789abcdef" }
        if selectedFormat == .dec { allowed += "23456789" }
        if selectedFormat == .oct { allowed += "234567" }
        
        for char in string {
            if !allowed.contains(char) {
                return false
            }
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let x = data
        data = x
        
        delegate?.formattedTextFieldDidEndEditing(self)
    }
    
    @objc func changeFormat() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "UTF8", style: .default) { _ in self.selectedFormat = .utf8 })
        alert.addAction(UIAlertAction(title: "Hexadecimal", style: .default) { _ in self.selectedFormat = .hex })
        alert.addAction(UIAlertAction(title: "Decimal", style: .default) { _ in self.selectedFormat = .dec })
        alert.addAction(UIAlertAction(title: "Octal", style: .default) { _ in self.selectedFormat = .oct })
        alert.addAction(UIAlertAction(title: "Binary", style: .default) { _ in self.selectedFormat = .bin })
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        while let newRoot = rootViewController?.presentedViewController { rootViewController = newRoot }
        rootViewController?.present(alert, animated: true, completion: nil)
    }
}
