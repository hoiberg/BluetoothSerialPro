//
//  DeviceAnalysisTableViewController.swift
//  BluetoothSerialPro
//
//  Created by Alex on 21/03/2017.
//  Copyright © 2017 Hangar42. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceAnalysisTableViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Variables
    
    var peripheral: CBPeripheral!
    var advertisementDataDict: [String: Any]?
    var advertisementData = [(key: String, value: Any)]()
    var rssiTimer: Timer?
    var lastRSSI: NSNumber?
    var rssiLabel: UILabel?
    
    var manager: CBCentralManager {
        return serial.centralManager
    }

    
    // MAKR: - Functions
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if manager.delegate !== self {
            manager.delegate = self
            manager.connect(peripheral, options: nil)
            
            if let dict = advertisementDataDict {
                for (key, value) in dict {
                    advertisementData.append((key, value))
                }
            } else {
                advertisementData = []
            }
            
            title = (peripheral.name ?? "Unidentified") + " Analysis"
            tableView.reloadData()
            lastRSSI = nil
        } else {
            rssiTimer?.invalidate()
            rssiTimer = Timer.scheduledTimer(timeInterval: 0.5, target: peripheral, selector: #selector(CBPeripheral.readRSSI), userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        rssiTimer?.invalidate()
    }
    
    func stringFrom(uuids: [CBUUID]?) -> String {
        if uuids == nil {
            return "nil"
        } else {
            var string = ""
            uuids!.forEach {
                string += " " + $0.uuidString
            }
            return string == "" ? "none" : string
        }
    }
    
    
    // MARK: - CBCentralManager
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            performSegue(withIdentifier: "unwindToScan", sender: self)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        rssiTimer?.invalidate()
        rssiTimer = Timer.scheduledTimer(timeInterval: 0.5, target: peripheral, selector: #selector(CBPeripheral.readRSSI), userInfo: nil, repeats: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        performSegue(withIdentifier: "unwindToScan", sender: self)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        performSegue(withIdentifier: "unwindToScan", sender: self)
    }
    
    
    // MARK: - CBPeripheral
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        tableView.reloadData()
        for s in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        tableView.reloadData()
        for c in service.characteristics! {
            peripheral.readValue(for: c)
            peripheral.discoverDescriptors(for: c)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        tableView.reloadData()
        for d in characteristic.descriptors! {
            peripheral.readValue(for: d)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // I know Nothing! </spanish accent>
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        tableView.reloadData()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        lastRSSI = RSSI
        rssiLabel?.text = RSSI.stringValue + "dB"
    }


    // MARK: - TableView DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 2
        case 2: return advertisementData.isEmpty ? 1 : advertisementData.count
        case 3:
            var i = 0
            for s in peripheral.services ?? [] {
                for _ in s.characteristics ?? [] {
                    i += 1
                }
                i += 1
            }
            return i == 0 ? 1 : i
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
            if indexPath.section == 0 {
                switch indexPath.row {
                case 0:
                    cell.textLabel!.text = "Name"
                    cell.detailTextLabel!.text = peripheral.name ?? "Unidentified"
                case 1:
                    cell.textLabel!.text = "UUID"
                    cell.detailTextLabel!.text = peripheral.identifier.uuidString
                default:
                    cell.textLabel!.text = "Error"
                    cell.detailTextLabel!.text = "Error"
                }
            } else if indexPath.section == 1 {
                switch indexPath.row {
                case 0:
                    cell.textLabel!.text = "Connected"
                    cell.detailTextLabel!.text = peripheral.state == .connected ? "True" : "False"
                case 1:
                    cell.textLabel!.text = "RSSI"
                    cell.detailTextLabel!.text = lastRSSI == nil ? "nil" : lastRSSI!.stringValue + "dB"
                    rssiLabel = cell.detailTextLabel
                default:
                    cell.textLabel!.text = "Error"
                    cell.detailTextLabel!.text = "Error"
                }
            } else if indexPath.section == 2 {
                if advertisementData.isEmpty {
                    cell.textLabel!.text = "nil"
                    cell.detailTextLabel!.text = ""
                } else {
                    let ad = advertisementData[indexPath.row]
                    switch ad.key {
                    case CBAdvertisementDataLocalNameKey:
                        cell.textLabel!.text = "Name"
                        cell.detailTextLabel!.text = ad.value as? String ?? "nil"
                    case CBAdvertisementDataIsConnectable:
                        cell.textLabel!.text = "Connectable"
                        cell.detailTextLabel!.text = ((ad.value as? NSNumber)?.intValue == 1 ? "True" : "False") ?? "nil"
                    case CBAdvertisementDataServiceUUIDsKey:
                        cell.textLabel!.text = "Services"
                        cell.detailTextLabel!.text = stringFrom(uuids: ad.value as? [CBUUID])
                    case CBAdvertisementDataServiceDataKey:
                        cell.textLabel!.text = "Service Data"
                        cell.detailTextLabel!.text = "Not Supported"
                    case CBAdvertisementDataTxPowerLevelKey:
                        cell.textLabel!.text = "Power Level"
                        cell.detailTextLabel!.text = (ad.value as? NSNumber)?.stringValue ?? "nil"
                    case CBAdvertisementDataOverflowServiceUUIDsKey:
                        cell.textLabel!.text = "Overflow Services"
                        cell.detailTextLabel!.text = stringFrom(uuids: ad.value as? [CBUUID])
                    case CBAdvertisementDataSolicitedServiceUUIDsKey:
                        cell.textLabel!.text = "Solicited Services"
                        cell.detailTextLabel!.text = stringFrom(uuids: ad.value as? [CBUUID])
                    default:
                        cell.textLabel!.text = "Error"
                        cell.detailTextLabel!.text = "Error"
                    }
                }
            }
            
            return cell
        } else {
            if (peripheral.services ?? []).isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
                cell.textLabel!.text = "nil"
                cell.detailTextLabel!.text = ""
                return cell
            } else {
                var i = 0
                for s in peripheral.services ?? [] {
                    if indexPath.row == i {
                        // Service Cell
                        let cell = tableView.dequeueReusableCell(withIdentifier: "serviceCell", for: indexPath)
                        cell.textLabel!.text = s.uuid.uuidString
                        if s.uuid.uuidString != "\(s.uuid)" {
                            cell.detailTextLabel!.text = "\(s.uuid)"
                        } else {
                            cell.detailTextLabel!.text = s.isPrimary ? "Primary" : "Secondary"
                        }
                        return cell
                    }
                    for c in s.characteristics ?? [] {
                        i += 1
                        if indexPath.row == i {
                            // Characteristic Cell
                            let cell = tableView.dequeueReusableCell(withIdentifier: "characteristicCell", for: indexPath)
                            cell.textLabel!.text = c.uuid.uuidString
                            if c.uuid.uuidString != "\(c.uuid)" {
                                cell.detailTextLabel!.text = "\(c.uuid)"
                            } else {
                                let desc = c.descriptors?.first { $0.uuid.uuidString == CBUUIDCharacteristicUserDescriptionString }
                                cell.detailTextLabel!.text = (desc?.value as? String) ?? "nil"
                            }
                            
                            if c == s.characteristics!.last {
                                cell.indentationLevel = 5
                                cell.separatorInset.left = 15
                            } else {
                                cell.indentationLevel = 0
                                cell.separatorInset.left = 60
                            }
                            return cell
                        }
                    }
                    i += 1
                }
                let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath)
                cell.textLabel!.text = "Error"
                cell.detailTextLabel!.text = "Error"
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "General"
        case 1: return "Status"
        case 2: return "Advertisement Data"
        case 3: return "Services"
        default: return "Error"
        }
    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToScan" {
            manager.delegate = serial
        } else {
            var i = 0
            let req = tableView.indexPathForSelectedRow!.row
            for s in peripheral.services! {
                for c in s.characteristics ?? [] {
                    i += 1
                    if i == req {
                        let vc = segue.destination as! CharacteristicAnalysisTableViewController
                        vc.characteristic = c
                        return
                    }
                }
                i += 1
            }
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: Any? = nil) {
        manager.cancelPeripheralConnection(peripheral)
    }
}
