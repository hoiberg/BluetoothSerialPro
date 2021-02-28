//
//  InputOptionsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 25/02/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

class InputOptionsTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var formatSegments: UISegmentedControl!
    @IBOutlet weak var appendToEndSegements: UISegmentedControl!
    @IBOutlet weak var maxChunkSizeField: UITextField!
    
    private let appendToEndOptions = ["", "\n", "\r", "\r\n"] // duplicate in FunctionOptionsTVC
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        formatSegments.selectedSegmentIndex = Settings.inputFormat.value
        appendToEndSegements.selectedSegmentIndex = appendToEndOptions.index(of: Settings.appendToInput.value)!
        maxChunkSizeField.text = "\(Settings.maxChunkSize.value)"
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }
        
        let allowed = "0123456789"
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
    
    @IBAction func done(_ sender: Any) {
        Settings.inputFormat.value = formatSegments.selectedSegmentIndex
        Settings.appendToInput.value = appendToEndOptions[appendToEndSegements.selectedSegmentIndex]
        Settings.maxChunkSize.value = Int(maxChunkSizeField.text!)!
        NotificationCenter.default.post(name: .inputOptionsChanged)
        dismiss(animated: true)
    }
    
    @IBAction func reset(_ sender: Any) {
        formatSegments.selectedSegmentIndex = Settings.inputFormat.defaultValue
        appendToEndSegements.selectedSegmentIndex = appendToEndOptions.index(of: Settings.appendToInput.defaultValue)!
        maxChunkSizeField.text = "\(Settings.maxChunkSize.defaultValue)"
    }
}
