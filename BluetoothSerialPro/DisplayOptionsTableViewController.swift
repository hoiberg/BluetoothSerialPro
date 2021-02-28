//
//  DisplayOptionsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 26/02/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

class DisplayOptionsTableViewController: UITableViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var styleSegments: UISegmentedControl!
    @IBOutlet weak var formatSegments: UISegmentedControl!
    @IBOutlet weak var displaySentSwitch: UISwitch!
    @IBOutlet weak var autoScrollSwitch: UISwitch!

    @IBOutlet weak var afterEachCell: UITableViewCell!
    @IBOutlet weak var afterNewLineCell: UITableViewCell!
    @IBOutlet weak var afterAmountBytesCell: UITableViewCell!
    @IBOutlet weak var afterSpecificByteCell: UITableViewCell!
    
    @IBOutlet weak var byteCountTextField: UITextField!
    @IBOutlet weak var specificByteTextField: UITextField!
    
    @IBOutlet weak var displayTimeStampSwitch: UISwitch!
    @IBOutlet weak var displayMicrosecondsSwitch: UISwitch!
    @IBOutlet weak var displayRowNumberSwitch: UISwitch!
    
    @IBOutlet weak var playSoundsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let sWidth = UIScreen.main.bounds.width
        let sHeight = UIScreen.main.bounds.height
        if sqrt(pow(sWidth, 2)+pow(sHeight, 2)) < 660 { // 4 inch = 652pt diagonal
            styleSegments.setTitle("Chat", forSegmentAt: 1)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        styleSegments.selectedSegmentIndex = Settings.displayStyle.value
        formatSegments.selectedSegmentIndex = Settings.displayFormat.value
        displaySentSwitch.isOn = Settings.displaySentMessages.value
        autoScrollSwitch.isOn = Settings.autoScroll.value

        
        switch NewlineAfter(id: Settings.messageSeparation.value) {
        case .message: afterEachCell.accessoryType = .checkmark
        case .newLine: afterNewLineCell.accessoryType = .checkmark
        case .count(_): afterAmountBytesCell.accessoryType = .checkmark
        case .byte(_): afterSpecificByteCell.accessoryType = .checkmark
        }
        
        byteCountTextField.text = String(Settings.messageSeparationByteCount.value)
        specificByteTextField.text = UInt8(Settings.messageSeparationByte.value).string(withFormat: .hex)
        
        displayTimeStampSwitch.isOn = Settings.displayTimeStamps.value
        displayMicrosecondsSwitch.isOn = Settings.displayMicroseconds.value
        displayRowNumberSwitch.isOn = Settings.displayLineNumbers.value
        
        playSoundsSwitch.isOn = Settings.shouldPlaySounds.value
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        afterEachCell.accessoryType = .none
        afterNewLineCell.accessoryType = .none
        afterAmountBytesCell.accessoryType = .none
        afterSpecificByteCell.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }
        
        var allowed = "0123456789"
        if textField == specificByteTextField { allowed += "ABCDEF" }
        
        for char in string {
            if !allowed.contains(char) {
                return false
            }
        }
        
        if textField.text!.count - range.length + string.count > 2 {
            return false
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text == nil || textField.text!.isEmpty {
            if textField == byteCountTextField {
                byteCountTextField.text = String(Settings.messageSeparationByteCount.value)
            } else {
                specificByteTextField.text = UInt8(Settings.messageSeparationByte.value).string(withFormat: .hex)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func done(_ sender: Any) {
        Settings.displayStyle.value = styleSegments.selectedSegmentIndex
        Settings.displayFormat.value = formatSegments.selectedSegmentIndex
        Settings.displaySentMessages.value = displaySentSwitch.isOn
        Settings.autoScroll.value = autoScrollSwitch.isOn
        
        if afterEachCell.accessoryType == .checkmark { Settings.messageSeparation.value = NewlineAfter.message.id }
        if afterNewLineCell.accessoryType == .checkmark { Settings.messageSeparation.value = NewlineAfter.newLine.id }
        if afterAmountBytesCell.accessoryType == .checkmark { Settings.messageSeparation.value = NewlineAfter.count(0).id }
        if afterSpecificByteCell.accessoryType == .checkmark { Settings.messageSeparation.value = NewlineAfter.byte(0).id }
        
        Settings.messageSeparationByteCount.value = Int(byteCountTextField.text!)!
        Settings.messageSeparationByte.value = Int(specificByteTextField.text!, radix: 16)!
        
        Settings.displayTimeStamps.value = displayTimeStampSwitch.isOn
        Settings.displayMicroseconds.value = displayMicrosecondsSwitch.isOn
        Settings.displayLineNumbers.value = displayRowNumberSwitch.isOn
        
        Settings.shouldPlaySounds.value = playSoundsSwitch.isOn

        NotificationCenter.default.post(name: .displayOptionsChanged)
        dismiss(animated: true)
    }
    
    @IBAction func reset(_ sender: Any) {
        styleSegments.selectedSegmentIndex = Settings.displayStyle.defaultValue
        formatSegments.selectedSegmentIndex = Settings.displayFormat.defaultValue
        displaySentSwitch.isOn = Settings.displaySentMessages.defaultValue
        autoScrollSwitch.isOn = Settings.autoScroll.defaultValue
        
        afterEachCell.accessoryType = .none
        afterNewLineCell.accessoryType = .none
        afterAmountBytesCell.accessoryType = .none
        afterSpecificByteCell.accessoryType = .none
        
        switch NewlineAfter(id: Settings.messageSeparation.defaultValue) {
        case .message: afterEachCell.accessoryType = .checkmark
        case .count(_): afterAmountBytesCell.accessoryType = .checkmark
        case .byte(_): afterSpecificByteCell.accessoryType = .checkmark
        case .newLine: afterNewLineCell.accessoryType = .checkmark
        }
        
        byteCountTextField.text = String(Settings.messageSeparationByteCount.defaultValue)
        specificByteTextField.text = UInt8(Settings.messageSeparationByte.defaultValue).string(withFormat: .hex)
        
        displayTimeStampSwitch.isOn = Settings.displayTimeStamps.defaultValue
        displayMicrosecondsSwitch.isOn = Settings.displayMicroseconds.defaultValue
        displayRowNumberSwitch.isOn = Settings.displayLineNumbers.defaultValue
        
        playSoundsSwitch.isOn = Settings.shouldPlaySounds.defaultValue
    }
}
