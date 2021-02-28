//
//  EditButtonFunctionTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 05/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit

class EditButtonFunctionTableViewController: UITableViewController, EditIndividualFunction, UITextFieldDelegate, SelectionTableViewControllerDelegate {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var messageField: FormattedTextField!
    @IBOutlet weak var repeatsLabel: UILabel!
    @IBOutlet weak var colorView: NeverClearView!
    
    var functions = [Function]()
    var functionIndex = 0
    
    var function: ButtonFunction {
        return functions[functionIndex] as! ButtonFunction
    }
    
    // note: don't change these (saved in json)
    let repeatOptions = ["Don't Repeat", "1Hz", "2Hz", "5Hz", "10Hz"]
    let repeatValues = [0, 1, 2, 5, 10]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = function.title
        
        nameField.text = function.title
        messageField.data = function.message
        messageField.selectedFormat = function.format
        repeatsLabel.text = function.repeats == 0 ? "Don't Repeat" : "\(function.repeats)Hz"
        colorView.backgroundColor = function.color
        
        colorView.layer.cornerRadius = colorView.bounds.height/2
        colorView.layer.masksToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        function.title = nameField.text ?? ""
        function.message = messageField.data
        function.format = messageField.selectedFormat
        
        do {
            try JSON.saveFunctions(functions)
        } catch {
            print("Error saving functions: \(error.localizedDescription)")
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 1 {
            let vc = ColorSelectionCollectionViewController()
            vc.callback = { newColor in
                self.function.color = newColor
                self.colorView.backgroundColor = newColor
            }
            
            show(vc, sender: self)
        } else if indexPath.row == 3 {
            let vc = SelectionTableViewController()
            vc.delegate = self
            vc.items = repeatOptions
            vc.selectedItem = repeatValues.index(of: function.repeats)
            
            show(vc, sender: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        function.title = nameField.text ?? ""
        title = function.title
    }
    
    func selectionTableWithTag(_ tag: Int, didSelectItem item: Int) {
        function.repeats = repeatValues[item]
    }
}
