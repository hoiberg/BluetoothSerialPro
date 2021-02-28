//
//  SettingsTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 24/02/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit
import MessageUI

class SettingsTableViewController: UITableViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {

    // MARK: - Outlets
    
    @IBOutlet weak var serviceTextField: UITextField!
    @IBOutlet weak var readCharTextField: UITextField!
    @IBOutlet weak var writeCharTextField: UITextField!
    @IBOutlet weak var showAllSwitch: UISwitch!
    @IBOutlet weak var autoReconnectSwitch: UISwitch!
    @IBOutlet weak var sendOnConnectField: FormattedTextField!
    
    
    // MARK: - Functions
    
    private func isValidUUID(_ string: String) -> Bool {
        return [4, 8].contains(string.count) // 128 (32char) doesn't seem to work (use NSUUID?(uuidString:) ?)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showAllSwitch.isOn = !Settings.scanAllDevices.value
        autoReconnectSwitch.isOn = Settings.autoReconnect.value
        serviceTextField.text = Settings.serviceUUID.value
        readCharTextField.text = Settings.readCharacteristicUUID.value
        writeCharTextField.text = Settings.writeCharacteristicUUID.value
        sendOnConnectField.data = Settings.sendOnConnect.value
        sendOnConnectField.selectedFormat = String.Format(rawValue: Settings.sendOnConnectFormat.value)!
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    // MARK: - TextField
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }
        
        let allowed = "0123456789ABCDEF"
        for char in string {
            if !allowed.contains(char) {
                return false
            }
        }
        
        if textField.text!.count - range.length + string.count > 8 {
            return false
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !isValidUUID(textField.text!) {
            if textField == serviceTextField { textField.text = Settings.serviceUUID.value }
            else if textField == readCharTextField { textField.text = Settings.readCharacteristicUUID.value }
            else if textField == writeCharTextField { textField.text = Settings.writeCharacteristicUUID.value }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: - MailComposeController Delegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    // MARK: - Actions
    
    @IBAction func importFunctions(_ sender: Any) {
        let documentsPicker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: .import)
        documentsPicker.delegate = self
        present(documentsPicker, animated: true)
    }
    
    @IBAction func exportFunctions(_ sender: UIButton) {
        RappleActivityIndicatorView.startAnimatingWithLabel("Loading...", attributes: RappleModernAttributes)
        DispatchQueue.global().async {
            do {
                // xml doc url
                let url = try JSON.createFunctionsCopy()
                
                // share sheet with said url
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                
                // iPad uses popover
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceRect = self.view.convert(sender.bounds, from: sender)
                    popover.sourceView = self.view
                }
                
                DispatchQueue.main.async {
                    RappleActivityIndicatorView.stopAnimation()
                    self.present(activityViewController, animated: true)
                }
            } catch {
                print("Failed to create copy of JSON file: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func sendFeedback(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([""])
            mail.setSubject("Bluetooth Serial Pro Feedback")
            mail.setMessageBody("\n\n\(UIDevice.current.systemInfo)", isHTML: false)
            present(mail, animated: true)
        } else {
            let alert = UIAlertController(title: "Cannot send mail", message: "Maybe there is no internet connection?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            present(alert, animated: true)
        }
    }

    @IBAction func leaveReview(_ sender: Any) {
        var string = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id="
        string += "1221924372" // App ID
        string += "&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"
        UIApplication.shared.openURL(URL(string: string)!)
    }
    
    @IBAction func done(_ sender: Any) {
        Settings.scanAllDevices.value = !showAllSwitch.isOn
        Settings.autoReconnect.value = autoReconnectSwitch.isOn
        
        // Seems better not to clear the UUID (more intuitive)
        /*if !autoReconnectSwitch.isOn {
            Settings.autoReconnectUUID.value = ""
        }*/
        
        if isValidUUID(serviceTextField.text!) {
            Settings.serviceUUID.value = serviceTextField.text!
        }
        
        if isValidUUID(readCharTextField.text!) {
            Settings.readCharacteristicUUID.value = readCharTextField.text!
        }
        
        if isValidUUID(writeCharTextField.text!) {
            Settings.writeCharacteristicUUID.value = writeCharTextField.text!
        }
        
        Settings.sendOnConnect.value = sendOnConnectField.data
        Settings.sendOnConnectFormat.value = sendOnConnectField.selectedFormat.rawValue
        
        NotificationCenter.default.post(name: .settingsChanged)
        dismiss(animated: true)
    }
    
    @IBAction func reset(_ sender: Any) {
        showAllSwitch.isOn = !Settings.scanAllDevices.defaultValue
        autoReconnectSwitch.isOn = Settings.autoReconnect.defaultValue
        serviceTextField.text = Settings.serviceUUID.defaultValue
        readCharTextField.text = Settings.readCharacteristicUUID.defaultValue
        writeCharTextField.text = Settings.writeCharacteristicUUID.defaultValue
        sendOnConnectField.data = Settings.sendOnConnect.defaultValue
        sendOnConnectField.selectedFormat = String.Format(rawValue: Settings.sendOnConnectFormat.defaultValue)!
    }
}


// MARK: DocumentsPicker Delegate

extension SettingsTableViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // note: there's a copy of this in the appdelegate
        func importFunctions(replace: Bool) {
            do {
                // try to load & save (takes care of migration too)
                let imported = try JSON.loadFunctions(url: url)
                
                if replace {
                    try JSON.saveFunctions(imported)
                } else {
                    let existing = try JSON.loadFunctions()
                    var i = existing.count
                    imported.forEach { $0.order = i; i += 1; }
                    try JSON.saveFunctions(existing + imported)
                }
                
                let alert = UIAlertController(title: "Success", message: "Imported \(imported.count) Functions", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                present(alert, animated: true)

            } catch {
                print("Failed to import: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Failed to load functions", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                present(alert, animated: true)
            }
        }
        
        func add(_: UIAlertAction) {
            importFunctions(replace: false)
        }
        func replace(_: UIAlertAction) {
            importFunctions(replace: true)
        }
        
        // create alert
        let alert = UIAlertController(title: "Import Functions", message: "Add to existing functions or replace all? This cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: add))
        alert.addAction(UIAlertAction(title: "Replace", style: .destructive, handler: replace))
        
        // present
        present(alert, animated: true)
    }
    
}
