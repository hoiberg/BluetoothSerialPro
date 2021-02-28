//
//  AlertDetailTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 16/04/2019.
//  Copyright © 2019 Hangar42. All rights reserved.
//

import UIKit

class AlertDetailTableViewController: UITableViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var isActiveSwitch: UISwitch!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var triggerField: FormattedTextField!
    @IBOutlet weak var soundLabel: UILabel!
    @IBOutlet weak var showAlertSwitch: UISwitch!
    
    
    // MARK: - Variables
    
    var alerts: [DataAlert]!
    var alert: DataAlert!

    
    // MARK: - ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        title = alert.title.isEmpty ? "Unnamed Alert" : alert.title
        isActiveSwitch.isOn = alert.isActive
        nameField.text = alert.title
        triggerField.data = alert.trigger
        triggerField.selectedFormat = alert.format
        soundLabel.text = alert.sound.name
        showAlertSwitch.isOn = alert.showAlert
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        alert.isActive = isActiveSwitch.isOn
        
        // here because textFieldDidEndEditing may be called after this function
        if let new = nameField.text, !new.isEmpty {
            alert.title = new
        }
        
        // same
        if !triggerField.data.isEmpty {
            alert.trigger = triggerField.data
        }
        
        alert.format = triggerField.selectedFormat
        
        // sound is set in alertsoundstableviewcontroller
        
        alert.showAlert = showAlertSwitch.isOn
        
        do {
            try JSON.saveAlerts(alerts)
        } catch {
            print("Error saving alerts: \(error.localizedDescription)")
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlertSounds" {
            let dest = segue.destination as! AlertSoundsTableViewController
            dest.alert = alert
        }
    }
    
}


extension AlertDetailTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let new = nameField.text, !new.isEmpty {
            title = new
        } else {
            nameField.text = alert.title
        }
    }
    
}


extension AlertDetailTableViewController: FormattedTextFieldDelegate {
    
    func formattedTextFieldDidEndEditing(_ formattedTextField: FormattedTextField) {
        if triggerField.data.isEmpty {
            triggerField.data = alert.trigger
        }
    }
}
