//
//  CharacteristicAnalysisTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 21/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit
import CoreBluetooth

class CharacteristicAnalysisTableViewController: UITableViewController {
    
    @IBOutlet weak var formatButton: UIBarButtonItem!
    
    var characteristic: CBCharacteristic! {
        didSet {
            descriptors = characteristic.descriptors ?? []
            properties = []
            if characteristic.properties.contains(.authenticatedSignedWrites)  { properties.append("Authenticated Signed Writes") }
            if characteristic.properties.contains(.broadcast)                  { properties.append("Broadcast") }
            if characteristic.properties.contains(.read)                       { properties.append("Read") }
            if characteristic.properties.contains(.writeWithoutResponse)       { properties.append("Write Without Response") }
            if characteristic.properties.contains(.write)                      { properties.append("Write With Response") }
            if characteristic.properties.contains(.notify)                     { properties.append("Notify") }
            if characteristic.properties.contains(.indicate)                   { properties.append("Indicate") }
            if characteristic.properties.contains(.extendedProperties)         { properties.append("Extended Properties") }
            if characteristic.properties.contains(.notifyEncryptionRequired)   { properties.append("Notify Encryption Required") }
            if characteristic.properties.contains(.indicateEncryptionRequired) { properties.append("Indicate Encryption Required") }
        }
    }
    
    var descriptors: [CBDescriptor]!
    var properties: [String]!
    var selectedFormat = String.Format.hex

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = characteristic.uuid.uuidString + " Analysis"
        selectedFormat = String.Format.hex
        tableView.reloadData()
    }
    
    private func selectFormat(_ newFormat: String.Format) {
        selectedFormat = newFormat
        formatButton.title = ["UTF8", "Hex", "Dec", "Oct", "Bin"][selectedFormat.rawValue]
        tableView.reloadData()
    }


    // MARK: - TableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return descriptors.isEmpty ? 1 : descriptors.count
        case 2: return properties.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            if indexPath.section == 0 {
                switch indexPath.row {
                case 0:
                    cell.textLabel!.text = "UUID"
                    cell.detailTextLabel!.text = characteristic.uuid.uuidString
                case 1:
                    cell.textLabel!.text = "Descriptor"
                    if characteristic.uuid.uuidString != "\(characteristic.uuid)" {
                        cell.detailTextLabel!.text = "\(characteristic.uuid)"
                    } else {
                        cell.detailTextLabel!.text = "n/a"
                    }

                case 2:
                    cell.textLabel!.text = "Value"
                    cell.detailTextLabel!.text = characteristic.value?.string(withFormat: selectedFormat) ?? "nil"
                default:
                    cell.textLabel!.text = "Error"
                    cell.detailTextLabel!.text = "Error"
                }
            } else {
                if descriptors.isEmpty {
                    cell.textLabel!.text = "nil"
                    cell.detailTextLabel!.text = ""
                } else {
                    let descriptor = descriptors[indexPath.row]
                    switch descriptor.uuid.uuidString {
                    case CBUUIDCharacteristicFormatString:
                        cell.textLabel!.text = "Format UUID"
                        cell.detailTextLabel!.text = (descriptor.value as? Data)?.string(withFormat: .utf8) ?? "nil"
                    case CBUUIDCharacteristicExtendedPropertiesString:
                        cell.textLabel!.text = "Extended Properties"
                        cell.detailTextLabel!.text = (descriptor.value as? NSNumber)?.stringValue ?? "nil"
                    case CBUUIDCharacteristicUserDescriptionString:
                        cell.textLabel!.text = "User Description"
                        cell.detailTextLabel!.text = descriptor.value as? String ?? "nil"
                    case CBUUIDServerCharacteristicConfigurationString:
                        cell.textLabel!.text = "Server Configuration"
                        cell.detailTextLabel!.text = (descriptor.value as? NSNumber)?.stringValue ?? "nil"
                    case CBUUIDClientCharacteristicConfigurationString:
                        cell.textLabel!.text = "Client Configuration"
                        cell.detailTextLabel!.text = (descriptor.value as? NSNumber)?.stringValue ?? "nil"
                    case CBUUIDCharacteristicAggregateFormatString:
                        cell.textLabel!.text = "Aggregate Format"
                        cell.detailTextLabel!.text = (descriptor.value as? NSNumber)?.stringValue ?? "nil"
                    default:
                        cell.textLabel!.text = descriptor.uuid.uuidString
                        cell.detailTextLabel!.text = (descriptor.value as? Data)?.string(withFormat: .hex) ?? "error"
                    }
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
            cell.textLabel!.text = properties[indexPath.row]
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "General"
        case 1: return "Descriptors"
        case 2: return "Properties"
        default: return "Error"
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func selectFormat(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "UTF8",        style: .default) { _ in self.selectFormat(.utf8) })
        alert.addAction(UIAlertAction(title: "Hexadecimal", style: .default) { _ in self.selectFormat(.hex)  })
        alert.addAction(UIAlertAction(title: "Decimal",     style: .default) { _ in self.selectFormat(.dec)  })
        alert.addAction(UIAlertAction(title: "Octal",       style: .default) { _ in self.selectFormat(.oct)  })
        alert.addAction(UIAlertAction(title: "Binary",      style: .default) { _ in self.selectFormat(.bin)  })
        present(alert, animated: true, completion: nil)
    }
}
